#!/usr/bin/env python3
"""Create and verify a private, application-consistent DSM config backup.

Usage:
  python3 .scripts/synology-backup-verify.py [--config-root PATH]
      [--backup-root PATH] [--name NAME]

The default backup location is the existing same-volume private checkpoint
directory under /volume1/docker/homelab-v2/.backups. The script captures the
active media stack's configuration trees, SQLite databases through SQLite's
online backup API, Compose project files, and any present per-stack .env files.
It excludes media, caches, logs, and SQLite sidecar files. It then copies the
backup into a temporary isolated directory and verifies file hashes and SQLite
integrity there. It does not stop services, prune older backups, or modify live
application data. The NAS backup is not protection from failure of volume1.
"""

from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import os
import pathlib
import re
import shutil
import sqlite3
import stat
import subprocess
import tempfile


CONTAINERS = (
    "homelab-v2-jellyfin", "homelab-v2-tailscale", "homelab-v2-vpn",
    "homelab-v2-qbittorrent", "homelab-v2-prowlarr",
    "homelab-v2-radarr", "homelab-v2-sonarr", "homelab-v2-seerr",
)
CONFIG_DIRS = (
    "jellyfin/data/config", "tailscale/data", "gluetun/data", "gluetun/auth",
    "gluetun/secrets", "qbittorrent/data/config", "prowlarr/data",
    "radarr/data", "sonarr/data", "seerr/data",
)
DATABASE_SUFFIXES = (".db", ".sqlite", ".sqlite3")
EXCLUDED_DIRS = {"cache", "caches", "logs", "log", "transcodes", "metadata"}
EXCLUDED_FILES = {"logs.db"}


def digest(path: pathlib.Path) -> str:
    """Return a streaming SHA-256 digest for a regular file."""
    hasher = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            hasher.update(block)
    return hasher.hexdigest()


def sqlite_backup(source: pathlib.Path, destination: pathlib.Path) -> None:
    """Take an online SQLite snapshot and verify the resulting database."""
    destination.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    source_uri = source.resolve().as_uri() + "?mode=ro"
    with sqlite3.connect(source_uri, uri=True, timeout=30) as live:
        with sqlite3.connect(str(destination), timeout=30) as saved:
            live.backup(saved, pages=256, sleep=0.05)
            result = saved.execute("PRAGMA quick_check").fetchall()
    if result != [("ok",)]:
        raise RuntimeError(f"SQLite integrity check failed for {source.name}")
    destination.chmod(0o600)


def ignore_copy(_directory: str, names: list[str]) -> set[str]:
    """Exclude generated caches/logs and SQLite files copied separately online."""
    ignored = set()
    for name in names:
        entry = pathlib.Path(_directory) / name
        lower = name.lower()
        if lower in EXCLUDED_DIRS or lower in {x.lower() for x in EXCLUDED_FILES}:
            ignored.add(name)
        elif lower.endswith(".log") or any(
            lower.endswith(suffix + sidecar)
            for suffix in DATABASE_SUFFIXES
            for sidecar in ("", "-wal", "-shm", "-journal")
        ):
            ignored.add(name)
        else:
            try:
                mode = entry.lstat().st_mode
            except FileNotFoundError:
                mode = None  # Unit fixtures may pass names without creating files.
            if mode is not None and not stat.S_ISDIR(mode) and not stat.S_ISREG(mode):
                # Runtime sockets and device nodes are not recoverable config
                # and must never be passed to shutil.copy2 as ordinary files.
                ignored.add(name)
    return ignored


def is_ignored_file(name: str) -> bool:
    """Return whether a file is excluded from the backed-up config payload."""
    lower = name.lower()
    return lower in {x.lower() for x in EXCLUDED_FILES} or lower.endswith(".log") or any(
        lower.endswith(suffix + sidecar)
        for suffix in DATABASE_SUFFIXES
        for sidecar in ("-wal", "-shm", "-journal")
    )


