# Active Context

## Current Focus
Implementation, backup verification, and final exact-file audit are complete on `feature/synology-coding-agent-harness`. Push to the user's fork is pending because GitHub rejected the OAuth credential for lacking the `workflow` scope required by the inherited CI workflow. The existing local SSH key was also rejected by GitHub (`Permission denied (publickey)`) after verifying GitHub's host key. The branch is based on standalone harness `origin/main` and preserves the separate dirty main checkout. Plan: `.agents/artifacts/plan_synology-coding-agent-harness.md`.

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
- User needs to reauthorize the saved GitHub credential with `workflow` scope; then retry pushing the same sanitized branch to the verified fork. The existing local SSH key is not an available alternate credential.
- Latest local recheck: Synology suite passed 5/5. The conventions suite passed 8/10; its two agent-symlink checks fail in this Windows SMB checkout because `core.symlinks=false` materializes Git mode-120000 entries as target-text files. The Git tree contains the intended symlinks; Linux/DSM materialization was not re-tested here.
- Do not push to the upstream author's repository.
- Stop at the mandatory user review gate before merge, release, tag, or deployment to DSM.
