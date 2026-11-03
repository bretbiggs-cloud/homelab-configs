# Collection shortlist requests, second batch - 2026-11-02

User requested the missing movies after the 12-collection table. Added the 27 named movies from that table, rather than interpreting this as a request for every candidate in the 242-title report. Checked live Seerr movie availability and active requests before submission. Created standard requests 43 through 69 using the existing automatic approval and 1080p defaults.

Seven requests became failed after submission; retried those same requests through the native retry endpoint. Final read-back verified all 27 have one approved standard request, one monitored Radarr movie, and quality profile 4. None had imported files at verification time. Existing requests and configuration were unchanged.

Private title/ID plan, submission records and verification are outside Git in the Windows private homelab directory. Requests can be canceled individually if necessary; no automated rollback, media deletion, push or release was performed.
