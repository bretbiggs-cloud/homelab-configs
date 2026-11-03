# Purpose: verify the isolated Synology Jellyfin deployment from Windows.
# Usage: pwsh -File .tests/suites/test_synology_jellyfin.ps1
# Prerequisites: existing SSH authentication and LAN access to the NAS.
# Side effects: read-only Docker inspection and HTTP/permission probes.
# No secrets/raw inspection results are displayed or persisted. Throws on failure.
$ErrorActionPreference = 'Stop'
$nasTarget = 'Bret@192.168.1.220'
$inspection = & ssh -o BatchMode=yes -o ConnectTimeout=10 $nasTarget '/usr/local/bin/docker inspect homelab-v2-jellyfin'
if ($LASTEXITCODE -ne 0) { throw 'Container inspection failed' }
$state = ($inspection | ConvertFrom-Json)[0]
$checks = [ordered]@{
  Running = $state.State.Running
  Healthy = ($state.State.Health.Status -eq 'healthy')
  NoRestarts = ($state.RestartCount -eq 0)
  NoOOM = (!$state.State.OOMKilled)
  NonRoot = ($state.Config.User -eq '1026:100')
  NotPrivileged = (!$state.HostConfig.Privileged)
  DropCapabilities = ($state.HostConfig.CapDrop -contains 'ALL')
  NoPrivilegeEscalation = ($state.HostConfig.SecurityOpt -contains 'no-new-privileges:true')
  ConfigIsolated = (($state.Mounts | Where-Object Destination -eq '/config').Source -eq '/volume1/docker/homelab-v2/jellyfin/data/config')
  CacheIsolated = (($state.Mounts | Where-Object Destination -eq '/cache').Source -eq '/volume1/docker/homelab-v2/jellyfin/data/cache')
  MediaReadOnly = (!(($state.Mounts | Where-Object Destination -eq '/media').RW))
  MediaSource = (($state.Mounts | Where-Object Destination -eq '/media').Source -eq '/volume1/media')
  Port = ($state.HostConfig.PortBindings.'8096/tcp'[0].HostPort -eq '8097')
  LANBinding = ($state.HostConfig.PortBindings.'8096/tcp'[0].HostIp -eq '192.168.1.220')
  LogBound = ($state.HostConfig.LogConfig.Config.'max-size' -eq '10m' -and $state.HostConfig.LogConfig.Config.'max-file' -eq '3')
}
foreach ($entry in $checks.GetEnumerator()) {
  if (!$entry.Value) { throw "FAIL: $($entry.Key)" }
  Write-Output "PASS: $($entry.Key)"
}
& ssh -o BatchMode=yes -o ConnectTimeout=10 $nasTarget '/usr/local/bin/docker exec homelab-v2-jellyfin sh -c "test -w /config && test -w /cache && test -r /media && test -x /media"'
if ($LASTEXITCODE -ne 0) { throw 'Application permissions failed' }
foreach ($port in @(8097)) {
  $response = Invoke-WebRequest -Uri "http://192.168.1.220:$port/health" -TimeoutSec 10
  if ($response.StatusCode -ne 200) { throw "HTTP health failed: $port" }
  Write-Output "PASS: HTTP health $port"
}
$oldRaw = & ssh -o BatchMode=yes -o ConnectTimeout=10 $nasTarget '/usr/local/bin/docker ps -a --filter name=^/jellyfin$ --format "{{.Names}}"'
if ($LASTEXITCODE -ne 0 -or ($oldRaw -join '').Trim()) { throw 'Removed old Jellyfin container unexpectedly present' }
& ssh -o BatchMode=yes -o ConnectTimeout=10 $nasTarget 'test ! -e /volume1/docker/jellyfin/config && test ! -e /volume1/docker/jellyfin/cache && test -d /volume1/media'
if ($LASTEXITCODE -ne 0) { throw 'Old-data removal or shared-media preservation check failed' }
Write-Output 'PASS: old Jellyfin removed; shared media retained.'
Write-Output 'Infrastructure checks passed; user has separately confirmed Tailscale playback.'