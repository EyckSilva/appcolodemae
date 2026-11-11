"""Verifica arquivos versionados/versionáveis; não imprime conteúdo de segredos."""
import json
import subprocess
import sys
from pathlib import Path


def main():
    root = Path(subprocess.run(['git', 'rev-parse', '--show-toplevel'], check=True, capture_output=True, text=True).stdout.strip())
    paths = subprocess.run(['git', 'ls-files', '--cached', '--others', '--exclude-standard', '-z'], cwd=root, check=True, capture_output=True).stdout.decode('utf-8').split('\0')
    unsafe = []
    for name in paths:
        path = root / name
        if not path.is_file() or path.suffix.lower() not in ('.json', '.pem', '.key'):
            continue
        text = path.read_text(encoding='utf-8-sig', errors='replace')
        bad = '-----BEGIN PRIVATE KEY-----' in text or '-----BEGIN RSA PRIVATE KEY-----' in text
        if path.suffix.lower() == '.json':
            try:
                data = json.loads(text)
                bad = bad or isinstance(data, dict) and (data.get('type') in ('service_account', 'authorized_user') or 'private_key' in data or 'refresh_token' in data)
            except ValueError:
                pass
        if bad: unsafe.append(name)
    if unsafe:
        print('Credenciais não devem entrar no Git: ' + ', '.join(unsafe), file=sys.stderr)
        return 1
    print('Nenhuma credencial administrativa encontrada nos arquivos versionados/versionáveis examinados.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
