# Project Progress & Milestones

> The inherited milestones and 79-assertion UGREEN runtime validation below describe the reference project, not the active Synology deployment. For current DSM state and evidence, use `.docs/synology.md`.

## Completed Capabilities
- [x] Baseline homelab infrastructure operational: 20 active container services managed via Dockge.
- [x] Dual-homed Caddy reverse proxy on `external_npm` macvlan (`192.168.0.4`) with automated TLS (`*.kamaka.tech`).
- [x] Zero-downtime Restic backup automation with online database staging and retention pruning.
- [x] Automated smoke, routing, interconnect, direct admin, and security test suites.
- [x] Dual-tagging release model (SemVer + CalVer) and changelog governance.
- [x] Modern multi-agent harness aligned with `ParanoydAndroid/coding-agent`.
  - [x] Architectural plan drafted, executed, and archived.
  - [x] Session memory bank established (`.agents/memory/`).
  - [x] Invocable subagents authored (`.agents/subagents/`).
  - [x] Modular scoped rules authored (`.agents/rules/`).
  - [x] Canonical root `AGENTS.md` and ecosystem symlinks converged.
  - [x] Test harness migrated to `.harness/` with new `conventions` suite.
  - [x] Unified `manage.sh` master entrypoint implemented.
  - [x] GitHub Actions CI workflow authored (`.github/workflows/ci.yml`).
  - [x] Git hooks guarding `main` installed.
  - [x] Legacy `.tests/` directory and symlink decommissioned.
  - [x] Comprehensive repository-wide documentation and link audit completed (129/129 valid).
  - [x] Tracked and host systemd unit files updated to `manage.sh`.
  - [x] Legacy `homelab.sh` fully decommissioned.
  - [x] User review gate approved for patch release `3.4.1` / `2026.11.5.1`.

## Verification Status
- Automated test suite: 79/79 passing (`./manage.sh test all`).
- Codebase & infrastructure audit: Clean, zero issues (`./manage.sh audit`).
- Markdown link audit: 129/129 links valid across 43 files.
- Active containers: 20/20 running and healthy.
- Active release: `3.4.1` / `2026.11.5.1`.

## Known Issues / Backlog
- None.

## Synology Harness Adaptation
- [x] Created isolated `feature/synology-coding-agent-harness` from updated `origin/main`; preserved dirty `main` and the older Synology worktree.
- [x] Added the Synology project overlay, current deployment/environment references, and DSM-specific onboarding guidance.
- [x] Added fail-closed DSM command routing, read-only status, and explicit private config/database backup with SQLite online snapshots and isolated restore integrity verification.
- [x] Added the Synology test suite and regression fixtures for symlink, path traversal, and SQLite sidecar safeguards; focused suite passed 5/5 locally, with live DSM checks skipped on Windows.
- [x] Created a private NAS checkpoint on November 5: 1,612 files, five SQLite databases, five isolated restore integrity checks passed. This is same-volume recovery material, not off-device disaster recovery.
- [x] Confirmed the natural 10:30 Eastern monitoring run passed with zero warnings after updating the collector.
- [x] Exact-file publication review: 25 staged files, no `.env`, zero secret-pattern hits, and all 66 internal links resolved. The generated Python cache was excluded.
- [x] Scoped local implementation commit `f0c1adc` on `feature/synology-coding-agent-harness`.
- [ ] Push to the verified user fork is pending GitHub OAuth reauthorization: the current credential lacks `workflow` scope required for the inherited CI workflow. No remote branch was created by the rejected push. The local SSH key fallback was rejected by GitHub after its published host key was verified.
- [ ] User review remains required before merge, release, tag, or deployment.
