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
  - [x] Canonical root `AGENTS.md` and portable agent instruction copies converged.
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
- [x] Replaced symlink entrypoints with tracked full-file copies and a generated `.skills/` mirror; the Windows conventions suite passed 10/10.
- [x] Integrated the authenticated app-health helper and five regression fixtures from the canonical monitoring work, preserving exact source-file bytes.
- [x] Focused recheck after portable-copy and monitoring integration: conventions 11/11; Synology suite 7/7, including five authenticated app-health unit fixtures. Live DSM container inspection was skipped on Windows.
- [x] Updated the Synology reference to the latest scheduled monitor report: DSM recovered, Radarr/Sonarr clear, and Prowlarr `IndexerProxyStatusCheck` remains unresolved.
- [x] Exact staged review: 39 files, no `.env`, no secret-pattern hits, six documentation files checked with zero broken local links, copied monitoring sources hash-identical, and `git diff --cached --check` clean. Generated Python cache was excluded.
- [ ] Commit the scoped portable-entrypoint and monitoring integration changes locally.
- [x] GitHub branch backup published to bretbiggs-cloud/homelab-configs on 2026-11-05. Remote feature/synology-coding-agent-harness matched reviewed commit 50bb805 before this status update. A command-scoped Git Credential Manager selection used the newly authorized workflow scope; no global helper changes or credentials were published.
- [ ] User review remains required before merge, release, tag, or deployment.

## Active workspace framework — November 5, 2026

- [x] User authorized activation. Installed full instructions and ten skills at HomeLab and the older repository entrypoint, routing commands and memory to the tested worktree.
- [x] Verified 40 generated files with zero mismatches; entrypoint instructions fit the default discovery budget. Existing files preserved in a timestamped activation checkpoint.
- [x] Current chat read canonical instructions, deployment reference, and memory. Framework use does not require a service restart or checkout replacement.
