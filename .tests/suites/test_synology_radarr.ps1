# Read-only acceptance checks for isolated Synology Radarr; PowerShell7.5+.
# Reads private credentials, never prints API keys/passwords. No searches or jobs.
param([Parameter(Mandatory=$true)][string]$NasUser, [switch]$CoreOnly)
$ErrorActionPreference='Stop'
function Check([bool]$Ok,[string]$Name){if(!$Ok){throw "FAIL: $Name"}; Write-Output "PASS: $Name"}
$raw=& ssh -o BatchMode=yes -o ConnectTimeout=10 "$NasUser@192.168.1.220" '/usr/local/bin/docker inspect homelab-v2-radarr prowlarr sonarr radarr seerr qbittorrent homepage omada-controller portainer'
Check ($LASTEXITCODE -eq 0) 'Container inspection'
$all=$raw|ConvertFrom-Json -DateKind String; $r=$all[0]
Check ($r.State.Running -and $r.RestartCount -eq 0 -and !$r.State.OOMKilled) 'Radarr running without crashes'
Check ($r.Mounts.Count -eq 2 -and ($r.Mounts|Where-Object Destination -eq '/config').Source -eq '/volume1/docker/homelab-v2/radarr/data' -and ($r.Mounts|Where-Object Destination -eq '/downloads').Source -eq '/volume1/media/downloads-v2') 'Only isolated config and shared new-stack data mounted'
Check ($r.HostConfig.PortBindings.'7878/tcp'[0].HostIp -eq '192.168.1.220' -and $r.HostConfig.PortBindings.'7878/tcp'[0].HostPort -eq '7879') 'LAN-only port7879'
Check (!$r.HostConfig.Privileged -and $r.Config.Env -contains 'PUID=1026' -and $r.Config.Env -contains 'PGID=100') 'Supported LSIO identity model'
$b=Get-Content "$PSScriptRoot/../../.configs/validation/container-baseline.json" -Raw|ConvertFrom-Json -DateKind String
foreach($old in $all[1..8]){$before=$b|Where-Object Name -eq $old.Name; Check ($old.State.Running -and $old.Id -eq $before.Id -and $old.State.StartedAt -eq $before.StartedAt) "Old $($old.Name) unchanged since recovery"}
$c=Get-Content "$env:USERPROFILE/.codex/private/homelab/radarr-new-admin.json" -Raw|ConvertFrom-Json; $h=@{'X-Api-Key'=$c.ApiKey}
$status=Invoke-RestMethod "$($c.Url)/api/v3/system/status" -Headers $h -TimeoutSec 15
Check ($status.appName -eq 'Radarr') 'Authenticated Radarr API'
$hc=Invoke-RestMethod "$($c.Url)/api/v3/config/host" -Headers $h -TimeoutSec 15
Check ($hc.authenticationMethod -eq 'forms' -and $hc.authenticationRequired -eq 'enabled') 'Authentication required for all addresses'
$denied=Invoke-WebRequest "$($c.Url)/api/v3/system/status" -SkipHttpErrorCheck -TimeoutSec 15
Check ($denied.StatusCode -eq 401) 'Anonymous API denied'
$session=[Microsoft.PowerShell.Commands.WebRequestSession]::new()
Invoke-WebRequest "$($c.Url)/login" -Method Post -Body @{username=$c.Username;password=$c.Password;rememberMe='on'} -WebSession $session -TimeoutSec 15|Out-Null
$page=Invoke-WebRequest "$($c.Url)/" -WebSession $session -SkipHttpErrorCheck -MaximumRedirection 0 -ErrorAction SilentlyContinue -TimeoutSec 15
Check ($page.StatusCode -eq 200 -and $session.Cookies.GetCookies($c.Url).Count -gt 0) 'Private saved browser credential works'
$roots=Invoke-RestMethod "$($c.Url)/api/v3/rootfolder" -Headers $h -TimeoutSec 15
Check (@($roots).Count -eq 1 -and $roots[0].path -eq '/downloads/library/movies' -and $roots[0].accessible) 'Only isolated accessible root folder'
$profiles=Invoke-RestMethod "$($c.Url)/api/v3/qualityprofile" -Headers $h -TimeoutSec 15
$profile=$profiles|Where-Object name -eq 'Movies 1080p'
Check ($null -ne $profile -and !$profile.upgradeAllowed) '1080p profile with upgrades off'
function Allowed-Qualities($items){foreach($item in $items){if($item.allowed){if($item.quality){$item.quality.name}; if($item.items){Allowed-Qualities $item.items}}}}
$allowed=@(Allowed-Qualities $profile.items)
Check ($allowed.Count -gt 0 -and @($allowed|Where-Object {$_ -notmatch '1080p' -or $_ -match 'Remux'}).Count -eq 0) 'Only1080p qualities; no remux/4K'
# Deliberate end-to-end validation replaces the earlier empty movie baseline.
$movies=Invoke-RestMethod "$($c.Url)/api/v3/movie" -Headers $h -TimeoutSec 15
Check (@($movies).Count -eq 1 -and $movies[0].tmdbId -eq 45745 -and !$movies[0].monitored -and $movies[0].hasFile) 'Only imported unmonitored Sintel validation movie exists'
# Approved pipeline phase supersedes the earlier empty-client baseline.
$clients=Invoke-RestMethod "$($c.Url)/api/v3/downloadclient" -Headers $h -TimeoutSec 15
Check (@($clients).Count -eq 1 -and $clients[0].name -eq 'qBittorrent New' -and $clients[0].enable -and $clients[0].implementation -eq 'QBittorrent') 'Only new qBittorrent client enabled'
$client=$clients[0]
Check (($client.fields|Where-Object name -eq 'host').value -eq 'homelab-v2-vpn' -and ($client.fields|Where-Object name -eq 'port').value -eq 8082 -and ($client.fields|Where-Object name -eq 'movieCategory').value -eq 'radarr') 'New VPN endpoint and dedicated Radarr category'
Check (!$client.removeCompletedDownloads -and !$client.removeFailedDownloads) 'Automatic downloader removal disabled during parallel setup'
$management=Invoke-RestMethod "$($c.Url)/api/v3/config/mediamanagement" -Headers $h -TimeoutSec 15
Check $management.copyUsingHardlinks 'Hardlink imports enabled'
$mapping=Invoke-RestMethod "$($c.Url)/api/v3/remotepathmapping" -Headers $h -TimeoutSec 15
Check (@($mapping).Count -eq 0) 'Shared paths need no remote path mapping'
$indexers=Invoke-RestMethod "$($c.Url)/api/v3/indexer" -Headers $h -TimeoutSec 15
$expected=@('1337x (Prowlarr)','LimeTorrents (Prowlarr)','The Pirate Bay (Prowlarr)')
if ($CoreOnly) {
    Check (@($indexers).Count -ge 2 -and $indexers.name -contains 'LimeTorrents (Prowlarr)' -and $indexers.name -contains 'The Pirate Bay (Prowlarr)' -and @($indexers|Where-Object name -notin $expected).Count -eq 0) 'Core movie indexers present; no unexpected indexers'
    Write-Warning 'Core-only validation: full three-indexer acceptance remains pending.'
} else {
Check (@($indexers).Count -eq 3 -and @(Compare-Object ($indexers.name|Sort-Object) ($expected|Sort-Object)).Count -eq 0) 'Three compatible movie indexers synced from new Prowlarr'
}
foreach($i in $indexers){Check (($i.fields|Where-Object name -eq 'baseUrl').value -match '^http://homelab-v2-prowlarr:9696/') "New Prowlarr endpoint: $($i.name)"}
$serve=Get-Content "$PSScriptRoot/../../.configs/tailscale/serve.json" -Raw|ConvertFrom-Json
Check ($serve.TCP.'7879'.TCPForward -eq 'homelab-v2-radarr:7878') 'Private Tailscale target declared'
$ping=& ssh -o BatchMode=yes -o ConnectTimeout=10 "$NasUser@192.168.1.220" '/usr/local/bin/docker exec homelab-v2-tailscale wget -qO- -T 10 http://homelab-v2-radarr:7878/ping'
Check ($LASTEXITCODE -eq 0 -and ($ping -join '') -match 'OK') 'Tailscale resolves and reaches Radarr'
$notifications=Invoke-RestMethod "$($c.Url)/api/v3/notification" -Headers $h -TimeoutSec 15
$n=$notifications|Where-Object name -eq 'Jellyfin New'
Check ($null -ne $n -and $n.onDownload -and $n.onUpgrade -and ($n.fields|Where-Object name -eq 'host').value -eq 'homelab-v2-jellyfin' -and ($n.fields|Where-Object name -eq 'mapFrom').value -eq '/downloads/library' -and ($n.fields|Where-Object name -eq 'mapTo').value -eq '/media/downloads-v2/library') 'Native new Jellyfin import notification and path mapping configured'
