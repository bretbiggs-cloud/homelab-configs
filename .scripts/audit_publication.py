"""Review a source allowlist without exposing secret values.

Usage: python .scripts/audit_publication.py --files PRIVATE_ALLOWLIST.txt
Reads tracked/reviewed source paths only. Rejects runtime file types and known
credential values from private management JSON. Also detects common token formats
and private-key headers. This is a safeguard, not proof that arbitrary secrets
are absent. The caller must still review the publication scope and Git history.
"""
import argparse,json,pathlib,re
p=argparse.ArgumentParser()
p.add_argument('--files',required=True)
a=p.parse_args()
private=pathlib.Path.home()/'.codex/private/homelab'
secrets=set()
for f in private.glob('*admin.json'):
    obj=json.loads(f.read_text(encoding='utf-8-sig'))
    for key,value in obj.items():
        if re.search('password|apikey|token',key,re.I) and isinstance(value,str) and len(value)>=8:
            secrets.add(value)
issues=[]
files=pathlib.Path(a.files).read_text(encoding='utf-8-sig').splitlines()
for name in files:
    f=pathlib.Path(name)
    if f.name=='.env' or f.suffix in ('.db','.dpapi','.log','.key'):
        issues.append({'file':name,'reason':'runtime/secret file type'});continue
    data=f.read_text(encoding='utf-8-sig')
    if any(secret in data for secret in secrets):
        issues.append({'file':name,'reason':'known private credential value'})
    if re.search(r'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----|gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{40,}',data):
        issues.append({'file':name,'reason':'credential pattern'})
print(json.dumps({'reviewedFiles':len(files),'issues':issues},indent=2))
raise SystemExit(bool(issues))
