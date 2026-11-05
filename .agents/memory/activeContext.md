# Active Context

## Current Focus
Adapt the homelab repository to the standalone coding-agent harness on `origin/main` while preserving verified Synology guidance and isolating unrelated dirty work. Feature branch: `feature/synology-coding-agent-harness`. Plan: `.agents/artifacts/plan_synology-coding-agent-harness.md`.

## Recent Changes
- Modernized agentic harness in alignment with `ParanoydAndroid/coding-agent`.
- Established persistent 3-file memory bank (`activeContext.md`, `systemPatterns.md`, `progress.md`).
- Authored invocable subagent specifications (`architect-critic.md`, `code-auditor.md`).
- Authored modular rules (`containers-and-env.md`, `shell-scripting.md`).
- Converted `AGENTS.md` to canonical root entrypoint with multi-agent symlinks (`agent.md`, `CLAUDE.md`, `GEMINI.md`, `.cursorrules`, `.agents/rules/project-conventions.md`).
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
- Reconcile the old Synology overlay and current production reference with the harness's new `AGENTS.md`, memory, skills, `manage.sh`, and `.harness` layout.
- Add fail-closed DSM command routing and safe, read-only Synology checks/tests; do not deploy this branch to the NAS.
- Validate documentation links, script/test behavior, and current runtime evidence; then stop at the mandatory user review gate before any release/merge/push.
