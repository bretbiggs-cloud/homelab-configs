# New media stack cutover checkpoint — 2026-11-02

User requested finishing the new stack so the old one can be removed. Core movie automation is verified; final phone playback confirmation is outstanding. This is a reversible shutdown checkpoint, not complete deletion or full feature completion.

## Verified production behavior

The Dog Stars (TMDB1384216) and Toy Story5 (TMDB1084244) were automatically downloaded and imported by new Radarr. Both exist under /downloads/library/movies, are indexed from /media/downloads-v2/library/movies by new Jellyfin, and have completed/available Seerr status. Authenticated64KiB video reads returned206 for both. This establishes file serving, not smooth sustained remote playback.

All nine new containers run; VPN, Jellyfin and Seerr report healthy. Native Seerr-to-Radarr/Sonarr and both managers-to-new-qBittorrent connection tests passed. Both managers reference only new Prowlarr. Corrected Radarr's TPB source URL from /2/ (LimeTorrents) to /3/ (TPB); original config retained privately and the corrected native indexer test passed. Added exact source-ID regression assertions.

Tailscale Serve reports all six application routes tailnet-only. No public router/firewall changes. Homepage, Omada and Portainer retain baseline container IDs/start times and remain running.

## Old services stopped

Stopped exact containers qbittorrent, prowlarr, sonarr, radarr, seerr with docker stop --time60. Disabled their runtime restart policies to prevent reboot reactivation. No container, image, volume, configuration or media deleted. Old Compose files still exist and can recreate/restart these services if manually invoked; do not invoke old stacks during this checkpoint.

Old Radarr and Sonarr had no library entries or queued items; old Seerr public settings reported initialized=false. Old qBittorrent has422 saved fastresume records, all with positive completion/finished/seeding timestamps. These are historical completion evidence, not current integrity or live transfer verification. Paused flags167true/255false; stopping old qBittorrent stops old seeding. Preserve its resume/config data and all media. Exit codes after requested stop: qBittorrent1, Seerr143, other three0; no claim every application exited cleanly.

RAM available increased from463MiB before shutdown to1095MiB after; swap remained heavily used at4047/4383MiB. Stopping duplicates reduces pressure but does not prove the buffering issue resolved.

## Rollback and subsequent removal

Private Windows records under .codex/private/homelab include pre-cutover-old-containers.json (secret-bearing), old-restart-policies-cutover.json, and radarr-tpb-before-cutover.json. Do not commit these.

Rollback while containers are retained: restore each original restart policy from the private record using docker update --restart=<recorded policy> <exact container>; docker start qbittorrent prowlarr sonarr radarr seerr. This resumes old seeding and resource use. No need to restore application files for this shutdown.

After satisfactory phone playback, remove only the five stopped containers with docker rm and no volume flag. Retain old bind directories and media-automation_seerr-config named volume unless separately authorized to delete their data. Never use prune or compose down -v. Unrelated services remain outside removal scope.

## Tests and limits

Run .tests/suites/test_synology_cutover.ps1 -NasUser <SSH user> for the current stopped-old phase. All checks passed before adding the persisted restart-policy assertion; the policies were then independently verified. Existing parallel-phase service suites intentionally require old services running and some require the initial Sintel-only catalog; those historical assertions do not apply after authorized cutover and real requests. They are not silently weakened. The new phase suite verifies runtime isolation, correct indexer IDs, native connections, real requests and authenticated file serving.

Retained Sintel media-validation suite passed all five checks including hardlink identity and authenticated file read. Upstream full DSM-incompatible test suite not run, per local conventions. No new downloads/searches launched by acceptance tests.

Outstanding: user retry of Jellyfin Android playback over Tailscale (prior browser session buffered and used DERP); actual TV request/download/import not yet exercised; optional browser-dependent indexers remain unreliable; backups explicitly deferred. These must not be represented as completed. No merge, push, tag or release performed.

## Completed container retirement (later November2)

User confirmed phone playback is smooth. Live Android session advanced from58.505seconds (paused sample) to77.469seconds (playing), DirectPlay, no transcoding. Jellyfin CPU0.81%, system load0.53 at sample. This confirms this phone/movie playback; it does not guarantee every codec or remote network.

Removed only the five stopped containers qbittorrent, prowlarr, sonarr, radarr, seerr using docker rm without force or volume flags. Pre-removal inspection verified all stopped with restart=no and was saved privately as old-containers-before-removal.json. All media and old application directories remain, including media-automation_seerr-config named volume. No image cleanup, data deletion or public networking changes.

Post-removal test_synology_cutover.ps1 -NasUser <SSH user> -OldRemoved passed: nine new services running, old five absent, unrelated services unchanged, native connections, exact indexer source IDs, both production movie files served and Seerr availability, and Tailscale-container access to Seerr. Old data directories and named volume independently verified present.

The preceding stopped-container rollback instructions are now historical: docker start cannot restore deleted containers. Recovery would require recreation from the preserved /volume1/docker/qbittorrent/compose.yaml and /volume1/docker/media-automation/compose.yaml with existing data, after reviewing their networking and saved private container inspection. Do not run those stacks during normal operation. Settings retained for recovery are not a verified backup.

Movie cutover and old container retirement are complete. Actual TV download/import validation, optional browser-indexer reliability, and the deferred backup plan remain separate outstanding work. Phone playback confirmation is no longer outstanding. New service names and Tailscale URLs remain unchanged.

## Old settings deleted at user's request

User explicitly stated the old settings are not needed. Deleted only /volume1/docker/qbittorrent/config, /volume1/docker/media-automation/{prowlarr,radarr,sonarr}, both old compose.yaml files, and the unused media-automation_seerr-config Docker volume. Before deletion, verified exact resolved paths, absence of overlap with every existing container mount, and no container reference to the named volume. This intentionally supersedes the earlier retention and rollback plan: old application databases and downloader resume/history records are no longer retained on the NAS, and the old deployment cannot be restored using those earlier instructions.

Preserved /volume1/media and the separate /volume1/docker/qbittorrent/media directory. No new-stack configuration, credentials, media, images or unrelated services deleted. Private inspection records remain historical metadata, not application backups. The post-removal cutover suite passed again after settings deletion, including native connections and both production movie file reads. No data-deletion rollback claimed.
