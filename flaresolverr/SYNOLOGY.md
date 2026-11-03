> Dated implementation history. Later entries supersede earlier entries; for current production state use [the consolidated Synology reference](../.docs/synology.md). Old parallel-stage rollback instructions are historical after cutover.

# Synology FlareSolverr

Container/project: homelab-v2-flaresolverr. Official3.5.2 image pinned in compose.yml. Image-defined non-root user, cap_drop ALL, no-new-privileges, no host ports or bind mounts. Internal8191 on homelab-v2-jellyfin_homelab. No Tailscale forward or persistent state. Capped256MiB /tmp tmpfs is not an overall memory limit. HTML logging disabled; normal info logs bounded.

New Prowlarr proxy: FlareSolverr New, http://homelab-v2-flaresolverr:8191, requestTimeout120 seconds, explicit flaresolverr tag. Apply that tag only to selected indexers needing the solver. No indexers added or retagged. Old Prowlarr untouched. Solver uses ordinary outbound networking; downloader remains behind NordVPN.

## Timeout diagnosis and mitigation

Initial native test reached the solver, but its browser timed out after60 seconds. Direct HTTPS GET from the solver returned Pong from the same endpoint. A separate browser fetch of example.com succeeded but took73.9 seconds overall. A short host CPU sample showed48.9 percent IO-wait, with substantial swap in use. Temporary debug logs later showed browser creation around9 seconds and successful navigation to Prowlarr's test endpoint, with no challenge detected. Native retry passed in19.8 seconds wall time (solver12.3 seconds).

Evidence supports intermittent browser latency under host IO pressure rather than a persistent DNS/TLS or Prowlarr-to-solver connection fault. The exact cause of the original navigation stall was not proven. Raising the explicit Prowlarr budget to120 seconds provides bounded tolerance; the successful retry was already below60 seconds, so this is a resilience mitigation rather than proof that the setting alone resolved the original event. No credentials, privileges, firewall or old-service changes made. Debug logging reverted to info. No claim to eliminate host IO contention or solve every Cloudflare challenge.

## Verification and operations

From PowerShell7.5+, run .tests/suites/test_synology_flaresolverr.ps1 -NasUser <NAS SSH username>. Dated baseline in .agents/artifacts/flaresolverr-old-baseline.json records old IDs and start times. Checks require unchanged old services, no host exposure, non-root hardening, Docker DNS/backend access, stored tagged proxy with120-second timeout, native Prowlarr test, and one example.com Chromium fetch. Client transport budget150 seconds includes browser cleanup overhead. Test success assertions remain strict; no bypass of native validation.

Only sequential browser validation on this4GiB NAS. Startup footprint was about216MiB; request browsers use additional RAM. Source-specific challenges remain untested because the new indexer list is empty. Never present basic browser tests as proof of successful indexer bypass.

Rollback: remove only the new proxy, remove its tag only if unused, and stop only the new solver. Keep old containers and other settings. Permanent feature worktree owns deployment; do not remove it. No public exposure, automatic downloads or Git publication. Backup system deferred by user.

Source: https://github.com/FlareSolverr/FlareSolverr .

Final validation: full targeted suite passed after recreation with normal info logging, including native Prowlarr proxy test, example.com browser fetch, security checks and unchanged old IDs/start times. One test-script array-enumeration defect was corrected after direct API inspection confirmed the saved proxy; success criteria were unchanged. Solver measured265MiB in a later sample, host available memory about1GiB. Source-specific challenge solving remains pending.

Current state2026-11-02: resumed alongside new Prowlarr. Native EZTV/1337x tests and saves succeeded with observed solved Cloudflare challenges; both explicitly tagged. Earlier untested-source statements describe initial rollout. Native proxy test and completed Prowlarr health refresh pass. Untagged candidate tests also attempted solver access while it was stopped; tags are selection settings, not a security boundary. Old stack unchanged since recovery; new downloader remains stopped.
