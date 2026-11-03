> Dated implementation history. Later entries supersede earlier entries; for current production state use [the consolidated Synology reference](../.docs/synology.md). Old parallel-stage rollback instructions are historical after cutover.

# Synology Seerr

New Seerr3.5.1 runs as homelab-v2-seerr with official pinned image, UID1026:GID100, init, cap_dropALL and no-new-privileges. Own /volume1/docker/homelab-v2/seerr/data:/app/config only. LAN5056/internal5055; Tailscale http://substation.tail8f9607.ts.net:5056 . Old Seerr5055 unchanged.

Sign in with the existing NEW Jellyfin admin username/password. Local Seerr password login disabled; Jellyfin login enabled. Single initial owner created through Jellyfin authentication. No other users imported; new-user self-enrollment disabled. Default permissions160 (REQUEST32 + AUTO_APPROVE128) applies to admitted trusted users. No default4K request permissions; owner admin privileges are broader. API key saved privately outside Git. This configures automatic approval, not automatic creation of requests or watchlist acquisition.

New-only Radarr/Sonarr connections pass native tests, default1080p profiles, isolated /downloads/library/movies and /downloads/library/tv roots, automatic searching for future intentional requests. No4K server configured. Seerr Jellyfin endpoint homelab-v2-jellyfin:8096; playback external link is private Tailscale8096. Existing two Jellyfin libraries enabled in Seerr; no full library scan requested during setup.

Playback path completion: added /media/downloads-v2/library/movies to existing Movies library and /media/downloads-v2/library/tv to existing TV Shows library with refreshLibrary=false. Existing Movies/Kid Movies/tv_shows locations preserved. Jellyfin's pre-existing read-only /volume1/media mount covers the new empty folders; no media write access added. Previous library configuration saved privately for rollback. Normal library discovery/import-to-playback timing still requires end-to-end validation.

Acceptance covers isolated mounts/privileges, authenticated Jellyfin login, anonymous API denial, approval policy, new-only service endpoints/roots/profiles, native server tests, zero request queue, Tailscale backend and all eight old IDs/start timestamps. Repeat after restart for persistence. Phone access and actual auto-approved request/download/import/playback not claimed tested. Browser-dependent indexers remain pending from earlier rollout. No new media requests, series, torrents or downloads created by setup.

Rollback: stop only new Seerr and remove only5056 forward; retain state. Remove only the two added Jellyfin folder references if rolling back playback paths (no deletion of files). Its app-created Jellyfin API token may be revoked specifically if abandoning integration. Preserve old stack. No cutover, old deletion, release tags or publication authorized.

References: https://docs.seerr.dev/getting-started/docker/ ; https://raw.githubusercontent.com/seerr-team/seerr/develop/server/lib/permissions.ts ; https://typescript-sdk.jellyfin.org/interfaces/generated-client.MediaPathDto.html .

Post-restart acceptance completed successfully2026-11-02; effective Tailscale5056 forward confirmed. Startup on this host exceeded the first readiness window and subsequently completed without container restart/OOM flags. Jellyfin /health Healthy.

Validation update2026-11-02: see .agents/artifacts/validation_media_2026-11-02.md. Existing Sintel test file was requested through Seerr, explicitly manually imported by Radarr as a hardlink, indexed/streamed by Jellyfin and marked available by Seerr's recent scan. Retained unmonitored test fixture supersedes earlier empty movie/request baseline. Native new Radarr/Sonarr Jellyfin import notifications configured/tested with mapped paths; fresh unattended download/import still unverified. No old-stack change.
