# Read-only pre-enrollment checks. Run with PowerShell on the management PC.
# Requires SSH authentication and the new Tailscale container; no secrets logged.
$ErrorActionPreference='Stop'
$raw=& ssh -o BatchMode=yes -o ConnectTimeout=10 Bret@192.168.1.220 '/usr/local/bin/docker inspect homelab-v2-tailscale'
if($LASTEXITCODE -ne 0){throw 'Inspect failed'}
$c=($raw|ConvertFrom-Json)[0]
$checks=[ordered]@{
 Running=$c.State.Running
 NonRoot=($c.Config.User -eq '1026:100')
 NotPrivileged=(!$c.HostConfig.Privileged)
 NoHostNetworking=($c.HostConfig.NetworkMode -ne 'host')
 NoPublishedPorts=(@($c.HostConfig.PortBindings.PSObject.Properties).Count -eq 0)
 NoAddedCapabilities=($null -eq $c.HostConfig.CapAdd -or $c.HostConfig.CapAdd.Count -eq 0)
 Userspace=($c.Config.Env -contains 'TS_USERSPACE=true')
 EnrollmentTimeout=($c.Config.Env -contains 'TS_BOOT_TIMEOUT=24h')
 PersistentIdentity=(($c.Mounts|Where-Object Destination -eq '/var/lib/tailscale').Source -eq '/volume1/docker/homelab-v2/tailscale/data')
 NoEnrollmentKey=(@($c.Config.Env|Where-Object {$_ -match '^TS_AUTHKEY=.'}).Count -eq 0)
}
foreach($e in $checks.GetEnumerator()){if(!$e.Value){throw "FAIL: $($e.Key)"};Write-Output "PASS: $($e.Key)"}
& ssh -o BatchMode=yes -o ConnectTimeout=10 Bret@192.168.1.220 '/usr/local/bin/docker exec homelab-v2-tailscale wget -qO- -T 10 http://homelab-v2-jellyfin:8096/health'
if($LASTEXITCODE -ne 0){throw 'Backend health failed'}
Write-Output 'Pre-enrollment checks passed; tailnet login/access is a separate acceptance gate.'
# Enrolled-state assertions: identity, routes and private TCP forwarding.
$statusRaw=& ssh -o BatchMode=yes -o ConnectTimeout=10 Bret@192.168.1.220 '/usr/local/bin/docker exec homelab-v2-tailscale tailscale --socket=/tmp/tailscaled.sock status --json'
if($LASTEXITCODE -ne 0){throw 'Tailscale status unavailable'}
$status=$statusRaw|ConvertFrom-Json
if($status.BackendState -ne 'Running' -or !$status.Self.Online){throw 'Node not online'}
if($status.Self.DNSName -ne 'substation.tail8f9607.ts.net.'){throw 'Unexpected node DNS name'}
$serveRaw=& ssh -o BatchMode=yes -o ConnectTimeout=10 Bret@192.168.1.220 '/usr/local/bin/docker exec homelab-v2-tailscale tailscale --socket=/tmp/tailscaled.sock serve status --json'
if($LASTEXITCODE -ne 0){throw 'Serve status unavailable'}
$serve=$serveRaw|ConvertFrom-Json
if($serve.TCP.'8096'.TCPForward -ne 'homelab-v2-jellyfin:8096'){throw 'Wrong forward target'}
if($serve.AllowFunnel){throw 'Unexpected Funnel configuration'}
$prefsRaw=& ssh -o BatchMode=yes -o ConnectTimeout=10 Bret@192.168.1.220 '/usr/local/bin/docker exec homelab-v2-tailscale tailscale --socket=/tmp/tailscaled.sock debug prefs'
if($LASTEXITCODE -ne 0){throw 'Preferences unavailable'}
$prefs=$prefsRaw|ConvertFrom-Json
if($prefs.AdvertiseRoutes.Count -gt 0 -or $prefs.RunSSH -or $prefs.RouteAll -or $prefs.CorpDNS){throw 'Unexpected routes, SSH or DNS settings'}
Write-Output 'PASS: online permanent identity, private forward, no routes/SSH/DNS changes.'