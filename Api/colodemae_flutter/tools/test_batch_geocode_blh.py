"""Etapa 10: testes offline; redes e relógio simulados quando necessário."""
import copy
import datetime as dt
import json
import tempfile
import unittest
import urllib.error
from pathlib import Path
from unittest.mock import patch

from batch_geocode_blh import (BatchClient, LEVELS, OUTPUT, assess_candidate, confidence,
    digest, immutable_json, load_inputs, read_json, snapshot_review, verify_preservation)
import test_import_blh as fixtures
import test_national_blh as previous_tests
from geocode_blh import export_approved


class BatchGeographicTests(unittest.TestCase):
    def setUp(self):
        self.record = {'nome': 'Banco de Leite da Maternidade Aurora', 'cidade': 'Brasília', 'estado': 'DF'}
        self.entry = {'enderecoPesquisa': 'Rua das Flores, 10, Brasília, DF', 'termosIdentificacao': ['aurora']}
        self.item = {'latitude': -15.8, 'longitude': -47.9, 'consulta': 'https://provider.example/api/',
            'enderecoRetornado': {'name': 'Maternidade Aurora', 'city': 'Brasília', 'state': 'Distrito Federal',
                'street': 'Rua das Flores', 'housenumber': '10', 'osm_key': 'amenity', 'osm_value': 'hospital',
                'osm_type': 'N', 'osm_id': 1}}

    def assess(self, **props):
        item = copy.deepcopy(self.item)
        item['enderecoRetornado'].update(props)
        return assess_candidate(item, self.record, self.entry)

    def test_specific_name_address_number_high_confidence_is_never_verified(self):
        result = self.assess()
        self.assertEqual(result['nivelConfianca'], 'alta')
        self.assertFalse(result['coordenadasVerificadas'])
        self.assertNotIn('ativo', result)
        self.assertEqual(confidence([result]), 'alta')

    def test_anonymous_compatible_address_is_medium_and_missing_number_is_low(self):
        self.assertEqual(self.assess(name='', type='house')['nivelConfianca'], 'media')
        self.assertEqual(self.assess(housenumber=None)['nivelConfianca'], 'baixa')

    def test_wrong_establishment_region_and_centroid_are_not_adequate(self):
        for changes in ({'name': 'Hospital Outro'}, {'city': 'Outra cidade'}, {'state': 'Sergipe'},
                        {'type': 'city'}, {'osm_key': 'highway'}):
            with self.subTest(changes=changes):
                result = self.assess(**changes)
                self.assertFalse(result['passivelRevisao'])
                self.assertEqual(confidence([result]), 'nao_encontrado')

    def test_wrong_street_and_number_are_address_conflicts(self):
        for changes in ({'street': 'Rua das Pedras'}, {'housenumber': '99'}):
            result = self.assess(**changes)
            self.assertFalse(result['passivelRevisao'])
            self.assertTrue(result['conflitoEndereco'])
            self.assertEqual(confidence([result]), 'conflito')

    def test_two_distant_points_conflict_and_close_duplicate_does_not(self):
        a, b = self.assess(), self.assess()
        self.assertEqual(confidence([a, b]), 'alta')
        b['longitude'] -= .01
        self.assertEqual(confidence([a, b]), 'conflito')

    def test_invalid_coordinates_and_malformed_records_are_discarded(self):
        for coords in ((91, 0), (0, 181), (True, 0), (float('nan'), 0), (0, None)):
            item = {**self.item, 'latitude': coords[0], 'longitude': coords[1]}
            self.assertIsNone(assess_candidate(item, self.record, self.entry))
        self.assertIsNone(assess_candidate({'enderecoRetornado': None}, self.record, self.entry))


