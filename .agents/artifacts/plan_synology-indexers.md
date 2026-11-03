# New Prowlarr indexers

User authorized adding/testing previously discussed1337x, EZTV, LimeTorrents, LinuxTracker and The Pirate Bay, using existing FlareSolverr where necessary and preserving the old stack. No Nyaa (optional anime) or private account-based tracker selected.

Use current installed Prowlarr schema, primary definition-provided URL, Standard profile and default priority25. Run sequential native indexer tests. Direct first; if Cloudflare-related failure, tag only that candidate flaresolverr and retry using existing120-second solver budget. Bounded diagnostic retries are part of this authorized setup. Save only candidates passing native validation; no forced saves or success claims for failures. Existing empty list confirmed. No downloads, managers, old-stack changes or indexer credentials copied.

LinuxTracker is for Linux distribution content, not movie/TV coverage. Keep it as explicitly selected test/source. No blanket FlareSolverr tag. Indexer validation fetches listings, not payload downloads.

Validate saved configuration, native tests, no download clients/apps and preserved old IDs/start times. Update the prior empty-indexer assertion only for the approved source additions; retain no-production-automation checks. Report unresolved source failures explicitly and do not commit completion while unresolved failures remain. Rollback deletes only newly added indexers. Local plan/config/test records only; no publication.
