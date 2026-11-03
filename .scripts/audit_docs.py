"""Audit tracked Markdown local links and optionally remote HTTP links.

Run from the repository root: python .scripts/audit_docs.py --output PRIVATE.json
Add --remote for bounded HTTP GET checks. Reports paths/status only, never file contents.
Reference examples and historical records remain in scope. HTTP errors are reported,
not silently treated as passes. No repository or server mutations occur.
"""
import argparse, concurrent.futures, ipaddress, json, pathlib, re, subprocess, urllib.parse, urllib.request

p = argparse.ArgumentParser()
p.add_argument('--output', required=True)
p.add_argument('--remote', action='store_true')
a = p.parse_args()
root = pathlib.Path.cwd()
files = subprocess.check_output(['git','-c','safe.directory=*','ls-files'], text=True).splitlines()
files += [str(x.relative_to(root)).replace('\\','/') for x in root.glob('.docs/*.md')]
docs = sorted(set(x for x in files if x.endswith('.md')))
broken, urls = [], set()
for f in docs:
    path = root / f
    if not path.exists():
        broken.append({'file':f,'target':'missing tracked file'}); continue
    text = path.read_text(encoding='utf-8-sig')
    text = re.sub(r'```.*?```', '', text, flags=re.S)
    for url in re.findall(r'https?://[^\s<>`"\)\]]+', text):
        url = url.rstrip('.,;')
        host = urllib.parse.urlsplit(url).hostname or ''
        if any(x in url for x in ('${','*','<')): continue
        try:
            if ipaddress.ip_address(host).is_private: continue
        except ValueError: pass
        if host.endswith(('.home','.local','.ts.net')) or host == 'localhost': continue
        # Historical owner domains are examples, not expected live deployment URLs.
        if host.endswith('kamaka.tech'): continue
        urls.add(url)
    for raw in re.findall(r'\]\(([^\n]+?)\)', text):
        target = raw.strip().split(' "')[0].strip('<>')
        if target.startswith(('http://','https://')):
            urls.add(target); continue
        if not target or target.startswith(('mailto:','plugin:','app:')): continue
        dest, _, anchor = target.partition('#')
        dest = urllib.parse.unquote(dest)
        resolved = (path.parent / dest) if dest else path
        if not resolved.exists():
            broken.append({'file':f,'target':target,'reason':'path missing'}); continue
        if anchor and resolved.suffix == '.md':
            headings = re.findall(r'^#{1,6}\s+(.+)$', resolved.read_text(encoding='utf-8-sig'), re.M)
            slugs = []
            for heading in headings:
                slug = re.sub(r'[^\w\- ]','',heading.lower()).replace(' ','-')
                slugs.append(slug)
            if urllib.parse.unquote(anchor) not in slugs:
                broken.append({'file':f,'target':target,'reason':'anchor needs review'})
def check(url):
    try:
        request = urllib.request.Request(url, headers={'User-Agent':'Mozilla/5.0 Homelab documentation audit'})
        with urllib.request.urlopen(request, timeout=12) as response:
            return {'url':url,'status':response.status}
    except Exception as e:
        return {'url':url,'status':getattr(e,'code',None),'error':type(e).__name__}
remote = []
internal = []
for url in list(urls):
    host = urllib.parse.urlsplit(url).hostname or ''
    private = '.' not in host or host.endswith(('.home','.local','.ts.net','kamaka.tech'))
    try: private = private or not ipaddress.ip_address(host).is_global
    except ValueError: pass
    if private:
        urls.remove(url)
        internal.append(url)
if a.remote:
    with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:
        remote = list(pool.map(check, sorted(urls)))
result = {'documents':len(docs),'localIssues':broken,'externalUrls':len(urls),'remote':remote,'internalOrExampleUrls':sorted(internal)}
pathlib.Path(a.output).write_text(json.dumps(result,indent=2),encoding='utf-8')
print(json.dumps({'documents':len(docs),'localIssues':broken,'externalUrls':len(urls),'remoteIssues':[x for x in remote if x['status'] != 200]},indent=2))
