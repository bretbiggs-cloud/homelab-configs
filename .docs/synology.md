# Synology deployment reference

Current deployment evidence reviewed November 5, 2026. This page is the source of truth for the active NAS. Older README and template documents describe the upstream UGREEN reference host and do not describe this deployment unless explicitly stated here.

## Host and storage

- NAS: Synology DS923+; DSM 7.2.1; Container Manager 24.0.2. These model/software details were last recorded during the November 2 review; recheck before any hardware-specific operation.
- Application identity: UID 1026 / GID 100. LinuxServer containers use their `PUID`/`PGID` entrypoint; Jellyfin runs as `1026:100`.
- One Btrfs data volume: `/volume1`. The November 5 read-only inspection showed about 7.0 TiB total, 4.2 TiB used, and 2.9 TiB free. RAID members were present (`md2` 3/3, `md1` and `md0` 4/4) with no rebuild in progress. This is not a drive-health certification.
- Docker data root: `/volume1/@docker`. Service configuration is under `/volume1/docker/homelab-v2`; media is under `/volume1/media`. There is no active `/volume2` NVMe tier.
- The application stack runs on the existing Compose project and networks. Keep its present bind mounts, container names, restart policies, ports, ownership, and permissions. Do not rename or move the active Compose projects to match the template.

## Services and access

The active `homelab-v2` containers observed November 5 are Jellyfin, Tailscale, Gluetun VPN, qBittorrent, Prowlarr, FlareSolverr, Radarr, Sonarr, and Seerr. Homepage, Portainer, Omada, and the unrelated `stocks-paper` container are outside the media-stack management scope; leave Homepage alone.

| Service | LAN address | Container port | Remote Tailscale Serve port | Notes |
| --- | --- | --- | --- | --- |
| Jellyfin | `192.168.1.220:8097` | 8096 | 8096 | Media read-only mount at `/media` |
| qBittorrent | `192.168.1.220:8082` | 8082 via Gluetun | 8082 | Shares Gluetun network namespace |
| Prowlarr | `192.168.1.220:9697` | 9696 | 9697 | |
| Radarr | `192.168.1.220:7879` | 7878 | 7879 | |
| Sonarr | `192.168.1.220:8990` | 8989 | 8990 | |
| Seerr | `192.168.1.220:5056` | 5055 | 5056 | |
| FlareSolverr | No host port | 8191 | None | Internal container access |
| Tailscale | No host port | Userspace | Serves the listed apps | Application access only; no subnet router or exit node |
| Gluetun | `192.168.1.220:8082` | 8082 | 8082 | NordVPN egress for qBittorrent; it is not user remote access |

LAN application ports are bound to `192.168.1.220`. Remote application access is through Tailscale Serve at `substation.tail8f9607.ts.net`; there is no public reverse proxy or Cloudflare tunnel in this deployment. Tailscale Serve currently forwards the media managers and downloader UI as well as Jellyfin. Tailnet membership therefore provides network reachability to those application UIs; do not promise Jellyfin-only access to a tailnet user without confirming Tailscale policy and app authorization.

The media apps share `/volume1/media/downloads-v2` as `/downloads`; the active library roots are `/downloads/library/movies` and `/downloads/library/tv`. Jellyfin mounts `/volume1/media` read-only at `/media`. Do not change those paths or perform file moves/deletes as part of an agent-harness task.

## Integration verification

Read-only checks on November 5 found Radarr and Sonarr with zero reported health warnings, one enabled qBittorrent client each, and the expected movie/TV roots. Seerr status returned HTTP 200 and both manager settings were configured. qBittorrent authentication returned HTTP 204 followed by a successful authenticated version request. Its outbound address differed from the NAS host, confirming the downloader uses the VPN egress path. Tailscale's configured `/tmp/tailscaled.sock` answered IP and Serve status requests.

