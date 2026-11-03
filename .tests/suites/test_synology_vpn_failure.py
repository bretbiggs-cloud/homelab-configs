#!/usr/bin/env python3
"""Verify isolated downloader egress and an explicitly approved tunnel loss.
Usage: python3 .tests/suites/test_synology_vpn_failure.py
Requires new VPN/qBittorrent containers, curl and protected local control key.
Mutates only new VPN runtime via Gluetun control API; always requests recovery.
No torrents are added. Prints fixed results, never credentials or IP addresses.
"""
import json, pathlib, re, subprocess, time
D='/usr/local/bin/docker'
Q='homelab-v2-qbittorrent'
V='homelab-v2-vpn'
auth=pathlib.Path('/volume1/docker/homelab-v2/gluetun/auth/config.toml').read_text()
key=re.search(r'apikey = "([^"]+)"',auth).group(1)

def execute(args, timeout=20):
    """Run bounded command; capture all output privately; no filesystem mutation."""
    return subprocess.run(args,stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True,timeout=timeout)

def control(method, status=None):
    """Call new VPN API only; PUT changes its tunnel state; errors hide secrets."""
    args=[D,'exec',Q,'curl','-fsS','--max-time','10','-X',method,'-H','X-API-Key: '+key]
    if status: args+=['-H','Content-Type: application/json','-d',json.dumps({'status':status})]
    r=execute(args+['http://127.0.0.1:8000/v1/vpn/status'])
    if r.returncode: raise RuntimeError('New VPN control request failed')
    return r.stdout

def probe(url, interface=None):
    """Probe HTTP from downloader namespace; no downloads saved or IPs printed."""
    args=[D,'exec',Q,'curl','-fsS','--connect-timeout','4','--max-time','8','-o','/dev/null']
    if interface: args+=['--interface',interface]
    return execute(args+[url]).returncode==0

# Require working baseline so subsequent blocked probes are meaningful.
assert probe('https://api.ipify.org'), 'Baseline DNS/HTTPS egress failed'
assert probe('http://1.1.1.1'), 'Baseline direct IPv4 probe failed'
assert not probe('http://1.1.1.1','eth0'), 'Unexpected non-VPN interface egress'
print('PASS: baseline egress works; explicit eth0 internet egress blocked',flush=True)
try:
    control('PUT','stopped')
    time.sleep(2)
    assert json.loads(control('GET'))['status']=='stopped', 'Tunnel not stopped'
    rules=execute([D,'exec',V,'iptables-legacy','-S','OUTPUT']).stdout
    assert '-P OUTPUT DROP' in rules, 'Default-drop firewall missing'
    assert not probe('http://1.1.1.1'), 'IPv4 egress escaped after tunnel stop'
    assert not probe('https://api.ipify.org'), 'DNS/HTTPS egress escaped after tunnel stop'
    assert not probe('http://1.1.1.1','eth0'), 'eth0 egress escaped after tunnel stop'
    ipv6=execute([D,'exec',Q,'cat','/proc/sys/net/ipv6/conf/all/disable_ipv6'])
    assert ipv6.stdout.strip()=='1', 'IPv6 unexpectedly enabled'
    print('PASS: tunnel stopped; firewall retained; bounded IPv4/HTTPS/eth0 probes blocked; IPv6 disabled',flush=True)
finally:
    control('PUT','running')
    print('Recovery requested for new VPN',flush=True)
for attempt in range(24):
    if probe('https://api.ipify.org'):
        print('PASS: VPN egress recovered',flush=True)
        break
    time.sleep(5)
else:
    raise RuntimeError('Recovery not confirmed within bounded window')
