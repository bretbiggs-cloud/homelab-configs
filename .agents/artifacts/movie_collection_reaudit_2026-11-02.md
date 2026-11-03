# Refreshed movie collection audit - 2026-11-02

Performed a read-only refresh of Jellyfin movie identities, Seerr collection membership and requests, and Radarr inventory. All 217 recognized collection lookups succeeded. Classified 414 collection entries as in Jellyfin, 25 as requested, 49 as upcoming or undated, and 242 as candidate missing titles. A further apparent gap was flagged as likely present with incorrect metadata after inspecting its filename. These counts describe collection entries, not the entire movie library.

Cross-checked candidate titles against indexed filenames and differentiated sequels, remakes and dates. Provider-ID or filename checks cannot establish absence from unidentified or unindexed files. Catalog release dates do not verify digital release availability; collection definitions include some spin-offs and shorts.

Saved the complete grouped private report, CSV and JSON outside Git in the Windows private homelab directory. No additional requests, metadata changes or media operations were performed. No configuration change, rollback, push or release applies.