Prowlarr has two enabled applications (Radarr and Sonarr, full sync). Native indexer tests returned LimeTorrents HTTP 200 in 4.9 seconds, LinuxTracker HTTP 200 in 3.0 seconds, and Pirate Bay HTTP 200 in 1.3 seconds. EZTV returned HTTP 400 after 133 seconds; 1337x primary/alternate tests returned HTTP 400 or timed out. The existing Prowlarr settings were privately preserved, then only EZTV and 1337x were disabled; neither was deleted. No service restart or proxy change was made, and the saved 1337x URL was not rewritten. `ApplicationIndexerSync` and an earlier `CheckHealth` check then reported empty issue lists for Prowlarr, Radarr, and Sonarr. Both Radarr and Sonarr have LimeTorrents and Pirate Bay enabled for RSS and automatic search; later native downloader tests for both apps returned HTTP 200. The latest scheduled monitor report (November 5, 18:15:05 UTC; 9 seconds) completed after an earlier DSM HTTP timeout; DSM recovered, Radarr/Sonarr were clear, and Prowlarr `IndexerProxyStatusCheck` was the only remaining application health error. Prowlarr proxy/browser reliability remains unresolved. EZTV and 1337x remain disabled; neither source is claimed repaired. The FlareSolverr proxy points to the internal FlareSolverr service; its tag matched the 1337x indexer tag before that indexer was disabled. Prowlarr uses FlareSolverr only for matching-tag indexers when a Cloudflare challenge is detected, according to the [official Prowlarr settings guide](https://wiki.servarr.com/prowlarr/settings).

The reporting collector invokes `.scripts/synology-app-health.py` when Python 3 and the helper are available. The helper reads the existing API keys from the three Arr `config.xml` files, performs bounded authenticated health GETs without redirects or proxy use, and prints only fixed-format warning/error counts. It does not print keys or raw server messages. An earlier Nov. 5 live run reported Radarr 0 warnings, Sonarr 0 warnings, and Prowlarr 1 warning (collector exit 1); the latest scheduled report completed in 9 seconds with the Prowlarr proxy check error as the only remaining health issue. The helper's five unit fixtures cover warning classification, malformed responses, missing credentials, and redirect rejection. High NAS I/O was observed after tests; its cause has not been established.

## Management commands

The generic `manage.sh` setup, startup, backup, snapshot, restore, audit, and hook implementations target the upstream reference environment. The adapted entrypoint blocks those commands when it detects DSM. Supported DSM operations are:

```bash
./manage.sh synology status
./manage.sh synology backup
./manage.sh test synology
```

`status` and `test` are read-only. The explicit `backup` command creates a private mode-0700 same-volume checkpoint under the pre-existing `/volume1/docker/homelab-v2/.backups` directory. It copies active app configuration, Compose files and any present per-stack `.env` files; SQLite databases use the online backup API. It excludes media, caches, and logs, does not stop services or prune earlier backups, and verifies file hashes plus SQLite integrity after copying the checkpoint into an isolated temporary restore directory. This verifies that the stored config/database copy can be read and restored in isolation; it does not test restarting each application from restored state.

This backup destination is on the same NAS volume, so it does not protect against NAS or volume failure. The user's GitHub account is authorized for sanitized repository code and documentation only; never upload `.env`, runtime DBs, credentials, raw reports, or media. The DSM test target does not run the upstream reverse proxy, PIA, systemd, Restic, or UGREEN network suites. Do not execute a blocked operation by invoking an underlying script directly.

## Monitoring, backup, and recovery

- NAS monitoring is a DSM scheduled, reporting-only task, every 15 minutes with 14-day report retention. Notifications and automatic repairs are disabled.
- The collector recognizes the active `homelab-v2` containers and LAN ports and calls the authenticated app-health helper before emitting its final warning total. The 10:30 Eastern scheduled run on November 5 occurred before this helper addition and passed with `CollectorExit=0`, `Result=PASS`, `Warnings=0`, duration 2 seconds. A later scheduled report completed at 18:15:05 UTC in 9 seconds; DSM had recovered and only the Prowlarr proxy health error remained. Keep these as distinct time-stamped evidence; the earlier scheduled PASS does not verify the later helper-enabled behavior.
- The user selected a NAS-local checkpoint and GitHub for sanitized configuration/code. No automatic pruning or new retention period has been authorized. The NAS copy is same-volume rollback/recovery material, not off-device disaster recovery.
- A private checkpoint was created on November 5 at `/volume1/docker/homelab-v2/.backups/homelab-v2-20261105T155725Z`: 1,612 files, five online SQLite snapshots, and five isolated restore integrity checks passed. An earlier interrupted attempt is retained as a failed checkpoint; do not restore from it. No older backup was pruned.
- A repository-only feature-branch push to the user's confirmed fork is authorized after secret/publication review. Do not push databases, `.env`, credentials, raw reports, or media. Do not merge or tag without the feature review gate.

## Reconciliation rules

- For current host state, prefer fresh read-only DSM/Docker observations over dated records. Mark historical facts with their verification date.
- Before changing runtime behavior, preserve the current configuration and establish a rollback path. Deployment, restarts, deletion, storage, networking, VPN, and access-control changes require explicit authorization.
- Keep secrets, live `.env` files, credentials, raw logs, and private monitoring reports outside Git and publication.
- Preserve the existing branch/worktree user changes; do not merge unrelated media scripts, Homepage configuration, or runtime records into this adaptation.

See [Synology environment reference](synology-env.md) and [Synology optimization decisions](performance-optimization-synology.md).
