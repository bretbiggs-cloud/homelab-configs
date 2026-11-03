> Dated implementation history. Later entries supersede earlier entries; for current production state use [the consolidated Synology reference](../.docs/synology.md). Old parallel-stage rollback instructions are historical after cutover.

# Synology Radarr - core service and downloader connected

Current status2026-11-02: running, with user-confirmed remote login page. New qBittorrent integration is enabled and native connection tests pass. Movies1080p remains the sole profile. The isolated shared root is /downloads/library/movies, backed by /volume1/media/downloads-v2/library/movies. LimeTorrents and The Pirate Bay are synced;1337x remains pending after a failed browser test. This is not full three-indexer acceptance or an end-to-end automatic movie import acceptance.

Both new applications use /volume1/media/downloads-v2 at /downloads. qBittorrent category radarr saves to /downloads/complete/movies. A tiny disposable hardlink fixture between that directory and the movie root passed under UID1026 and was removed. Radarr hardlinks are enabled; no remote path mapping. Original empty /volume1/media/library-v2/movies was retained. No old library or service changed. New client uses homelab-v2-vpn:8082, saved private credentials and category radarr; automatic completed/failed torrent removal is disabled during parallel setup.

Downloader is running behind healthy NordVPN; tun0 binding, namespace sharing and default-drop firewall verified. Its existing permitted validation torrent remains complete/stopped. No movies, new torrents, automatic searches or production imports initiated. Tailscale backend reaches both Radarr and downloader. Native client test and settings persistence checked after Radarr restart. Post-recovery old-container identity/start-time checks pass.

Rollback for this integration: remove only qBittorrent New client, restore the prior Radarr Compose/env files and /movies root using private management-PC copies, recreate only new Radarr. No files were moved or deleted from original movie root. Stop only new downloader/VPN if deferring integration. Preserve old stack. Full backup planning remains deferred.

## Historical rollout and incident records

The dated entries below describe earlier states and are superseded by the current status above.

Status2026-11-02: configured but STOPPED pending NAS resource investigation. Not ready for use; indexer-sync and full acceptance incomplete. No implementation commit.

Container/project homelab-v2-radarr. LSIO6.4.4.10685 image pinned by digest in compose.yml, UID1026/GID100, no-new-privileges, LAN7879/internal7878 on existing new bridge. State /volume1/docker/homelab-v2/radarr/data. Only other mount /volume1/media/library-v2/movies:/movies; no production library, download folder or old application data.

Forms auth required for all addresses, analytics/in-app updating disabled. Admin credential/API key saved in management PC private homelab directory outside Git. Root /movies was accepted as accessible. Movies1080p is the sole profile; fresh unused presets removed after zero movies verified. HDTV/WEB/Blu-ray1080p allowed, remux/4K excluded, upgrades off. Zero movies/download clients added.

New Prowlarr native application test passed; Radarr New link saved using private API key, new-only internal URLs, full sync and categories2000/8000. Explicit ApplicationIndexerSync command23 began; final sync result not verified. Tailscale7879 forward declared and effective configuration inspected; current Radarr target stopped. Native root write test passed. Browser/API end-to-end acceptance and restart persistence are pending. Test suite is authored but not yet executed to completion.

During sync NAS SSH banner timed out and IO load climbed to around33, predominantly storage wait. To preserve old stack, stopped only new Radarr, FlareSolverr and Prowlarr. Old eight IDs/start times verified unchanged against recovery baseline; Jellyfin remains healthy and Tailscale stays running. New VPN/downloader were already stopped. No proof of another daemon crash this phase; do not conflate recurrence of IO stalls with previously confirmed Docker panic.

After stopping new services, five-second diskstats sample showed physical-drive busy percentages0.5-7.5 and await1.4-7.4ms; md2 await52.1ms. This recovery-time sample does not diagnose the cause of earlier stall or prove a failing disk. Load averages decay after recovery. Need resource/storage investigation or explicitly revised parallel-deployment strategy before resuming. Do not restart full new stack or stop old stack automatically.

Rollback/defer: keep new services stopped, retain state and link/forward for diagnosis. Existing new Prowlarr indexer configurations preserved. If removing this phase, remove only Radarr New link and7879 forward; preserve all other services and data. No production cutover/deletion or publication authorized.

## Controlled retry 2026-11-02 08:10–08:15

