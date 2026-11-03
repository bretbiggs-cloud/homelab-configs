# Synology FlareSolverr phase

User authorized internal FlareSolverr connected to new Prowlarr; keep old stack running. Continue deployed feature/synology-stack and local commits only.

Use official ghcr.io/flaresolverr/flaresolverr stable image pinned by resolved digest. Dedicated homelab-v2-flaresolverr container/project on existing homelab-v2-jellyfin_homelab bridge, internal8191 only. No host ports, Tailscale forward, media mounts, secrets or persistent state required. Use image-defined non-root identity, drop capabilities and no-new-privileges, bounded logs, /tmp tmpfs capped256MiB. Validate browser startup under hardening; do not add privileges speculatively.

New Prowlarr proxy points to http://homelab-v2-flaresolverr:8191 with60-second timeout and explicit flaresolverr tag. Do not apply globally or add indexers without selection. Current new indexer list is empty; screenshot is not evidence of new-instance configuration. Preserve existing new proxy/tag settings if present. Do not modify old Prowlarr.

Checks: Compose validity, no published port/mount/privilege, running process, backend reachability from new Prowlarr, browser request to example.com, Prowlarr native proxy test, stored tagged proxy, unchanged old IDs/start times, measured memory. Browser test establishes browser operation, not success against every Cloudflare challenge. Source-specific checks deferred until indexers are added.

Rollback: delete only newly created proxy/tag if unused, stop only new FlareSolverr. No old container restart/deletion, production jobs, pushes or release tags. Backup system remains user-deferred. Initial available memory930MiB; sequential validation and monitor footprint.

Source: https://github.com/FlareSolverr/FlareSolverr .

Authorized diagnosis amendment: initial60-second native browser timeout investigated with direct GET and browser probes. Use120-second Prowlarr budget,150-second test-client budget, unchanged strict success assertions; record transient IO-related latency evidence and uncertainty in flaresolverr/SYNOLOGY.md. User authorized diagnosis/fix while preserving old stack.
