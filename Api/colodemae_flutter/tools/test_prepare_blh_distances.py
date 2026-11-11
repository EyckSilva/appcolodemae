"""Pontos artificiais em arquivos temporários; nunca altera a fonte do aplicativo."""
import datetime as dt
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace

from geocode_blh import ROOT, digest, read_json, write_json, review_template
from prepare_blh_distances import prepare, export


class DistancePreparationTests(unittest.TestCase):
    def review(self, folder, approve=False):
        raw = read_json(ROOT / 'data/blh/sergipe.json')[:1]
        identifier = 'se-blh-marly-sarney'
        report = {'hashBase': digest(raw), 'hashEnderecos': digest([]), 'provedor': 'https://fixture.example/api/',
            'unidades': [{'id': identifier, 'candidatos': [], 'pendencias': []}]}
        report['hashRevisao'] = digest(report)
        review = review_template(report)
        if approve:
            source = 'https://saude.gov.br/fixture'
            review['revisoes'][0].update({'status': 'aprovado', 'pontoRealConfirmado': True,
                'enderecoOperacionalConfirmado': True, 'funcionamentoConfirmado': True, 'contatoConfirmado': True,
                'revisadoPor': 'fixture-admin', 'revisadoEm': dt.datetime.now(dt.timezone.utc).isoformat(),
                'latitudeVerificada': 0, 'longitudeVerificada': 1, 'fonteCoordenadas': source,
                'enderecoConfirmado': 'Endereço artificial exclusivo de teste, 10', 'telefoneConfirmado': '(79) 9999-8888',
                'fontesCampos': {field: source for field in ('nome', 'tipo', 'endereco', 'cidade', 'estado', 'telefone', 'situacao')},
                'observacoesValidacao': 'Evidência artificial apenas para validar a exportação em teste.', 'pendencias': []})
        for name, data in [('base', raw), ('report', report), ('review', review)]: write_json(folder / f'{name}.json', data)
        return SimpleNamespace(base=folder / 'base.json', report=folder / 'report.json',
            review=folder / 'review.json', output=folder / 'points.json')

    def test_queue_preserves_source_status_and_rejected_history(self):
        original = (ROOT / 'data/blh/sergipe.json').read_bytes()
        history = (ROOT / 'data/blh/geografia/sergipe.aprovacao-manual.json').read_bytes()
        with tempfile.TemporaryDirectory() as directory:
            folder = Path(directory) / 'queue'
            prepare(folder)
            rows = read_json(folder / 'base.json')
            self.assertEqual(len(rows), 3)
            self.assertTrue(all(not row['ativo'] and not row['coordenadasVerificadas'] for row in rows))
            self.assertTrue(all('latitude' not in row for row in rows))
            with self.assertRaises(ValueError): prepare(folder)
        self.assertEqual((ROOT / 'data/blh/sergipe.json').read_bytes(), original)
        self.assertEqual((ROOT / 'data/blh/geografia/sergipe.aprovacao-manual.json').read_bytes(), history)

    def test_pending_and_rejected_reviews_never_export_coordinates(self):
        with tempfile.TemporaryDirectory() as directory:
            args = self.review(Path(directory))
            with self.assertRaises(ValueError): export(args)
            decision = read_json(args.review)
            decision['revisoes'][0]['status'] = 'rejeitado'
            write_json(args.review, decision)
            with self.assertRaises(ValueError): export(args)
            self.assertFalse(args.output.exists())

    def test_manual_export_contains_audit_and_no_publication_fields(self):
        with tempfile.TemporaryDirectory() as directory:
            args = self.review(Path(directory), approve=True)
            before = args.base.read_bytes()
            export(args)
            points = read_json(args.output)
            self.assertEqual(points[0]['id'], 'se-blh-marly-sarney')
            self.assertTrue(points[0]['coordenadasVerificadas'])
            self.assertIn('aprovacaoManual', points[0])
            for key in ('ativo', 'publicado', 'nome', 'endereco'): self.assertNotIn(key, points[0])
            self.assertEqual(args.base.read_bytes(), before)
            with self.assertRaises(ValueError): export(args)


if __name__ == '__main__': unittest.main()
