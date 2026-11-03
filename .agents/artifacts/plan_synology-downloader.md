# Synology NordVPN and qBittorrent replacement plan

Status: design review draft; no new downloader deployed.
Date:2026-11-01 America/New_York. Existing branch feature/synology-stack.

## Scope and evidence

User approved starting the next replacement phase. Keep old qbittorrent and existing automation running until replacement tests and explicit cutover. Fresh inspection confirms old dyonr/qbittorrentvpn, config /volume1/docker/qbittorrent/config, media /volume1/media mapped /downloads, WebUI8080, bridge qbittorrent_default. VPN_USERNAME and VPN_PASSWORD fields populated; contents not displayed or written to this plan. OpenVPN profile us13454.nordvpn.com.udp_2.6.ovpn present. Public-IP route uses tun0; leak protection is not established. TUN device available. Available RAM1036MiB, swap1330/4383MiB after old Jellyfin removal; monitor with new workloads.

## Proposed design

Retain upstream separation of VPN and downloader but replace PIA-specific implementation with qmcgaw/gluetun using its built-in NordVPN OpenVPN integration. qBittorrent uses lscr.io/linuxserver/qbittorrent with network_mode service:vpn and starts after VPN health. Select supported immutable image digests before deployment. Gluetun handles firewall/DNS and tunnel recovery; no custom firewall scripts as a substitute for native behavior. Set qBittorrent interface binding to tun0 as a second constraint; verify actual runtime settings.

Names: homelab-v2-vpn and homelab-v2-qbittorrent. Preserve old names/state/ports. VPN joins the new service bridge; downloader shares that namespace only. NET_ADMIN and /dev/net/tun belong only to VPN. No privileged mode, host networking, Docker socket, PIA port-forwarding callbacks or NordVPN-provider change. Restrict UI ingress to required WebUI port. No broad LAN or Tailscale outbound bypass rules; inspect actual interface subnet and return routing requirements first.

US NordVPN server selection proposed to retain current region. Reuse existing service credentials securely if authentication succeeds; user login password is not a substitute. Protect untracked secret storage under the new runtime root; blank placeholders only in .env.example. Prefer image-supported secret-file options after checking current documentation. Never copy old application databases, resume state or all old configuration wholesale.

Fresh configuration under /volume1/docker/homelab-v2/qbittorrent/data/config and VPN state under /volume1/docker/homelab-v2/gluetun/data. Single-volume download staging proposed /volume1/media/downloads-v2 with incomplete, complete/movies and complete/tv directories, subject to absence/permissions checks. During isolated testing mount only this staging subtree writable at /downloads; no production library write access. Later new managers can mount the shared parent to support efficient same-filesystem imports; do not mix mount schemas blindly. Old jobs and automation are not repointed in this phase.

UI uses an inventoried unused LAN-only validation port (candidate8082, not verified free yet), plus optional new Tailscale-only forward after authentication is set. No public port forwarding. Generate a fresh strong UI password and retain it privately outside Git; do not log temporary image passwords. Use PUID1026/PGID100 via LSIO environment, not forced Compose user. Bound logging. No real torrents copied/started before protections pass.

## Implementation and acceptance

1. Settle review questions, commit approved plan locally. Read pinned provider/firewall/secrets/health guidance; resolve image versions, ports, paths and namespace-recreation behavior.
2. Prepare Compose and secret placeholders; capture old-container starts and bindings. Create only new state paths, securely transfer necessary NordVPN fields in memory without output, validate quietly.
3. Start VPN alone. Verify authenticated tunnel, server selection, DNS behavior, IPv4 egress and IPv6 constraints. Check expected provider endpoint without exposing credentials. Do not label differing IP alone as kill-switch proof.
4. Start empty qBittorrent only after VPN healthy. Configure tun0 binding, staging paths and disabled UPnP/NAT-PMP. Verify UI login, namespace sharing, permissions and absence of broad bypass rules.
5. With explicit approval, conduct a controlled tunnel-loss test inside NEW VPN namespace with no torrents: stop/suspend only its OpenVPN process or use supported image controls while keeping firewall active; issue bounded egress probes from downloader namespace. Verify no fallback on direct IPv4/DNS/IPv6 paths as applicable, restore tunnel and verify recovery. The old VPN is never interrupted. A stopped-container-only test does not prove firewall correctness.
6. Download one permitted test artifact after protections pass; verify placement/hash and no library writes. Measure memory/CPU and preserve old start times. Application-level seeding/import integration belongs to subsequent manager phases.
7. Document results and rollback. Old shutdown/deletion requires separate user confirmation; no queue migration inferred. Local commits only, no upstream push.

## Rollback and limits

Stop only the two new services; retain their new configuration for diagnosis. No old config edit means old downloader remains usable. On VPN container recreation, explicitly recreate dependent downloader as required to attach the new network namespace; health dependencies alone do not ensure safe runtime recovery. Test this behavior before unattended use. Full backup planning remains user-deferred; preserve config checkpoints without claiming a tested disaster recovery system.

## Design review

Recommendation: Gluetun plus separate LSIO qBittorrent, OpenVPN with existing NordVPN service credentials, US region, fresh empty queue, private staging. This is a provider-specific adaptation of the upstream architecture, not an in-place repair.

Decision required: approve a controlled tunnel interruption of the NEW VPN only, with no torrents, to demonstrate blocked egress before production use. This does not authorize interrupting the old VPN. If declined, deployment can proceed but protection must remain explicitly unverified and production downloads deferred.

References: https://github.com/qdm12/gluetun-wiki/blob/main/setup/providers/nordvpn.md ; https://docs.linuxserver.io/images/docker-qbittorrent/ .