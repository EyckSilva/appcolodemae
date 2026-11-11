"""Artificial values only. Never contacts providers or writes production."""
import hashlib
import json
from pathlib import Path
import tempfile
import unittest

from audit_repository_secrets import findings
from blh_preservation import preserved
from check_blh_secrets import is_reviewed_client_key


class SecurityAuditTests(unittest.TestCase):
    def test_reviewed_public_key_requires_exact_fingerprint_and_config_path(self):
        root = Path(__file__).resolve().parents[1]
        approved = {'type':'google_api_key', 'sha256':'3f2466e8f4faba6bdceb62388a05d4527dd7014c506217cfdebe14f1279e7ccc'}
        self.assertTrue(is_reviewed_client_key(root/'lib/firebase_options.dart', approved))
        self.assertFalse(is_reviewed_client_key(root/'data/example.json', approved))
        self.assertFalse(is_reviewed_client_key(root/'lib/firebase_options.dart', {**approved,'sha256':'unknown'}))

    def test_finding_contains_fingerprint_and_line_but_never_key(self):
        key = b'AI' + b'za' + b'X' * 35
        found = findings(b'line one\nkey=' + key)
        self.assertEqual(found, [{'type':'google_api_key', 'sha256':hashlib.sha256(key).hexdigest(), 'line':2}])
        self.assertNotIn(key.decode(), json.dumps(found))

    def test_private_material_and_tokens_are_distinct_from_markers(self):
        marker = b'-----BEGIN ' + b'PRIVATE KEY-----'
        self.assertEqual([r['type'] for r in findings(marker)], ['private_key_marker'])
        material = marker + b'\n' + b'A' * 128 + b'\n-----END ' + b'PRIVATE KEY-----'
        self.assertIn('private_key', [r['type'] for r in findings(material)])
        self.assertIn('google_oauth_token', [r['type'] for r in findings(b'ya' + b'29.' + b'x'*40)])
        self.assertIn('credential_json_value', [r['type'] for r in findings(b'{"client_' + b'secret":"' + b'x'*20 + b'"}')])

    def test_archive_is_redacted_and_hashes_document_transformation(self):
        root = Path(__file__).resolve().parents[1]
        ledger = json.loads((root/'data/security/sanitizacao-fontes.json').read_text(encoding='utf-8'))
        path = root/'data/blh/nacional/fontes/amamenta-brasilia.html'
        self.assertNotIn('google_api_key', [r['type'] for r in findings(path.read_bytes())])
        self.assertIn(b'REDACTED_EXTERNAL_MAPS_KEY', path.read_bytes())
        for name, hashes in ledger['arquivos'].items():
            self.assertEqual(hashlib.sha256((root/name).read_bytes()).hexdigest(), hashes['depois'])
            self.assertTrue(preserved(root, name, hashes['antes']))

    def test_redaction_exception_rejects_unrelated_data_and_new_modifications(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            path = root/'data/blh/nacional/fontes/amamenta-brasilia.html'
            path.parent.mkdir(parents=True)
            path.write_bytes(b'changed')
            ledger = root/'data/security/sanitizacao-fontes.json'
            ledger.parent.mkdir(parents=True)
            ledger.write_text(json.dumps({'arquivos':{str(path.relative_to(root)).replace('\\','/'):{'antes':'original','depois':hashlib.sha256(b'approved').hexdigest()}}}))
            self.assertFalse(preserved(root, 'data/blh/nacional/fontes/amamenta-brasilia.html', 'original'))
            other = root/'data/blh/sergipe.json'
            other.parent.mkdir(parents=True, exist_ok=True)
            other.write_bytes(b'changed')
            self.assertFalse(preserved(root, 'data/blh/sergipe.json', 'original'))


if __name__ == '__main__': unittest.main()
