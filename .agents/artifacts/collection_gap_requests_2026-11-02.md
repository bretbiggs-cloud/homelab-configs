# Collection gap requests - 2026-11-02

User authorized requesting the missing movies in the preceding 15-collection shortlist. Submitted 21 standard movie requests (20 through 40), checking current availability and existing requests first. Preserved the existing automatic approval and 1080p defaults. All 21 have exactly one request and one monitored Radarr movie with profile 4.

Some Seerr requests failed while Radarr still accepted the movies. Retried only the same failed requests through the native retry endpoint. Final read-back confirmed all 21 approved. Radarr searches are processing or queued; no completed downloads were verified. Existing requests were left unchanged.

Private title/ID plan, submission results, and verification are stored outside Git in the Windows private homelab directory. No configuration, media deletion, networking, or deployment changes. Requests can be canceled individually if needed; no automated rollback or deletion was performed.
