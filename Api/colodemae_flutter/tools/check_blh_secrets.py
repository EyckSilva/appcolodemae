"""Verifica arquivos versionados/versionáveis; não imprime conteúdo de segredos."""
import subprocess
import sys
from pathlib import Path
from audit_repository_secrets import findings


# Exact reviewed client keys, at client configuration paths only. These are
# fingerprints, not key values. This does not dismiss any GitHub alert.
PUBLIC_CLIENT_KEYS = {
    'lib/firebase_options.dart': {
        '3f2466e8f4faba6bdceb62388a05d4527dd7014c506217cfdebe14f1279e7ccc',
        '20667643cfcb54e9e2a501da4610bfdf95741c745a5e6c16665294953d28cf93',
        '5df59a173473f7d4e977ef15c8ff4015b9ff11b40fcdfd2246496dc414d670f4',
    },
    'android/app/google-services.json': {
        '20667643cfcb54e9e2a501da4610bfdf95741c745a5e6c16665294953d28cf93',
    },
}


def is_reviewed_client_key(path, finding):
    relative = path.relative_to(Path(__file__).resolve().parents[1]).as_posix()
    return finding['type'] == 'google_api_key' and finding['sha256'] in PUBLIC_CLIENT_KEYS.get(relative, set())


def main():
    root = Path(subprocess.run(['git', 'rev-parse', '--show-toplevel'], check=True, capture_output=True, text=True).stdout.strip())
    paths = subprocess.run(['git', 'ls-files', '--cached', '--others', '--exclude-standard', '-z'], cwd=root, check=True, capture_output=True).stdout.decode('utf-8').split('\0')
    unsafe = []
    for name in paths:
        path = root / name
        if not path.is_file():
            continue
        for item in findings(path.read_bytes()):
            # A marker string in scanner source is not private key material.
            if item['type'] == 'private_key_marker': continue
            try:
                reviewed = is_reviewed_client_key(path, item)
            except ValueError:
                reviewed = False
            if not reviewed: unsafe.append(name + ':' + str(item['line']) + ' (' + item['type'] + ')')
    if unsafe:
        print('Credenciais não devem entrar no Git: ' + ', '.join(unsafe), file=sys.stderr)
        return 1
    print('Nenhuma credencial privada ou chave Google inesperada encontrada nos arquivos versionados/versionáveis examinados; configurações Firebase públicas revisadas foram preservadas.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
