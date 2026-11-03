# Synology Prowlarr phase

Scope: user authorized new Prowlarr alongside the old stack. Continue feature/synology-stack because it owns deployed definitions; do not reset to upstream or move the worktree. Local commits only.

Design: homelab-v2-prowlarr, Compose project homelab-v2-prowlarr, LinuxServer stable image pinned by digest. Shared new bridge homelab-v2-jellyfin_homelab, internal port9696, LAN192.168.1.220:9697, private Tailscale TCP9697. Ordinary outbound networking, independent of downloader VPN; downloads remain constrained by their VPN. No public ingress, host networking, media mounts or Docker socket.

Persistence: /volume1/docker/homelab-v2/prowlarr/data:/config. LSIO startup privilege dropping with verified PUID1026/PGID100, TZ America/New_York, no-new-privileges and bounded logs. Authentication required for all addresses; generate a fresh admin credential and save in management PC private directory outside Git. Do not reuse old writable state.

Review: preserve all old services and their start times. User explicitly selected an empty indexer list. Do not connect old Sonarr/Radarr. New managers and FlareSolverr will be separate phases. No automatic jobs or download-client integration needed to establish Prowlarr. Existing LAN validation/Tailscale access convention retained; no extra proxy or VPN added.

Preflight: no RAID rebuild, ~1GiB available RAM and3.4TiB disk free. New data path unused and TCP9697 absent from current listeners. Recheck resource footprint after startup.

Implementation: resolve stable image, commit reviewed plan, create compose.yml and .env.example plus private .env, deploy only named new service. Configure authentication before adding Tailscale forwarding. Retain previous Serve configuration via Git and an excluded rollback copy.

Verification: Compose syntax; isolated state and correct mount; process identity; application readiness; authenticated API success and unauthenticated API denial; login success; persistent configuration after new-only restart; Tailscale Serve target and backend reachability; no changes to old container IDs/start times. Targeted Synology tests replace incompatible upstream all-suite. Indexer search/integration tests remain pending until sources and new managers are configured.

Rollback: remove only new forwarding entry and stop new Prowlarr, keeping its state. No old-stack stop, deletion or migration. Backup system remains deferred; retained old state is not a backup. No push, tags or main-branch merge in this incremental phase.

Sources: https://docs.linuxserver.io/images/docker-prowlarr/ and https://prowlarr.com/docs/api/ .
