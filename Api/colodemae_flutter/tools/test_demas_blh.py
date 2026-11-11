"""DEMAS: snapshots públicos reais; escrita e transações exclusivamente simuladas."""
import copy
import datetime as dt
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

from demas_blh import (DIRECTORY, ROOT, DemasClient, cnes, establishment, plan_patch,
                       preserve, read_json, sync, UpdateConflict)
from import_blh import validate_record


class DemasTests(unittest.TestCase):
    def setUp(self):
        self.report = read_json(DIRECTORY / 'coleta-aracaju-validada/relatorio.json')
        self.unit = self.report['unidades'][0]
        self.original = validate_record(read_json(ROOT / 'data/blh/sergipe.json')[0])
        self.decision = {'id': self.unit['id'], 'cnes': '0002569', 'status': 'aprovado', 'campos': ['demas'],
            'vinculoBlhConfirmado': True, 'conflitosRevisados': True, 'contatoConfirmado': False,
            'enderecoOperacionalConfirmado': False, 'revisadoPor': 'fixture-admin',
            'revisadoEm': dt.datetime.now(dt.timezone.utc).isoformat(),
            'justificativa': 'Aprovação artificial restrita aos testes; nunca executar em produção.',
            'fontesComplementares': [self.unit['evidenciaVinculo']], 'valoresAnteriores': {'demas': None}}

    def test_real_crosswalk_is_three_units_not_all_hospitals(self):
        self.assertEqual(len(self.report['unidades']), 3)
        self.assertEqual(self.unit['recuperado']['cnes'], '0002569')
        self.assertEqual([u['relacao'] for u in self.report['unidades']], ['proprio', 'mantenedora', 'mantenedora'])
        self.assertTrue(all(not u['ativo'] and not u['publicado'] and not u['coordenadasVerificadas'] for u in self.report['unidades']))
        self.assertIsNone(self.report['unidades'][2]['recuperado']['telefone'])
        self.assertTrue(any(c['campo'] == 'coordenadasCadastrais' for c in self.unit['conflitos']))
        self.assertTrue(any(c['campo'] == 'numeroEnderecoPesquisaAnterior' for c in self.report['unidades'][2]['conflitos']))
        self.assertEqual(preserve(), 479)

    def test_cnes_keeps_leading_zeros_and_rejects_invalid_types(self):
        self.assertEqual(cnes(2569), '0002569')
        for value in (True, None, '12345678', -1, 1.2, 'AB12345'):
            with self.subTest(value=value), self.assertRaises(ValueError): cnes(value)

    def test_real_response_validation_rejects_wrong_cnes_city_state_and_name(self):
        raw = read_json(DIRECTORY / 'marly.json')
        for key, value in [('codigo_cnes', 2232), ('codigo_municipio', 280290), ('codigo_uf', 35), ('nome_fantasia', 'Hospital diferente')]:
            with self.subTest(key=key), self.assertRaises(ValueError):
                establishment({**raw, key: value}, '0002569', ['marly', 'sarney'])

    def test_missing_phone_is_never_completed_or_invented(self):
        raw = read_json(DIRECTORY / 'marly.json')
        for value in (None, '32266301', 'telefone 7932266301'):
            self.assertIsNone(establishment({**raw, 'numero_telefone_estabelecimento': value}, '0002569', ['marly'])['telefone'])

    def test_real_offset_filter_behavior_and_service_scoping(self):
        a, b, invalid, _ = self.report['provasFiltros']
        self.assertEqual(a['dados']['estabelecimentos'][1]['codigo_cnes'], b['dados']['estabelecimentos'][0]['codigo_cnes'])
        self.assertEqual(invalid['dados']['estabelecimentos'], [])
        for unit in self.report['unidades']:
            self.assertTrue(all(cnes(row['co_cnes']) == unit['recuperado']['cnes'] and row['co_ibge'] == 280030
                and row['nu_comp'] == unit['competenciaServicos'] for row in unit['servicos']))
            self.assertEqual(unit['codigosLeiteIdentificados'], [])

    def test_client_rejects_undocumented_filters_without_network(self):
        with tempfile.TemporaryDirectory() as directory:
            client = DemasClient(Path(directory))
            with patch('urllib.request.urlopen', side_effect=AssertionError('Must remain offline')):
                with self.assertRaises(ValueError): client.get('/cnes/estabelecimentos', {'nome': 'leite'})
                with self.assertRaises(ValueError): client.get('/cnes/servicos-inventados')

    def test_short_pages_do_not_end_pagination_early_and_duplicate_pages_fail(self):
        with tempfile.TemporaryDirectory() as directory:
            client = DemasClient(Path(directory))
            pages = [{'dados': {'rows': [{'co_cnes': '0002569', 'value': i}]}, 'url': str(i), 'consultadoEm': '', 'hashResposta': ''} for i in (1, 2)]
            empty = {'dados': {'rows': []}, 'url': 'empty', 'consultadoEm': '', 'hashResposta': ''}
            with patch.object(client, 'get', side_effect=[*pages, empty]) as get:
                rows, _ = client.pages('fixture', 'rows', {'co_cnes': '0002569'})
                self.assertEqual(len(rows), 2)
                self.assertEqual([call.args[1]['offset'] for call in get.call_args_list], [0, 1, 2])
            with patch.object(client, 'get', side_effect=[pages[0], pages[0]]):
                with self.assertRaises(ValueError): client.pages('fixture', 'rows', {'co_cnes': '0002569'})

    def test_pending_and_rejected_records_cannot_publish_or_update(self):
        for status, action in [('pendente', 'pending'), ('rejeitado', 'rejected')]:
            self.assertEqual(plan_patch(self.original, self.unit, {'status': status}), (action, {}))
        with self.assertRaises(UpdateConflict): plan_patch(None, self.unit, self.decision)

    def test_manual_metadata_patch_preserves_visual_identity_and_is_idempotent(self):
        action, patch_data = plan_patch(self.original, self.unit, self.decision)
        self.assertEqual(action, 'update')
        self.assertEqual(set(patch_data), {'demas'})
        merged = {**self.original, **patch_data}
        self.assertEqual(plan_patch(merged, self.unit, self.decision), ('unchanged', {}))
        for key in ('nome', 'tipo', 'ativo', 'publicado', 'pendencias', 'coordenadasVerificadas', 'fonte'):
            self.assertEqual(merged[key], self.original[key])

    def test_published_and_concurrently_changed_records_are_protected(self):
        for changes in ({'ativo': True}, {'publicado': True}, {'verificacao': 'verificado'}, {'demas': {'cnes': 'other'}}, {'nome': 'Outro nome'}):
            with self.subTest(changes=changes), self.assertRaises(UpdateConflict):
                plan_patch({**self.original, **changes}, self.unit, self.decision)

    def test_conflicting_address_requires_explicit_confirmation_and_previous_value(self):
        decision = {**self.decision, 'campos': ['endereco'], 'valoresAnteriores': {'endereco': self.original['endereco']}}
        with self.assertRaises(UpdateConflict): plan_patch(self.original, self.unit, decision)
        decision['enderecoOperacionalConfirmado'] = True
        _, result = plan_patch(self.original, self.unit, decision)
        self.assertEqual(result['endereco'], self.unit['recuperado']['endereco'])
        self.assertEqual(result['fontesCampos']['endereco'], self.unit['fonte']['url'])
        for forbidden in ('ativo', 'publicado', 'latitude', 'longitude', 'verificadoEm', 'criadoEm'):
            self.assertNotIn(forbidden, result)

    def test_firestore_read_and_transactional_update_simulated(self):
        stored = {self.unit['id']: copy.deepcopy(self.original)}
        updates = []
        class Reference:
            def __init__(self, identifier): self.id = identifier
            def get(self, transaction=None):
                return SimpleNamespace(exists=self.id in stored, to_dict=lambda: copy.deepcopy(stored.get(self.id)), update_time=None)
        class Transaction:
            def update(self, ref, data):
                stored[ref.id].update(data)
                updates.append(data)
        class DB:
            def collection(self, name):
                assert name == 'bancos_leite'
                return SimpleNamespace(document=Reference)
            def transaction(self): return Transaction()
        with tempfile.TemporaryDirectory() as directory:
            folder = Path(directory)
            report = {'unidades': [self.unit]}
            review = {'hashRelatorio': __import__('demas_blh').digest(report['unidades']), 'revisoes': [self.decision]}
            for name, data in [('report', report), ('review', review)]:
                (folder / f'{name}.json').write_text(__import__('json').dumps(data), encoding='utf-8')
            args = SimpleNamespace(report=folder / 'report.json', review=folder / 'review.json', project='fixture-project',
                output=folder / 'audit-1.json', apply=True, firebase_cli_auth=False)
            fake = SimpleNamespace(firestore=SimpleNamespace(transactional=lambda function: function, SERVER_TIMESTAMP='SERVER_TIMESTAMP_FIXTURE'))
            with patch('demas_blh.initialize_db', return_value=DB()), patch.dict('sys.modules', {'firebase_admin': fake}):
                sync(args)
                args.output = folder / 'audit-2.json'
                sync(args)
            self.assertEqual(len(updates), 1)
            self.assertEqual(stored[self.unit['id']]['atualizadoEm'], 'SERVER_TIMESTAMP_FIXTURE')
            self.assertFalse(read_json(args.output)['gravacaoExecutada'])


if __name__ == '__main__': unittest.main()
