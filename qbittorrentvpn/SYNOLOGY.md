> Dated implementation history. Later entries supersede earlier entries; for current production state use [the consolidated Synology reference](../.docs/synology.md). Old parallel-stage rollback instructions are historical after cutover.

# Synology downloader

CURRENT STATUS: server-selection fault isolated and replacement restored. Unchanged credentials succeeded with us13409.nordvpn.com and again after full two-container recreation. Old downloader remains running; no cutover authorized. See diagnosis below for evidence and limits.

Project: homelab-v2-downloads. Old qbittorrent remains running on LAN8080.
New UI: http://192.168.1.220:8082; Tailscale: http://substation.tail8f9607.ts.net:8082.

Gluetun and LSIO qBittorrent images are digest-pinned in compose.yml. Built-in NordVPN OpenVPN, US selection, native firewall/DNS, IPv6 disabled. Only VPN has NET_ADMIN/TUN. Downloader shares its network namespace and binds to tun0. UI ingress8082; authenticated control API is loopback-only. Credentials are protected runtime files outside Git; administrator login is stored privately on the management PC.

Fresh state is under /volume1/docker/homelab-v2/gluetun and qbittorrent. Only /volume1/media/downloads-v2 is writable at /downloads; no production library or old application data mounted. Categories radarr and tv-sonarr use complete/movies and complete/tv; temporary files use incomplete. UPnP/local discovery off, DHT/PEX enabled after protection tests.

## Verification

Initial server TLS timeout recovered through native retry. On DSM inspect firewall with iptables-legacy, not unsupported nft backend. OUTPUT DROP and tun0 routing verified.

Approved Python failure suite stopped only the new tunnel while keeping firewall active. Baseline public IPv4/HTTPS worked, explicit eth0 internet access blocked. During tunnel loss, direct IPv4, DNS-dependent HTTPS and eth0 probes failed; IPv6 disabled. Recovery verified. These bounded tests do not establish protection against every possible leak scenario. Old tunnel was not interrupted.

Creative Commons Sintel test torrent from https://webtorrent.io/free-torrents completed:129302391 bytes. Stopped and forced full hash recheck returned complete/stoppedUP. Data retained in /downloads/validation. No production jobs copied.

PowerShell test_synology_downloader.ps1 verifies health, namespace sharing, isolation, settings, test completion and old-container start time. test_synology_vpn_failure.py deliberately interrupts only the new VPN; requires deliberate authorization and an idle validation workload. Both are in .tests/suites.

## Maintenance

Recreate vpn and qbittorrent together to attach the dependent process to the current namespace. Initial --no-deps creation failed to resolve service:vpn on this Compose version; dependency-aware up succeeded. Do not move/remove this feature worktree while it owns deployed Compose files.

Rollback stops only the two new services and retains data. Old downloader/automation are unchanged; shutdown, deletion and queue migration require confirmation. Full backup planning remains deferred. No publication to GitHub.

## Authentication diagnosis

New secret files exactly match the old container environment and old OpenVPN credential file, with no surrounding whitespace and restrictive mode600. The service username is not email-shaped. Failed recreation repeatedly reached us12298.nordvpn.com and then received AUTH_FAILED. Old downloader uses us13454.nordvpn.com; the two do not collide on the same server/protocol. Credentials were neither reset nor changed.

NordVPN's recommendation API listed us13409.nordvpn.com online. Filtering the new stack to that server authenticated successfully. Full recreation of both new containers authenticated successfully again; infrastructure/app tests passed with correct namespace, credentials, tun0 binding, stopped/completed test data and unchanged old start time. This isolates a server-specific rejection in the observed attempts, but does not establish NordVPN's internal reason (server auth backend/account-session policy cannot be inspected here).

The host filter trades automatic broad server selection for predictable validated behavior. If NordVPN retires this endpoint or the Gluetun database drops it, inspect and select another current server; do not disable authentication or firewall controls. Keep the existing old downloader until explicit confirmation of cutover.

Regression suite checks the selected hostname and uses a bounded HTTP readiness wait before login. It does not weaken authentication checks. The first app probe after recreation was too early; it passed after WebUI became ready.

Final verification after the server change repeated the approved tunnel-loss test: default-drop firewall remained active, IPv4/HTTPS/eth0 probes were blocked, and VPN egress recovered. Subsequent application/infrastructure checks all passed, including unchanged old downloader start time. No production cutover has occurred. Remote phone access to the new downloader UI remains a user-side acceptance check.

Sources: https://support.nordvpn.com/hc/en-us/articles/19476515228305-How-many-devices-can-I-use-with-NordVPN and https://support.nordvpn.com/hc/en-us/articles/47830508425745-How-to-set-up-an-OpenVPN-manual-connection-to-NordVPN-with-Gluetun .

## Movie integration update — 2026-11-02

Resumed after the authorized crash recovery. New Radarr now shares /volume1/media/downloads-v2 at /downloads and uses /downloads/library/movies as its isolated movie root; category radarr remains /downloads/complete/movies. Native client connection and tiny cross-directory hardlink checks pass. No new torrents started; previous validation torrent remains complete/stopped. Existing old downloader unchanged against post-recovery baseline. Test now compares exact recovery-baseline ID/start timestamp rather than obsolete pre-crash time.
