# Read-only checks for internal FlareSolverr. One browser request, no downloads.
# PowerShell7.5+; private Prowlarr credential stays outside repository/output.
param([Parameter(Mandatory=$true)][string]$NasUser)
$ErrorActionPreference='Stop'
function Check([bool]$Ok,[string]$Name){if(!$Ok){throw "FAIL: $Name"}; Write-Output "PASS: $Name"}
$target="$NasUser@192.168.1.220"
$raw=& ssh -o BatchMode=yes -o ConnectTimeout=10 $target '/usr/local/bin/docker inspect homelab-v2-flaresolverr prowlarr sonarr radarr seerr qbittorrent'
Check ($LASTEXITCODE -eq 0) 'Container inspection'
$all=$raw|ConvertFrom-Json -DateKind String; $f=$all[0]
Check ($f.State.Running -and $f.RestartCount -eq 0 -and !$f.State.OOMKilled) 'Solver running without crash/OOM'
Check (@($f.HostConfig.PortBindings.PSObject.Properties).Count -eq 0) 'No published host ports'
Check (!$f.HostConfig.Privileged -and $f.HostConfig.CapDrop -contains 'ALL' -and $f.Config.User -notin @('','0','root')) 'Non-root image with capabilities dropped'
Check (@($f.Mounts|Where-Object Type -eq 'bind').Count -eq 0) 'No host data mounts'
$baseline=Get-Content "$PSScriptRoot/../../.configs/validation/container-baseline.json" -Raw|ConvertFrom-Json -DateKind String
foreach($old in $all[1..5]){$b=$baseline|Where-Object Name -eq $old.Name; Check ($old.State.Running -and $old.Id -eq $b.Id -and $old.State.StartedAt -eq $b.StartedAt) "Old $($old.Name) unchanged"}
$root=& ssh -o BatchMode=yes $target '/usr/local/bin/docker exec homelab-v2-prowlarr curl -fsS --max-time 10 http://homelab-v2-flaresolverr:8191/'
Check ($LASTEXITCODE -eq 0 -and ($root|ConvertFrom-Json).msg -match 'ready') 'New Prowlarr reaches solver by Docker DNS'
$c=Get-Content "$env:USERPROFILE/.codex/private/homelab/prowlarr-new-admin.json" -Raw|ConvertFrom-Json
$h=@{'X-Api-Key'=$c.ApiKey}
# Assign first so PowerShell enumerates the API array into individual proxies.
$proxies=Invoke-RestMethod "$($c.Url)/api/v1/indexerproxy" -Headers $h
$proxy=$proxies|Where-Object name -eq 'FlareSolverr New'
Check ($null -ne $proxy -and $proxy.implementation -eq 'FlareSolverr') 'New proxy exists'
Check (($proxy.fields|Where-Object name -eq 'host').value -eq 'http://homelab-v2-flaresolverr:8191') 'Correct internal proxy target'
Check (($proxy.fields|Where-Object name -eq 'requestTimeout').value -eq 120) 'Bounded 120-second browser budget for NAS latency'
$tags=Invoke-RestMethod "$($c.Url)/api/v1/tag" -Headers $h
$tag=$tags|Where-Object label -eq 'flaresolverr'
Check ($proxy.tags.Count -eq 1 -and $proxy.tags[0] -eq $tag.id) 'Explicit tag prevents global proxy matching'
Invoke-RestMethod "$($c.Url)/api/v1/indexerproxy/test" -Method Post -Headers $h -ContentType application/json -Body ($proxy|ConvertTo-Json -Depth 15) -TimeoutSec 150|Out-Null
Write-Output 'PASS: Prowlarr native proxy test'
# One harmless browser fetch validates Chromium; does not prove challenge solving.
$payload='{"cmd":"request.get","url":"https://example.com/","maxTimeout":120000}'
$result=$payload | & ssh -o BatchMode=yes $target '/usr/local/bin/docker exec -i homelab-v2-prowlarr curl -fsS --max-time 150 -H "Content-Type: application/json" --data-binary @- http://homelab-v2-flaresolverr:8191/v1'
Check ($LASTEXITCODE -eq 0) 'Browser request transport'
$r=$result|ConvertFrom-Json
Check ($r.status -eq 'ok' -and $r.solution.status -eq 200 -and $r.solution.response -match 'Example Domain') 'Chromium fetch completed successfully'