class BatchCacheTests(unittest.TestCase):
    def config(self, directory):
        default = BatchClient(directory).config
        return {**default, 'endpoint': 'https://private.example/api/', 'politica': 'https://private.example/policy'}

    def test_offline_cache_deduplicates_without_http(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory)
            client = BatchClient(path)
            with patch('urllib.request.urlopen', side_effect=AssertionError('Offline must never call HTTP')):
                missing = client.search('Rua A')
                immutable_json(path / (digest(missing['url']) + '.json'),
                    {'url': missing['url'], 'consultadoEm': dt.datetime.now(dt.timezone.utc).isoformat(), 'features': []})
                self.assertNotIn('erro', client.search('Rua A'))
                self.assertEqual(client.search(' Rua  A '), client.search('Rua A'))
                self.assertEqual(client.hits, 1)
                self.assertEqual(client.requests, 0)

    def test_expired_corrupt_and_wrong_url_cache_are_not_reused(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory)
            client = BatchClient(path)
            result = client.search('Rua A')
            file = path / (digest(result['url']) + '.json')
            for data in ('invalid json', json.dumps({'url': result['url'], 'consultadoEm': '2000-01-01T00:00:00Z', 'features': []}),
                         json.dumps({'url': 'https://different.example', 'consultadoEm': dt.datetime.now(dt.timezone.utc).isoformat(), 'features': []})):
                file.write_text(data, encoding='utf-8')
                self.assertIn('erro', client.search('Rua A'))

    def test_public_online_provider_and_secret_configuration_are_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory)
            with self.assertRaises(ValueError): BatchClient(path, online=True)
            config = self.config(path)
            with self.assertRaises(ValueError): BatchClient(path, {**config, 'apiKey': 'fixture'})
            with self.assertRaises(ValueError): BatchClient(path, {**config, 'endpoint': 'https://user:password@example.test/api/'})
            with self.assertRaises(ValueError): BatchClient(path, {**config, 'intervaloSegundos': 0})

    def test_rate_limit_persists_block_and_does_not_repeat_requests(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory)
            client = BatchClient(path, self.config(path), online=True)
            error = urllib.error.HTTPError(client.endpoint, 429, 'limit', {'Retry-After': '7200'}, None)
            with patch('urllib.request.urlopen', side_effect=error) as request:
                self.assertIn('erro', client.search('Rua A'))
                self.assertIn('erro', client.search('Rua B'))
                self.assertEqual(request.call_count, 1)
                second = BatchClient(path, self.config(path), online=True)
                self.assertIn('erro', second.search('Rua C'))
                self.assertEqual(request.call_count, 1)
                self.assertEqual(read_json(client.quota)['requisicoes'], 1)

    def test_daily_budget_survives_restart(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory)
            config = {**self.config(path), 'maxRequisicoesDia': 1}
            client = BatchClient(path, config, online=True)
            immutable_json(client.quota, {'dia': dt.datetime.now(dt.timezone.utc).date().isoformat(), 'requisicoes': 1})
            with patch('urllib.request.urlopen', side_effect=AssertionError('Budget exceeded')):
                self.assertIn('Orçamento', client.search('Rua A')['erro'])

    def test_successful_request_respects_run_budget_and_cache(self):
        import io
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory)
            config = {**self.config(path), 'maxRequisicoesExecucao': 1}
            client = BatchClient(path, config, online=True)
            with patch('urllib.request.urlopen', return_value=io.BytesIO(b'{"features": []}')) as request:
                self.assertNotIn('erro', client.search('Rua A'))
                self.assertNotIn('erro', client.search(' Rua A '))
                self.assertIn('Orçamento', client.search('Rua B')['erro'])
                self.assertEqual(request.call_count, 1)
                self.assertEqual(client.requests, 1)


