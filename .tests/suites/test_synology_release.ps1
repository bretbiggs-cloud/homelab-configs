# Read-only production release checks, adapted to DSM and completed old-stack retirement.
# Usage: ./test_synology_release.ps1 -NasUser <SSH user> [-SkipEnhanced]
# SkipEnhanced is only for pre-restart checks, not final release acceptance.
# Uses private management credentials; prints assertions, never keys or raw inspection.
# No new downloads, service restarts, file deletions or network changes.
param([Parameter(Mandatory=$true)][string]$NasUser,[switch]$SkipEnhanced)
$ErrorActionPreference='Stop'
function Check([bool]$Ok,[string]$Name){if(!$Ok){throw "FAIL: $Name"};"PASS: $Name"}
$private="$env:USERPROFILE/.codex/private/homelab"
$names=@('jellyfin','tailscale','vpn','qbittorrent','prowlarr','flaresolverr','radarr','sonarr','seerr')|ForEach-Object {"homelab-v2-$_"}
$raw=ssh -o BatchMode=yes -o ConnectTimeout=15 "$NasUser@192.168.1.220" ('/usr/local/bin/docker inspect '+($names -join ' '))
Check ($LASTEXITCODE -eq 0) 'Inspect production services'
$containers=$raw|ConvertFrom-Json -DateKind String
foreach($c in $containers){
 Check ($c.State.Running -and !$c.State.OOMKilled -and (!$c.State.Health -or $c.State.Health.Status -eq 'healthy')) "$($c.Name) runtime"
 Check ($c.HostConfig.LogConfig.Type -eq 'json-file' -and $c.HostConfig.LogConfig.Config.'max-size' -eq '10m' -and $c.HostConfig.LogConfig.Config.'max-file' -eq '3') "$($c.Name) log rotation"
}
$j=$containers|Where-Object Name -eq '/homelab-v2-jellyfin'
Check (@($j.Mounts|Where-Object {$_.Destination -eq '/media' -and !$_.RW}).Count -eq 1) 'Jellyfin media read-only'
foreach($kind in @('radarr','sonarr','qbittorrent')){
 $c=$containers|Where-Object Name -eq "/homelab-v2-$kind"
 Check (@($c.Mounts|Where-Object {$_.Destination -eq '/downloads' -and $_.Source -eq '/volume1/media/downloads-v2'}).Count -eq 1) "$kind unified download/library filesystem"
}
foreach($kind in @('radarr','sonarr')){
 $a=Get-Content "$private/$kind-new-admin.json" -Raw|ConvertFrom-Json
 $h=@{'X-Api-Key'=$a.ApiKey}
 $cfg=Invoke-RestMethod "$($a.Url)/api/v3/config/mediamanagement" -Headers $h -TimeoutSec 30
 Check $cfg.copyUsingHardlinks "$kind hardlinks enabled"
 $clients=Invoke-RestMethod "$($a.Url)/api/v3/downloadclient" -Headers $h -TimeoutSec 30
 Check ($clients.Count -eq 1 -and ($clients[0].fields|Where-Object name -eq host).value -eq 'homelab-v2-vpn') "$kind new VPN downloader only"
}
$a=Get-Content "$private/jellyfin-new-admin.json" -Raw|ConvertFrom-Json
$base='http://192.168.1.220:8097'
$auth=@{Authorization='MediaBrowser Client="Codex release", Device="Windows", DeviceId="homelab-release-tests", Version="1.0"'}
$session=Invoke-RestMethod "$base/Users/AuthenticateByName" -Method Post -Headers $auth -ContentType application/json -Body (@{Username=$a.Username;Pw=$a.Password}|ConvertTo-Json)
$jh=@{Authorization=('MediaBrowser Token="'+$session.AccessToken+'", Client="Codex release", Device="Windows", DeviceId="homelab-release-tests", Version="1.0"')}
try {
 $encoding=Invoke-RestMethod "$base/System/Configuration/encoding" -Headers $jh
 Check ($encoding.EnableThrottling -and $encoding.EnableSegmentDeletion) 'Transcode throttling and old-segment cleanup'
 $users=Invoke-RestMethod "$base/Users" -Headers $jh
 $kids=$users|Where-Object Name -eq 'Popcorn Gremlins'
 Check ($kids -and !$kids.Policy.IsAdministrator -and !$kids.Policy.EnableContentDeletion -and $kids.Policy.MaxParentalRating -eq 10 -and 'Movie' -in $kids.Policy.BlockUnratedItems -and 'Series' -in $kids.Policy.BlockUnratedItems) 'Kids account restrictions preserved'
 $plugins=Invoke-RestMethod "$base/Plugins" -Headers $jh
 $plugin=$plugins|Where-Object Name -eq 'Jellyfin Enhanced'
 if($SkipEnhanced){'SKIP: Enhanced activation/integration until approved idle restart'}else{
  Check ($plugin.Status -eq 'Active' -and $plugin.Version -eq '12.14.0.0') 'Enhanced installed and active'
  $config=Invoke-RestMethod "$base/Plugins/$($plugin.Id)/Configuration" -Headers $jh
  Check ($config.JellyseerrEnabled -and !$config.JellyseerrAutoImportUsers -and !$config.JellyseerrEnable4KRequests -and !$config.AnalyticsEnabled) 'Enhanced integration and restricted defaults'
  $status=Invoke-RestMethod "$base/JellyfinEnhanced/jellyseerr/status" -Headers $jh
  Check $status.active 'Enhanced can reach Seerr'
  $results=Invoke-RestMethod "$base/JellyfinEnhanced/jellyseerr/search?query=Sintel&page=1" -Headers $jh -TimeoutSec 30
  Check (@($results.results).Count -gt 0) 'Authenticated Enhanced to Seerr search'
  $public=Invoke-WebRequest "$base/JellyfinEnhanced/public-config" -Headers $jh
  $se=Get-Content "$private/seerr-new-admin.json" -Raw|ConvertFrom-Json
  Check (!$public.Content.Contains($se.ApiKey)) 'Seerr key absent from public client configuration'
  $web=Invoke-WebRequest "$base/web/index.html"
  Check ($web.Content -match 'JellyfinEnhanced') 'Server web page injects Enhanced assets'
  $kidCredentials=Get-Content "$private/jellyfin-kids-account.json" -Raw|ConvertFrom-Json
  $kidSession=Invoke-RestMethod "$base/Users/AuthenticateByName" -Method Post -Headers $auth -ContentType application/json -Body (@{Username=$kidCredentials.Username;Pw=$kidCredentials.Password}|ConvertTo-Json)
  $kh=@{Authorization=('MediaBrowser Token="'+$kidSession.AccessToken+'", Client="Codex release", Device="Windows", DeviceId="homelab-release-tests", Version="1.0"')}
  try {
   $denied=Invoke-WebRequest "$base/JellyfinEnhanced/jellyseerr/search?query=Sintel&page=1" -Headers $kh -SkipHttpErrorCheck
   Check ($denied.StatusCode -eq 403) 'Kids account cannot use Seerr integration'
   $visible=Invoke-RestMethod "$base/Items?UserId=$($kids.Id)&Recursive=true&IncludeItemTypes=Movie,Series&Limit=5000" -Headers $kh
   Check (@($visible.Items|Where-Object {$_.OfficialRating -notin @('G','PG','TV-G','TV-PG','TV-Y','TV-Y7')}).Count -eq 0) 'Kids browse results respect rating limits'
  }finally{$null=Invoke-RestMethod "$base/Sessions/Logout" -Method Post -Headers $kh}
 }
}finally{$null=Invoke-RestMethod "$base/Sessions/Logout" -Method Post -Headers $jh}
