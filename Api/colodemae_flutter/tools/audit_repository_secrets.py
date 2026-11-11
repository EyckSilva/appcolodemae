"""Scan versionable files and reachable Git blobs; output fingerprints, never values.

Heuristic audit, not a guarantee that no unknown secret exists. Does not mutate Git.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess

PATTERNS = {
    'google_api_key': rb'AIza[0-9A-Za-z_-]{35}',
    'private_key_marker': rb'-----BEGIN (?:RSA |EC |OPENSSH |ENCRYPTED )?PRIVATE KEY-----',
    'private_key': rb'-----BEGIN (?:RSA |EC |OPENSSH |ENCRYPTED )?PRIVATE KEY-----\s+[A-Za-z0-9+/=\r\n]{64,}-----END (?:RSA |EC |OPENSSH |ENCRYPTED )?PRIVATE KEY-----',
    'google_oauth_token': rb'ya29\.[A-Za-z0-9_-]{30,}',
    'google_refresh_token': rb'1//[A-Za-z0-9_-]{40,}',
    'github_token': rb'(?:gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{50,})',
    'aws_access_id': rb'(?:AKIA|ASIA)[0-9A-Z]{16}',
    'service_account_json': rb'"type"\s*:\s*"service_account"',
    'authorized_user_json': rb'"type"\s*:\s*"authorized_user"',
    'credential_json_value': rb'"(?:private_key|refresh_token|client_secret)"\s*:\s*"[^"\r\n]{12,}"',
}


def findings(data):
    result = []
    for kind, pattern in PATTERNS.items():
        for match in re.finditer(pattern, data):
            result.append({'type': kind, 'sha256': hashlib.sha256(match.group()).hexdigest(),
                           'line': data[:match.start()].count(b'\n') + 1})
    return result


def git(root, *args):
    return subprocess.run(['git', '-C', str(root), *args], check=True, capture_output=True).stdout


def audit(root, history=False):
    paths = git(root, 'ls-files', '--cached', '--others', '--exclude-standard', '-z').decode().split('\0')
    current = []
    for name in sorted(set(filter(None, paths))):
        path = root / name
        if path.is_file():
            for item in findings(path.read_bytes()): current.append({'path': name, **item})
    historical = []
    scanned = 0
    if history:
        objects = git(root, 'rev-list', '--objects', '--all').decode().splitlines()
        candidates = [row.split(' ', 1) for row in objects if ' ' in row]
        batch = subprocess.Popen(['git', '-C', str(root), 'cat-file', '--batch'], stdin=subprocess.PIPE, stdout=subprocess.PIPE)
        try:
            for oid, name in candidates:
                batch.stdin.write((oid+'\n').encode()); batch.stdin.flush()
                header = batch.stdout.readline().decode().split()
                size = int(header[2])
                data = batch.stdout.read(size); batch.stdout.read(1)
                if header[1] != 'blob': continue
                scanned += 1
                for item in findings(data): historical.append({'blob': oid, 'path': name, **item})
        finally:
            batch.stdin.close(); batch.wait()
    return {'current': current, 'history': historical, 'historyBlobsScanned': scanned,
            'reachableCommits': int(git(root, 'rev-list', '--all', '--count')),
            'head': git(root, 'rev-parse', 'HEAD').decode().strip(),
            'scope': 'versionable worktree and locally reachable Git refs; ignored files, remote-only refs, forks and unreachable objects excluded'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--history', action='store_true')
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    root = Path(subprocess.run(['git', 'rev-parse', '--show-toplevel'], check=True, capture_output=True, text=True).stdout.strip())
    report = audit(root, args.history)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    print(json.dumps({'output':str(args.output), 'currentFindings':len(report['current']),
        'historyFindings':len(report['history']), 'historyBlobsScanned':report['historyBlobsScanned'],
        'reachableCommits': report['reachableCommits'], 'nonGoogleFindings': [r for r in report['current']+report['history'] if r['type'] != 'google_api_key']},ensure_ascii=True))


if __name__ == '__main__': main()
