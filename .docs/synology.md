> Dated implementation history. Later entries supersede earlier entries; for current production state use [the consolidated Synology reference](../.docs/synology.md). Old parallel-stage rollback instructions are historical after cutover.

# Synology production configuration

Verified November 2, 2026. This page supersedes the upstream UGREEN assumptions and earlier parallel-deployment plans.

## Host and ownership

Live DSM reports DS923+, an AMD Ryzen Embedded R1600 CPU, DSM 7.2.1 build 69057 update 13, Container Manager 24.0.2-1543, approximately 4 GiB RAM, and a single Btrfs data volume at /volume1. The md2 RAID5 array reports all three members present and no rebuild in /proc/mdstat. These are software observations, not a drive-health certification. Docker's root is /volume1/@docker with the Btrfs driver. No /dev/dri device was found; hardware transcoding is not enabled.

The application identity is UID 1026 / GID 100. LinuxServer images start through their supported entrypoint and use PUID/PGID; Jellyfin directly uses user 1026:100. Timezone is America/New_York. No global ownership changes are needed.

## Services and access

All nine new containers retain their homelab-v2 names after cutover. Their shared Docker bridge is homelab-v2-jellyfin_homelab. Use Docker DNS internally. LAN host address is 192.168.1.220. Remote clients connect to Tailscale node substation, DNS substation.tail8f9607.ts.net. No exit node, subnet routing, public reverse proxy or Cloudflare tunnel was added.

| Container | Compose directory | Internal port | LAN port | Tailnet port |
| --- | --- | --- | --- | --- |
| homelab-v2-jellyfin | jellyfin | 8096 | 8097 | 8096 |
| homelab-v2-tailscale | tailscale | Serve forwards | none | application forwards |
| homelab-v2-vpn | qbittorrentvpn | qBittorrent 8082 | 8082 | 8082 |
| homelab-v2-qbittorrent | qbittorrentvpn | 8082 via VPN namespace | via VPN | via VPN |
| homelab-v2-prowlarr | prowlarr | 9696 | 9697 | 9697 |
| homelab-v2-flaresolverr | flaresolverr | 8191 | none | none |
| homelab-v2-radarr | radarr | 7878 | 7879 | 7879 |
| homelab-v2-sonarr | sonarr | 8989 | 8990 | 8990 |
| homelab-v2-seerr | seerr | 5055 | 5056 | 5056 |

Tailscale uses userspace networking and TCP Serve forwards from [.configs/tailscale/serve.json](../.configs/tailscale/serve.json). qBittorrent shares Gluetun's network namespace; NordVPN remains its egress provider. Tailscale is private application access, not the downloader VPN. Existing Homepage, Omada and Portainer are outside this deployment's management scope.

The inherited cloudflared, nginx, postgres, sonarr-radarr, tandoor, vpn-bridge and Dockge definitions are reference material, not this NAS's deployed topology. The inherited Homepage definition does not own the existing Homepage container.

## Storage and imports

Runtime state is under /volume1/docker/homelab-v2. Jellyfin mounts /volume1/media at /media read-only, with separate writable /config and /cache directories. It reads legacy Movies, Kid Movies and TV directories plus the new library. Seerr has no media bind mount.

qBittorrent, Radarr and Sonarr share the SAME host /volume1/media/downloads-v2 bind at /downloads. New movie and TV roots are /downloads/library/movies and /downloads/library/tv. Hardlinks are enabled in both managers; the retained Sintel fixture provides an inode-level verification. Do not migrate these roots to the upstream /media examples merely to match its guide.

The old downloader/managers/request service containers and their old settings were deleted after explicit user confirmation. Historical rollback instructions that start those old containers are no longer valid. Existing media was preserved, including /volume1/docker/qbittorrent/media.

## Configuration and secrets

Use each active stack's .env.example as its input inventory; see the [complete active variable table](synology-env.md). Actual .env files and application credentials are excluded from Git. PUID, PGID, TZ, DOCKER_DATA_DIR, MEDIA_DIR and NAS_LAN_IP describe this host. Each service adds its own host-port or image/network variables where declared. Compose uses required ${VAR:?message} assertions, except intentionally optional values. The upstream root environment propagation tooling is not deployed on DSM.

Seerr automatically approves requests for authorized users and targets the new managers, with 1080p profiles and 4K requests disabled. Popcorn Gremlins has PG/TV-PG and lower access, unrated Movie/Series blocking, and no administrator or deletion privileges. Kids Movie Night is a static browsing collection, not an access restriction or an automatic rule for new downloads.

## Operations and tests

Do not run the upstream homelab.sh setup, restore, backup or full UGREEN test suite on DSM. Docker Compose is supplied by DSM Container Manager; the service definitions pin image digests. Keep deployed Compose projects and .env files in their existing locations unless performing an explicit migration. A GitHub checkout alone does not relocate the running deployment.

The production test entry point is [.tests/suites/test_synology_release.ps1](../.tests/suites/test_synology_release.ps1). Historical parallel-stage suites require old containers or empty catalogs and are not production acceptance tests. Their sanitized identity/start-time baseline is tracked under .configs/validation; secrets and raw inspection records are excluded. The current release suite checks the active services, authentication, mounts, hardlink settings, plugin integration and parental controls. The retained media validation suite checks file serving and hardlink identity. Optional indexers requiring browser challenges remain unreliable; these are documented limitations, not silently passed tests.

No Restic backup repository, restore-tested full-stack backup, systemd backup timer or PIA bridge has been established. DSM scheduling/monitoring records must be distinguished from verified scheduled execution. The bounded Jellyfin checkpoint created by [.scripts/backup_jellyfin_config.py](../.scripts/backup_jellyfin_config.py) uses SQLite's online backup API and verifies the saved database. It is same-volume rollback material, excludes artwork/cache/logs, and is not a full NAS disaster-recovery strategy.

See [optimization decisions](performance-optimization-synology.md) and [Jellyfin Enhanced setup](jellyfin-enhanced.md).
