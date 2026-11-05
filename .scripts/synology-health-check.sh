#!/bin/sh
# Synology read-only health collector. Run: sh .scripts/synology-health-check.sh
# Requires NAS shell, /usr/local/bin/docker access, awk, curl, /proc and df.
# Does not restart/exec into containers, edit configuration, delete, notify or schedule.
# Homepage is excluded from application probes and logs by user request.
# stdout contains metrics and fixed log-category counts only, never raw log text,
# environment variables, credentials, process arguments or healthcheck output.
# Exit 0: checks pass; 1: warning/action required; 2: collector cannot run.
# Logs are bounded to the last hour and 500 lines per service; counts are heuristics,
# not a complete audit. Redirect stdout to a new report under .agents/artifacts.
set -u
PATH=/usr/local/bin:/usr/bin:/bin
DOCKER=/usr/local/bin/docker
warnings=0
# Emit a fixed diagnostic warning and mark the run for operator review.
# Argument 1 is a script-generated label; no raw external messages are accepted.
warn() { printf 'WARN %s\n' "$1"; warnings=$((warnings+1)); }
[ -x "$DOCKER" ] && "$DOCKER" info >/dev/null 2>&1 || { echo 'ERROR Docker unavailable'; exit 2; }
printf 'Timestamp: '; date -Iseconds
uptime
free -m
df -h / /volume1
cat /proc/mdstat
if grep -Eq '\[[U_]*_[U_]*\]' /proc/mdstat; then warn 'RAID member missing'; fi
for mount in / /volume1; do
  used=$(df -P "$mount" | awk 'NR==2 {gsub(/%/,"",$5);print $5}')
  [ "$used" -lt 85 ] || warn "filesystem $mount at least 85 percent used"
done
available=$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo)
[ "$available" -ge 524288 ] || warn 'available memory below 512 MiB'
swap_used_pct=$(awk '/^SwapTotal:/ {t=$2} /^SwapFree:/ {f=$2} END {if(t>0)printf "%.0f",100*(t-f)/t;else print 0}' /proc/meminfo)
printf 'SwapUsedPercent=%s\n' "$swap_used_pct"
[ "$swap_used_pct" -lt 90 ] || warn 'swap occupancy at least 90 percent; inspect active paging before repair'
for service in homelab-v2-sonarr homelab-v2-seerr homelab-v2-radarr homelab-v2-prowlarr homelab-v2-jellyfin homelab-v2-qbittorrent homelab-v2-flaresolverr homelab-v2-vpn homelab-v2-tailscale portainer omada-controller; do
  state=$("$DOCKER" inspect --format '{{.State.Status}}' "$service" 2>/dev/null) || state=missing
  [ "$state" = running ] || warn "$service not running"
  "$DOCKER" inspect --format '{{.Name}} state={{.State.Status}} restarts={{.RestartCount}} oom={{.State.OOMKilled}} health={{if .State.Health}}{{.State.Health.Status}}{{else}}not-configured{{end}} started={{.State.StartedAt}}' "$service" 2>/dev/null || warn "$service inspect unavailable"
  health=$("$DOCKER" inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}not-configured{{end}}' "$service" 2>/dev/null) || health=unknown
  [ "$health" != unhealthy ] || warn "$service unhealthy"
  restart=$("$DOCKER" inspect --format '{{.RestartCount}}' "$service" 2>/dev/null) || restart=0
  [ "$restart" -eq 0 ] || warn "$service has nonzero lifetime restart count (not a rate)"
  oom=$("$DOCKER" inspect --format '{{.State.OOMKilled}}' "$service" 2>/dev/null) || oom=unknown
  [ "$oom" != true ] || warn "$service current state OOMKilled"
  # Capture bounded logs in shell memory; never emit raw text even on failure.
  if logs=$("$DOCKER" logs --since 60m --tail 500 "$service" 2>&1); then
    printf '%s\n' "$logs" | awk -v s="$service" '
      NF {n++; line=tolower($0); if(line ~ /error|fatal|exception/)e++; if(line ~ /warn/)w++; if(line ~ /timeout|timed out/)t++; if(line ~ /permission denied|access denied/)p++; if(line ~ /no space left/)d++; if(line ~ /tls error|auth_failed/)v++}
      END {printf "LOG %s last60m max500 sampled=%d error-keywords=%d warning-keywords=%d timeouts=%d permission=%d disk-full=%d vpn-auth-tls=%d\n",s,n,e,w,t,p,d,v}'
  else
    warn "$service logs unavailable"
  fi
  unset logs
done
for item in dsm:5000 homelab-v2-jellyfin:8097 homelab-v2-radarr:7879 homelab-v2-sonarr:8990 homelab-v2-prowlarr:9697 homelab-v2-seerr:5056 homelab-v2-qbittorrent:8082 portainer:9000; do
  service=${item%:*}; port=${item#*:}
  code=$(curl --noproxy '*' --connect-timeout 3 --max-time 10 -s -o /dev/null -w '%{http_code}' "http://192.168.1.220:$port/") || code=000
  printf 'HTTP %s %s\n' "$service" "$code"
  case "$code" in 200|301|302|303|307|308|401) :;; *) warn "$service HTTP probe failed";; esac
done
# Omada uses its existing local certificate; -k applies only to this probe.
code=$(curl --noproxy '*' -k --connect-timeout 3 --max-time 10 -s -o /dev/null -w '%{http_code}' https://192.168.1.220:8043/) || code=000
printf 'HTTP omada %s (certificate not validated)\n' "$code"
case "$code" in 200|301|302|303|307|308|401) :;; *) warn 'omada HTTP probe failed';; esac
printf 'Warnings=%s\n' "$warnings"
echo 'HTTP login/redirect is reachability, not end-to-end integration. SMART, backup recovery and VPN leak protection are not tested.'
[ "$warnings" -eq 0 ]
