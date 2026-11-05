# System Patterns & Architecture Idioms

## Architectural Invariants
- **Active platform**: This repository manages a Synology DSM deployment. The inherited UGREEN host model is reference-only. Read `.docs/synology.md` for the current deployment contract before host work.
- **DSM command boundary**: `manage.sh` detects DSM and blocks inherited setup/startup/backup/restore/snapshot/audit/hook operations. Only bounded read-only Synology status and the adapted test suite are enabled on DSM.
- **Remote access boundary**: Remote application access is through Tailscale. NordVPN is the downloader egress tunnel only; it does not provide user access to the NAS.
- **Operations boundary**: Monitoring is reporting-only. User authorized private same-volume config/database checkpoints and sanitized configuration in GitHub; do not prune or claim off-volume recovery. No alerting, repair automation, storage/network/VPN change, or destructive cleanup is authorized.
- **Dockge Compatibility**: Repository root contains stack folders with `compose.yml` and an optional `.env`. Non-stack entities are hidden (`.` prefix); portable root agent instruction copies are regular files. Dockge's own compose is deployed to `${DOCKGE_DIR}/compose.yml` above stacks.
- **Network Exposure Model**: Backend services run on the user-defined `homelab` Docker bridge network (`192.168.255.0/24`). Reverse proxy (Caddy) bridges LAN (`external_npm` macvlan `192.168.0.0/24`, static IP `192.168.0.4`) and `homelab` bridge. Direct host ports are closed except for non-HTTP/emergency fallback.
- **Secrets & Environment Variable Management**: Two-tier configuration model. Root `.env.example` syncs global host/network variables to stack `.env` files; per-stack `.env.example` defines secrets with blank defaults. Docker Compose enforces required variables with strict `${VAR:?Error message}` assertion syntax. Shell scripts use `${VAR}` parameter expansion.
- **Least-Privilege Container Execution**: Standard `1000:100` (`PUID:PGID`) execution, `security_opt: [no-new-privileges:true]`, `cap_drop: [ALL]`. Media mounts read-only (`:ro`) where possible.
- **Host Volume Standardization**: Persistent data isolated by container under `${DOCKER_DATA_DIR}/<service>/data/...` and media under `${MEDIA_DIR}`. Restic snapshot backups with zero-downtime database staging.
- **TRaSH Guides Adherence**: Media management baseline, NVMe scratch buffering (`/incomplete`), Btrfs No-CoW flags (`chattr +C`), RAM cache, anti-starvation queues.

## Repository & Agent Patterns
- **Portable Multi-Agent Entrypoints**: `AGENTS.md` is canonical. `CLAUDE.md`, `GEMINI.md`, `.cursorrules`, `agent.md`, and `.agents/rules/project-conventions.md` are tracked full copies. `.skills/` is a generated copy of `.agents/skills/`; run `bash .scripts/sync-agent-entrypoints.sh` after editing the canonical instructions or skills.
- **Memory Bank Lifecycle Synchronization**: Sessions must begin by reading memory bank files; task initiation updates `activeContext.md`; completion updates `activeContext.md` and `progress.md`.
- **Modular Scoped Rules**: Language and format conventions are glob-triggered (`containers-and-env.md`, `shell-scripting.md`) rather than combined into a single monolith.
- **Operational Dispatcher**: `./manage.sh` orchestrates `setup`, `startup`, `backup`, `snapshots`, `restore`, `test`, `audit`, and `hook` with zero external dependencies.
- **Protected Mainline**: Direct commits and pushes to `main` are guarded by git hooks and CI; feature branches permit unrestricted intermediate commits.
- **Agile Trunk Dual-Tagging**: Semantic versioning (`vMAJOR.MINOR.PATCH`) for functional milestones paired with Calendar Versioning (`YYYY.M.D.N`) for continuous trunk deployments.
