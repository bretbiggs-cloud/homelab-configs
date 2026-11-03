# Indexer rollout status

Completed2026-11-02 after user authorized resumption. New Prowlarr and FlareSolverr running; new VPN/downloader remain stopped. Old eight services preserve recovery baseline IDs/start times; Jellyfin healthy and overnight scan completed.

| Indexer | Native test/save | Solver tag |
| --- | --- | --- |
| LinuxTracker | Passed, saved | None |
| LimeTorrents | Passed, saved | None |
| The Pirate Bay | Passed, saved | None |
| EZTV | Passed, saved | flaresolverr |
| 1337x | Passed, saved | flaresolverr |

Primary definition-provided URLs and Standard profile, priority25. Nonsecret catalogue in .configs/prowlarr/indexers.json. Runtime database under isolated Prowlarr config is authoritative; catalogue is a reviewed record, not automatic import tooling. LinuxTracker is distribution content, not film/TV coverage. No apps/download clients configured, and no payload downloads initiated.

New Prowlarr initially attempted the stopped solver even for untagged test candidates; absence of indexer tag must not be treated as an isolation/security guarantee. Both challenge-requiring candidates are now explicitly tagged. Solver logs confirm actual Cloudflare challenge resolution for EZTV and1337x. Responses ranged around50-121 seconds including startup/cleanup; challenge success is time-specific, not a future guarantee. Remain sequential on4GiB NAS.

After source saves, native solver check passed and CheckHealth command completed; health API returned no warnings. Targeted Prowlarr regression passed: five approved sources, tags, profile/enabled status, authenticated UI/API, unauthorized-access rejection, no production connections, private forwarding/backend, and old IDs/start times. Separate check verified all eight old services plus Jellyfin health.

Test changes are intentional: approved indexers replace initial empty-list assertion; old baseline now uses recorded user-authorized recovery timestamps/IDs rather than pre-crash uptime. Historical baseline retained. Full upstream suites not run because they assume an incompatible deployment. No container restarts beyond starting the two stopped new services, no old-stack cutover/deletion, no public publication.

The overnight daemon crash was separately diagnosed and recorded in incident_docker_2026-11-01.md. Morning scan completion and low load permitted incremental resume, but neither proves the Docker defect fixed nor provides unlimited workload capacity. Old-stack removal remains a later user-confirmed cutover.
