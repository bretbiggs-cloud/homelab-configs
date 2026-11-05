# Active Context

## Current Focus
Implementation and validation are complete on `feature/synology-coding-agent-harness`; final exact-file review and sanitized push to the user's fork remain. The branch is based on the standalone harness at `origin/main` and preserves the separate dirty main checkout. Plan: `.agents/artifacts/plan_synology-coding-agent-harness.md`.

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
- Finish internal-link and secret scans over the exact changed files, then stage only the explicit safe allowlist.
- Commit the implementation locally and push the sanitized feature branch only to the user's verified public fork, never the upstream author's repository.
- Stop at the mandatory user review gate before merge, release, tag, or deployment to DSM.
