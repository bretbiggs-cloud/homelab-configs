# Synology Radarr phase

User authorized next new Radarr service while retaining old stack; explicitly selected1080p. Continue deployed feature/synology-stack, no upstream reset/push/merge. Apply feature-initiation, stack-authoring and targeted test-authoring with Synology overrides.

Architecture: homelab-v2-radarr project/container, official LSIO stable image resolved/pinned by digest; shared new bridge; LAN192.168.1.220:7879 to7878 and private Tailscale TCP7879. No public ingress. LSIO PUID1026/PGID100, no-new-privileges, bounded logs. Fresh config /volume1/docker/homelab-v2/radarr/data. Isolated root /volume1/media/library-v2/movies:/movies. No production media/config, old downloader, or Docker socket mounts.

New-only Prowlarr application link with API key kept private, full sync of compatible movie indexers using category2000 (and8000 as required for LimeTorrents keywordless validation). TV-only EZTV/LinuxTracker should not be force-synced. Verify actual compatible sync result. No movies added, automatic searches, old library import or download-client integration in this core phase; new VPN/downloader remain stopped to control resource use. Downloads/import path and hardlink layout require next pipeline validation before production; this phase exposes no downloads mount and makes no hardlink claims.

Forms authentication required on all addresses; generated admin password/API key saved privately. Configure a clearly named1080p-only profile, no4K/remux by default, upgrades disabled unless user later requests. Radarr has no global per-movie default selection: downstream Seerr and future additions must select this profile explicitly.

Review: fresh state and isolated root follow already approved parallel deployment. Keep LAN validation/Tailscale access pattern. Use supported APIs, no custom entrypoint. ~774MiB available before startup; monitor rather than start all remaining services. Docker daemon crash root cause previously recorded; low load is not proof software defect fixed. No backup infrastructure per user deferral; rollback removes only new Prowlarr link/forward and stops new Radarr while retaining state.

Validation: compose; app readiness/auth; isolated mounts/write permission;1080p profile; Prowlarr native app connection and compatible indexer sync; no movie/download jobs; Tailscale backend/live forward; all eight old IDs/start times unchanged against post-recovery baseline; post-restart settings persistence and bounded resource observations. Use targeted Synology suites, not incompatible upstream all-suite. Save reviewed records/local commit only when relevant checks pass.

Execution paused: see radarr/SYNOLOGY.md. New Radarr auth/root/1080p profile configured and new Prowlarr native app test passed. Sync triggered recurrence of severe NAS IO wait/SSH timeout; stopped new Radarr/FlareSolverr/Prowlarr only. Old stack verified uninterrupted and Jellyfin healthy. Full acceptance pending; no implementation commit.

Controlled retry08:10–08:15 reproduced I/O stalls during ApplicationIndexerSync command28 after staged starts. Rolled back to stopped new Radarr/Prowlarr/FlareSolverr; all old IDs/start times preserved and Jellyfin healthy. See radarr/SYNOLOGY.md for observations and remaining checks. Implementation remains uncommitted.

User instructed continued installation despite failed source test. Resumed three new services; Radarr core accepted with two synced indexers. 1337x remains pending; default full acceptance test unchanged, explicit CoreOnly subset provided. See current-status addendum in radarr/SYNOLOGY.md.
