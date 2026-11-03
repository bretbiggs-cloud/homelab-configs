# Read-only checks of the retained Creative Commons Sintel artifact. No downloads.
param([Parameter(Mandatory=$true)][string]$NasUser)
$ErrorActionPreference='Stop'
function Check([bool]$Ok,[string]$Name){if(!$Ok){throw "FAIL: $Name"};"PASS: $Name"}
$v=Get-Content "$PSScriptRoot/../../.configs/validation/sintel.json" -Raw|ConvertFrom-Json
$r=Get-Content "$env:USERPROFILE/.codex/private/homelab/radarr-new-admin.json" -Raw|ConvertFrom-Json
$m=Invoke-RestMethod "$($r.Url)/api/v3/movie/$($v.radarrId)" -Headers @{'X-Api-Key'=$r.ApiKey} -TimeoutSec 20
Check ($m.tmdbId -eq $v.tmdbId -and $m.hasFile -and !$m.monitored -and $m.movieFile.quality.quality.name -eq 'WEBDL-480p') 'Imported file labeled low resolution and unmonitored'
$s=Get-Content "$env:USERPROFILE/.codex/private/homelab/seerr-new-admin.json" -Raw|ConvertFrom-Json
$req=Invoke-RestMethod "$($s.Url)/api/v1/request/$($v.seerrRequestId)" -Headers @{'X-Api-Key'=$s.ApiKey} -TimeoutSec 20
Check ($req.status -eq 5 -and $req.media.status -eq 5 -and $req.media.tmdbId -eq $v.tmdbId) 'Seerr request completed and test movie available'
$cmd="stat -c '%i %h %s' '/volume1/media/downloads-v2/validation/Sintel/Sintel.mp4' '/volume1/media/downloads-v2/library/movies/Sintel (2010)/Sintel.mp4'"
$stats=ssh -o BatchMode=yes -o ConnectTimeout=15 "$NasUser@192.168.1.220" $cmd
Check ($LASTEXITCODE -eq 0 -and $stats.Count -eq 2 -and $stats[0] -eq $stats[1] -and [int]($stats[0].Split(' ')[1]) -ge 2) 'Original and import share inode; no duplicate video allocation'
$secret=(Get-Content "$env:USERPROFILE/.codex/private/homelab/jellyfin-session.dpapi" -Raw).Trim()|ConvertTo-SecureString
$token=[Net.NetworkCredential]::new('',$secret).Password
$h=@{Authorization=('MediaBrowser Token="'+$token+'", Client="Codex setup", Device="Windows", DeviceId="homelab-new-setup", Version="1.0"')}
$items=Invoke-RestMethod 'http://192.168.1.220:8097/Items?Recursive=true&SearchTerm=Sintel&Fields=Path,MediaSources' -Headers $h -TimeoutSec 20
$item=@($items.Items|Where-Object Path -eq $v.jellyfinPath)
Check ($item.Count -eq 1 -and $item[0].Type -eq 'Movie') 'Jellyfin indexed exact imported file'
$range=@{Authorization=$h.Authorization;Range='bytes=0-65535'}
$response=Invoke-WebRequest "http://192.168.1.220:8097/Videos/$($item[0].Id)/stream?static=true" -Headers $range -TimeoutSec 30
Check ($response.StatusCode -eq 206 -and $response.RawContentLength -eq 65536) 'Jellyfin serves authenticated64KiB video range'
