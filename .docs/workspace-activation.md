# Active workspace framework

The user activated the adapted framework on November 5, 2026. The canonical framework remains in `NAS Configuration/.agents/artifacts/worktrees/synology-coding-agent-harness` beneath the HomeLab workspace. Its feature-branch location is an implementation detail, not an inactive status.

## Entry points

- `HomeLab/AGENTS.md` contains the full canonical instructions plus workspace routing and Synology precedence.
- `NAS Configuration/AGENTS.override.md` selects the same framework when a chat starts in the older Git checkout; that checkout's previous AGENTS.md is preserved.
- Both entrypoints have `.agents/skills/` discovery copies of the ten canonical skills. Edit skills only in the canonical worktree.
- Rules, persistent memory, tests, review prompts, and management scripts remain authoritative in the canonical worktree. Run framework commands from there. Deployed Compose files remain in the separate synology-stack worktree.

From the canonical worktree on Windows, refresh after changing instructions or skills:

```powershell
python -B .scripts/activate-workspace.py --workspace "\\substation\home\HomeLab"
python -B .scripts/activate-workspace.py --workspace "\\substation\home\HomeLab" --check
```

The installer preserves every overwritten file in a timestamped checkpoint under the older checkout's `.agents/artifacts/framework-activation/`, records hashes and newly created paths, and verifies written bytes. It never merges branches, deletes files, changes services or loads credentials. The first installation verified 40 files, ten skills, and no mismatches.

## Session behavior

The current chat explicitly loaded the canonical instructions, deployment reference, and memory. New Codex runs discover the installed instructions and skills from these workspace entrypoints. Existing sessions may need a new run/restart to refresh their automatically discovered instruction chain; no claim is made that files rewrite an already assembled system prompt.

[Official instruction discovery](https://learn.chatgpt.com/docs/agent-configuration/agents-md) and [skill discovery](https://learn.chatgpt.com/docs/build-skills) describe the supported locations.

## Rollback

Use the relevant checkpoint manifest to restore the previous bytes for only the recorded paths. For paths marked previously absent, remove only those exact generated files after verifying that their current hash still matches the activation manifest. Preserve unrelated skill files and user changes. Do not delete directories recursively or remove the canonical worktree: it is the active framework.

This activation does not resolve the separate FlareSolverr proxy-health issue or authorize storage, networking, VPN, service restarts, data deletion, or release tagging.
