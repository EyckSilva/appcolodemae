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
    ledger = root / 'data/blh/correcao-demo/alteracoes-autorizadas.json'
    if not ledger.exists() or not name.startswith(('lib/', 'test/')): return False
    entry = json.loads(ledger.read_text(encoding='utf-8'))['arquivos'].get(name)
    return bool(entry and entry['antes'] == expected and entry['depois'] == actual)
