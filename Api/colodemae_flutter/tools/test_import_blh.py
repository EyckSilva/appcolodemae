"""Fixtures artificiais: estes testes nunca acessam o Firebase."""
import copy
import datetime as dt
import unittest
from pathlib import Path
from import_blh import validate_record, geohash, plan_update, UpdateConflict, load_records, content_hash

SOURCE = 'https://rblh.fiocruz.br/localizacao-dos-blhs'


class ImportValidationTests(unittest.TestCase):
    def draft(self):
        return {'chaveUnidade': 'fixture-unit', 'nome': 'Unidade artificial de teste',
                'tipo': 'BLH', 'cidade': 'São Luís', 'estado': 'MA', 'ativo': False,
                'fonte': SOURCE, 'verificacao': 'pendente'}

    def verified(self):
        return {**self.draft(), 'ativo': True, 'verificacao': 'verificado',
                'endereco': 'Endereço artificial, 10', 'telefone': '(98) 1234-5678',
                'verificadoEm': '2026-01-01T00:00:00Z',
                'coordenadasVerificadas': True, 'latitude': -2.5, 'longitude': -44.3,
                'fonteCoordenadas': SOURCE,
                'fontesCampos': {key: SOURCE for key in ['nome', 'tipo', 'endereco', 'cidade', 'estado', 'telefone', 'situacao']}}

    def test_draft_stays_inactive_without_inventing_missing_fields(self):
        result = validate_record(self.draft())
        self.assertFalse(result['ativo'])
        self.assertFalse(result['publicado'])
        self.assertFalse(result['coordenadasVerificadas'])
        for key in ('geohash', 'telefone', 'endereco', 'verificadoEm'):
            self.assertNotIn(key, result)
        self.assertEqual(result['cidadeBusca'], 'sao luis')

    def test_deterministic_id_survives_name_and_address_changes(self):
        a = validate_record(self.draft())
        b = validate_record({**self.draft(), 'nome': 'Outro nome oficial', 'endereco': 'Novo endereço'})
        self.assertEqual(a['id'], 'ma-fixture-unit')
        self.assertEqual(a['id'], b['id'])
        with self.assertRaises(ValueError): validate_record({**self.draft(), 'id': 'wrong'})

    def test_complete_verified_record_can_be_published(self):
        result = validate_record(self.verified())
        self.assertTrue(result['ativo'])
        self.assertTrue(result['publicado'])
        self.assertEqual(result['geohash'], geohash(-2.5, -44.3))
        self.assertEqual(geohash(42.6, -5.6, 5), 'ezs42')

    def test_active_requires_verification_all_fields_and_coordinates(self):
        for key in ('endereco', 'telefone', 'verificadoEm', 'fonteCoordenadas', 'latitude', 'longitude', 'fontesCampos'):
            data = self.verified()
            del data[key]
            with self.subTest(key=key), self.assertRaises(ValueError): validate_record(data)
        for changes in [{'verificacao': 'pendente'}, {'coordenadasVerificadas': False}, {'pendencias': ['verificar contato']}]:
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                validate_record({**self.verified(), **changes})

    def test_invalid_coords_are_rejected_even_for_drafts(self):
        for lat, lon in [(91, 0), (0, 181), (float('nan'), 0), (0, float('inf')), (True, 0), (0, None)]:
            with self.subTest(lat=lat, lon=lon), self.assertRaises(ValueError):
                validate_record({**self.draft(), 'latitude': lat, 'longitude': lon})

    def test_invalid_sources_schema_and_phone_are_rejected(self):
        for changes in [
            {'fonte': 'https://untrusted.example/unit'},
            {'fonte': 'https://fiocruz.br.untrusted.example/unit'},
            {'ativo': 'true'}, {'estado': 'XX'}, {'publicado': True},
            {'chaveUnidade': '../bad'}, {'telefone': '123'},
            {'telefone': '(98) 1234-5678 ramal 10'},
            {'verificadoEm': '2026-01-01'},
            {'consultadoEm': (dt.datetime.now(dt.timezone.utc) + dt.timedelta(days=1)).isoformat()},
        ]:
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                validate_record({**self.draft(), **changes})

    def test_seed_contains_only_five_real_pending_sergipe_entries(self):
        path = Path(__file__).resolve().parents[1] / 'data/blh/sergipe.json'
        records = load_records(path)
        self.assertEqual(len(records), 5)
        self.assertEqual(len({row['id'] for row in records}), 5)
        for record in records:
            self.assertEqual(record['estado'], 'SE')
            self.assertFalse(record['ativo'])
            self.assertFalse(record['publicado'])
            self.assertNotIn('latitude', record)
            self.assertNotIn('longitude', record)
            self.assertTrue(record['pendencias'])

    def test_default_policy_creates_and_then_is_idempotent(self):
        record = validate_record(self.draft())
        action, patch = plan_update(record, None)
        self.assertEqual(action, 'create')
        original = {**patch, 'criadoEm': dt.datetime(2026, 1, 1, tzinfo=dt.timezone.utc), 'campoLegado': 'preservado'}
        action, patch = plan_update(record, original)
        self.assertEqual(action, 'unchanged')
        self.assertEqual(patch, {})
        self.assertEqual(original['campoLegado'], 'preservado')

    def test_default_rejects_overwriting_existing_data(self):
        record = validate_record(self.draft())
        existing = {k: v for k, v in record.items() if k != 'id'}
        existing['telefone'] = '(98) 1111-2222'
        changed = validate_record({**self.draft(), 'telefone': '(98) 3333-4444'})
        with self.assertRaises(UpdateConflict): plan_update(changed, existing)
        self.assertEqual(existing['telefone'], '(98) 1111-2222')

    def test_fill_missing_never_replaces_fields_or_publishes(self):
        old = validate_record(self.draft())
        old['nome'] = 'Nome preservado'
        old['criadoEm'] = dt.datetime(2026, 1, 1, tzinfo=dt.timezone.utc)
        incoming = validate_record({**self.draft(), 'telefone': '(98) 3333-4444'})
        action, patch = plan_update(incoming, old, 'fill-missing')
        self.assertEqual(action, 'update')
        self.assertEqual(patch['telefone'], '(98) 3333-4444')
        for field in ('nome', 'ativo', 'publicado', 'criadoEm'):
            self.assertNotIn(field, patch)
        with self.assertRaises(UpdateConflict): plan_update(incoming, {**old, 'publicado': True}, 'fill-missing')

    def test_verified_update_requires_newer_verification(self):
        old = validate_record(self.verified())
        old['criadoEm'] = dt.datetime(2025, 1, 1, tzinfo=dt.timezone.utc)
        old['campoLegado'] = 'preservado'
        newer = validate_record({**self.verified(), 'nome': 'Novo nome oficial', 'verificadoEm': '2026-02-01T00:00:00Z'})
        action, patch = plan_update(newer, old, 'update-verified')
        self.assertEqual(action, 'update')
        self.assertEqual(patch['nome'], 'Novo nome oficial')
        self.assertNotIn('criadoEm', patch)
        self.assertNotIn('campoLegado', patch)
        original = copy.deepcopy(old)
        same_date = validate_record({**self.verified(), 'nome': 'Tentativa sem nova verificação'})
        with self.assertRaises(UpdateConflict): plan_update(same_date, old, 'update-verified')
        with self.assertRaises(UpdateConflict): plan_update(validate_record(self.draft()), old, 'update-verified')
        self.assertEqual(old, original)

    def test_hash_ignores_server_timestamps_and_is_stable(self):
        record = validate_record(self.draft())
        self.assertEqual(record['hashConteudo'], content_hash({**record, 'criadoEm': object(), 'atualizadoEm': object()}))

    def test_activation_cannot_hide_existing_pending_notes_by_omission(self):
        old = validate_record({**self.draft(), 'pendencias': ['Confirmar localização']})
        active = validate_record(self.verified())
        with self.assertRaises(UpdateConflict): plan_update(active, old, 'update-verified')
        active = validate_record({**self.verified(), 'pendencias': []})
        action, patch = plan_update(active, old, 'update-verified')
        self.assertEqual(action, 'update')
        self.assertEqual(patch['pendencias'], [])

    def test_draft_update_requires_newer_consultation_and_cannot_change_active_units(self):
        old = validate_record({**self.draft(), 'consultadoEm': '2026-01-01T00:00:00Z'})
        new = validate_record({**self.draft(), 'nome': 'Nome corrigido', 'consultadoEm': '2026-02-01T00:00:00Z'})
        action, patch = plan_update(new, old, 'update-draft')
        self.assertEqual(action, 'update')
        self.assertEqual(patch['nome'], 'Nome corrigido')
        self.assertNotIn('criadoEm', patch)
        with self.assertRaises(UpdateConflict): plan_update(new, {**old, 'ativo': True}, 'update-draft')
        same_date = validate_record({**self.draft(), 'nome': 'Sem nova consulta', 'consultadoEm': '2026-01-01T00:00:00Z'})
        with self.assertRaises(UpdateConflict): plan_update(same_date, old, 'update-draft')


if __name__ == '__main__':
    unittest.main()
