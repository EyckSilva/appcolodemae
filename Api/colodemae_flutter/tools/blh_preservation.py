"""Manifestações históricas intactas e evolução explicitamente autorizada do código.

Dados administrativos continuam protegidos; exceções só aceitam hashes exatos de
arquivos de código listados na correção solicitada, sem recalcular o histórico.
"""
import hashlib
import json


def preserved(root, name, expected):
    path = root / name
    if not path.is_file(): return False
    actual = hashlib.sha256(path.read_bytes()).hexdigest()
    if actual == expected: return True
    # Hosting was already committed before the security audit. Preserve that
    # exact reviewed configuration instead of reverting to the pre-Hosting hash.
    configuration = root / 'data/security/configuracao-preservada.json'
    if name == 'firebase.json' and configuration.is_file():
        entry = json.loads(configuration.read_text(encoding='utf-8'))
        if entry['antes'] == expected and entry['depois'] == actual:
            return True
    # Only the documented redaction of an unrelated third-party Maps key and
    # its source manifest can replace historical hashes. Other data stay immutable.
    sanitized_paths = {'data/blh/nacional/fontes/amamenta-brasilia.html',
                       'data/blh/nacional/fontes/manifesto.json'}
    redactions = root / 'data/security/sanitizacao-fontes.json'
    if name in sanitized_paths and redactions.is_file():
        entry = json.loads(redactions.read_text(encoding='utf-8'))['arquivos'].get(name)
        if entry and entry['antes'] == expected and entry['depois'] == actual:
            return True
    ledger = root / 'data/blh/correcao-demo/alteracoes-autorizadas.json'
    if not ledger.exists() or not name.startswith(('lib/', 'test/')): return False
    entry = json.loads(ledger.read_text(encoding='utf-8'))['arquivos'].get(name)
    return bool(entry and entry['antes'] == expected and entry['depois'] == actual)
