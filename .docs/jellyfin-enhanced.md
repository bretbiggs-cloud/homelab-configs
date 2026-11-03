# Jellyfin Enhanced

Requested plugin: [Jellyfin Enhanced](https://github.com/n00bcodr/Jellyfin-Enhanced). The official repository manifest is https://raw.githubusercontent.com/n00bcodr/jellyfin-plugins/main/manifest.json .

Installed version: 12.14.0.0, build target 12.0.0.0, on Jellyfin 12.4.0. Restarted only Jellyfin after two idle observations and a final playback check. The plugin is active and its authenticated Seerr search passes.

Verified integration: server-side Seerr URL http://homelab-v2-seerr:5055, with the existing key kept only in private plugin configuration. Browser links use the tailnet URL. Biggs already has a linked Seerr account. Do not auto-import Popcorn Gremlins or grant it request rights. Preserve rating restrictions, disable 4K requests, automatic next-movie/season requests and telemetry. No additional TMDb/MDBList key is assumed.

Verified Active plugin status, authenticated Seerr search, API-key absence in public client configuration, server web-page script injection, and unchanged kids policy. An authenticated kids request to Enhanced Seerr search returns 403; no child account was imported into Seerr. Native TV rendering and personal layout remain client checks.

Rollback: disable/uninstall this exact plugin and restart Jellyfin after playback ends. Preserve the private settings checkpoint and remove only the added plugin repository if desired. Never restore the database over a running server. The SQLite checkpoint under /volume1/docker/homelab-v2/.backups/enhanced-20261102 is a configuration recovery point, not a full media backup.
