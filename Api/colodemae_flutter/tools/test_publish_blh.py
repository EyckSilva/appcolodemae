"""Prévia real como fixture; aprovação e timestamps só simulados nestes testes."""
import copy
import datetime as dt
import unittest

from publish_blh import (DIRECTORY, read_json, validate_authorization, make_patch,
                         check_point, UpdateConflict, digest)


class PublicationTests(unittest.TestCase):
    def setUp(self):
        self.plan = read_json(DIRECTORY / 'previa-02/plano.json')
        self.approval = read_json(DIRECTORY / 'previa-02/autorizacao.pendente.json')

    def allow_fixture(self):
        approval = copy.deepcopy(self.approval)
        approval.update({'autorizacaoExplicita': True, 'autorizadoPor': 'fixture-responsavel',
            'autorizadoEm': dt.datetime.now(dt.timezone.utc).isoformat()})
        for row in approval['unidades']:
            row.update({'publicarDocumento': True, 'aprovarCoordenadas': True,
                        'confirmoPontoDoEstabelecimentoMantenedor': True})
        return approval

    def test_real_manual_points_and_independent_comparison_do_not_imply_approval(self):
        self.assertEqual(len(self.plan['unidades']), 3)
        self.assertFalse(self.plan['gravacaoExecutada'])
        self.assertTrue(all(row['conferenciaGeografica']['resultado'] == 'compativel_com_estabelecimento' for row in self.plan['unidades']))
        for row in self.plan['unidades']:
            self.assertFalse(row['antes']['publicado'])
            self.assertFalse(row['antes']['coordenadasVerificadas'])
        with self.assertRaises(UpdateConflict): validate_authorization(self.plan, self.approval)

    def test_responsible_confirmation_is_required_for_host_establishment_points(self):
        approval = self.allow_fixture()
        decisions = validate_authorization(self.plan, approval)
        self.assertEqual(len(decisions), 3)
        next(r for r in approval['unidades'] if 'marly' not in r['id'])['confirmoPontoDoEstabelecimentoMantenedor'] = False
        with self.assertRaises(UpdateConflict): validate_authorization(self.plan, approval)

    def test_tampered_plan_unknown_ids_and_divergent_point_are_rejected(self):
        approval = self.allow_fixture()
        plan = copy.deepcopy(self.plan)
        plan['unidades'][0]['coordenadasFornecidas']['latitude'] = 0
        with self.assertRaises(UpdateConflict): validate_authorization(plan, approval)
        approval['unidades'][0]['id'] = 'unknown'
        with self.assertRaises(UpdateConflict): validate_authorization(self.plan, approval)
        plan = copy.deepcopy(self.plan)
        plan['unidades'][0]['conferenciaGeografica']['resultado'] = 'divergente_bloqueado'
        plan['hashPlano'] = digest({k:v for k,v in plan.items() if k != 'hashPlano'})
        approval = self.allow_fixture()
        approval['hashPlano'] = plan['hashPlano']
        with self.assertRaises(UpdateConflict): validate_authorization(plan, approval)

    def test_document_and_geographic_approval_are_separate_and_existing_fields_survive(self):
        approval = self.allow_fixture()
        unit = self.plan['unidades'][0]
        decision = next(r for r in approval['unidades'] if r['id'] == unit['id'])
        before = {**unit['antes'], 'campoLegado': 'preservar', 'criadoEm': 'original'}
        timestamp = dt.datetime.now(dt.timezone.utc)
        patch = make_patch(before, unit, decision, self.plan, approval, timestamp)
        merged = {**before, **patch}
        self.assertEqual(merged['campoLegado'], 'preservar')
        self.assertEqual(merged['criadoEm'], 'original')
        self.assertEqual(merged['latitude'], unit['coordenadasFornecidas']['latitude'])
        self.assertTrue(merged['coordenadasVerificadas'])
        self.assertEqual(merged['aprovacaoDocumental']['status'], 'aprovado')
        self.assertEqual(merged['historicoValidacaoAnterior'][-1]['dadosAnteriores'], unit['antes'])
        self.assertEqual(make_patch(merged, unit, decision, self.plan, approval, timestamp), {})
        decision['aprovarCoordenadas'] = False
        patch = make_patch(before, unit, decision, self.plan, approval, timestamp)
        self.assertTrue(patch['publicado'])
        self.assertFalse(patch['coordenadasVerificadas'])
        self.assertNotIn('latitude', patch)
        self.assertEqual(patch['aprovacaoGeografica']['status'], 'pendente')

    def test_already_verified_missing_and_modified_records_are_protected(self):
        approval = self.allow_fixture()
        unit = self.plan['unidades'][0]
        decision = next(r for r in approval['unidades'] if r['id'] == unit['id'])
        for existing in (None, {**unit['antes'], 'coordenadasVerificadas': True}):
            with self.assertRaises(UpdateConflict): make_patch(existing, unit, decision, self.plan, approval, dt.datetime.now(dt.timezone.utc))
        applied = {**unit['antes'], **make_patch(unit['antes'], unit, decision, self.plan, approval, dt.datetime.now(dt.timezone.utc))}
        applied['telefone'] = 'alteracao posterior'
        with self.assertRaises(UpdateConflict): make_patch(applied, unit, decision, self.plan, approval, dt.datetime.now(dt.timezone.utc))

    def test_point_outside_maternity_polygon_is_blocked_not_city_centroid(self):
        manual = read_json(DIRECTORY / 'coordenadas-responsavel.json')['unidades']
        point = copy.deepcopy(next(r for r in manual if r['cnesEstabelecimento'] == '4099206'))
        official = read_json(DIRECTORY / 'demas-atual.json')[point['cnesEstabelecimento']]
        point['latitude'] = -10.90
        self.assertEqual(check_point(point, official)['resultado'], 'divergente_bloqueado')

    def test_sdk_serializes_history_without_server_timestamp_inside_array(self):
        from firebase_admin import firestore
        from google.cloud.firestore_v1 import _helpers
        approval = self.allow_fixture()
        for unit in self.plan['unidades']:
            decision = next(r for r in approval['unidades'] if r['id'] == unit['id'])
            patch = make_patch(unit['antes'], unit, decision, self.plan, approval, firestore.SERVER_TIMESTAMP)
            history_date = patch['historicoValidacaoAnterior'][-1]['registradoEm']
            self.assertIsInstance(history_date, dt.datetime)
            writes = _helpers.pbs_for_update(
                'projects/test/databases/(default)/documents/bancos_leite/' + unit['id'], patch, None)
            self.assertEqual(len(writes), 1)


if __name__ == '__main__': unittest.main()
