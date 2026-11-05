"""Create a bounded, online Jellyfin configuration recovery checkpoint on DSM.

Usage: python3 backup_jellyfin_config.py CONFIG_ROOT NEW_DESTINATION
Copies settings and plugin files, and uses SQLite's online backup API for each
database under data/. Artwork/cache/logs/media are excluded. Verifies each copied
database with quick_check. Destination must not exist; no pruning or restoration.
This same-volume checkpoint does not protect against NAS or volume failure.
"""
import json, pathlib, shutil, sqlite3, sys
source, dest = map(pathlib.Path, sys.argv[1:])
if not (source/'data/jellyfin.db').is_file():
    raise SystemExit('Expected Jellyfin database is missing')
dest.mkdir(mode=0o700, parents=True, exist_ok=False)
for folder in ('config','plugins','root'):
    if (source/folder).exists():
        shutil.copytree(source/folder, dest/folder)
(dest/'data').mkdir()
checks = []
for db in (source/'data').rglob('*.db'):
    target = dest / db.relative_to(source)
    target.parent.mkdir(parents=True, exist_ok=True)
    with sqlite3.connect(str(db), timeout=30) as live, sqlite3.connect(str(target)) as saved:
        live.backup(saved, pages=256, sleep=0.05)
        result = saved.execute('PRAGMA quick_check').fetchall()
    if result != [('ok',)]: raise RuntimeError('Backup integrity check failed')
    checks.append({'database':str(db.relative_to(source)),'quick_check':'ok'})
(dest/'verification.json').write_text(json.dumps(checks,indent=2))
print(json.dumps({'databases':checks,'destination':str(dest)}))
