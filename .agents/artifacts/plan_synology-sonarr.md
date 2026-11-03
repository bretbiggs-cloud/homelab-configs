# Synology Sonarr core phase

User authorized continuing without routine questions. Reuse accepted movie pipeline design for TV: homelab-v2-sonarr project/container, official LSIO image pinned sha256386c962ee6e260e3a5656b25df2ed056bcc9b6410e197d075f9547fd14c23bca, PUID1026/PGID100, isolated /volume1/docker/homelab-v2/sonarr/data:/config, existing /volume1/media/downloads-v2:/downloads, root /downloads/library/tv. LAN8990/internal8989 and Tailscale8990. Old Sonarr8989 and all other old services remain untouched.

Apply1080p-only preference consistently, upgrades off, forms authentication on all addresses, credentials private. New-only qBittorrent connection homelab-v2-vpn:8082 category tv-sonarr, automatic torrent removal off. New Prowlarr Sonarr application fullSync TV categories5000 and8000. Avoid repeating failing browser-source stress tests; establish core with available direct sources, retain source configs and explicitly report missing synced indexers. No series, searches, production downloads, old imports or cutover.

Review: shared single-volume tree avoids copies/path mapping; native APIs and image entrypoint, no custom startup. Restore involves stopping only new Sonarr and removing only its app link/8990 forward, retaining data. Backup infrastructure deferred. Use current deployed feature branch; do not reset upstream or publish.

Tests: compose, identity/mounts/auth, sole1080p profile, writable root/hardlink fixture, native client test and persistence, Prowlarr application connectivity/sync result, Tailscale backend and effective forward, all eight old IDs/start timestamps preserved. Explicitly defer user remote confirmation and real TV download/import until applicable; no false full-stack acceptance claim.

Source: https://docs.linuxserver.io/images/docker-sonarr/ . Follow existing project feature-initiation, stack-authoring and test-authoring with local Synology overrides.

Implemented and validated with two direct sources selected through sonarr-core tag. TV hardlink/write test, native app/downloader tests, restart persistence and old-eight preservation passed. User remote verification and real download/import remain explicitly untested.
