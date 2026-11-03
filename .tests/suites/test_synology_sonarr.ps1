# Read-only acceptance checks for isolated Synology Sonarr; PowerShell7.5+.
# Reads private credentials, never prints API keys/passwords. No searches or jobs.
param([Parameter(Mandatory=$true)][string]$NasUser)
$ErrorActionPreference='Stop'
function Check([bool]$Ok,[string]$Name){if(!$Ok){throw "FAIL: $Name"}; Write-Output "PASS: $Name"}
$raw=& ssh -o BatchMode=yes -o ConnectTimeout=10 "$NasUser@192.168.1.220" '/usr/local/bin/docker inspect homelab-v2-sonarr prowlarr sonarr radarr seerr qbittorrent homepage omada-controller portainer'
Check ($LASTEXITCODE -eq 0) 'Container inspection'
$all=$raw|ConvertFrom-Json -DateKind String; $r=$all[0]
Check ($r.State.Running -and $r.RestartCount -eq 0 -and !$r.State.OOMKilled) 'Sonarr running without crashes'
Check ($r.Mounts.Count -eq 2 -and ($r.Mounts|Where-Object Destination -eq '/config').Source -eq '/volume1/docker/homelab-v2/sonarr/data' -and ($r.Mounts|Where-Object Destination -eq '/downloads').Source -eq '/volume1/media/downloads-v2') 'Only isolated config and shared new-stack data mounted'
Check ($r.HostConfig.PortBindings.'8989/tcp'[0].HostIp -eq '192.168.1.220' -and $r.HostConfig.PortBindings.'8989/tcp'[0].HostPort -eq '8990') 'LAN-only port8990'
Check (!$r.HostConfig.Privileged -and $r.Config.Env -contains 'PUID=1026' -and $r.Config.Env -contains 'PGID=100') 'Supported LSIO identity model'
$b=Get-Content "$PSScriptRoot/../../.configs/validation/container-baseline.json" -Raw|ConvertFrom-Json -DateKind String
foreach($old in $all[1..8]){$before=$b|Where-Object Name -eq $old.Name; Check ($old.State.Running -and $old.Id -eq $before.Id -and $old.State.StartedAt -eq $before.StartedAt) "Old $($old.Name) unchanged since recovery"}
$c=Get-Content "$env:USERPROFILE/.codex/private/homelab/sonarr-new-admin.json" -Raw|ConvertFrom-Json; $h=@{'X-Api-Key'=$c.ApiKey}
$status=Invoke-RestMethod "$($c.Url)/api/v3/system/status" -Headers $h -TimeoutSec 15
Check ($status.appName -eq 'Sonarr') 'Authenticated Sonarr API'
$hc=Invoke-RestMethod "$($c.Url)/api/v3/config/host" -Headers $h -TimeoutSec 15
Check ($hc.authenticationMethod -eq 'forms' -and $hc.authenticationRequired -eq 'enabled') 'Authentication required for all addresses'
$denied=Invoke-WebRequest "$($c.Url)/api/v3/system/status" -SkipHttpErrorCheck -TimeoutSec 15
Check ($denied.StatusCode -eq 401) 'Anonymous API denied'
$session=[Microsoft.PowerShell.Commands.WebRequestSession]::new()
Invoke-WebRequest "$($c.Url)/login" -Method Post -Body @{username=$c.Username;password=$c.Password;rememberMe='on'} -WebSession $session -TimeoutSec 15|Out-Null
$page=Invoke-WebRequest "$($c.Url)/" -WebSession $session -SkipHttpErrorCheck -MaximumRedirection 0 -ErrorAction SilentlyContinue -TimeoutSec 15
Check ($page.StatusCode -eq 200 -and $session.Cookies.GetCookies($c.Url).Count -gt 0) 'Private saved browser credential works'
$roots=Invoke-RestMethod "$($c.Url)/api/v3/rootfolder" -Headers $h -TimeoutSec 15
Check (@($roots).Count -eq 1 -and $roots[0].path -eq '/downloads/library/tv' -and $roots[0].accessible) 'Only isolated accessible root folder'
$profiles=Invoke-RestMethod "$($c.Url)/api/v3/qualityprofile" -Headers $h -TimeoutSec 15
$profile=$profiles|Where-Object name -eq 'TV 1080p'
Check ($null -ne $profile -and !$profile.upgradeAllowed) '1080p profile with upgrades off'
function Allowed-Qualities($items){foreach($item in $items){if($item.allowed){if($item.quality){$item.quality.name}; if($item.items){Allowed-Qualities $item.items}}}}
$allowed=@(Allowed-Qualities $profile.items)
Check ($allowed.Count -gt 0 -and @($allowed|Where-Object {$_ -notmatch '1080p' -or $_ -match 'Remux'}).Count -eq 0) 'Only1080p qualities; no remux/4K'
foreach($endpoint in @('series')){$items=Invoke-RestMethod "$($c.Url)/api/v3/$endpoint" -Headers $h -TimeoutSec 15; Check (@($items).Count -eq 0) "No $endpoint entries or production jobs"}
# Approved pipeline phase supersedes the earlier empty-client baseline.
$clients=Invoke-RestMethod "$($c.Url)/api/v3/downloadclient" -Headers $h -TimeoutSec 15
Check (@($clients).Count -eq 1 -and $clients[0].name -eq 'qBittorrent New' -and $clients[0].enable -and $clients[0].implementation -eq 'QBittorrent') 'Only new qBittorrent client enabled'
$client=$clients[0]
Check (($client.fields|Where-Object name -eq 'host').value -eq 'homelab-v2-vpn' -and ($client.fields|Where-Object name -eq 'port').value -eq 8082 -and ($client.fields|Where-Object name -eq 'tvCategory').value -eq 'tv-sonarr') 'New VPN endpoint and dedicated Sonarr category'
Check (!$client.removeCompletedDownloads -and !$client.removeFailedDownloads) 'Automatic downloader removal disabled during parallel setup'
$management=Invoke-RestMethod "$($c.Url)/api/v3/config/mediamanagement" -Headers $h -TimeoutSec 15
Check $management.copyUsingHardlinks 'Hardlink imports enabled'
$mapping=Invoke-RestMethod "$($c.Url)/api/v3/remotepathmapping" -Headers $h -TimeoutSec 15
Check (@($mapping).Count -eq 0) 'Shared paths need no remote path mapping'
$indexers=Invoke-RestMethod "$($c.Url)/api/v3/indexer" -Headers $h -TimeoutSec 15
$expected=@('LimeTorrents (Prowlarr)','The Pirate Bay (Prowlarr)')
Check (@($indexers).Count -eq 2 -and @(Compare-Object ($indexers.name|Sort-Object) ($expected|Sort-Object)).Count -eq 0) 'Two selected direct TV indexers synced from new Prowlarr'
foreach($i in $indexers){Check (($i.fields|Where-Object name -eq 'baseUrl').value -match '^http://homelab-v2-prowlarr:9696/') "New Prowlarr endpoint: $($i.name)"}
$serve=Get-Content "$PSScriptRoot/../../.configs/tailscale/serve.json" -Raw|ConvertFrom-Json
Check ($serve.TCP.'8990'.TCPForward -eq 'homelab-v2-sonarr:8989') 'Private Tailscale target declared'
$ping=& ssh -o BatchMode=yes -o ConnectTimeout=10 "$NasUser@192.168.1.220" '/usr/local/bin/docker exec homelab-v2-tailscale wget -qO- -T 10 http://homelab-v2-sonarr:8989/ping'
Check ($LASTEXITCODE -eq 0 -and ($ping -join '') -match 'OK') 'Tailscale resolves and reaches Sonarr'
$notifications=Invoke-RestMethod "$($c.Url)/api/v3/notification" -Headers $h -TimeoutSec 15
$n=$notifications|Where-Object name -eq 'Jellyfin New'
Check ($null -ne $n -and $n.onDownload -and $n.onUpgrade -and ($n.fields|Where-Object name -eq 'host').value -eq 'homelab-v2-jellyfin' -and ($n.fields|Where-Object name -eq 'mapFrom').value -eq '/downloads/library' -and ($n.fields|Where-Object name -eq 'mapTo').value -eq '/media/downloads-v2/library') 'Native new Jellyfin import notification and path mapping configured'
