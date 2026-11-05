# Synology adaptation plan for the coding-agent harness

Date: 2026-11-05

## Objective

Carry the homelab repository onto the standalone coding-agent harness already present in `origin/main`, then reapply and verify the Synology-specific project guidance and operational procedures. Preserve the new harness's agent compatibility, persistent memory, modular instructions, `manage.sh` entrypoint, and `.harness` tests while preventing UGREEN/Debian host assumptions from being treated as DSM facts.

## Starting points reviewed

- Harness baseline: `origin/main` at `ea21041` (`docs(cleanup): remove planning artifact and synchronize memory bank`). It already contains the coding-agent harness modernization, memory bank, modular skills/rules, `manage.sh`, and `.harness` test runner.
- Synology reference: local `feature/synology-stack` at `0c3fc68`, including the Synology production reference, environment reference, optimization guide, release checks, and local Synology instruction overlay.
- The current `main` checkout has unrelated dirty and untracked user work. This feature uses a separate worktree branched from `origin/main`; the original worktree remains untouched.
- The running DSM host is a Synology deployment. The repository's upstream README, stack catalog, `manage.sh` setup/backup/restore routines, and UGREEN runtime suites describe a different host and must not be applied to DSM without an explicit adaptation.

## Design decisions

1. Keep the standalone harness as the general agent framework. Do not recreate or fork generic harness functionality already present in `origin/main`.
2. Keep Synology facts and constraints in a focused platform reference and always-on project overlay. Link them from `AGENTS.md`, onboarding, operations, skills, memory, and tests where needed instead of copying one large block into every document.
3. Mark upstream UGREEN-specific architecture as reference-only for this deployment. Preserve it where useful to upstream users, but make the active Synology production reference the source of truth for this NAS.
4. Make `manage.sh` detect DSM before dispatching any inherited command. On DSM, fail closed for unadapted mutating host operations (`setup`, `startup`, `backup`, `snapshots`, `restore`, environment convergence, network provisioning, permission changes, and service deployment). Provide only explicitly documented Synology-safe checks and test targets. Detection uncertainty must not silently fall through to UGREEN operations.
5. Split tests into repository-only checks and explicitly invoked live DSM checks. Keep live checks read-only, bounded, and based on current service/container identities. Do not run generic tests that assume Caddy, Dockge, Restic, PIA, systemd, or UGREEN paths against the NAS.
6. Keep the existing NAS deployment and monitoring schedule unchanged during repository adaptation. Do not deploy code, restart services, change storage/network/VPN/access settings, add alerting/repairs, or create backup retention/destination policy as part of this branch.
7. Keep secrets, live `.env` files, raw logs, monitoring reports, credentials, and runtime state outside tracked/public artifacts. Preserve the existing private monitoring scripts and current dirty workspace files; add only reviewed source and sanitized documentation to this branch.

## Implementation sequence

1. **Reconcile instructions:** compare the coding-agent harness entrypoint, skills, memory lifecycle, modular rules, and tests to the Synology overlay. Update the project instructions and onboarding references so every supported agent resolves the same Synology constraints.
2. **Reconcile documentation:** move the current Synology production facts, environment contract, storage/import rules, Tailscale-only access, NordVPN downloader boundary, and verified versus historical evidence into the new documentation structure. Mark stale or UGREEN-only information clearly; retain source/history records that remain useful.
3. **Adapt the entrypoint:** add fail-closed DSM platform routing and a narrow Synology read-only command surface. Ensure inherited setup, backup, restore, startup, and network-mutating behavior cannot be triggered accidentally on DSM. Update help and operation documentation.
4. **Adapt tests:** add a Synology test target to `.harness`, retain fast repository/conventions checks, and add bounded read-only assertions for expected live service identity, health, and access bindings. Update the runner and test-authoring references. Do not run the generic UGREEN live suites against DSM.
5. **Memory and skills:** update active context, system patterns, and progress for the converted layout; revise only skills whose instructions conflict with DSM. Keep platform-specific procedures modular and keep the next-session onboarding order explicit.
6. **Verification:** run repository-only conventions and static checks first, then bounded Synology read-only checks when safe. Review documentation links, environment claims, shell/PowerShell entrypoints, and test coverage. Compare the test plan with live evidence without applying it to the NAS.
7. **Feature review gate:** commit scoped plan and implementation changes locally on this feature branch. Stop before release lifecycle, merge, tagging, or publishing; present the changed files, runtime evidence, and test results for user review.

## Acceptance criteria

- A new agent can identify this as a Synology DSM deployment, find the current production reference and memory bank, and select the supported local/SSH workflow without inheriting unrelated UGREEN facts.
- The coding-agent harness remains the generic baseline and its agent-compatible entrypoints and skill discovery continue to work.
- Running an inherited mutating command on DSM is rejected with a clear explanation before any host mutation.
- A documented Synology command/test target performs only bounded read-only checks and does not require unrelated UGREEN services.
- Repository-only tests can run without reaching the NAS; live NAS checks are opt-in and clearly distinguished.
- No runtime deployment, service restart, data deletion, network/VPN/access change, backup policy, external push, or release tag occurs in this feature branch.
- Links and claims about configuration, environment variables, services, containers, and Synology-specific constraints are checked against repository files and current available evidence.

## Risks and open verification items

- The remote-tracking base is current, but the root checkout has local dirty work and the existing Synology branch is substantially divergent. Cherry-pick/merge is not the integration strategy; reviewed Synology-specific material must be re-applied selectively.
- Some historical Synology documents describe earlier ports, service states, monitoring status, or migration phases. Reconcile each claim with newer records/live evidence before labeling it current.
- The generic harness can contain assumptions that are safe on its reference host but unsafe on DSM. Platform detection and command gating must precede all command-specific parsing and side effects.
- Live health checks are a point-in-time observation. They do not certify disk health, backup recoverability, VPN kill-switch behavior, or access-control policy.

