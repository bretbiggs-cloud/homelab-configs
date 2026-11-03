# Seerr core acceptance. Reads private credentials, signs in and tests native
# integrations. Does not create requests, import users or launch downloads.
param([Parameter(Mandatory=$true)][string]$NasUser)
$ErrorActionPreference='Stop'
function Check([bool]$Ok,[string]$Label){if(!$Ok){throw "FAIL: $Label"};"PASS: $Label"}
$raw=ssh -o BatchMode=yes -o ConnectTimeout=15 "$NasUser@192.168.1.220" '/usr/local/bin/docker inspect homelab-v2-seerr prowlarr sonarr radarr seerr qbittorrent homepage omada-controller portainer'
Check ($LASTEXITCODE -eq 0) 'Container inspection'
$all=$raw|ConvertFrom-Json -DateKind String;$n=$all[0]
Check ($n.State.Running -and !$n.State.OOMKilled -and $n.RestartCount -eq 0) 'New Seerr running without crash/OOM'
Check ($n.Config.User -eq '1026:100' -and !$n.HostConfig.Privileged -and $n.HostConfig.CapDrop -contains 'ALL' -and $n.HostConfig.Init) 'Supported non-root identity, init and dropped capabilities'
Check ($n.Mounts.Count -eq 1 -and $n.Mounts[0].Source -eq '/volume1/docker/homelab-v2/seerr/data' -and $n.Mounts[0].Destination -eq '/app/config') 'Isolated config; no media or old data mounts'
Check ($n.HostConfig.PortBindings.'5055/tcp'[0].HostIp -eq '192.168.1.220' -and $n.HostConfig.PortBindings.'5055/tcp'[0].HostPort -eq '5056') 'LAN-only5056 binding'
$b=Get-Content "$PSScriptRoot/../../.configs/validation/container-baseline.json" -Raw|ConvertFrom-Json -DateKind String
foreach($old in $all[1..8]){$before=$b|Where-Object Name -eq $old.Name;Check ($old.State.Running -and $old.Id -eq $before.Id -and $old.State.StartedAt -eq $before.StartedAt) "Old $($old.Name) unchanged"}
$c=Get-Content "$env:USERPROFILE/.codex/private/homelab/seerr-new-admin.json" -Raw|ConvertFrom-Json;$h=@{'X-Api-Key'=$c.ApiKey}
$pub=Invoke-RestMethod "$($c.Url)/api/v1/settings/public" -TimeoutSec 20
Check ($pub.initialized -and $pub.mediaServerType -eq 2) 'Initialized with Jellyfin'
$anon=Invoke-WebRequest "$($c.Url)/api/v1/auth/me" -SkipHttpErrorCheck -TimeoutSec 15
Check ($anon.StatusCode -in @(401,403)) 'Anonymous authenticated API denied'
$j=Get-Content "$env:USERPROFILE/.codex/private/homelab/jellyfin-new-admin.json" -Raw|ConvertFrom-Json
$session=[Microsoft.PowerShell.Commands.WebRequestSession]::new()
$u=Invoke-RestMethod "$($c.Url)/api/v1/auth/jellyfin" -Method Post -ContentType application/json -Body (@{username=$j.Username;password=$j.Password}|ConvertTo-Json) -WebSession $session -TimeoutSec 30
Check ($u.id -eq 1 -and $session.Cookies.GetCookies($c.Url).Count -gt 0) 'Saved Jellyfin admin login works'
$main=Invoke-RestMethod "$($c.Url)/api/v1/settings/main" -Headers $h -TimeoutSec 15
Check ($main.defaultPermissions -eq 160 -and !$main.newPlexLogin -and $main.mediaServerLogin -and !$main.localLogin) 'Automatic approval for admitted users; no automatic new-user enrollment'
$jf=Invoke-RestMethod "$($c.Url)/api/v1/settings/jellyfin" -Headers $h -TimeoutSec 15
Check ($jf.ip -eq 'homelab-v2-jellyfin' -and $jf.port -eq 8096) 'Only new Jellyfin linked'
Check ($jf.externalHostname -eq 'http://substation.tail8f9607.ts.net:8096') 'Jellyfin playback link uses Tailscale'
foreach($kind in @('radarr','sonarr')){
 $services=Invoke-RestMethod "$($c.Url)/api/v1/settings/$kind" -Headers $h -TimeoutSec 15;$s=$services[0]
 $root=if($kind -eq 'radarr'){'/downloads/library/movies'}else{'/downloads/library/tv'}
 $profile=if($kind -eq 'radarr'){'Movies 1080p'}else{'TV 1080p'}
 Check (@($services).Count -eq 1 -and $s.hostname -eq "homelab-v2-$kind" -and $s.isDefault -and !$s.is4k -and !$s.preventSearch -and $s.activeDirectory -eq $root -and $s.activeProfileName -eq $profile) "New $kind default1080p root and automatic search"
 $payload=@{hostname=$s.hostname;port=$s.port;apiKey=$s.apiKey;useSsl=$s.useSsl;baseUrl=$s.baseUrl}
 Invoke-RestMethod "$($c.Url)/api/v1/settings/$kind/test" -Headers $h -Method Post -ContentType application/json -Body ($payload|ConvertTo-Json) -TimeoutSec 30|Out-Null
 "PASS: native $kind connection"
}
$req=Invoke-RestMethod "$($c.Url)/api/v1/request" -Headers $h -TimeoutSec 15
Check (@($req.results).Count -eq 1 -and $req.results[0].id -eq 1 -and $req.results[0].media.tmdbId -eq 45745 -and $req.results[0].status -eq 5) 'Only completed Sintel validation request exists'
$serve=Get-Content "$PSScriptRoot/../../.configs/tailscale/serve.json" -Raw|ConvertFrom-Json
Check ($serve.TCP.'5056'.TCPForward -eq 'homelab-v2-seerr:5055') 'Private Tailscale5056 declared'
$raw=ssh -o BatchMode=yes -o ConnectTimeout=15 "$NasUser@192.168.1.220" '/usr/local/bin/docker exec homelab-v2-tailscale wget -qO- -T 15 http://homelab-v2-seerr:5055/api/v1/status'
Check ($LASTEXITCODE -eq 0 -and ($raw|ConvertFrom-Json).version) 'Tailscale resolves and reaches Seerr'
# New import destinations must be visible through Jellyfin's existing read-only
# media mount; preserve original library folders while adding new destinations.
$secret=(Get-Content "$env:USERPROFILE/.codex/private/homelab/jellyfin-session.dpapi" -Raw).Trim()|ConvertTo-SecureString
$token=[Net.NetworkCredential]::new('',$secret).Password
$jh=@{Authorization=('MediaBrowser Token="'+$token+'", Client="Codex setup", Device="Windows", DeviceId="homelab-new-setup", Version="1.0"')}
$libs=Invoke-RestMethod 'http://192.168.1.220:8097/Library/VirtualFolders' -Headers $jh -TimeoutSec 15
$movies=$libs|Where-Object Name -eq 'Movies';$tv=$libs|Where-Object Name -eq 'TV Shows'
Check ($movies.Locations -contains '/media/downloads-v2/library/movies' -and $movies.Locations -contains '/media/Movies' -and $movies.Locations -contains '/media/Kid Movies' -and $tv.Locations -contains '/media/downloads-v2/library/tv' -and $tv.Locations -contains '/media/tv_shows') 'Jellyfin preserves original folders and includes new import roots'
