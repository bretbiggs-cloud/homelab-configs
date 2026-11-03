# Docker outage and old-stack recovery - 2026-11-01

User denied intentional stop and authorized restoring old stack and investigation. All times America/New_York.

## Confirmed cause and timeline

Daemon service log /var/log/systemd/pkg-ContainerManager-dockerd.service.log records at23:29:38: panic: runtime error: invalid memory address or nil pointer dereference, SIGSEGV. Stack: github.com/docker/docker/daemon.(*Daemon).ProcessEvent.func1(), daemon/monitor.go:190, created by ProcessEvent at monitor.go:189.

System service log records dockerd exited status2 at23:29:45; DSM scheduled restart at23:29:47 and marked engine started at23:31:38. Container exits occurred roughly23:30:25-23:30:52 during recovery. Engine recovery records hasBeenManuallyStopped=true and restart canceled, explaining why unless-stopped containers stayed down. This flag is not proof of user action. No assistant stop commands were issued during indexer setup or recovery diagnosis.

Preceding logs show event deadlines, inactive RPC streams and health-check timeouts. Observed load reached58 dominated by IO wait; user reported Jellyfin movie activity. Exact trigger of daemon nil-pointer bug is unproven. Do not blame indexer access, upload, a particular disk or memory exhaustion without further evidence. Container OOMKilled flags were false. Historical kernel OOM logs predate incident. RAID reported all members present and no rebuild; this is not a comprehensive drive-health diagnosis. ContainerManager package upgrade completed at12:24 earlier that day, not at incident time.

## Recovery

Started existing old containers only: qbittorrent, omada-controller, homepage, prowlarr, sonarr, radarr, seerr. Portainer had already resumed. Preserved container definitions, volumes and files. No redeployment, image updates, deletion or daemon-setting changes. All eight running; Homepage and Omada report healthy. HTTP checks succeeded for qBittorrent8080, Prowlarr9696, Sonarr8989, Radarr7878, Homepage3000, Portainer9000; Seerr5055 responds307. Old downloader tun0 is present and its log reports qBittorrent daemon startup. Full download/import/playback not tested.

All homelab-v2 containers remain stopped, including previously accepted Jellyfin and Tailscale, to avoid immediately restoring concurrent load. Therefore new Jellyfin playback and Tailscale access are currently unavailable. Old Jellyfin was previously deleted by user authorization; it was not recreated. Resume those accepted services deliberately after capacity/stability review.

Before future preservation tests, compare to recovery baseline captured beside this record. Old start-time assertions deliberately referencing pre-incident times will fail; do not claim old uninterrupted uptime. Keep prior baseline for historical evidence.

Raw daemon log saved privately on management PC at .codex/private/homelab/docker-incident-service.log. No raw logs or secrets published. Diagnostics used ephemeral read-only, network-disabled log-reader containers with bounded DAC read capability; these exit and auto-remove. Their exit notifications may appear in DSM.

## Remaining work

Indexer rollout remains incomplete: LinuxTracker, LimeTorrents and The Pirate Bay passed and saved; EZTV interrupted,1337x not tested. No source or proxy retests while new stack remains stopped. Investigate vendor-supported daemon fixes and workload capacity before further expansion; no upgrade or restart-policy changes authorized/performed in this recovery.

At23:50 America/New_York, user requested Jellyfin access and overnight processing. Preflight load0.14 and available RAM~1.28GiB. Started only accepted homelab-v2-jellyfin and homelab-v2-tailscale; LAN web200, health Healthy and Tailscale backend health verified. Authenticated API showed prior RefreshLibrary Cancelled and current Idle; restarted that task and confirmed Running. Old eight containers still running. Experimental VPN/downloader/Prowlarr/FlareSolverr remain stopped. This supersedes the earlier statement that Jellyfin/Tailscale are unavailable. No overnight monitoring or guaranteed scan completion claimed.
