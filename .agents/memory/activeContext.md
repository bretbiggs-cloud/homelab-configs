# Active Context

## Current Focus
The repository adaptation is implemented on `feature/synology-coding-agent-harness`, based on standalone harness `origin/main`, while preserving the separate dirty main checkout. Portable Windows/SMB agent copies and the authenticated app-health helper are integrated. Focused tests pass. The latest scheduled monitor run completed in 9 seconds with a remaining Prowlarr `IndexerProxyStatusCheck` error; Radarr/Sonarr are clear. GitHub publication remains pending authorization; no retry is requested. Plan: `.agents/artifacts/plan_synology-coding-agent-harness.md`.

## Recent Changes
- Modernized agentic harness in alignment with `ParanoydAndroid/coding-agent`.
- Established persistent 3-file memory bank (`activeContext.md`, `systemPatterns.md`, `progress.md`).
- Authored invocable subagent specifications (`architect-critic.md`, `code-auditor.md`).
- Authored modular rules (`containers-and-env.md`, `shell-scripting.md`).
- Converted `AGENTS.md` to canonical root entrypoint with tracked full-file copies (`agent.md`, `CLAUDE.md`, `GEMINI.md`, `.cursorrules`, `.agents/rules/project-conventions.md`) and a generated portable `.skills/` copy.
- Migrated test infrastructure to `.harness/` with new `conventions` suite.
- Fully decommissioned legacy `homelab.sh` and `.tests/` directory.
- Migrated host systemd service units to `manage.sh startup` and `manage.sh backup`.
- Replaced all operational CLI and test references across documentation, skills, and templates with `manage.sh` and `.harness/`.
- Conducted exhaustive documentation and link audit (129/129 valid, 0 broken).
- Tested and verified: 79/79 assertions passed across 7 test suites; audit clean.

## Active Decisions
- `manage.sh` is the master operational entrypoint for all homelab lifecycle operations.
- Versioning tier: Semantic patch `3.4.1` paired with CalVer `2026.11.5.1`.

## Immediate Next Steps
- Do not retry GitHub publication while device/OAuth authorization is pending outside this worktree.
- Latest local verification: conventions passed 11/11 and the Synology-focused suite passed 7/7; live DSM container inspection was skipped because this runner is Windows. Exact source hashes, staged secret scan, link audit, and `git diff --check` are clean.
- Do not push to the upstream author's repository.
- Keep this branch local; do not deploy, merge, release, tag, or retry push while authorization is pending.
