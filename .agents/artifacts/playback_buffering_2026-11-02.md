# Remote playback buffering — 2026-11-02

User reported video buffering on cellular/another network. Live Jellyfin session showed Chrome Android web client playing The Dog Stars, paused near18.8 seconds. PlayMethodTranscode but IsVideoDirect=true; only audio converted toAAC because AudioCodecNotSupported. Reported processing1068fps and33.8% completion does not indicate insufficient real-time encoding speed. Session bitrate field13.68Mbps is an estimate, not measured network throughput.

NAS load9.95 with IO8.39, CPU1.56; availableRAM654MiB. New Jellyfin consumed about131%CPU during sample. New downloader receiving3.89MB/s, sending0.084MB/s. These indicate competing activity, not proof of a single cause. No running scheduled Jellyfin task returned during initial check.

Tailscale ping to phone used DERP(nyc) on all3 probes,110–122ms; direct connection not established. Netcheck UDPtrue, IPv6unavailable, MappingVariesByDestIPtrue, no port mapping. This supports difficult NAT/direct-connect constraints. Relay throughput was NOT measured; no claim relay alone caused buffering. No public port, router, firewall, network mode or old service change.

Changed only new Jellyfin encoding EnableThrottling false->true, retained180-second lead and other values. Original encoding config saved privately at .codex/private/homelab/jellyfin-encoding-before-throttle.json. Read-back verified true. No restart/forced playback stop. Intended to reduce processing and disk writes far ahead of playback; actual improvement needs user retry. Restore exact previous boolean/config if regression.

Next client test: official Jellyfin Android app with integrated/native player if offered, same Tailscale server. Stop/reopen playback to use a fresh session. Compare direct play/audio conversion and buffering. Lower remote bitrate may force video transcoding and should not be assumed an unconditional improvement on this NAS. Further direct-connect diagnosis remains separate; do not alter router exposure speculatively.

Sources: https://tailscale.com/docs/reference/best-practices/performance ; https://tailscale.com/docs/reference/troubleshooting/network-configuration/hard-nat-issues ; https://jellyfin.org/docs/general/clients/codec-support/ .
