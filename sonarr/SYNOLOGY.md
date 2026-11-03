> Dated implementation history. Later entries supersede earlier entries; for current production state use [the consolidated Synology reference](../.docs/synology.md). Old parallel-stage rollback instructions are historical after cutover.

# Synology Sonarr

Running LSIO4.0.20.3014 pinned by digest. New-only project/container homelab-v2-sonarr, LAN8990/internal8989, Tailscale http://substation.tail8f9607.ts.net:8990. UID1026/GID100, no-new-privileges, bounded logs. Own config /volume1/docker/homelab-v2/sonarr/data; shared new tree /volume1/media/downloads-v2:/downloads, TV root /downloads/library/tv. No old configuration or production-library write mount.

Forms auth required on all addresses; admin credentials/API key saved privately on management PC. Sole TV1080p profile, no remux/4K, upgrades off. New qBittorrent client uses homelab-v2-vpn:8082 and tv-sonarr category (/downloads/complete/tv); automatic torrent removal off. Native connection test passes. Hardlinks enabled, no path mappings; disposable TV hardlink/write fixture passed as UID1026 and was removed.

Prowlarr Sonarr New fullSync uses sonarr-core tag selecting only LimeTorrents and The Pirate Bay. Native application test and automatic sync succeeded. EZTV/1337x retained in Prowlarr but deliberately excluded from this initial core due prior browser stalls; LinuxTracker is not a TV source. This selection uses native application/indexer tags, not a security boundary. Source: https://wiki.servarr.com/prowlarr/settings .

First startup required database migrations; early readiness attempts timed out while migrations progressed, then startup completed. Acceptance suite covers auth, settings, roots, both sources, downloader, Tailscale backend and all eight old IDs/start times. New Sonarr restarted and native downloader test repeated; saved settings validated afterward. Effective Tailscale8990 forward confirmed. Real remote phone access and automatic TV download/import remain untested. Zero series or new downloads initiated.

Rollback: stop only new Sonarr, remove Sonarr New Prowlarr app and8990 forward, retain data. Remove sonarr-core tags only if abandoning this integration. No old-stack cutover, deletion, backup infrastructure or public publication.

Image deployment reference: https://docs.linuxserver.io/images/docker-sonarr/ .

Validation update2026-11-02: see .agents/artifacts/validation_media_2026-11-02.md. Existing Sintel test file was requested through Seerr, explicitly manually imported by Radarr as a hardlink, indexed/streamed by Jellyfin and marked available by Seerr's recent scan. Retained unmonitored test fixture supersedes earlier empty movie/request baseline. Native new Radarr/Sonarr Jellyfin import notifications configured/tested with mapped paths; fresh unattended download/import still unverified. No old-stack change.
