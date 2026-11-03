<#
Configure the installed, active Enhanced plugin for this Synology deployment.
Run after an idle Jellyfin restart. Reads existing private credentials, preserves
unrelated plugin settings, and saves a private before-image. Does not restart,
create Seerr users, request media or print credentials. Restore the before-image
through the plugin Configuration endpoint to undo these settings.
#>
param([string]$PrivateDirectory="$env:USERPROFILE/.codex/private/homelab")
$ErrorActionPreference='Stop'
$admin=Get-Content "$PrivateDirectory/jellyfin-new-admin.json" -Raw|ConvertFrom-Json
$seerr=Get-Content "$PrivateDirectory/seerr-new-admin.json" -Raw|ConvertFrom-Json
$kids=Get-Content "$PrivateDirectory/jellyfin-kids-account.json" -Raw|ConvertFrom-Json
$base='http://192.168.1.220:8097'
$auth=@{Authorization='MediaBrowser Client="Codex release", Device="Windows", DeviceId="homelab-enhanced-config", Version="1.0"'}
$session=Invoke-RestMethod "$base/Users/AuthenticateByName" -Method Post -Headers $auth -ContentType application/json -Body (@{Username=$admin.Username;Pw=$admin.Password}|ConvertTo-Json)
$headers=@{Authorization=('MediaBrowser Token="'+$session.AccessToken+'", Client="Codex release", Device="Windows", DeviceId="homelab-enhanced-config", Version="1.0"')}
try {
 $plugins=Invoke-RestMethod "$base/Plugins" -Headers $headers
 $plugin=$plugins|Where-Object Name -eq 'Jellyfin Enhanced'
 if($plugin.Status -ne 'Active'){throw 'Enhanced must be active before configuration'}
 $endpoint="$base/Plugins/$($plugin.Id)/Configuration"
 $config=Invoke-RestMethod $endpoint -Headers $headers
 $before="$PrivateDirectory/enhanced-config-before.json"
 if(!(Test-Path $before)){$config|ConvertTo-Json -Depth 100|Set-Content $before}
 $updated=$config|ConvertTo-Json -Depth 100|ConvertFrom-Json -AsHashtable
 $changes=@{
  JellyseerrEnabled=$true
  JellyseerrUrls='http://homelab-v2-seerr:5055'
  JellyseerrApiKey=$seerr.ApiKey
  JellyseerrUrlMappings="http://192.168.1.220:8097|http://192.168.1.220:5056`nhttp://substation.tail8f9607.ts.net:8096|http://substation.tail8f9607.ts.net:5056`nhttp://100.104.49.30:8096|http://100.104.49.30:5056"
  JellyseerrAutoImportUsers=$false
  JellyseerrImportBlockedUsers=$kids.UserId
  JellyseerrEnable4KRequests=$false
  JellyseerrEnable4KTvRequests=$false
  JellyseerrSearchExcludeLibraryItems=$true
  AutoMovieRequestEnabled=$false
  AutoSeasonRequestEnabled=$false
  AnalyticsEnabled=$false
  AnalyticsHasBeenConfigured=$true
  ElsewhereEnabled=$false
 }
 foreach($key in $changes.Keys){$updated[$key]=$changes[$key]}
 $null=Invoke-RestMethod $endpoint -Method Post -Headers $headers -ContentType application/json -Body (ConvertTo-Json -InputObject $updated -Depth 100)
 $check=Invoke-RestMethod $endpoint -Headers $headers
 if(!$check.JellyseerrEnabled -or $check.JellyseerrAutoImportUsers -or $check.AnalyticsEnabled){throw 'Enhanced settings read-back failed'}
 'Enhanced Seerr integration configured; no new users or requests created.'
}finally{$null=Invoke-RestMethod "$base/Sessions/Logout" -Method Post -Headers $headers}
