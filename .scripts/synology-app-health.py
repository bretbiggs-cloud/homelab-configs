#!/usr/bin/env python3
"""Read authenticated Arr health without exposing keys or server messages.

Run on DSM as the existing monitoring user. Reads the deployed config.xml
files and makes three bounded GET requests; does not alter application state.
Exit 0 is healthy, 1 is an application warning/error, 2 is unavailable evidence.
No redirects or environment HTTP proxies are used for these local API calls.
"""
import json
import pathlib
import urllib.request
import xml.etree.ElementTree as ET


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def classify(payload):
    """Validate a health response; return warning and error counts."""
    if not isinstance(payload, list):
        raise ValueError('Unexpected health response')
    warnings = errors = 0
    for item in payload:
        if not isinstance(item, dict) or item.get('type') not in ('ok', 'notice', 'warning', 'error'):
            raise ValueError('Unexpected health entry')
        warnings += item['type'] == 'warning'
        errors += item['type'] == 'error'
    return warnings, errors


def check_service(name, url, config, opener):
    """Return exit state and a fixed-format summary; never echo exceptions/keys."""
    try:
        key = ET.parse(config).findtext('ApiKey')
        if not key or not key.strip():
            raise ValueError('API key unavailable')
        request = urllib.request.Request(url, headers={'X-Api-Key': key.strip()})
        with opener.open(request, timeout=6) as response:
            payload = response.read(262145)
            if len(payload) > 262144:
                raise ValueError('Oversized response')
            warnings, errors = classify(json.loads(payload))
        return int(bool(warnings or errors)), 'APP {} warnings={} errors={}'.format(name, warnings, errors)
    except Exception:
        return 2, 'APP {} status=unavailable'.format(name)


def main():
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}), NoRedirect())
    status = 0
    for name, port, version in (('radarr', 7879, 'v3'), ('sonarr', 8990, 'v3'), ('prowlarr', 9697, 'v1')):
        config = pathlib.Path('/volume1/docker/homelab-v2') / name / 'data/config.xml'
        code, message = check_service(name, 'http://192.168.1.220:{}/api/{}/health'.format(port, version), config, opener)
        print(message)
        status = max(status, code)
    return status


if __name__ == '__main__':
    raise SystemExit(main())
