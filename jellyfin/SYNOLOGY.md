> Dated implementation history. Later entries supersede earlier entries; for current production state use [the consolidated Synology reference](../.docs/synology.md). Old parallel-stage rollback instructions are historical after cutover.

# Synology Jellyfin deployment and verification

Status: deployed and infrastructure-verified. Setup wizard complete; initial indexing and user playback acceptance remain pending. Old Jellyfin remains running. Plan committed locally as b20704d; no push.

## Ownership

Compose is jellyfin/compose.yml in this feature worktree, project homelab-v2-jellyfin. Do not remove or relocate the worktree while a deployment uses it. Runtime configuration is outside Git at /volume1/docker/homelab-v2/jellyfin/data/config and cache. The old /volume1/docker/jellyfin is untouched.

## Prepared design

New endpoint http://192.168.1.220:8097; old endpoint remains8096. Container homelab-v2-jellyfin runs as1026:100. Image digest fea863d0cd9ec445985d9c75fc6ed64e38a1d2766cf0c250a33d553f4fc1b771 corresponds to locally verified Jellyfin12.4.0.0. Media /volume1/media is mounted read-only. Drop all capabilities, no-new-privileges, json-file logging10m/3. No GPU or discovery ports. Dedicated Compose bridge. No Tailscale installation in this step.

Compose config --quiet passed on the NAS. Created isolated target directories and homelab-v2-jellyfin container/network; application data is owned by the verified non-root identity. Current observed RAM available780MiB; swap4377/4383MiB. Observe idle footprint before library scans; direct playback and transcoding are not yet tested.

## Deployment steps after plan commit

Create only the new config/cache directories after confirming target is absent; preserve ownership of all existing directories. Record all original container start timestamps. Validate Compose again and start only new Jellyfin with --no-deps --pull never. Do not run upstream setup.

## Required checks

- Container running/healthy, restart0, OOMfalse, identity1026:100.
- Inspect exact isolated config/cache mounts and read-only media mount.
- Check new and old HTTP health endpoints, and unchanged old container start timestamps.
- Check actual log bounds, capabilities, network and only intended port publication.
- Verify readable media and writable new app state without editing media.
- Record before/after memory availability and idle container memory.
- Complete fresh setup with user-controlled admin credentials, selected media libraries and an identifiable new server name.
- Verify library discovery and representative playback with the user before calling the replacement operational. Never shut down old Jellyfin until explicit user confirmation.

## Rollback

Stop only service jellyfin in Compose project homelab-v2-jellyfin using this worktree's Compose file. Retain new data for diagnosis. Never issue broad down/prune or target container jellyfin (the old server). No existing database migration is performed, and full backups remain deferred by user decision.

## Evidence sources

Official container guidance: https://jellyfin.org/docs/general/installation/container/
Local authorized architecture: .agents/artifacts/plan_synology-stack.md.
## Deployment verification

All assertions in .tests/suites/test_synology_jellyfin.ps1 passed after initial database migrations completed. Early startup health returned503/starting; no configuration change or restart was needed. Final state healthy, restart0, OOMfalse; HTTP health passed on old8096 and new8097. New web UI HTTP200, public API reports12.4.0 and StartupWizardCompleted=false. All nine preexisting container start timestamps matched the pre-deployment snapshot.

Verified exact isolated bind mounts, read-only media, UID1026:100, dropped capabilities, no-new-privileges, LAN-only8097 binding and bounded logs. Sample startup memory297MiB for new container, NAS available553MiB and swap full. This is startup evidence, not a steady-state capacity guarantee; avoid additional services or large scans until observed under normal use.

Run scoped Windows tests with PowerShell: .tests/suites/test_synology_jellyfin.ps1. This is a separate Synology suite; upstream UGREEN full-suite checks are not applicable to this phase. Library/file playback, credentials, scan load, transcoding, Tailscale and restoration remain untested. Do not call the replacement accepted until the user verifies playback and explicitly authorizes cutover. No remote exposure or router changes made.
## Fresh setup completed

