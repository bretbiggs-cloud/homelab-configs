#!/bin/sh
set -eu
BASE='/volume1/homes/bret/HomeLab/NAS Configuration'
OUT="$BASE/.agents/artifacts/monitoring"
RUN="$BASE/.scripts/synology-monitor-run.sh"
tag="$(date +%s)-$$"
old="$OUT/reports/health-retention-test-$tag.txt"
keep="$OUT/reports/keep-retention-test-$tag.txt"
[ ! -e "$old" ] && [ ! -e "$keep" ]
printf 'Synthetic expired monitor report\n' > "$old"
printf 'Synthetic unrelated file; must survive retention\n' > "$keep"
touch -t 202001010000 "$old" "$keep"
exec 8>"$OUT/run.lock"
/usr/bin/flock -n 8
# Close inherited lock FD in child; parent retains lock.
output=$(/bin/sh "$RUN" self-test 8>&-)
case "$output" in 'SKIPPED overlap:'*) echo 'Overlap exclusion PASS';; *) exit 3;; esac
/usr/bin/flock -u 8
exec 8>&-
set +e
/bin/sh "$RUN" self-test
rc=$?
set -e
[ "$rc" -eq 2 ] || exit 4
[ ! -e "$old" ] && [ -f "$keep" ] || exit 5
echo 'Simulated failure exit2 PASS; expired report removed and unrelated file retained PASS'
# Remove only this uniquely named synthetic fixture, never application data.
rm -- "$keep"
echo 'Test fixture cleanup PASS'
