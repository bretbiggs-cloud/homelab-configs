# Synology stack architecture plan

Status: revised requirements draft; not approved for deployment.
Date: 2026-11-01 (America/New_York).
Branch: feature/synology-stack; upstream base754a811.

## User requirements superseding the previous draft

Build a NEW stack from this repository alongside the existing deployment. Do not adapt the old deployment in place. Keep the old stack available during validation. Shut it down only after the user explicitly confirms the new stack works. Shutdown does not authorize deleting old containers, configuration, volumes or media.

Remote access must be through Tailscale only. No Cloudflare Tunnel, public reverse-proxy ingress or router port forwarding. Seerr requests should be automatically approved. Exact trusted-user scope and request limits will be defined during setup, without reverting to manual approval by default.

Clarified user decisions: prefer Docker for services including Tailscale; discourage additional DSM packages. Use a single-volume stack design. Bring up the core first, adding one service at a time. Full backup design is deferred by the user; it is not a prerequisite to isolated core deployment. Retain old state and narrowly scoped configuration rollback copies. No backups or recoverability are claimed.

## Evidence and instructions

Fresh planning inspection confirmed DS923+, nine existing containers running, and no RAID rebuild in /proc/mdstat. FlareSolverr and Tailscale were absent from container inventory; standard Tailscale DSM package directory absent. Historical records describe4GB RAM with substantial swap use; resource capacity must be rechecked before parallel deployment.

Use AGENTS.md and local Synology overrides, feature-initiation and its grill-me reference. The user's new-build instruction supersedes the earlier preserve-in-place constraint for the new stack. Preserve old deployment until confirmed cutover, not as the target architecture. Apply stack-authoring, backup-recovery and test-authoring with Synology-specific paths, identities and commands. Never run upstream homelab.sh setup unchanged.

The feature worktree isolates design changes from the active checkout and its Homepage bind mount. Existing uncommitted work remains intact. Do not deploy upstream templates from either checkout until they are adapted. Draft plan remains uncommitted pending convergence; no remote changes or publication. Private artifact exclusion remains; only explicitly reviewed files may later be force-added.

## Proposed target architecture

Use repository-managed declarative service stacks with a dedicated new project identity. Use a coordinated Compose project for the new core, with service-by-service startup and independently controlled VPN/remote-access components where required. Final grouping follows network and failure-boundary review. One coordinated homelab project does not require every service to share one lifecycle.

New media services: Jellyfin, Radarr, Sonarr, Prowlarr, Seerr and FlareSolverr. New downloader/VPN service: qBittorrent with NordVPN unless the user chooses otherwise; Tailscale remote access does not replace downloader VPN egress. Prefer the tailscale/tailscale Docker image; verify DSM kernel/device requirements before finalizing container privileges. Use DSM packages only if a concrete limitation is discussed with the user.

Candidate image families, not approved versions: jellyfin/jellyfin; lscr.io/linuxserver/radarr, sonarr and prowlarr; ghcr.io/seerr-team/seerr; ghcr.io/flaresolverr/flaresolverr; tailscale/tailscale if Docker chosen. Review a supported NordVPN-capable VPN/downloader design rather than copying the existing unverified protection or upstream PIA configuration. Resolve supported releases/digests, capabilities and health checks before implementation.

Homepage, Portainer and Omada are not automatically included in replacement or shutdown. The requested old-stack shutdown must name affected services precisely; Omada may control network equipment. Upstream Dockge, recipes/PostgreSQL, Cloudflare and PIA exit bridge remain outside proposed scope, not approved deletions.

## Parallel-deployment isolation

- Distinct Compose project, container names, network names, app configuration directories and named volumes. No simultaneous instances using the same writable app database or qBittorrent resume state.
- Inventory existing host listeners, then choose nonconflicting temporary bindings. Final ports are undecided until inventory; no invented available ports.
- New applications get fresh configuration by default. Selective import of old preferences requires separate review and database-consistent export; do not silently clone live databases.
- New stack may read existing media for validation, but initially mount it read-only where possible. Give new automation a separate writable test library and download staging area. Old and new automation must not concurrently rename, delete or import into the same production library.
- Seerr automatic approvals apply to configured authorized users. During validation, requests target isolated test destinations and bounded permitted test content; prevent uncontrolled download queues.
- Prove resource headroom first. Parallel Chromium/media workloads may exceed available memory. If parallel operation is infeasible, present resource options; do not silently stop the old stack to make room.

