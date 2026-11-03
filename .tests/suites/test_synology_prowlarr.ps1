# Read-only Synology Prowlarr acceptance checks. Run from Windows with SSH access.
# Uses the private credential file; never prints passwords, API keys or raw config.
# No indexers, downloads, or application connections are created.
param([Parameter(Mandatory=$true)][string]$NasUser)
$ErrorActionPreference='Stop'
function Confirm-Check([bool]$Condition,[string]$Name) {
    # Emit fixed check result; failed assertions stop the suite without mutation.
    if(!$Condition){throw "FAIL: $Name"}; Write-Output "PASS: $Name"
}
$c=Get-Content "$env:USERPROFILE\.codex\private\homelab\prowlarr-new-admin.json" -Raw|ConvertFrom-Json
$raw=& ssh -o BatchMode=yes -o ConnectTimeout=10 "$NasUser@192.168.1.220" '/usr/local/bin/docker inspect homelab-v2-prowlarr prowlarr sonarr radarr seerr qbittorrent'
if($LASTEXITCODE -ne 0){throw 'Container inspection failed'}
# Preserve Docker timestamp strings exactly. Automatic DateTime conversion of
# seven-digit fractions changes formatting and produces false change reports.
$all=$raw|ConvertFrom-Json -DateKind String; $new=$all[0]
Confirm-Check ($new.State.Running -and $new.RestartCount -eq 0) 'New Prowlarr running without crashes'
Confirm-Check ($new.Mounts.Count -eq 1 -and $new.Mounts[0].Source -eq '/volume1/docker/homelab-v2/prowlarr/data' -and $new.Mounts[0].Destination -eq '/config') 'Isolated config only; no media or old data mounts'
Confirm-Check ($new.HostConfig.PortBindings.'9696/tcp'[0].HostIp -eq '192.168.1.220' -and $new.HostConfig.PortBindings.'9696/tcp'[0].HostPort -eq '9697') 'LAN-only port9697'
Confirm-Check (!$new.HostConfig.Privileged -and $new.Config.Env -contains 'PUID=1026' -and $new.Config.Env -contains 'PGID=100') 'Expected privilege model and identity'
# User-authorized outage recovery changed start times. Preserve that baseline,
# including container IDs, rather than pretending pre-crash uptime continued.
$baseline=Get-Content "$PSScriptRoot/../../.configs/validation/container-baseline.json" -Raw|ConvertFrom-Json -DateKind String
foreach($old in $all[1..5]){
    $before=$baseline|Where-Object Name -eq $old.Name
    Confirm-Check ($old.State.Running -and $old.Id -eq $before.Id -and $old.State.StartedAt -eq $before.StartedAt) "Old $($old.Name) unchanged since authorized recovery"
}
$headers=@{'X-Api-Key'=$c.ApiKey}
$status=Invoke-RestMethod "$($c.Url)/api/v1/system/status" -Headers $headers -TimeoutSec 15
Confirm-Check ($status.appName -eq 'Prowlarr') 'Authenticated API ready'
$h=Invoke-RestMethod "$($c.Url)/api/v1/config/host" -Headers $headers -TimeoutSec 15
Confirm-Check ($h.authenticationMethod -eq 'forms' -and $h.authenticationRequired -eq 'enabled') 'Authentication required for all addresses'
$unauth=Invoke-WebRequest "$($c.Url)/api/v1/system/status" -SkipHttpErrorCheck -TimeoutSec 15
Confirm-Check ($unauth.StatusCode -eq 401) 'Unauthenticated API denied'
$session=[Microsoft.PowerShell.Commands.WebRequestSession]::new()
Invoke-WebRequest "$($c.Url)/login" -Method Post -Body @{username=$c.Username;password=$c.Password;rememberMe='on'} -WebSession $session -TimeoutSec 15 | Out-Null
# Prowlarr API endpoints require API keys independently of browser cookies.
# Verify the authenticated browser root without following login redirects.
$login=Invoke-WebRequest "$($c.Url)/" -WebSession $session -MaximumRedirection 0 -SkipHttpErrorCheck -ErrorAction SilentlyContinue -TimeoutSec 15
Confirm-Check ($login.StatusCode -eq 200 -and $session.Cookies.GetCookies($c.Url).Count -gt 0) 'Saved admin login works'
$anonymous=Invoke-WebRequest "$($c.Url)/" -MaximumRedirection 0 -SkipHttpErrorCheck -ErrorAction SilentlyContinue -TimeoutSec 15
Confirm-Check ($anonymous.StatusCode -eq 302 -and ($anonymous.Headers.Location -join '') -match '/login') 'Anonymous browser redirected to login'
# Approved indexer rollout supersedes the initial empty-indexer requirement.
$indexers=Invoke-RestMethod "$($c.Url)/api/v1/indexer" -Headers $headers -TimeoutSec 15
$expected=@('1337x','EZTV','LimeTorrents','LinuxTracker','The Pirate Bay')
Confirm-Check (@($indexers).Count -eq 5 -and @(Compare-Object ($indexers.name|Sort-Object) ($expected|Sort-Object)).Count -eq 0) 'Exactly five approved indexers saved'
$tags=Invoke-RestMethod "$($c.Url)/api/v1/tag" -Headers $headers -TimeoutSec 15
$solverTag=$tags|Where-Object label -eq 'flaresolverr'
foreach($idx in $indexers){
    Confirm-Check ($idx.enable -and $idx.appProfileId -eq 1 -and $idx.priority -eq 25) "Enabled Standard profile: $($idx.name)"
    if($idx.name -in @('EZTV','1337x')){Confirm-Check ($idx.tags -contains $solverTag.id) "Solver tag: $($idx.name)"}
}
# Authorized Sonarr phase adds a second new-only application.
$apps=Invoke-RestMethod "$($c.Url)/api/v1/applications" -Headers $headers -TimeoutSec 15
Confirm-Check (@($apps).Count -eq 2 -and $apps.name -contains 'Radarr New' -and $apps.name -contains 'Sonarr New') 'Only approved new Radarr and Sonarr linked'
foreach($app in $apps){
    $base=if($app.name -eq 'Radarr New'){'http://homelab-v2-radarr:7878'}else{'http://homelab-v2-sonarr:8989'}
    Confirm-Check ($app.syncLevel -eq 'fullSync' -and ($app.fields|Where-Object name -eq 'baseUrl').value -eq $base -and ($app.fields|Where-Object name -eq 'prowlarrUrl').value -eq 'http://homelab-v2-prowlarr:9696') "New-only sync endpoints: $($app.name)"
}
$coreTag=$tags|Where-Object label -eq 'sonarr-core'
$sonarrApp=$apps|Where-Object name -eq 'Sonarr New'
Confirm-Check ($null -ne $coreTag -and $sonarrApp.tags.Count -eq 1 -and $sonarrApp.tags -contains $coreTag.id) 'Sonarr sync restricted to selected direct sources'
foreach($idx in $indexers){Confirm-Check (($idx.tags -contains $coreTag.id) -eq ($idx.name -in @('LimeTorrents','The Pirate Bay'))) "Sonarr source selection: $($idx.name)"}
foreach($endpoint in @('downloadclient')){
    $items=Invoke-RestMethod "$($c.Url)/api/v1/$endpoint" -Headers $headers -TimeoutSec 15
    Confirm-Check (@($items).Count -eq 0) "Fresh $endpoint list; no production automation"
}
$serve=Get-Content "$PSScriptRoot/../../.configs/tailscale/serve.json" -Raw|ConvertFrom-Json
Confirm-Check ($serve.TCP.'9697'.TCPForward -eq 'homelab-v2-prowlarr:9696') 'Private Tailscale forwarding declared'
$ping=& ssh -o BatchMode=yes -o ConnectTimeout=10 "$NasUser@192.168.1.220" '/usr/local/bin/docker exec homelab-v2-tailscale wget -qO- -T 10 http://homelab-v2-prowlarr:9696/ping'
Confirm-Check ($LASTEXITCODE -eq 0 -and ($ping|Out-String) -match 'OK') 'Tailscale container resolves and reaches new Prowlarr'