User instructed the assistant to finish setup. Created administrator Biggs with a randomly generated password stored in a restricted user-only local folder outside this repository. No password or token recorded here. Authenticated login verified; server name Substation Jellyfin New; wizard complete.

Movies library includes /media/Movies and /media/Kid Movies. TV Shows uses /media/tv_shows. US/English metadata. Read-only media retained; local metadata/subtitle writes disabled. Realtime watching, chapter/trickplay extraction and LUFS scanning disabled to bound initial workload. Remote access and UPnP both verified false; later Docker Tailscale phase will configure appropriate private remote access.

Initial scan underway: observed35.2%, later1552 movies indexed; TV count0 at that sampling point does not establish final contents. One playback-info request timed out during scanning. Subsequent authenticated direct-stream Range request returned HTTP206 and exactly1048576 bytes, proving server delivery of indexed media. This does not verify client decoding, full playback, subtitles or transcoding. Both old/new servers healthy, restart0; old start timestamp unchanged. Available RAM454MiB and full swap observed while indexing; no additional services started.

All infrastructure/isolation tests passed again after setup. Old server remains active pending user confirmation; no cutover performed. Full scan completion and device playback remain acceptance items. Full backup planning deferred as requested.
## Jellyfin cutover accepted

User confirmed successful remote login and playback via Tailscale, then explicitly authorized shutdown. Stopped only the old container jellyfin and changed its restart policy from always to no so it remains retired after NAS reboot. Verified old Running=false/restart=no; new instance healthy with zero restarts and HTTP200 health. Scoped infrastructure/retirement tests passed. All old configuration, cache and media retained; no deletions. Other old-stack services remain running pending individual replacements. New LAN port remains8097 and private Tailscale port8096; no port migration or Homepage edit.

Rollback if authorized: stop new writers as needed, set old jellyfin restart policy back to always, then start old jellyfin. Its original configuration and LAN8096 binding are retained. Review before using both in production. User-confirmed playback is evidence of successful tested playback, not exhaustive codec/device coverage.
## Authorized old-instance removal

User stated old instance was installed today and had no history worth preserving, then explicitly approved removal. Verified old container stopped, canonical config/cache paths exact and not symlinks, and no other container referencing old data. Removed only container jellyfin and /volume1/docker/jellyfin/config plus cache with a one-filesystem boundary. Absence verified. Prior measured old data approximately4.93GiB; actual filesystem free-space gain may differ due to snapshots/shared extents. Shared /volume1/media, Docker image and all new-instance binds preserved. New healthy/restart0/OOMfalse and HTTP health/isolation tests passed. Other services untouched.

This supersedes earlier rollback instructions: the old container and app data no longer exist, and no old-instance restore copy was established. Do not attempt the prior docker start rollback. Scoped tests now assert old-container/data absence and media preservation.
Seerr integration2026-11-02: existing Movies and TV Shows libraries also include /media/downloads-v2/library/movies and /media/downloads-v2/library/tv respectively. Existing folders retained; paths added with refreshLibrary=false, no full scan requested. Read-only media mount unchanged. Seerr authenticates to new Jellyfin and provides private Tailscale playback links. Actual new import/playback pending.

Validation update2026-11-02: see .agents/artifacts/validation_media_2026-11-02.md. Existing Sintel test file was requested through Seerr, explicitly manually imported by Radarr as a hardlink, indexed/streamed by Jellyfin and marked available by Seerr's recent scan. Retained unmonitored test fixture supersedes earlier empty movie/request baseline. Native new Radarr/Sonarr Jellyfin import notifications configured/tested with mapped paths; fresh unattended download/import still unverified. No old-stack change.

Remote playback2026-11-02: enabled transcode throttling with existing180-second lead after web-client audio conversion and highIO observation. Phone Tailscale link measured DERP relay, not direct. Setting read-back verified; user playback improvement not yet verified. See .agents/artifacts/playback_buffering_2026-11-02.md. No router or old-stack changes.
