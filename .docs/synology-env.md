# Active Synology Compose inputs

Generated from the active per-stack templates. Values below are examples; actual .env files remain private. Root automatic propagation is not used on DSM. Secrets have blank examples and must be provisioned separately.

| Stack | Variable | Template default |
| --- | --- | --- |
| jellyfin | PUID | `1026` |
| jellyfin | PGID | `100` |
| jellyfin | TZ | `America/New_York` |
| jellyfin | DOCKER_DATA_DIR | `/volume1/docker/homelab-v2` |
| jellyfin | MEDIA_DIR | `/volume1/media` |
| jellyfin | NAS_LAN_IP | `192.168.1.220` |
| jellyfin | JELLYFIN_HTTP_PORT | `8097` |
| tailscale | DOCKER_DATA_DIR | `/volume1/docker/homelab-v2` |
| tailscale | PUID | `1026` |
| tailscale | PGID | `100` |
| qbittorrentvpn | DOCKER_DATA_DIR | `/volume1/docker/homelab-v2` |
| qbittorrentvpn | DOWNLOADS_DIR | `/volume1/media/downloads-v2` |
| qbittorrentvpn | NAS_LAN_IP | `192.168.1.220` |
| qbittorrentvpn | PUID | `1026` |
| qbittorrentvpn | PGID | `100` |
| qbittorrentvpn | TZ | `America/New_York` |
| prowlarr | DOCKER_DATA_DIR | `/volume1/docker/homelab-v2` |
| prowlarr | NAS_LAN_IP | `192.168.1.220` |
| prowlarr | PUID | `1026` |
| prowlarr | PGID | `100` |
| prowlarr | TZ | `America/New_York` |
| flaresolverr | TZ | `America/New_York` |
| radarr | DOCKER_DATA_DIR | `/volume1/docker/homelab-v2` |
| radarr | RADARR_SHARED_DATA_DIR | `/volume1/media/downloads-v2` |
| radarr | NAS_LAN_IP | `192.168.1.220` |
| radarr | PUID | `1026` |
| radarr | PGID | `100` |
| radarr | TZ | `America/New_York` |
| sonarr | DOCKER_DATA_DIR | `/volume1/docker/homelab-v2` |
| sonarr | SONARR_SHARED_DATA_DIR | `/volume1/media/downloads-v2` |
| sonarr | NAS_LAN_IP | `192.168.1.220` |
| sonarr | PUID | `1026` |
| sonarr | PGID | `100` |
| sonarr | TZ | `America/New_York` |
| seerr | DOCKER_DATA_DIR | `/volume1/docker/homelab-v2` |
| seerr | NAS_LAN_IP | `192.168.1.220` |
| seerr | PUID | `1026` |
| seerr | PGID | `100` |
| seerr | TZ | `America/New_York` |
