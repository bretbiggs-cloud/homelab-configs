> Dated implementation history. Later entries supersede earlier entries; for current production state use [the consolidated Synology reference](../.docs/synology.md). Old parallel-stage rollback instructions are historical after cutover.

# Synology Prowlarr

Project homelab-v2-prowlarr is managed from this permanent feature worktree. Do not move or remove the worktree while deployed. LinuxServer stable amd64 image is digest-pinned; application uses verified PUID1026/PGID100 via the supported image entrypoint. No media, download or old application directories are mounted.

LAN: http://192.168.1.220:9697
Tailscale: http://substation.tail8f9607.ts.net:9697
Internal service: http://homelab-v2-prowlarr:9696
State: /volume1/docker/homelab-v2/prowlarr/data

Forms authentication is required on all addresses. Administrator username is admin; generated password and API key are saved in the management PC's private homelab credentials directory, outside Git. Browser sessions and API-key authentication are tested separately. Analytics and in-app automatic updating are disabled; update the pinned image through reviewed Compose changes.

User selected an empty indexer list. No old database/settings were copied, and no download clients or application connections were added. New Sonarr/Radarr and indexer choices are later phases; search, synchronization, FlareSolverr and end-to-end downloads are not yet validated. Prowlarr uses ordinary outbound networking; only downloader egress is constrained to NordVPN. Remote ingress uses the existing private Tailscale forward, without public routing or Funnel.

## Operations and validation

Use the stack directory with docker compose -p homelab-v2-prowlarr. Validate config --quiet before up -d. Rollback stops only this new service and removes only TCP9697 from .configs/tailscale/serve.json; preserve other Serve targets and state. Full backup tooling remains deferred. Old services are still authoritative until separately approved cutover.

From Windows PowerShell7.5+, run .tests/suites/test_synology_prowlarr.ps1 -NasUser <NAS SSH username>. Checks include isolated mounts, expected identity/port, required authentication, API denial without key, saved browser login, empty integration lists, Tailscale backend reachability and unchanged old-container start times. Do not run upstream homelab.sh test all unchanged on DSM.

Initial startup exceeded a short readiness window while creating databases; logs showed progressing migrations and the application subsequently became ready. No container crash occurred. Test implementation corrections preserve exact Docker timestamps with ConvertFrom-Json -DateKind String, require explicit NAS SSH username instead of assuming the Windows username, and check browser authentication at the UI while testing API-key access separately. These corrections retain the original security and preservation assertions.

Sources: https://docs.linuxserver.io/images/docker-prowlarr/ and https://prowlarr.com/docs/api/ .

Final acceptance: Prowlarr2.7.0.5723 passed targeted checks before and after new-only restart; ~97MiB RAM measured. Effective Tailscale Serve configuration includes9697, and existing Jellyfin/qBittorrent backends remain reachable. All five old automation/downloader start times are unchanged. Phone-to-Prowlarr acceptance remains user-side; indexer functionality is intentionally unconfigured.

FlareSolverr integration: proxy FlareSolverr New uses http://homelab-v2-flaresolverr:8191 with120-second request budget and flaresolverr tag. No indexers were added or tagged. See ../flaresolverr/SYNOLOGY.md for timeout diagnosis, validation and rollback.

Current state2026-11-02: five approved public indexers enabled and native-tested; see .configs/prowlarr/indexers.json and .agents/artifacts/status_synology-indexers.md. EZTV/1337x carry flaresolverr tag and their challenges were solved during validation. Earlier empty-indexer/untested-source statements above describe initial deployment only. No managers or download clients connected. CheckHealth completed with no warnings.