def assert_no_symlinks(path: pathlib.Path) -> None:
    """Reject symlinks so copy, hashing, and permission changes cannot follow live paths."""
    if path.is_symlink():
        raise RuntimeError("Symlink source is not allowed in a private backup")
    if path.is_dir():
        for root, directories, files in os.walk(path, followlinks=False):
            for name in directories:
                entry = pathlib.Path(root) / name
                if name.lower() in EXCLUDED_DIRS:
                    continue
                if entry.is_symlink():
                    raise RuntimeError("Symlink entry is not allowed in a private backup")
            directories[:] = [name for name in directories if name.lower() not in EXCLUDED_DIRS]
            for name in files:
                if is_ignored_file(name):
                    continue
                if (pathlib.Path(root) / name).is_symlink():
                    raise RuntimeError("Symlink entry is not allowed in a private backup")


def valid_backup_name(name: str) -> bool:
    """Allow only a simple path component for the backup directory name."""
    return bool(re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._-]{0,79}", name))


def copy_tree(source: pathlib.Path, destination: pathlib.Path) -> None:
    """Copy a configuration directory while excluding volatile and DB files."""
    assert_no_symlinks(source)
    if source.is_dir():
        shutil.copytree(source, destination, symlinks=False, ignore=ignore_copy)
    elif source.is_file():
        destination.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
        shutil.copy2(source, destination)
    else:
        raise FileNotFoundError(f"Required configuration path is missing: {source}")


def compose_paths() -> list[pathlib.Path]:
    """Find active Compose directories and files from Docker's container labels."""
    result: set[pathlib.Path] = set()
    for container in CONTAINERS:
        raw = subprocess.check_output(
            ["/usr/local/bin/docker", "inspect", "--format",
             '{{index .Config.Labels "com.docker.compose.project.working_dir"}}|'
             '{{index .Config.Labels "com.docker.compose.project.config_files"}}', container],
            text=True,
        ).strip()
        working, files = raw.split("|", 1)
        if working:
            directory = pathlib.Path(working)
            for filename in (".env",):
                candidate = directory / filename
                if candidate.is_file():
                    result.add(candidate)
        for filename in files.split(","):
            candidate = pathlib.Path(filename.strip())
            if candidate.is_file():
                result.add(candidate)
    return sorted(result)


