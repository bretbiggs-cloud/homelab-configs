# Kids Jellyfin account - 2026-11-02

Created the user-approved Popcorn Gremlins account with a password stored privately outside Git. Applied the live server PG rating score of 10 (including TV-PG and lower), blocked unrated Movies and Series, disabled administrator rights, content deletion and folder deletion grants, management features, other-user remote control, live TV, downloads, conversion and public sharing. Existing users, libraries and media were unchanged.

Verified policy by read-back, authenticated as the new account, and queried visible movies and series using that user's session. The 305 visible entries had only G, PG, TV-G, TV-PG, TV-Y or TV-Y7 ratings; no unrated or higher-rated entries were returned. Logged out the verification session. Playback remains enabled. Ratings depend on library metadata and do not imply individual parental review.

Private credentials and before/after policy snapshots are stored in the Windows private homelab directory. Rollback is disabling or deleting only this new user through the administrator user settings; no media deletion is needed. No push or release.
