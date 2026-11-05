#!/bin/sh
# NAS-only reporting wrapper. No application mutations, alerts or repairs.
set -u
PATH=/usr/local/bin:/usr/bin:/bin
export PATH
umask 077
BASE='/volume1/homes/bret/HomeLab/NAS Configuration'
OUT="$BASE/.agents/artifacts/monitoring"
MODE=${1:-scheduled}
case "$MODE" in scheduled|manual|self-test) ;; *) exit 64;; esac
[ ! -e "$OUT/DISABLED" ] || exit 0
mkdir -p "$OUT/reports" || exit 2
[ ! -L "$OUT" ] && [ ! -L "$OUT/reports" ] || exit 2
exec 9>"$OUT/run.lock"
if ! /usr/bin/flock -n 9; then
  echo 'SKIPPED overlap: another monitoring run holds the lock'
  exit 0
fi
stamp=$(date -u +%Y%m%dT%H%M%SZ)
report="$OUT/reports/health-$stamp-$$.txt"
tmp="$report.partial"
start=$(date +%s)
{
  echo 'NAS reporting-only monitor'
  printf 'RunUTC=%s Mode=%s PID=%s ParentPID=%s\n' "$stamp" "$MODE" "$$" "$PPID"
  printf 'Host='; hostname
  printf 'User='; id -un
  if [ "$MODE" = self-test ]; then
    echo 'SIMULATED_FAILURE: intentional collector exit 2; no application probe or change'
    rc=2
  else
    /usr/bin/timeout -k 10 600 /bin/sh "$BASE/.scripts/synology-health-check.sh" 2>/dev/null
    rc=$?
  fi
  case "$rc" in 0) result=PASS;; 1) result=WARNING;; *) result=FAILED;; esac
  printf 'CollectorExit=%s Result=%s DurationSeconds=%s\n' "$rc" "$result" "$(($(date +%s)-start))"
} >"$tmp"
mv "$tmp" "$report" || exit 2
# Only monitor-generated regular files in this dedicated directory, older than
# 14 days (20160 minutes). No recursion, symlink traversal or application files.
find "$OUT/reports" -maxdepth 1 -type f -name 'health-*.txt' -mmin +20160 -delete || exit 2
find "$OUT/reports" -maxdepth 1 -type f -name 'health-*.txt.partial' -mmin +20160 -delete || exit 2
printf 'Report=%s\nCollectorExit=%s Result=%s\n' "$report" "$rc" "$result"
exit "$rc"