## Access and network design

Remote access exclusively through Tailscale with reviewed device/user access policy. No exit-node or subnet-router advertisements by default. Clarify whether remote scope is NAS applications only or other LAN devices as well.

Use a new internal service network with DNS-based interconnects. FlareSolverr exposes8191 internally only, no host publication. Seerr connects to the NEW Jellyfin/Radarr/Sonarr, and Prowlarr syncs only to the NEW managers. New downloader is reachable only through its intended VPN namespace/routing design. Test effective egress and deny-outside-tunnel behavior before production downloads.

Tailscale-only remote access does not automatically prohibit existing local LAN access. Final host bindings and optional private HTTPS design remain to be settled; no public ingress is required.

## Storage, configuration and secrets

Single-volume placement is confirmed; verify Volume1 shares, filesystem and available capacity before assigning final paths. Choose a distinct persistent root for the new stack; never reuse old app-data directories. Preserve efficient imports by considering filesystem boundaries between downloads and libraries. Do not assume multiple volumes support hardlinks.

Use two-tier root/per-stack .env.example templates with blank secret placeholders, verified PUID/PGID/TZ/path values, and required Compose assertions. Keep actual credentials in protected untracked configuration. No plaintext credentials in the plan, logs or Git. Follow supported image startup privilege behavior; no global chown or upstream UID1000 assumption.

A single volume, if chosen, is storage placement rather than a backup strategy. Backup destination and retention remain unresolved and deferred. Do not gate isolated core startup on a full backup system. Preserve old application state and rollback configuration; define any necessary consistent export before migrating existing state. Record recovery limitations explicitly. Old deployment retained after shutdown is useful rollback but not protection against NAS failure.

## Build, validation and cutover sequence

1. Use Docker and a single NAS volume; finalize new-stack membership and remote access scope.
2. Inspect actual host ports, packages, mounts, identity, memory and existing routing read-only. Validate available capacity and target paths.
3. Author new repository definitions, exact image versions, protected environment setup, data layout, backup/rollback steps and Synology-aware tests. Review design before deployment.
4. Deploy isolated new services incrementally with separate state and test paths. Keep old services available. Avoid broad operations that target old container names.
5. Configure Seerr automatic requests and new application connections; FlareSolverr only for applicable indexers. Establish Tailscale remote access after chosen runtime is confirmed.
6. Verify container health, DNS, authorized access, VPN protection, request/search/download/import/playback and resource trends using bounded test content. Mark skipped tests explicitly.
7. Present measured acceptance results and exact cutover/shutdown list. User explicitly confirms the new stack works before any old-stack shutdown.
8. After confirmation, quiesce the selected old automation/downloader, preserve state, transfer production ownership to the new stack and enable production writes. Avoid simultaneous writers during transition. Verify real production operation; retain old data/config for rollback.
9. Update the Synology catalog and operating instructions. Old-state deletion, pruning, repository publication and unrelated Omada/Portainer changes remain separate actions.

## Rollback

Before cutover, stop only new services if testing fails; old deployment remains available. After cutover, stop new writers first, inspect any production changes and restore old service ownership in a controlled order. Do not promise that restarting the old stack undoes media modifications. Preserve job state and define reconciliation before production writes. Tailscale changes must not sever local administrative access.

## Acceptance tests

Adapt .tests/suites for the selected Synology architecture; inspect the runner rather than execute upstream test all unchanged. Include:
- Distinct names, projects, binds, writable state and nonconflicting host ports.
- No unintended changes to old containers, start times, networks or app files during parallel deployment.
- Seerr auto-approved test request reaches only new Radarr/Sonarr and intended isolated destinations.
- Prowlarr indexer tests and applicable FlareSolverr path succeed; no solver host port.
- Controlled permitted download imports successfully and plays in new Jellyfin; no library-root download warning.
- New downloader egress uses NordVPN and enforced constraints prevent unintended fallback; disruptive tunnel testing explicitly planned/authorized.
- Tailscale access from outside LAN succeeds for intended users; access policy and lack of public ingress verified.
- Representative workload fits RAM/CPU/disk capacity without destabilizing either stack.
- Deferred follow-up: design consistent backups and verify isolated restoration. This is not an initial isolated-core acceptance gate; no claim of established recoverability.
- User confirmation precedes old-stack shutdown; production cutover and rollback steps are recorded.