def tailscale_config_path() -> pathlib.Path:
    """Resolve the live Tailscale Serve config bind source from Docker metadata."""
    raw = subprocess.check_output(
        ["/usr/local/bin/docker", "inspect", "--format", "{{json .Mounts}}",
         "homelab-v2-tailscale"], text=True,
    )
    mounts = json.loads(raw)
    for mount in mounts:
        if mount.get("Destination") == "/config" and mount.get("Type") == "bind":
            return pathlib.Path(mount["Source"])
    raise RuntimeError("Tailscale /config bind mount could not be resolved")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config-root", default="/volume1/docker/homelab-v2")
    parser.add_argument("--backup-root", default="/volume1/docker/homelab-v2/.backups")
    parser.add_argument("--name", default=dt.datetime.now(dt.timezone.utc).strftime("homelab-v2-%Y%m%dT%H%M%SZ"))
    parser.add_argument("--dry-run", action="store_true", help="validate sources and destination without writing")
    args = parser.parse_args()

    if not valid_backup_name(args.name):
        raise SystemExit("Backup name must be one safe path component using letters, digits, dot, underscore, or hyphen.")

    config_root = pathlib.Path(args.config_root)
    backup_root = pathlib.Path(args.backup_root)
    if not config_root.is_dir() or not backup_root.is_dir():
        raise SystemExit("Configuration root or pre-existing private backup root is missing.")
    if config_root.is_symlink() or backup_root.is_symlink():
        raise SystemExit("Configuration and backup roots must not be symbolic links.")
    if stat.S_IMODE(backup_root.stat().st_mode) & 0o077:
        raise SystemExit("Backup root permissions must exclude group and other access (mode 0700).")
    destination = backup_root / args.name
    if destination.exists():
        raise SystemExit("Backup destination already exists; choose a unique --name.")

    required_sources = [config_root / relative for relative in CONFIG_DIRS]
    missing = [path for path in required_sources if not path.exists()]
    if missing:
        raise SystemExit(f"Required application configuration source is missing ({len(missing)} path(s)).")
    projects = compose_paths()
    ts_config = tailscale_config_path()
    if not ts_config.is_dir():
        raise SystemExit("Tailscale /config source is missing or is not a directory.")
    for source in required_sources + projects + [ts_config]:
        assert_no_symlinks(source)
    databases = []
    for root in required_sources:
        for path in root.rglob("*"):
            if path.is_file() and path.suffix.lower() in DATABASE_SUFFIXES and path.name not in EXCLUDED_FILES:
                if not any(part.lower() in EXCLUDED_DIRS for part in path.relative_to(root).parts):
                    databases.append(path)
    if args.dry_run:
        print(json.dumps({
            "result": "READY",
            "required_config_directories": len(required_sources),
            "compose_and_env_files": len(projects),
            "sqlite_databases": len(set(databases)),
            "tailscale_config_resolved": True,
            "backup_root_private": True,
            "destination_available": True,
        }))
        return 0

    destination.mkdir(mode=0o700)
    payload = destination / "payload"
    payload.mkdir(mode=0o700)
    db_sources: list[pathlib.Path] = []
    copied_files: list[pathlib.Path] = []

    try:
        for relative, source in zip(CONFIG_DIRS, required_sources):
            target = payload / "application" / relative
            copy_tree(source, target)
        db_sources.extend(databases)
        copy_tree(ts_config, payload / "deployment" / "tailscale-config")
        for source in projects:
            safe_name = source.parent.name + "/" + source.name
            target = payload / "deployment" / safe_name
            copy_tree(source, target)

        database_records = []
        for source in sorted(set(db_sources)):
            relative = source.relative_to(config_root)
            target = payload / "application" / relative
            sqlite_backup(source, target)
            database_records.append({"path": str(relative), "quick_check": "ok"})

        for path in payload.rglob("*"):
            if path.is_file():
                path.chmod(0o600)
                copied_files.append(path)
            elif path.is_dir() and not path.is_symlink():
                path.chmod(0o700)
        manifest = {
            "created_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
            "source_root": str(config_root),
            "database_checks": database_records,
            "file_count": len(copied_files),
            "files": [
                {"path": str(path.relative_to(payload)), "size": path.stat().st_size,
                 "sha256": digest(path)}
                for path in sorted(copied_files)
            ],
        }
        (destination / "verification.json").write_text(json.dumps(manifest, indent=2) + "\n")
        (destination / "verification.json").chmod(0o600)

        restored_databases = 0
        with tempfile.TemporaryDirectory(prefix="synology-restore-check-", dir=backup_root) as temp:
            restored = pathlib.Path(temp) / "payload"
            shutil.copytree(payload, restored, symlinks=True)
            for item in manifest["files"]:
                path = restored / item["path"]
                if not path.is_file() or path.stat().st_size != item["size"] or digest(path) != item["sha256"]:
                    raise RuntimeError("Isolated restore file verification failed")
            for record in database_records:
                path = restored / "application" / record["path"]
                with sqlite3.connect(f"file:{path}?mode=ro", uri=True) as restored_db:
                    if restored_db.execute("PRAGMA quick_check").fetchall() != [("ok",)]:
                        raise RuntimeError("Isolated restore SQLite verification failed")
                restored_databases += 1

        result = {
            "result": "PASS",
            "destination": str(destination),
            "files": len(copied_files),
            "sqlite_databases": len(database_records),
            "isolated_restore_databases_verified": restored_databases,
            "automatic_pruning": False,
        }
        (destination / "restore-verification.json").write_text(json.dumps(result, indent=2) + "\n")
        (destination / "restore-verification.json").chmod(0o600)
        print(json.dumps(result))
        return 0
    except Exception as error:
        (destination / "FAILED.txt").write_text(f"Backup/verification failed: {type(error).__name__}\n")
        (destination / "FAILED.txt").chmod(0o600)
        raise


if __name__ == "__main__":
    raise SystemExit(main())
