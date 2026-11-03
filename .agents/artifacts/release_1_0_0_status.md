# Synology 1.0.0 release verification

November 2, 2026. Owner authorized publication to both bretbiggs-cloud/synology-homelab (private) and bretbiggs-cloud/homelab-configs (public).

- Restarted only Jellyfin after playback finished. Enhanced 12.14.0.0 is active on Jellyfin 12.4.0; Seerr search and injected web assets passed verification.
- Full production release suite passed, including denied Seerr access for the kids account, permitted browse ratings and no Seerr key in public configuration.
- Cutover and retained Sintel media checks passed; unrelated container identities/start times remained unchanged. All nine image digests and eight active Compose definitions were checked.
- Live DS923+ hardware, DSM 7.2.1-69057 update 13, approximately 4 GiB RAM, Btrfs and no GPU device are documented in the current Synology guides.
- Enabled transcode-segment deletion; verified existing hardlinks, read-only media, throttling and log rotation. No speculative host/storage changes applied.
- Private same-volume Jellyfin checkpoint uses SQLite online backup and passed quick_check. This is limited rollback material, not disaster recovery.
- Local Markdown paths/anchors and 29 public links passed auditing. Historical UGREEN/phase records are labeled appropriately. Known credential and token-pattern scan of reviewed source found no issues.
- Publication preserves public-fork history, with Synology 1.0.0 and calendar tag 2026.11.2.1. Runtime secrets, databases and private reports are excluded.

## Limitations and manual follow-up

Hard-refresh browser clients. Native TV rendering requires client verification. Optional challenge-protected indexers remain unreliable. Independent backup destination, retention and restore testing remain owner decisions. Host dirty-write tuning needs an administrator trial; see the optimization guide for steps. The incompatible UGREEN suite, deliberate VPN outage and full disaster-recovery restore were not run on production.