## Review decisions

Confirmed: new parallel stack; old stack shut down only after user confirmation; remote access through Tailscale only; automatic Seerr approvals; Docker preferred and additional DSM packages discouraged; single NAS volume; core first, one service at a time; full backup planning deferred.
Pending: Tailscale NAS-only versus broader LAN access; precise replacement/shutdown membership; fresh app configuration versus selected settings import; final ports, versions, paths, resource capacity and production cutover details.
## Incremental rollout proposal after clarified requirements

Start with the new Jellyfin instance: separate config/cache, a verified unused test port, and read-only access to existing media. Validate login, library scan, representative playback and resource use while old Jellyfin remains available. This provides a useful working core without starting download automation.

Then add Tailscale in Docker to validate remote access to the new core. Build downloader VPN protection before introducing automatic acquisition: VPN component, qBittorrent, Prowlarr, Radarr, Sonarr, FlareSolverr, then Seerr. Each service has its own configure/test checkpoint; start no dependent service until prerequisites pass. Seerr automatic approval is enabled when the controlled request-to-import path is ready. FlareSolverr remains selected even if no current indexer needs it; integration coverage must be reported accurately.

This sequence is a proposal for review, not deployment authorization. Full backup tooling comes later as requested. Preserve the old stack and isolate all new writable state throughout validation.
## Authorized Jellyfin phase

User authorized starting the new Jellyfin stack while keeping the old instance running until confirmation. This approves the isolated Jellyfin phase; later services and old-stack shutdown are not part of this deployment.

Verified UID/GID1026:100, Volume1 free3.4TiB, free port8097, Compose v2.20.1. New container homelab-v2-jellyfin, Compose project homelab-v2-jellyfin, dedicated project network. LAN-only host binding192.168.1.220:8097; Tailscale remote access is a later phase. New config/cache /volume1/docker/homelab-v2/jellyfin/data/{config,cache}; existing /volume1/media mounted read-only at /media. Pin the locally verified Jellyfin12.4.0.0 image digest, not floating latest. No Intel GPU device/group assumptions. Current RAM available780MiB and swap nearly full: start only an idle fresh server, observe resources, defer scans until setup review. Old config is neither copied nor edited.

The approved Synology design uses a LAN validation port instead of upstream NPM/macvlan; this follows the earlier no-public-ingress and parallel-validation decisions. Keep deployment Compose in this permanent NAS feature worktree; do not remove/move the worktree while it owns the deployment. Configuration-authority promotion to main is a later reviewed step.
## Authorized Docker Tailscale phase

User authorized Docker Tailscale next with old stack retained. First endpoint is new Jellyfin only. Use official pinned Tailscale image with userspace networking, persistent /volume1/docker/homelab-v2/tailscale/data, no host networking, published ports, TUN mapping or NET_ADMIN. Attach to existing new Jellyfin project network; preserve all running service identities/start times. No routes, exit node, Tailscale SSH, Funnel or host DNS changes. TS_AUTH_ONCE=true preserves enrollment across restarts; interactive login avoids storing an enrollment key in Compose. Configure private Serve forwarding only after enrollment; test container-to-Jellyfin reachability and authorized tailnet access. Existing tailnet policy must be inspected before claiming access restriction to a specific user. User must authenticate the concrete new node in their chosen tailnet; no account inferred from Git email.

Trade-off: userspace avoids host routing changes but may limit throughput. Measure playback before considering kernel networking. One-service scope and no subnet routing follow the agreed private application access design. Current available RAM392MiB with heavy swap use; assess added footprint and do not start more services. Rollback stops only new Tailscale container, retaining state; old/new LAN Jellyfin remain independently available. No full backup tooling in this phase, per user decision.

Validation: Compose syntax, persisted identity directory, userspace/no privileges/no ports, DNS/backend HTTP, tailscale status and non-advertisement of routes, Serve/Funnel configuration, post-enrollment peer access and unchanged original containers. Final acceptance depends on user login and external-device testing; do not label enrollment pending as operational.