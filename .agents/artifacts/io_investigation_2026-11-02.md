# Synology I/O investigation — 2026-11-02

Read-only investigation following the 07:54–07:56 slowdown during new Radarr integration. Times America/New_York. No service configuration, scheduling, disk settings or existing workload changed. Experimental Radarr/Prowlarr/FlareSolverr and new VPN/downloader remain stopped. Accepted Jellyfin/Tailscale and eight old services remain running.

## Measured observations

- At 08:02 approximately 1.26 GiB available RAM out of 3.80 GiB. Reported swap about 1.96 GiB includes approximately 1.72 GiB in zram; physical disk swap only about 239 MiB. Earlier descriptions treating total swap as disk-backed were incorrect. Two zram devices occupied approximately 662 MiB physical RAM in the later sample.
- Twenty-second sample: 318 swap-in pages, zero swap-out pages, zero allocation stalls/direct reclaim. SATA device average request latency 5.0–10.5 ms and utilization 1.3–11%; md2 latency 18.9 ms. This recovered sample cannot establish pressure during the incident.
- At 08:06, two short iostat intervals showed renewed bursts: CPU I/O wait 12.9–22.6%, SATA data-drive utilization approximately 42–72%, md2 busy 92–99%. Array busy percentage does not by itself establish maximum throughput or failing hardware. Initial iostat report is since boot and was not treated as an interval sample.
- Ten-second process I/O sample, limited by permissions to 16 readable processes: scheduled shell PID6599 accumulated about 33.0 MiB reads and 3.7 MiB writes; old qbittorrent about 13.0 MiB reads. Parent shell accounting may include completed children. This is not complete host process attribution.
- PID6599 is the DSM-scheduled Storm Response Hub tools/run_storm_watch_snapshot.sh, with a Python child. Script runs multiple weather/outage collectors, forecasts and reports. The observed job started 08:00:02, AFTER the 07:54–07:56 incident, so it is not evidence that this run caused that incident. No changes to that project or its schedule.
- Largest resident process in earlier sample: Omada Java about 301 MiB RSS and 533 MiB swapped virtual pages; qBittorrent about 284 MiB RSS and 114 MiB swapped. Per-process swap does not establish disk-backed residency because zram is included. Docker memory counters also omit some memory accounting; Docker block-I/O counters were unusable (all zero).
- md2 RAID5 has three data members, all present, no rebuild. Four drives participate in system/swap arrays. Volume1 about 53% used. Do not equate four installed disks with a four-disk data array.
- Archived SMART records from October26: all four overall assessments PASSED; zero reallocated, pending, offline-uncorrectable and UDMA CRC counts. These are historical only. Direct live smartctl was denied by device permissions; no device privileges added and no SMART tests started.
- Kernel buffer retains historical Plex DLNA OOM entries already discussed in prior incident record. No new disk-error evidence surfaced in the bounded filtered check; this is not comprehensive hardware validation.
- Docker log tail read did not establish a second daemon panic. The Nov1 nil-pointer daemon crash remains confirmed separately. Current old-container start timestamps match the recovery baseline exactly; no subsequent restart of those eight services observed.
- At 08:09 Jellyfin /health returned Healthy. Tailscale running; remote phone playback not retested.

## Conclusion and next step

Intermittent storage contention is measured. The precise source of the earlier stall remains unproven; neither total swap nor temporal proximity to Radarr proves causation. Concurrent workloads and a previously confirmed Docker daemon bug are separate concerns.

Keep experimental services paused while collecting bounded process-level I/O and memory evidence during a future authorized single-service trial. Start with Prowlarr alone; inspect pending integration state before resuming Radarr or browser challenges. Do not start all new services together, repeat heavy browser tests, stop the old downloader, change the Storm Response Hub job, or buy hardware based solely on these samples. Current disk health can be checked through DSM before another rollout. No automated monitoring was installed by this investigation.

Radarr implementation remains incomplete and uncommitted. This diagnostic record does not claim integration acceptance or authorize cutover. No secrets or raw logs included.
