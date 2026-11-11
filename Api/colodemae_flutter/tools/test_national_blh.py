"""Fixtures artificiais e verificações locais; nenhum teste publica unidades."""
import copy
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace

from import_blh import load_records, plan_update, UpdateConflict
from geocode_blh import candidate, digest, export_approved, read_json, review_template, write_json
from national_blh import DIRECTORY, ROOT, STATES, aggregate, check_unique, classify, parse_annex, verify_preservation
import test_import_blh as fixtures


class NationalCatalogTests(unittest.TestCase):
    def setUp(self):
        self.raw = read_json(DIRECTORY / 'importacao-rascunhos.json')

    def test_all_states_source_counts_and_no_publication(self):
        self.assertEqual({row['estado'] for row in self.raw}, STATES)
        self.assertEqual(len(self.raw), 215)
        self.assertEqual(sum(row['tipo'] == 'BLH' for row in self.raw), 210)
        self.assertTrue(all(not row['ativo'] and not row['coordenadasVerificadas'] for row in self.raw))
        check_unique(self.raw)

    def test_sergipe_aliases_preserve_all_original_records(self):
        self.assertEqual([r for r in self.raw if r['estado'] == 'SE'], read_json(ROOT / 'data/blh/sergipe.json'))
        traces = read_json(DIRECTORY / 'SE/rastreabilidade.json')
        self.assertEqual(sum(t['documentacao'].get('aliasPreservado', False) for t in traces), 3)
        self.assertEqual(verify_preservation(), 73)

    def test_annex_uses_blh_city_instead_of_entity_city(self):
        rows = parse_annex((DIRECTORY / 'fontes/portaria-11175-2026.html').read_text(encoding='utf-8-sig'))
        row = next(row for row in rows if row[0] == 'SE' and row[6] == '2503824')
        self.assertEqual(row[3], 'LAGARTO')
        self.assertNotEqual(row[1], row[3])

    def test_annex_structure_and_duplicate_cnes_are_rejected(self):
        with self.assertRaises(ValueError): parse_annex('<table><tr><td>UF</td></tr></table>')
        html = (DIRECTORY / 'fontes/portaria-11175-2026.html').read_text(encoding='utf-8-sig')
        # Repetir o documento também repete cabeçalho e identidades.
        with self.assertRaises(ValueError): parse_annex(html + html)

    def test_duplicate_id_and_semantic_duplicate_with_new_id_are_rejected(self):
        with self.assertRaises(ValueError): check_unique([self.raw[0], self.raw[0]])
        other = {**self.raw[0], 'chaveUnidade': 'artificial-alternative-key'}
        with self.assertRaises(ValueError): check_unique([self.raw[0], other])

    def test_manifest_aggregation_is_repeatable_and_protects_sources(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / 'aggregate.json'
            aggregate(DIRECTORY / 'manifesto.json', output)
            first = output.read_bytes()
            aggregate(DIRECTORY / 'manifesto.json', output)
            self.assertEqual(first, output.read_bytes())
            self.assertEqual(read_json(output), self.raw)
        with self.assertRaises(ValueError):
            aggregate(DIRECTORY / 'manifesto.json', ROOT / 'data/blh/sergipe.json')

    def test_repeated_import_is_noop_and_existing_approval_is_protected(self):
        for row in load_records(DIRECTORY / 'importacao-rascunhos.json'):
            action, stored = plan_update(row, None)
            self.assertEqual(action, 'create')
            self.assertEqual(plan_update(row, stored)[0], 'unchanged')
            with self.assertRaises(UpdateConflict):
                plan_update(row, {**stored, 'ativo': True, 'publicado': True})

    def test_four_disjoint_classes(self):
        fixture = fixtures.ImportValidationTests().verified()
        self.assertEqual(classify(fixture), 'aprovados_verificados')
        fixture = fixtures.ImportValidationTests().draft()
        self.assertEqual(classify(fixture), 'sem_coordenadas')
        self.assertEqual(classify(fixture, [{'passivelRevisao': True}]), 'aguardando_validacao')
        self.assertEqual(classify(fixture, [{'passivelRevisao': True}] * 2), 'ambiguos_conflitantes')
        self.assertEqual(classify(fixture, [{'passivelRevisao': False}]), 'ambiguos_conflitantes')

    def test_rules_and_flutter_geographic_query_contract_remain_restricted(self):
        rules = (ROOT / 'firestore.rules').read_text(encoding='utf-8')
        catalog = rules.split('match /bancos_leite/{unidadeId}')[1].split('// Qualquer outra')[0]
        self.assertIn('allow create, update, delete: if false;', catalog)
        for clause in ('request.auth != null', 'resource.data.ativo == true', 'resource.data.publicado == true'):
            self.assertIn(clause, catalog)
        repository = (ROOT / 'lib/services/milk_bank_repository.dart').read_text(encoding='utf-8')
        for clause in (".where('coordenadasVerificadas', isEqualTo: true)", ".orderBy('geohash')", '.limit(101)'):
            self.assertIn(clause, repository)


class NationalGeographicTests(unittest.TestCase):
    def feature(self):
        return {'geometry': {'type': 'Point', 'coordinates': [-47.9, -15.8]},
                'properties': {'name': 'Unidade artificial', 'city': 'Brasília', 'state': 'Distrito Federal',
                               'osm_key': 'amenity', 'osm_value': 'hospital', 'osm_type': 'N', 'osm_id': 123}}

    def test_state_validation_supports_df_and_rejects_wrong_state_city_and_centroid(self):
        feature = self.feature()
        self.assertTrue(candidate(feature, 'https://example.test', 'Brasília', ['artificial'], 'DF')['passivelRevisao'])
        self.assertFalse(candidate(feature, 'https://example.test', 'Brasília', ['artificial'], 'SE')['passivelRevisao'])
        self.assertFalse(candidate(feature, 'https://example.test', 'Outra cidade', ['artificial'], 'DF')['passivelRevisao'])
        feature['properties']['type'] = 'city'
        self.assertFalse(candidate(feature, 'https://example.test', 'Brasília', ['artificial'], 'DF')['passivelRevisao'])

    def test_geocoder_rejects_invalid_and_nonpoint_coordinates(self):
        for coords in ([0, 91], [181, 0], [True, 0], [float('nan'), 0], [0]):
            feature = self.feature()
            feature['geometry']['coordinates'] = coords
            self.assertIsNone(candidate(feature, 'https://example.test', 'Brasília', [], 'DF'))
        feature['geometry']['type'] = 'Polygon'
        self.assertIsNone(candidate(feature, 'https://example.test', 'Brasília', [], 'DF'))

    def setup_review(self, folder):
        raw = fixtures.ImportValidationTests().draft()
        identifier = 'ma-fixture-unit'
        base, report_path, review_path, output = [folder / name for name in ('base.json', 'report.json', 'review.json', 'approved.json')]
        write_json(base, [raw])
        report = {'hashBase': digest([raw]), 'hashEnderecos': digest([]), 'provedor': 'https://example.test/api/',
                  'unidades': [{'id': identifier, 'candidatos': [], 'pendencias': []}]}
        report['hashRevisao'] = digest(report)
        write_json(report_path, report)
        review = review_template(report)
        write_json(review_path, review)
        return SimpleNamespace(base=base, report=report_path, review=review_path, output=output), review

    def test_pending_and_incomplete_manual_approval_cannot_export(self):
        with tempfile.TemporaryDirectory() as directory:
            args, review = self.setup_review(Path(directory))
            with self.assertRaises(ValueError): export_approved(args)
            review['revisoes'][0]['status'] = 'aprovado'
            write_json(args.review, review)
            with self.assertRaises(ValueError): export_approved(args)
            self.assertFalse(args.output.exists())

    def test_documented_manual_approval_exports_and_tampering_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            args, review = self.setup_review(Path(directory))
            verified = fixtures.ImportValidationTests().verified()
            row = review['revisoes'][0]
            row.update({'status': 'aprovado', 'pontoRealConfirmado': True, 'enderecoOperacionalConfirmado': True,
                'funcionamentoConfirmado': True, 'contatoConfirmado': True, 'revisadoPor': 'fixture-admin',
                'revisadoEm': verified['verificadoEm'], 'latitudeVerificada': verified['latitude'],
                'longitudeVerificada': verified['longitude'], 'fonteCoordenadas': verified['fonteCoordenadas'],
                'enderecoConfirmado': verified['endereco'], 'telefoneConfirmado': verified['telefone'],
                'fontesCampos': verified['fontesCampos'], 'observacoesValidacao': 'Evidência artificial exclusiva deste teste local.',
                'pendencias': []})
            write_json(args.review, review)
            export_approved(args)
            self.assertTrue(load_records(args.output)[0]['coordenadasVerificadas'])
            report = read_json(args.report)
            report['unidades'][0]['candidatos'] = [{'candidatoId': 'alterado'}]
            write_json(args.report, report)
            with self.assertRaises(ValueError): export_approved(args)


if __name__ == '__main__':
    unittest.main()
