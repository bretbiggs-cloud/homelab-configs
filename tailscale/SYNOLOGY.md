> Dated implementation history. Later entries supersede earlier entries; for current production state use [the consolidated Synology reference](../.docs/synology.md). Old parallel-stage rollback instructions are historical after cutover.

# Synology Docker Tailscale

Status: enrolled, online, private forwarding configured and restart persistence verified. External-device access test pending.

## Deployment

Compose project homelab-v2-tailscale; container homelab-v2-tailscale; permanent node name substation. Official Tailscale1.104.4 image pinned at sha256:ed6480b33c6eb67c9cbd203ed42b9fb57e361986725b6856def71b7a3d9e276c. Docker userspace, user1026:100, no added capabilities, no privileged/host networking, no host ports. State /volume1/docker/homelab-v2/tailscale/data, mode700, outside Git; socket /tmp/tailscaled.sock. Persistent identity and TS_AUTH_ONCE=true. No reusable auth key.

Joined existing new Jellyfin bridge homelab-v2-jellyfin_homelab. Backend http://homelab-v2-jellyfin:8096/health returned Healthy. Intended first private endpoint forwards only Jellyfin8096; final Serve configuration awaits enrollment. No subnet/exit-node advertisement, Funnel, Tailscale SSH, host DNS or NordVPN modification.

## Verification and unresolved gates

Pre-enrollment PowerShell suite .tests/suites/test_synology_tailscale.ps1 passed all checks. State file persisted; backend state NeedsLogin; restart count0. All10 existing container start times unchanged. Initial root-with-dropped-capabilities attempt could not write user-owned state; recreated only Tailscale as1026:100 and verified persistence. Initial test incorrectly counted null CapAdd as one; corrected null handling and independently inspected CapAdd=null. No privileges added to work around failures.

Docker Hub saved credentials rejected a public pull; temporary empty client configuration succeeded anonymously, then removed. Existing credentials unchanged.

User must approve the generated login link in their chosen tailnet. Login URL is intentionally not stored in Git. After approval: confirm Running, assigned address and identity; inspect relevant tailnet access policy; configure private Serve, persist/export declarative config, test from an authorized peer, and verify no Funnel/routes/exit node. Do not claim remote playback or restricted user policy before tests. Jellyfin currently disables remote access; assess private forwarding behavior and scope any required new-instance setting change. Old Jellyfin untouched.

## Rollback

Stop only tailscale service in project homelab-v2-tailscale using this worktree's Compose. Keep state for recovery; revoke only this device in tailnet if removal is requested. LAN Jellyfin remains independent. Do not remove the feature worktree while deployed Compose uses it.

Sources: https://tailscale.com/docs/features/containers/docker/docker-params and https://tailscale.com/docs/reference/tailscale-cli/serve .
## Enrollment timeout correction

The user approved the first link, but node status remained NeedsLogin. Investigation identified official containerboot's default60s boot context expiring and restarting the container before enrollment completed, generating a new auth URL. Set supported TS_BOOT_TIMEOUT=24h for interactive enrollment. This changes only new Tailscale container startup and does not bypass authentication. Verify the current link/state after recreation; old links are superseded. Reduce timeout after enrollment if appropriate. Source: pinned v1.104.4 cmd/containerboot/main.go and settings.go.
## Enrollment and private forwarding verified

User approved the replacement link; Running/Online verified. Renamed node to substation at user request and updated Compose TS_HOSTNAME/hostname. Address100.104.49.30; DNS substation.tail8f9607.ts.net. Private TCP8096 forwards only to homelab-v2-jellyfin:8096. Exported Serve config to .configs/tailscale/serve.json and mounted its directory read-only with TS_SERVE_CONFIG. Recreated only new Tailscale to verify identity/address/Serve persistence. All enrolled-state assertions pass: non-root userspace, no host ports/privileges, persistent state, backend HTTP health, Running/Online, intended DNS/target, no Funnel, no advertised routes, no route acceptance, no Tailscale SSH or DNS override.

User-facing URL: http://substation.tail8f9607.ts.net:8096 or http://100.104.49.30:8096 on a Tailscale-connected client. HTTP transport is inside the encrypted tailnet; this is not an HTTPS certificate deployment. Jellyfin's existing LAN binding remains and old Jellyfin8096 on the NAS LAN is unchanged; new endpoint at the Tailscale IP is distinct from NAS LAN IP.

Management PC has no Tailscale executable installed. A same-node nc probe returned no HTTP payload and is not counted as successful tailnet HTTP validation. Asked user to test from phone cellular plus Tailscale. Tailnet ACL/grants were not accessible through the node, so do not claim a verified user-specific restriction: access follows existing tailnet policy plus Jellyfin authentication. No tailnet policy was broadened. External playback remains pending. All10 preexisting container start times unchanged.

User confirmed remote login and playback through Tailscale; external test gate passed by user report. Old Jellyfin subsequently retired with explicit authorization; other services retained.
