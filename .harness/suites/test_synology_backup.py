#!/usr/bin/env python3
"""Local fixtures for Synology backup path and SQLite-sidecar safeguards."""

from __future__ import annotations

import importlib.util
import pathlib
import tempfile
from unittest import mock

ROOT = pathlib.Path(__file__).resolve().parents[2]
SCRIPT = ROOT / ".scripts" / "synology-backup-verify.py"
SPEC = importlib.util.spec_from_file_location("synology_backup_verify", SCRIPT)
if SPEC is None or SPEC.loader is None:
    raise SystemExit("Could not load Synology backup helper")
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


def main() -> None:
    sidecars = {
        "prowlarr.db-wal", "prowlarr.db-shm", "prowlarr.db-journal",
        "seerr.sqlite3-wal", "seerr.sqlite3-shm", "seerr.sqlite3-journal",
        "other.sqlite-wal", "other.sqlite-shm", "settings.json",
    }
    ignored = MODULE.ignore_copy("", sorted(sidecars))
    required = sidecars - {"settings.json"}
    if not required.issubset(ignored) or "settings.json" in ignored:
        raise AssertionError("SQLite sidecar exclusion fixture failed")
    if not MODULE.valid_backup_name("homelab-v2-20261105T160000Z"):
        raise AssertionError("Valid backup name was rejected")
    for invalid in ("../escape", "nested/name", "", ".", "..", "/tmp/outside"):
        if MODULE.valid_backup_name(invalid):
            raise AssertionError("Unsafe backup name was accepted")

    with tempfile.TemporaryDirectory(prefix="synology-backup-test-") as root:
        directory = pathlib.Path(root)
        source = directory / "source"
        source.mkdir()
        outside = directory / "outside-secret.txt"
        outside.write_text("unchanged")
        logs = source / "logs"
        logs.mkdir()
        link = source / "external-link"
        try:
            (logs / "seerr.log").symlink_to(outside)
            MODULE.copy_tree(source, directory / "logs-filtered")
            if (directory / "logs-filtered" / "logs").exists():
                raise AssertionError("Excluded log symlink was copied")
            link.symlink_to(outside)
            try:
                MODULE.copy_tree(source, directory / "destination")
            except RuntimeError:
                pass
            else:
                raise AssertionError("Symlink source was accepted")
        except (OSError, NotImplementedError):
            with mock.patch.object(pathlib.Path, "is_symlink", return_value=True):
                try:
                    MODULE.assert_no_symlinks(source)
                except RuntimeError:
                    pass
                else:
                    raise AssertionError("Symlink marker was accepted")
        if outside.read_text() != "unchanged":
            raise AssertionError("Symlink fixture modified its outside target")

    print("PASS: SQLite sidecars are excluded, backup names stay in-root, and symlinks are rejected")


if __name__ == "__main__":
    main()
