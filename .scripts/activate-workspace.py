#!/usr/bin/env python3
"""Install the reviewed framework's instructions and skills at workspace entrypoints.

Usage: python -B .scripts/activate-workspace.py --workspace PATH [--check]
Run from the existing synology-coding-agent-harness worktree. Preserves each
changed destination in a timestamped private activation checkpoint. Does not
merge branches, delete files, change services, or touch credentials.
"""
import argparse
import datetime
import hashlib
import json
from pathlib import Path


def digest(data):
    return hashlib.sha256(data).hexdigest()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--workspace', type=Path, required=True)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    workspace = args.workspace.resolve()
    source = Path(__file__).resolve().parent.parent
    legacy = workspace / 'NAS Configuration'
    expected = legacy / '.agents/artifacts/worktrees/synology-coding-agent-harness'
    if source != expected.resolve():
        raise SystemExit('Workspace does not contain this framework at the expected path')
    routing = f'''# Active HomeLab framework

The user activated this framework on November 5, 2026.
Canonical framework directory: `{source}`.
Use that directory as the working directory for framework commands and edits.
All repository-relative paths in the canonical instructions below resolve there.
Read its `.docs/synology.md`, `.agents/memory/activeContext.md`, and
`.agents/memory/systemPatterns.md` at session start. Update that same memory bank.
Consult `.agents/rules/` for the file types being edited, and the relevant skill
under `.agents/skills/` before applying a runbook. Skills installed at workspace
entrypoints are generated discovery copies; edit only the canonical sources.
Re-run `.scripts/activate-workspace.py --workspace "{workspace}"` after updates.

The full canonical instructions follow; the activation-specific rules at the end
take precedence over inherited reference-host examples.

'''
    override = f'''

## Active workspace routing and precedence

- This framework is active now; feature-branch location does not mean inactive.
- The older checkout at `{legacy}` contains user changes and the deployed
  reporting scripts. Do not reset, merge over, or clean it as an activation step.
- The separate `synology-stack` worktree owns deployed Compose files. Framework
  activation does not authorize moving those files or restarting containers.
- The Synology deployment reference and current verified user decisions override
  inherited UGREEN, Caddy/download.kamaka.tech, PIA, UID1000, NVMe, Restic pruning,
  unrestricted torrent queues, and generic full-suite examples in any runbook.
- Historical upstream test totals and releases are not current NAS validation.
- Framework scripts, rules, tests, memory and on-demand review prompts are available
  from the canonical directory above. Follow higher-priority tool rules on delegation;
  prompt files do not independently authorize spawning agents or messaging chats.
- Use only the adapted DSM commands. The existing live monitoring schedule remains
  reporting-only. Preserve secrets, backups, Homepage and existing service state.
- The user has approved this activation. No further approval is needed to use this
  framework; later unrelated releases, disruptive operations and publication still
  follow the applicable user instructions and project boundaries.
'''
    instructions = (routing + (source / 'AGENTS.md').read_text(encoding='utf-8') + override).encode()
    if len(instructions) > 30000:
        raise SystemExit('Generated instructions exceed conservative discovery budget')
    desired = {workspace / 'AGENTS.md': instructions,
               legacy / 'AGENTS.override.md': instructions}
    skills = source / '.agents/skills'
    for path in sorted(skills.rglob('*')):
        if path.is_symlink():
            raise SystemExit('Canonical skills must be regular files')
        if path.is_file():
            for root in (workspace, legacy):
                desired[root / '.agents/skills' / path.relative_to(skills)] = path.read_bytes()
    changes = []
    for target, data in desired.items():
        if not target.resolve().is_relative_to(workspace):
            raise SystemExit('Destination escapes workspace')
        if target.is_symlink():
            raise SystemExit('Refusing to replace a linked destination')
        if not target.exists() or target.read_bytes() != data:
            changes.append(target)
    if args.check:
        print(json.dumps({'verified_files': len(desired), 'mismatches': len(changes),
                          'skills': len(list(skills.glob('*/SKILL.md'))),
                          'instruction_bytes': len(instructions)}))
        return int(bool(changes))
    if not changes:
        print('Activation already matches canonical framework')
        return 0
    stamp = datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
    checkpoint = legacy / '.agents/artifacts/framework-activation' / stamp
    checkpoint.mkdir(parents=True, exist_ok=False)
    manifest = []
    for target in changes:
        previous = target.read_bytes() if target.exists() else None
        relative = target.relative_to(workspace)
        if previous is not None:
            backup = checkpoint / 'before' / relative
            backup.parent.mkdir(parents=True, exist_ok=True)
            backup.write_bytes(previous)
        manifest.append({'path': str(relative), 'existed': previous is not None,
                         'before_sha256': digest(previous) if previous is not None else None,
                         'after_sha256': digest(desired[target])})
    (checkpoint / 'manifest.json').write_text(json.dumps(manifest, indent=2), encoding='utf-8')
    for target in changes:
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(desired[target])
        if target.read_bytes() != desired[target]:
            raise SystemExit('Activation verification failed')
    print(json.dumps({'installed_files': len(changes), 'checkpoint': str(checkpoint)}))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
