# Read-only infrastructure and application validation for the new downloader.
# Run from Windows; private credential file is outside Git and never printed.
# Does not interrupt VPN or add torrents. Separate Python suite tests tunnel loss.
$ErrorActionPreference='Stop'
$raw=& ssh -o BatchMode=yes -o ConnectTimeout=10 Bret@192.168.1.220 '/usr/local/bin/docker inspect homelab-v2-vpn homelab-v2-qbittorrent qbittorrent'
if($LASTEXITCODE -ne 0){throw 'Inspect failed'}
$all=$raw|ConvertFrom-Json -DateKind String
$v=$all[0];$q=$all[1];$old=$all[2]
# Authorized Nov1 recovery changed the old container start time; preserve exact
# post-recovery identity instead of the obsolete pre-crash timestamp.
$baseline=Get-Content "$PSScriptRoot/../../.configs/validation/container-baseline.json" -Raw|ConvertFrom-Json -DateKind String
$oldBaseline=$baseline|Where-Object Name -eq '/qbittorrent'
$checks=[ordered]@{
 VPNHealthy=($v.State.Health.Status -eq 'healthy')
 SelectedServer=($v.Config.Env -contains 'SERVER_HOSTNAMES=us13409.nordvpn.com')
 DownloaderRunning=$q.State.Running
 SharedVPNNamespace=($q.HostConfig.NetworkMode -eq ('container:'+$v.Id))
 OldStillRunning=$old.State.Running
 OldStartUnchanged=($old.Id -eq $oldBaseline.Id -and $old.State.StartedAt -eq $oldBaseline.StartedAt)
 ConfigIsolated=(($q.Mounts|Where-Object Destination -eq '/config').Source -eq '/volume1/docker/homelab-v2/qbittorrent/data/config')
 StagingOnly=(($q.Mounts|Where-Object Destination -eq '/downloads').Source -eq '/volume1/media/downloads-v2')
 NoProductionMedia=(@($q.Mounts|Where-Object Source -eq '/volume1/media').Count -eq 0)
 LANBinding=($v.HostConfig.PortBindings.'8082/tcp'[0].HostIp -eq '192.168.1.220')
 NotPrivileged=(!$v.HostConfig.Privileged -and !$q.HostConfig.Privileged)
 NoRestarts=($v.RestartCount -eq 0 -and $q.RestartCount -eq 0)
}
foreach($e in $checks.GetEnumerator()){if(!$e.Value){throw "FAIL: $($e.Key)"};Write-Output "PASS: $($e.Key)"}
$c=Get-Content 'C:\Users\bretb\.codex\private\homelab\qbittorrent-new-admin.json' -Raw|ConvertFrom-Json
# Container running is not application readiness. Bound initial HTTP wait;
# authentication assertions below remain unchanged and are performed once.
$ready=$false
for($attempt=0;$attempt -lt 10;$attempt++){
 try { $response=Invoke-WebRequest $c.Url -TimeoutSec 3; if($response.StatusCode -eq 200){$ready=$true;break} } catch {}
 Start-Sleep -Seconds 2
}
if(!$ready){throw 'New WebUI readiness timeout'}
$session=[Microsoft.PowerShell.Commands.WebRequestSession]::new()
Invoke-WebRequest "$($c.Url)/api/v2/auth/login" -Method Post -Body @{username=$c.Username;password=$c.Password} -WebSession $session -TimeoutSec 15|Out-Null
$p=Invoke-RestMethod "$($c.Url)/api/v2/app/preferences" -WebSession $session -TimeoutSec 15
if($p.current_network_interface -ne 'tun0' -or $p.upnp -or $p.save_path -ne '/downloads/complete'){throw 'Downloader protection/path mismatch'}
Write-Output 'PASS: authenticated UI, tun0 binding, UPnP off, staging path.'
$t=Invoke-RestMethod "$($c.Url)/api/v2/torrents/info?tag=validation" -WebSession $session -TimeoutSec 15
if($t.Count -ne 1 -or $t[0].progress -ne 1 -or $t[0].state -ne 'stoppedUP'){throw 'Validation torrent not complete/stopped'}
Write-Output 'PASS: permitted test torrent complete and stopped.'
