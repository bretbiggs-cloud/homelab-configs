# Recommended movie requests — 2026-11-02

User explicitly requested adding all13 recommendations (10 main picks and3 family picks) to Seerr. Verified each intended movie by title, release year and director/provider ID. Checked availability and existing requests before submission. Created standard non-4K requests6 through18 using the existing automatic approval/default1080p configuration; no settings changed.

Edge of Tomorrow request12 initially showedFAILED after Seerr's10-second Radarr HTTP timeout, although Radarr had added the correct movie. Read the installed Seerr request route implementation and retried that same request through its native /request/12/retry endpoint. Subsequent read-back showedAPPROVED with mediaPROCESSING. No duplicate request or Radarr movie was created.

Final verification: all13 have exactly one approved standard request, exactly one monitored new Radarr movie, quality profile4 (1080p), and an isolated /downloads/library/movies root. All13 appear in Radarr's download queue; none imported at verification time. Queue presence is not a promise of download completion or a measured transfer rate. Media will appear in Jellyfin after download, import and discovery.

Private title/ID plan, submission results, final verification and diagnostic log are saved outside Git under the Windows .codex/private/homelab directory. No unrelated request, media deletion, network change, push or release.