User authorized continued work after the read-only investigation. Started only new Prowlarr first: initial API probe was before readiness; once ready its targeted acceptance suite passed, including saved five indexers, auth and Tailscale backend reachability. Started Radarr alone next; API ready, sole 1080p profile, one isolated root, zero movies/download clients. Only LimeTorrents had persisted from the prior interrupted sync. Prowlarr application still correctly points exclusively to new Radarr.

Started FlareSolverr separately. Browser installation self-test passed and internal readiness endpoint responded. Triggered exactly one ApplicationIndexerSync, command28 at approximately08:13. Shortly afterward SSH banner exchange and both application API reads timed out. At08:14:54 load12.95, IO12.83, CPU0.12. Stopped only new FlareSolverr/Radarr/Prowlarr; an initial delayed stop and a retry both completed idempotently. Old stack not stopped or recreated. No movie/download jobs started. No OOMKilled flag on inspected containers.

Final inspection: all eight old container IDs/start timestamps still exactly match recovery baseline; accepted Jellyfin/Tailscale running, Jellyfin /health Healthy. Three experimental application containers verified exited. New VPN/downloader remain stopped. This reproduces the stall in the sync/browser phase, but does not distinguish browser activity, indexer HTTP behavior, memory reclaim or shared disk contention. Do not assert a failing drive, RAM exhaustion or second daemon crash from these observations.

Readiness was insufficient to establish load tolerance. Full Radarr suite, restart persistence and live Tailscale client test remain incomplete; attempted compose/write/serve inspection encountered SSH timeout, so no pass claimed. Added back explicit Prowlarr test assertions for the sole approved new Radarr app and new-only endpoints; this edit awaits execution. No implementation commit, merge, tag or changelog change after failed trial, following feature-completion stop-on-failure instructions. Next diagnostic proposal: isolate browser work and obtain per-process I/O/reclaim evidence before repeating application sync. Avoid another full retry without a revised diagnostic plan.

## Current status — 2026-11-02 resumed installation

Supersedes the stopped-status paragraphs above. User explicitly instructed continued troubleshooting and installation despite the failed sync. New Radarr, Prowlarr and FlareSolverr are running; old stack remains untouched. Radarr core acceptance passed: authentication and saved browser login, isolated writable root, sole 1080p profile without remux/4K or upgrades, two movie indexers (LimeTorrents and The Pirate Bay), and Tailscale-to-Radarr reachability. No movies or download clients added. Downloader integration remains a separate phase.

1337x native test failed; it remains saved in Prowlarr but is not synced into Radarr. Full three-indexer acceptance remains pending. Test suite retains its default three-indexer assertion; explicit -CoreOnly validates the usable two-indexer configuration and prints a warning instead of claiming full acceptance. Do not interpret a completed Prowlarr sync command as all indexers succeeding.

FlareSolverr investigation: a single isolated 1337x request reported Chrome startup HTTPConnectionPool localhost read timeout120 after133.5 seconds, despite request maxTimeout60. A temporary512MiB total memory/swap limit was too restrictive for this trial; changed to768MiB memory and768MiB total memory+swap, then restarted only solver. Compose now records those limits to preserve them on recreation. Subsequent1337x native test still failed. This bounds allocation; it does not prove the underlying timeout or NAS contention fixed. No old workload limits changed.

Project changes remain local and uncommitted pending full acceptance; no merge, publication, tags or changelog edits. Remaining:1337x browser/indexer diagnosis and user remote Radarr confirmation. All previously approved indexers retained. Do not repeatedly shut down working applications solely because one optional source fails.

Post-restart verification: new Radarr restarted successfully; all CoreOnly assertions passed again, including both required core indexers, saved credentials/settings and all eight old IDs/start times. Compose validation passed for the bounded FlareSolverr configuration. Jellyfin health and final running-state checks performed separately.

Validation update2026-11-02: see .agents/artifacts/validation_media_2026-11-02.md. Existing Sintel test file was requested through Seerr, explicitly manually imported by Radarr as a hardlink, indexed/streamed by Jellyfin and marked available by Seerr's recent scan. Retained unmonitored test fixture supersedes earlier empty movie/request baseline. Native new Radarr/Sonarr Jellyfin import notifications configured/tested with mapped paths; fresh unattended download/import still unverified. No old-stack change.
