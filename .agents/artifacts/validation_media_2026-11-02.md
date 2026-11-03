# Controlled media validation — 2026-11-02

Scope: user authorized continuing new-stack validation without routine prompts. Existing Creative Commons Sintel2010 test download reused; no new acquisition. Old stack preserved.

## Procedure and measured results

- Original completed/stopped qBittorrent validation file is1024x436,129241752 video bytes. Retained source and original stopped torrent.1080p profiles were not changed.
- Temporarily disabled only new Radarr download client and set only new Seerr Radarr service preventSearch=true. Original settings saved privately. Submitted Seerr movie request for TMDB45745 as existing owner. Response status2 (approved); Radarr created movie id1. This verifies owner request delivery/approval, not a separate non-admin permissions scenario.
- Set only test movie unmonitored, restored original enabled client and preventSearch=false. No new downloads initiated. Later tests confirmed normal settings restored.
- Native Radarr manual import from /downloads/validation/Sintel/Sintel.mp4, importMode copy and honest WEBDL480p label. Name-only candidate could not parse quality; explicit manual quality supplied. Command112 completed, imported one file. This is an explicit manual import of existing content, not a test of unattended completed-download handling.
- Original and imported paths report inode13568, linkcount2, size129241752. Hardlink verified, no second video allocation. Imported path /downloads/library/movies/Sintel (2010)/Sintel.mp4.
- Added native MediaBrowser/Jellyfin notifications to NEW Radarr and Sonarr: imports/upgrades trigger library update; notify=false; host homelab-v2-jellyfin:8096; mapFrom /downloads/library, mapTo /media/downloads-v2/library. Dedicated Jellyfin API token saved privately. Both native connection tests passed. Future import notification execution remains to be observed on a subsequent import (these connections were added after this manual import).
- Targeted media update and Movies item refresh did not initially discover the newly configured folder. Started new Jellyfin's library-discovery task; it subsequently indexed Sintel with TMDB45745 and IMDbtt1727587. Existing library locations and read-only mount preserved. Scan found an unreadable pre-existing Dark Phoenix MP4 (moov atom missing); no source files changed/deleted.
- Jellyfin item9dcf82997da911bd02b4a10fc4165f27 points to exact imported path. Authenticated static video request with Range bytes0-65535 returned206 and65536 bytes. Jellyfin's ffmpeg decoded first2 seconds successfully. This is server-side streaming/decoding verification, not human phone playback or full-video validation.
- Ran Seerr's native Jellyfin Recently Added Scan; request1 status5 and media status5 (available). No manual availability override.
- Targeted downloader, Radarr core, Seerr, Sonarr and media-validation checks cover source preservation, new-only endpoints,1080p preferences, availability, native notifications and old-eight recovery-baseline identities/start times.1337x remains explicitly outside current Radarr core acceptance. No browser-source stress tests while Jellyfin scan is active.

## Remaining and rollback

Still unverified: fresh automatic torrent acquisition/completed-download import, a subsequent native Jellyfin import notification, TV media workflow, remote phone playback of this test, and browser-dependent indexer reliability. Library scan status is separate from successful test-file availability; do not claim scan completion unless observed.

Test fixture is intentionally retained and unmonitored. Removing it later should delete only the imported hardlink/test app records, not source validation data or original torrent. API fixtures and safe metadata are in .configs/validation/sintel.json; credentials/raw responses remain private. No old-stack shutdown, source cleanup, publication or release tags.

Final observation: Jellyfin library-discovery task Idle with LastExecutionResult Completed; the validation scan has finished.
