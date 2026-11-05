# Synology optimization decisions

Review of the user's [pinned optimization guide](https://github.com/ParanoydAndroid/homelab-configs/blob/bead48398a0c06571bc6e0d89aa06648ffd189f1/.docs/performance-optimization.md), against the live November 2, 2026 deployment.

| Guide area | Decision and verified state |
| --- | --- |
| SSD tiering | Keep the agreed single volume. No hardware purchase or volume migration. |
| Docker data-root | Keep DSM-managed /volume1/@docker; do not edit daemon.json to adopt /volume2. |
| Btrfs No-CoW | Do not apply recursively to populated databases/downloads. Existing extents do not retroactively become No-CoW, and disabling CoW also changes checksum/compression behavior. Requires a separately reviewed empty-directory migration and recoverable backup. |
| Dirty ratios | Current background/foreground values are 10/20. Guide proposes 5/10. Root authentication and a controlled comparison are needed; not applied through a privileged-container workaround. See manual steps below. |
| tmpfs transcoding | Do not allocate the guide's 4 GiB on a 4 GiB NAS with roughly 1 GiB available. Keep disk scratch space, throttling enabled and old-segment deletion enabled. |
| Cloudflare bypass | Not applicable; no Cloudflare media ingress. |
| Read-only media | Already enforced for Jellyfin; Seerr has no media mount. |
| Local wildcard CA | Not applicable to the existing IP/MagicDNS design. No CA or trust-store changes. Tailnet transport is encrypted; LAN HTTP is not TLS. |
| Split DNS | Not applicable without the upstream Pi-hole/subnet-router topology. Existing MagicDNS stays unchanged. |
| VPN exit node | Not deployed; user wants private app access and NordVPN downloader egress. |
| Hardlinks | Enabled in Radarr and Sonarr; shared /downloads mount keeps payload and new library on the same filesystem. |
| Homepage | Leave the existing separately managed instance unchanged. |
| Logs | All nine new containers use json-file, max-size 10m, max-file 3. This bounds Docker-managed log rotation approximately; application logs are separate. |
| Backups | User selected private NAS-local config/database checkpoints plus GitHub for sanitized code/config. NAS backup remains on the same volume and is not off-device disaster recovery. No pruning or new retention period is authorized. |
| UGOS Go workaround | Not applicable to DSM; no speculative GODEBUG changes. |
| Tests | Use Synology production checks and explicit upstream skips, not the UGREEN test runner. |

## Optional dirty-write tuning: requires DSM administrator input

1. Wait for a quiet maintenance period and record `sysctl vm.dirty_background_ratio vm.dirty_ratio` plus current playback/download behavior.
2. In an SSH session, run `sudo sysctl -w vm.dirty_background_ratio=5 vm.dirty_ratio=10`. Enter the DSM administrator password locally; do not put it in a script or chat.
3. Compare playback, disk latency and download throughput. Lower thresholds are not a guaranteed improvement, especially on this small-memory machine.
4. To undo this trial, run `sudo sysctl -w vm.dirty_background_ratio=10 vm.dirty_ratio=20`. A reboot normally discards an unpersisted trial.
5. Only after a successful trial, persist the two explicit sysctl commands with a DSM Task Scheduler boot-up task running as root. Avoid `sysctl --system`, which may reload unrelated DSM settings. Verify the values after a reboot and firmware update.

## Current backup scope and limitation

The current authorized scope is same-volume NAS config/database checkpoints plus sanitized repository content in the user's GitHub fork. The Synology backup helper uses online SQLite backups and verifies the copied data in an isolated temporary directory. It does not protect media or app data from failure of volume1. Do not configure automatic pruning or imply that GitHub stores runtime databases, credentials, or media. A separate off-device destination and retention policy can be selected later if the user wants NAS-level disaster recovery.

## Client steps

After the Enhanced restart, hard-refresh the browser (Ctrl+F5), then open Jellyfin Enhanced from the profile menu. Native TV apps may bundle their own web client and may not display server-injected interface changes. Verify the actual TV client rather than promising support based on the television brand. Keep Tailscale connected on remote phones; home TVs use the LAN server address.
