# Post-cutover smoke checks, replacing parallel-phase old-running assertions.
# Usage: ./test_synology_cutover.ps1 -NasUser <SSH user>
# Reads private credentials; tests native connections without requesting media.
param([Parameter(Mandatory=$true)][string]$NasUser, [switch]$OldRemoved)
$ErrorActionPreference='Stop'
function Check([bool]$Ok,[string]$Name){if(!$Ok){throw "FAIL: $Name"};"PASS: $Name"}
$oldNames=@('qbittorrent','prowlarr','sonarr','radarr','seerr')
$newNames=@('jellyfin','tailscale','vpn','qbittorrent','prowlarr','flaresolverr','radarr','sonarr','seerr')|ForEach-Object {"homelab-v2-$_"}
$names=$newNames+@('homepage','omada-controller','portainer')
if(!$OldRemoved){$names+=$oldNames}
$raw=ssh -o BatchMode=yes -o ConnectTimeout=15 "$NasUser@192.168.1.220" ('/usr/local/bin/docker inspect '+($names -join ' '))
Check ($LASTEXITCODE -eq 0) 'Inspect exact cutover containers'
$containers=$raw|ConvertFrom-Json -DateKind String
foreach($name in $newNames){
 $c=$containers|Where-Object Name -eq "/$name"
 Check ($c.State.Running -and !$c.State.OOMKilled -and (!$c.State.Health -or $c.State.Health.Status -eq 'healthy')) "$name running and healthy where configured"
}
# Removal is an authorized phase change; still assert exact absence, not just stopped.
if($OldRemoved){
 $present=ssh -o BatchMode=yes -o ConnectTimeout=15 "$NasUser@192.168.1.220" '/usr/local/bin/docker ps -a --format "{{.Names}}"'
 Check ($LASTEXITCODE -eq 0) 'Read all container names'
 foreach($name in $oldNames){Check ($present -notcontains $name) "Old $name removed"}
}else{
 foreach($name in $oldNames){$c=$containers|Where-Object Name -eq "/$name";Check (!$c.State.Running -and $c.HostConfig.RestartPolicy.Name -eq 'no') "Old $name stopped with automatic restart disabled, retained for rollback"}
}
$b=Get-Content "$PSScriptRoot/../../.configs/validation/container-baseline.json" -Raw|ConvertFrom-Json -DateKind String
foreach($name in @('homepage','omada-controller','portainer')){
 $c=$containers|Where-Object Name -eq "/$name";$before=$b|Where-Object Name -eq $c.Name
 Check ($c.State.Running -and $c.Id -eq $before.Id -and $c.State.StartedAt -eq $before.StartedAt) "$name unchanged"
}
foreach($kind in @('radarr','sonarr')){
 $cred=Get-Content "$env:USERPROFILE/.codex/private/homelab/$kind-new-admin.json" -Raw|ConvertFrom-Json
 $h=@{'X-Api-Key'=$cred.ApiKey};$v=if($kind -eq 'radarr'){'v3'}else{'v3'}
 $base="$($cred.Url)/api/$v"
 $clients=Invoke-RestMethod "$base/downloadclient" -Headers $h -TimeoutSec 20
 Check ($clients.Count -eq 1 -and $clients[0].enable -and ($clients[0].fields|Where-Object name -eq host).value -eq 'homelab-v2-vpn') "$kind uses new downloader only"
 Invoke-RestMethod "$base/downloadclient/test" -Method Post -ContentType application/json -Body ($clients[0]|ConvertTo-Json -Depth 30) -Headers $h -TimeoutSec 30|Out-Null
 Check $true "$kind native downloader connection test"
 $ix=Invoke-RestMethod "$base/indexer" -Headers $h -TimeoutSec 20
 Check ($ix.Count -ge 2 -and @($ix|Where-Object {($_.fields|Where-Object name -eq baseUrl).value -notmatch '^http://homelab-v2-prowlarr:9696/'}).Count -eq 0) "$kind indexers use new Prowlarr only"
 foreach($pair in @(@('LimeTorrents (Prowlarr)','2'),@('The Pirate Bay (Prowlarr)','3'))){
  $entry=@($ix|Where-Object name -eq $pair[0])
  Check ($entry.Count -eq 1 -and ($entry[0].fields|Where-Object name -eq baseUrl).value -eq "http://homelab-v2-prowlarr:9696/$($pair[1])/") "$kind correct source ID for $($pair[0])"
 }
 $health=Invoke-RestMethod "$base/health" -Headers $h -TimeoutSec 20
 foreach($issue in $health){Write-Output "$kind health: $($issue.type): $($issue.message)"}
 if($kind -eq 'radarr'){$movies=Invoke-RestMethod "$base/movie" -Headers $h -TimeoutSec 20}
}
$s=Get-Content "$env:USERPROFILE/.codex/private/homelab/seerr-new-admin.json" -Raw|ConvertFrom-Json
$sh=@{'X-Api-Key'=$s.ApiKey}
foreach($kind in @('radarr','sonarr')){
 $services=Invoke-RestMethod "$($s.Url)/api/v1/settings/$kind" -Headers $sh -TimeoutSec 20;$svc=$services[0]
 Check ($services.Count -eq 1 -and $svc.hostname -eq "homelab-v2-$kind" -and $svc.isDefault -and !$svc.preventSearch) "Seerr uses new $kind with automatic search"
 $body=@{hostname=$svc.hostname;port=$svc.port;apiKey=$svc.apiKey;useSsl=$svc.useSsl;baseUrl=$svc.baseUrl}|ConvertTo-Json
 Invoke-RestMethod "$($s.Url)/api/v1/settings/$kind/test" -Method Post -Headers $sh -ContentType application/json -Body $body -TimeoutSec 30|Out-Null
 Check $true "Seerr native $kind connection test"
}
$secret=(Get-Content "$env:USERPROFILE/.codex/private/homelab/jellyfin-session.dpapi" -Raw).Trim()|ConvertTo-SecureString
$token=[Net.NetworkCredential]::new('',$secret).Password
$jh=@{Authorization=('MediaBrowser Token="'+$token+'", Client="Codex setup", Device="Windows", DeviceId="homelab-new-setup", Version="1.0"')}
foreach($id in @(1384216,1084244)){
 $m=@($movies|Where-Object tmdbId -eq $id)
 Check ($m.Count -eq 1 -and $m[0].hasFile -and $m[0].path.StartsWith('/downloads/library/movies/')) "Real request $id imported into new movie root"
 $items=Invoke-RestMethod ('http://192.168.1.220:8097/Items?Recursive=true&Fields=Path&SearchTerm='+[uri]::EscapeDataString($m[0].title)) -Headers $jh -TimeoutSec 20
 $expected=($m[0].path+'/'+$m[0].movieFile.relativePath).Replace('/downloads/library/','/media/downloads-v2/library/')
 $item=@($items.Items|Where-Object Path -eq $expected)
 Check ($item.Count -eq 1) "Real request $id indexed in Jellyfin"
 $range=@{Authorization=$jh.Authorization;Range='bytes=0-65535'}
 $response=Invoke-WebRequest "http://192.168.1.220:8097/Videos/$($item[0].Id)/stream?static=true" -Headers $range -TimeoutSec 30
 Check ($response.StatusCode -eq 206 -and $response.RawContentLength -eq 65536) "Real request $id authenticated playback bytes served"
}
$requests=Invoke-RestMethod "$($s.Url)/api/v1/request?take=100" -Headers $sh -TimeoutSec 20
foreach($id in @(1384216,1084244)){$r=@($requests.results|Where-Object {$_.media.tmdbId -eq $id});Check ($r.Count -eq 1 -and $r[0].status -eq 5 -and $r[0].media.status -eq 5) "Seerr marks real request $id available"}
$raw=ssh -o BatchMode=yes -o ConnectTimeout=15 "$NasUser@192.168.1.220" '/usr/local/bin/docker exec homelab-v2-tailscale wget -qO- -T 15 http://homelab-v2-seerr:5055/api/v1/status'
Check ($LASTEXITCODE -eq 0 -and ($raw|ConvertFrom-Json).version) 'Tailscale container reaches new Seerr'