class BatchReviewTests(unittest.TestCase):
    def test_official_address_overlay_preserves_original_and_rejects_unknown_duplicates(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'overlay.json'
            before_records, before = load_inputs()
            identifier = next(identifier for identifier, source in before.items() if not source['endereco']['enderecoPesquisa'])
            row = {'id': identifier, 'enderecoPesquisa': 'Endereço artificial exclusivo de teste, 10',
                'fonteEndereco': 'https://saude.gov.br/fixture', 'consultadoEm': '2026-01-01T00:00:00Z'}
            immutable_json(path, [row])
            after_records, after = load_inputs(path)
            self.assertEqual(before_records, after_records)
            self.assertEqual(after[identifier]['historico']['enderecoAnterior'], before[identifier]['endereco'])
            self.assertEqual(load_inputs()[1][identifier], before[identifier])
            for rows in ([row, row], [{**row, 'id': 'unknown'}], [{**row, 'fonteEndereco': 'https://unofficial.example/fixture'}]):
                path.write_text(json.dumps(rows), encoding='utf-8')
                with self.assertRaises(ValueError): load_inputs(path)

    def test_changing_documented_address_requires_reason_and_cannot_replace_confirmation(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'overlay.json'
            _, original = load_inputs()
            identifier = 'se-blh-irma-rafaela-pepel'
            row = {'id': identifier, 'enderecoPesquisa': 'Endereço artificial de teste, 20',
                'fonteEndereco': 'https://saude.gov.br/fixture', 'consultadoEm': '2026-01-01T00:00:00Z'}
            immutable_json(path, [row])
            with self.assertRaises(ValueError): load_inputs(path)
            row['motivoAlteracao'] = 'Documento artificial apenas para exercitar histórico local.'
            path.write_text(json.dumps([row]), encoding='utf-8')
            source = load_inputs(path)[1][identifier]
            self.assertEqual(source['endereco']['confirmacaoDocumental'], original[identifier]['endereco']['confirmacaoDocumental'])
            row['confirmacaoDocumental'] = None
            path.write_text(json.dumps([row]), encoding='utf-8')
            with self.assertRaises(ValueError): load_inputs(path)

    def test_all_generated_review_templates_remain_pending(self):
        run = OUTPUT / 'revisao-cache-etapa10'
        summary = read_json(run / 'resumo.json')
        self.assertEqual(summary['requisicoesHTTP'], 0)
        self.assertFalse(summary['gravacaoFirebase'])
        self.assertEqual(summary['coordenadasAprovadasNestaEtapa'], 0)
        self.assertEqual(sum(summary['confianca'].values()), 215)
        reviews = [row for file in run.glob('*/revisao.pendente.json') for row in read_json(file)['revisoes']]
        self.assertEqual(len(reviews), 215)
        self.assertTrue(all(row['status'] == 'pendente' for row in reviews))

    def test_all_215_inputs_are_read_without_mutating_protected_files(self):
        records, lookup = load_inputs()
        self.assertEqual(len(records), 215)
        self.assertEqual(len(lookup), 215)
        self.assertEqual(sum(bool(v['endereco']['enderecoPesquisa']) for v in lookup.values()), 8)
        self.assertTrue(all(not row['ativo'] for row in records))
        self.assertEqual(verify_preservation(), 242)

    def test_rejected_decision_is_versioned_and_never_exported(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            folder = root / 'MA'
            folder.mkdir()
            args, review = previous_tests.NationalGeographicTests().setup_review(folder)
            (folder / 'report.json').rename(folder / 'candidatas.json')
            args.report = folder / 'candidatas.json'
            row = review['revisoes'][0]
            row.update({'status': 'rejeitado', 'revisadoPor': 'fixture-admin', 'revisadoEm': '2026-01-01T00:00:00Z',
                'observacoesValidacao': 'Endereço artificial não corresponde à unidade.'})
            args.review.write_text(json.dumps(review), encoding='utf-8')
            snapshot = snapshot_review(root, 'MA', args.review)
            self.assertEqual(read_json(snapshot)['decisao'], review)
            with self.assertRaises(FileExistsError): snapshot_review(root, 'MA', args.review)
            with self.assertRaises(ValueError): export_approved(args)
            self.assertFalse(args.output.exists())

    def test_approval_without_evidence_and_duplicate_decisions_are_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            folder = root / 'MA'
            folder.mkdir()
            args, review = previous_tests.NationalGeographicTests().setup_review(folder)
            (folder / 'report.json').rename(folder / 'candidatas.json')
            review['revisoes'][0]['status'] = 'aprovado'
            args.review.write_text(json.dumps(review), encoding='utf-8')
            with self.assertRaises(ValueError): snapshot_review(root, 'MA', args.review)
            review['revisoes'][0].update({'revisadoPor': 'fixture-admin', 'revisadoEm': '2026-01-01T00:00:00Z',
                'observacoesValidacao': 'Uma justificativa sem confirmação GPS não permite aprovar.'})
            args.review.write_text(json.dumps(review), encoding='utf-8')
            with self.assertRaises(ValueError): snapshot_review(root, 'MA', args.review)
            review['revisoes'] *= 2
            args.review.write_text(json.dumps(review), encoding='utf-8')
            with self.assertRaises(ValueError): snapshot_review(root, 'MA', args.review)

    def test_complete_manual_approval_creates_immutable_audit(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            folder = root / 'MA'
            folder.mkdir()
            args, review = previous_tests.NationalGeographicTests().setup_review(folder)
            (folder / 'report.json').rename(folder / 'candidatas.json')
            verified = fixtures.ImportValidationTests().verified()
            row = review['revisoes'][0]
            row.update({'status': 'aprovado', 'revisadoPor': 'fixture-admin', 'revisadoEm': verified['verificadoEm'],
                'observacoesValidacao': 'Evidência artificial apenas para validar este teste offline.',
                'pontoRealConfirmado': True, 'enderecoOperacionalConfirmado': True,
                'funcionamentoConfirmado': True, 'contatoConfirmado': True,
                'latitudeVerificada': verified['latitude'], 'longitudeVerificada': verified['longitude'],
                'fonteCoordenadas': verified['fonteCoordenadas'], 'enderecoConfirmado': verified['endereco'],
                'telefoneConfirmado': verified['telefone'], 'fontesCampos': verified['fontesCampos'], 'pendencias': []})
            args.review.write_text(json.dumps(review), encoding='utf-8')
            snapshot = snapshot_review(root, 'MA', args.review)
            self.assertEqual(read_json(snapshot)['decisao']['revisoes'][0]['status'], 'aprovado')
            self.assertFalse(args.output.exists())


if __name__ == '__main__': unittest.main()
