# Synology HomeLab

Docker-based media services on a single Synology volume, with Tailscale-only remote access and NordVPN-protected downloads. Adapted from [ParanoydAndroid/homelab-configs](https://github.com/ParanoydAndroid/homelab-configs).

## Start here

- [Current configuration, ports, storage and constraints](.docs/synology.md)
- [Synology optimization decisions and owner steps](.docs/performance-optimization-synology.md)
- [Jellyfin Enhanced installation and integration](.docs/jellyfin-enhanced.md)
- [Agent rules and Synology overrides](.agents/rules/project-conventions.md)

The running core is Jellyfin, Tailscale, Gluetun/NordVPN, qBittorrent, Prowlarr, FlareSolverr, Radarr, Sonarr and Seerr. Homepage, Portainer and Omada are separately managed and remain untouched.

## Operations

Use the active service Compose definitions and their local environment files. Do not run the inherited UGREEN homelab.sh setup/backup/restore/test commands on DSM. They assume a different OS, network and backup system. The repository is configuration, not a backup of databases or media.

The original UGREEN descriptions are retained as explicitly historical references in the other .docs pages and [upstream README](.docs/upstream-readme.md). Earlier dated Synology records describe intermediate migration states; current production facts are consolidated in .docs/synology.md.

## Publication

Never commit .env files, credentials, private logs, raw container inspections, databases, runtime state or secret-bearing backups. Review an explicit file allowlist before release. The original author remains the upstream source; publish the same reviewed Synology release to the owner's private repository and public fork, as explicitly requested.
