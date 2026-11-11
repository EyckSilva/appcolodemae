"""Prévia real e publicação transacional somente após autorização explícita.

Usa o helper/credenciais temporárias e a coleção existentes. Nenhuma alteração no Auth.
"""
import argparse
import datetime as dt
import math
from pathlib import Path

from geocode_blh import ROOT, read_json, digest
from import_blh import initialize_db, json_safe, geohash, content_hash, parse_date, normalize, UpdateConflict

DIRECTORY = ROOT / 'data/blh/publicacao-aracaju'


def save(path, value):
    import json
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open('x', encoding='utf-8') as stream:
        json.dump(json_safe(value), stream, ensure_ascii=False, indent=2)
        stream.write('\n')


def meters(a, b):
    lat1, lat2 = map(math.radians, (a['latitude'], b['latitude']))
    dlon = math.radians(b['longitude'] - a['longitude'])
    value = math.sin((lat2-lat1)/2)**2 + math.cos(lat1)*math.cos(lat2)*math.sin(dlon/2)**2
    return 6371000*2*math.asin(min(1, math.sqrt(value)))


def inside(point, ring):
    hit = False
    x, y = point['longitude'], point['latitude']
    for (ax, ay), (bx, by) in zip(ring, ring[1:]):
        if (ay > y) != (by > y) and x < (bx-ax)*(y-ay)/(by-ay)+ax: hit = not hit
    return hit


def check_point(point, demas):
    if any(type(point.get(k)) not in (int, float) or not math.isfinite(point[k]) for k in ('latitude', 'longitude')):
        raise ValueError('Coordenadas inválidas.')
    if abs(point['latitude']) > 90 or abs(point['longitude']) > 180: raise ValueError('Coordenadas fora dos limites.')
    props = demas['dados']
    if str(props['codigo_cnes']).zfill(7) != point['cnesEstabelecimento'] or props['codigo_municipio'] != 280030 or props['codigo_uf'] != 28:
        raise ValueError('CNES/município/UF não correspondem ao estabelecimento.')
    official = {'latitude': props['latitude_estabelecimento_decimo_grau'], 'longitude': props['longitude_estabelecimento_decimo_grau']}
    difference = meters(point, official)
    cnes = point['cnesEstabelecimento']
    remarks = []
    evidence = [demas['url']]
    if cnes == '0002569':
        compatible = difference <= 25 and 'marly sarney' in normalize(props['nome_fantasia'])
        criterion = 'Coincidência com o cadastro próprio atual do BLH (tolerância de comparação 25 m, não precisão certificada)'
        remarks.append('Séries históricas divergentes não foram escolhidas como coordenada atual; a tolerância não é margem de erro GPS.')
    else:
        way_id = 841076721 if cnes == '4099206' else 292330063
        source = read_json(DIRECTORY / f'osm-way-{way_id}.json')
        elements = source['resposta']['elements']
        nodes = {e['id']: (e['lon'], e['lat']) for e in elements if e['type'] == 'node'}
        way = next(e for e in elements if e['type'] == 'way' and e['id'] == way_id)
        ring = [nodes[node] for node in way['nodes']]
        expected = 'Maternidade do 17 de Março' if cnes == '4099206' else 'Hospital Santa Isabel'
        compatible = inside(point, ring) and way.get('tags', {}).get('name') == expected
        criterion = f'Ponto dentro do polígono OSM do prédio {expected}; conferência do estabelecimento mantenedor'
        evidence.append(source['fonte'])
        remarks.append('Ponto do estabelecimento mantenedor; não confirma sala, porta ou cadastro CNES exclusivo do posto.')
        if cnes == '4099206':
            remarks.append('DEMAS usa s/n e Prefeitura usa nº 64; a referência OSM é Avenida João Batista Costa. Mesmo prédio, divergência de numeração/referência viária mantida no histórico. Não confirma acesso ao posto.')
        else:
            remarks.append('Coordenada DEMAS distante foi rejeitada para esta proposta. O cadastro oficial e a AAB informam Avenida Simeão Sobral, 1312; via OSM próxima é Rua Deodato Maia, sem validação de acesso específico.')
    return {'resultado': 'compativel_com_estabelecimento' if compatible else 'divergente_bloqueado',
        'aprovacaoGeografica': 'pendente_autorizacao_responsavel', 'criterio': criterion,
        'distanciaAoPontoCadastralDemasMetros': round(difference, 2), 'fontes': evidence,
        'ressalvas': remarks, 'origem': 'fornecida_responsavel_projeto', 'servicoInformado': 'Google Maps',
        'linkConferenciaGerado': f"https://www.google.com/maps/search/?api=1&query={point['latitude']},{point['longitude']}"}


def proposed_data(existing, local):
    """Todos os campos propostos são mostrados na prévia; campos desconhecidos persistem."""
    keys = ('nome', 'tipo', 'cidade', 'estado', 'endereco', 'cep', 'telefone', 'horarioFuncionamento', 'descricaoTelefone')
    desired = {key: local[key] for key in keys if key in local}
    desired.update({'cnesEstabelecimento': local['cnes'], 'relacaoCnes': local['relacao'],
        'cidadeBusca': normalize(local['cidade'])})
    # Fonte original da unidade não é substituída pela fonte do hospital mantenedor.
    desired['fonte'] = existing.get('fonte') or local['fonte']
    sources = dict(existing.get('fontesCampos', {}))
    for field in ('endereco', 'telefone', 'horarioFuncionamento'):
        origin = {'endereco': 'fonteEndereco', 'telefone': 'fonteTelefone', 'horarioFuncionamento': 'fonteHorario'}[field]
        sources[field] = local.get(origin, local['fonte'])
    desired['fontesCampos'] = sources
    return desired


def preview(args):
    if args.output.exists(): raise ValueError('Use pasta nova para preservar a prévia anterior.')
    manual = read_json(DIRECTORY / 'coordenadas-responsavel.json')
    local = {r['id']: r for r in read_json(ROOT / 'assets/blh_demo/unidades-aracaju.json')}
    official = read_json(DIRECTORY / 'demas-atual.json')
    db = initialize_db(args.project, args.firebase_cli_auth)
    from google.cloud.firestore_v1.base_query import FieldFilter
    all_city = list(db.collection('bancos_leite').where(filter=FieldFilter('cidadeBusca', '==', 'aracaju')).stream())
    snapshots = {s.id: s for s in all_city}
    units = []
    for point in manual['unidades']:
        identifier = point['id']
        snapshot = snapshots.get(identifier)
        if snapshot is None: raise UpdateConflict('Documento existente não encontrado: ' + identifier)
        existing = snapshot.to_dict()
        if local[identifier]['cnes'] != point['cnesEstabelecimento'] or local[identifier]['relacao'] != point['relacaoCnes']:
            raise UpdateConflict('CNES/vínculo divergente do registro documental.')
        if normalize(existing.get('nome', '')) != normalize(local[identifier]['nome']):
            raise UpdateConflict('Nome do documento foi alterado; revisar identidade antes de propor atualização.')
        duplicates = [s.id for s in all_city if s.id != identifier and normalize(s.to_dict().get('nome', '')) == normalize(local[identifier]['nome'])]
        if duplicates: raise UpdateConflict('Possível duplicata; revisar antes de publicar: ' + str(duplicates))
        if existing.get('coordenadasVerificadas') and any(existing.get(k) != point[k] for k in ('latitude', 'longitude')):
            raise UpdateConflict('Coordenadas aprovadas diferentes; não sobrescrever: ' + identifier)
        comparison = check_point(point, official[point['cnesEstabelecimento']])
        desired = proposed_data(existing, local[identifier])
        units.append({'id': identifier, 'cnesEstabelecimento': point['cnesEstabelecimento'],
            'relacaoCnes': point['relacaoCnes'], 'versaoFirestoreEsperada': snapshot.update_time.isoformat(),
            'antes': json_safe(existing), 'dadosRevisadosPropostos': desired,
            'mudancasDados': {key: {'antes': json_safe(existing.get(key)), 'depois': value}
                for key, value in desired.items() if json_safe(existing.get(key)) != value},
            'coordenadasFornecidas': {key: point[key] for key in ('latitude', 'longitude')},
            'conferenciaGeografica': comparison,
            'camposPublicacaoPropostosAposAutorizacao': {'ativo': True, 'publicado': True, 'verificacao': 'verificado',
                'aprovacaoDocumental': 'aprovado_pelo_responsavel', 'coordenadasVerificadas': 'somente_se_aprovadas_explicitamente',
                'verificadoEm': 'data da autorização documental, gravada como Timestamp',
                'geohash': geohash(point['latitude'], point['longitude'])}})
    plan = {'projeto': args.project, 'colecao': 'bancos_leite', 'preparadoEm': dt.datetime.now(dt.timezone.utc).isoformat(),
        'origemCoordenadas': manual['origem'], 'origemGoogleMapsCertificadaPelaAPI': False,
        'gravacaoExecutada': False, 'quantidadeDocumentosExistentes': len(all_city), 'unidades': units}
    plan['hashPlano'] = digest(plan)
    save(args.output / 'plano.json', plan)
    save(args.output / 'autorizacao.pendente.json', {'hashPlano': plan['hashPlano'], 'autorizacaoExplicita': False,
        'autorizadoPor': None, 'autorizadoEm': None, 'unidades': [{'id': row['id'], 'publicarDocumento': False,
            'aprovarCoordenadas': False, 'confirmoPontoDoEstabelecimentoMantenedor': False} for row in units]})
    print(f'{len(units)} documentos existentes conferidos; prévia salva em {args.output}; nenhuma gravação.')


def validate_authorization(plan, approval):
    expected = digest({k: v for k, v in plan.items() if k != 'hashPlano'})
    if plan.get('hashPlano') != expected or approval.get('hashPlano') != expected: raise UpdateConflict('Plano alterado ou autorização de outra versão.')
    if approval.get('autorizacaoExplicita') is not True: raise UpdateConflict('Gravação exige autorização explícita posterior à prévia.')
    if len((approval.get('autorizadoPor') or '').strip()) < 3: raise UpdateConflict('Identifique o responsável pela autorização.')
    date = parse_date(approval.get('autorizadoEm'), 'autorizadoEm')
    if date < parse_date(plan['preparadoEm'], 'preparadoEm'): raise UpdateConflict('Autorização anterior à prévia.')
    decisions = approval.get('unidades', [])
    if len({r['id'] for r in decisions}) != len(decisions) or {r['id'] for r in decisions} != {r['id'] for r in plan['unidades']}:
        raise UpdateConflict('Decisões duplicadas ou IDs divergentes.')
    for unit in plan['unidades']:
        decision = next(r for r in decisions if r['id'] == unit['id'])
        if type(decision.get('publicarDocumento')) is not bool or type(decision.get('aprovarCoordenadas')) is not bool:
            raise UpdateConflict('Decisões devem ser booleanas explícitas.')
        if decision['aprovarCoordenadas']:
            if not decision['publicarDocumento'] or unit['conferenciaGeografica']['resultado'] != 'compativel_com_estabelecimento':
                raise UpdateConflict('Ponto divergente ou documento não autorizado; não aprovar coordenadas.')
            if unit['relacaoCnes'] == 'mantenedora' and decision.get('confirmoPontoDoEstabelecimentoMantenedor') is not True:
                raise UpdateConflict('Confirmar que o ponto é do estabelecimento mantenedor, sem presumir cadastro exclusivo do posto.')
    if not any(r['publicarDocumento'] for r in decisions): raise UpdateConflict('Nenhum documento autorizado para publicação.')
    return {r['id']: r for r in decisions}


def make_patch(existing, unit, decision, plan, approval, timestamp):
    if existing is None: raise UpdateConflict('Documento ausente; nunca criar duplicata.')
    if not decision['publicarDocumento']: return {}
    if existing.get('ultimaPublicacaoControlada', {}).get('hashPlano') == plan['hashPlano']:
        same_geography = existing.get('coordenadasVerificadas') == decision['aprovarCoordenadas']
        if decision['aprovarCoordenadas']:
            same_geography = same_geography and all(existing.get(k) == v for k, v in unit['coordenadasFornecidas'].items())
            same_geography = same_geography and existing.get('geohash') == geohash(unit['coordenadasFornecidas']['latitude'], unit['coordenadasFornecidas']['longitude'])
        if all(existing.get(k) == v for k, v in unit['dadosRevisadosPropostos'].items()) and existing.get('ativo') is True and existing.get('publicado') is True and same_geography:
            return {}
        raise UpdateConflict('Documento alterado depois da publicação; não sobrescrever.')
    if existing.get('coordenadasVerificadas'):
        raise UpdateConflict('Registro já tem coordenadas aprovadas; não sobrescrever por esta proposta.')
    patch = dict(unit['dadosRevisadosPropostos'])
    patch.update({'ativo': True, 'publicado': True, 'verificacao': 'verificado',
        'verificadoEm': parse_date(approval['autorizadoEm'], 'autorizadoEm'),
        'aprovacaoDocumental': {'status': 'aprovado', 'aprovadoPor': approval['autorizadoPor'], 'aprovadoEm': timestamp,
            'fontes': patch['fontesCampos']},
        'historicoValidacaoAnterior': [*existing.get('historicoValidacaoAnterior', []),
            {'hashPlano': plan['hashPlano'], 'registradoEm': parse_date(approval['autorizadoEm'], 'autorizadoEm'),
             'dadosAnteriores': unit['antes']}],
        'ultimaPublicacaoControlada': {'hashPlano': plan['hashPlano'], 'responsavel': approval['autorizadoPor'],
            'autorizadoEm': approval['autorizadoEm']}, 'atualizadoEm': timestamp})
    geographic = decision['aprovarCoordenadas']
    patch['coordenadasVerificadas'] = geographic
    patch['aprovacaoGeografica'] = {'status': 'aprovado' if geographic else 'pendente',
        'origem': plan['origemCoordenadas'], 'servicoInformado': 'Google Maps',
        'escopo': unit['relacaoCnes'], 'conferenciaPrevia': unit['conferenciaGeografica'],
        'aprovadoPor': approval['autorizadoPor'] if geographic else None,
        'aprovadoEm': timestamp if geographic else None}
    if geographic:
        patch.update(unit['coordenadasFornecidas'])
        patch.update({'geohash': geohash(patch['latitude'], patch['longitude']),
            'fonteCoordenadas': unit['conferenciaGeografica']['linkConferenciaGerado'],
            'coordenadasVerificadasEm': timestamp, 'pendencias': []})
    else:
        patch['pendencias'] = ['Coordenadas aguardam aprovação geográfica; não calcular distância.']
    patch['hashConteudo'] = content_hash({**existing, **patch})
    return patch


def apply(args):
    plan, approval = read_json(args.plan), read_json(args.approval)
    if args.project != plan['projeto']: raise UpdateConflict('Projeto diferente do revisado.')
    decisions = validate_authorization(plan, approval)
    if args.output.exists(): raise ValueError('Use nova saída de auditoria.')
    from firebase_admin import firestore
    db = initialize_db(args.project, args.firebase_cli_auth)
    refs = [db.collection('bancos_leite').document(unit['id']) for unit in plan['unidades']]
    @firestore.transactional
    def commit(transaction):
        snapshots = {s.id: s for s in db.get_all(refs, transaction=transaction)}
        prepared = []
        for unit in plan['unidades']:
            snapshot = snapshots[unit['id']]
            existing = snapshot.to_dict() if snapshot.exists else None
            patch = make_patch(existing, unit, decisions[unit['id']], plan, approval, firestore.SERVER_TIMESTAMP)
            if patch and snapshot.update_time.isoformat() != unit['versaoFirestoreEsperada']:
                raise UpdateConflict('Mudança concorrente: gerar nova prévia antes de gravar.')
            prepared.append((unit['id'], patch))
        for identifier, patch in prepared:
            if patch: transaction.update(db.collection('bancos_leite').document(identifier), patch)
        return [{'id': identifier, 'acao': 'update' if patch else 'unchanged'} for identifier, patch in prepared]
    actions = commit(db.transaction())
    save(args.output, {'hashPlano': plan['hashPlano'], 'autorizacao': approval, 'acoes': actions,
        'gravacaoExecutada': any(a['acao'] == 'update' for a in actions)})
    print('Transação concluída conforme autorização; auditoria salva.')


def verify(args):
    """Independent server readback; never writes documents."""
    from google.cloud.firestore_v1.base_query import FieldFilter
    plan, approval = read_json(args.plan), read_json(args.approval)
    if args.project != plan['projeto']: raise UpdateConflict('Projeto diferente do revisado.')
    decisions = validate_authorization(plan, approval)
    db = initialize_db(args.project, args.firebase_cli_auth)
    collection = db.collection('bancos_leite')
    snapshots = list(collection.stream())
    actual = {s.id: s.to_dict() for s in snapshots}
    expected_ids = {u['id'] for u in plan['unidades'] if decisions[u['id']]['publicarDocumento']}
    checks = {}
    for unit in plan['unidades']:
        identifier = unit['id']
        current = actual.get(identifier)
        if not current: raise UpdateConflict('Documento ausente: ' + identifier)
        expected = make_patch(current, unit, decisions[identifier], plan, approval, None)
        checks[identifier] = {
            'publicacaoIdempotente': expected == {},
            'dadosRevisadosPreservados': all(current.get(k) == v for k, v in unit['dadosRevisadosPropostos'].items()),
            'criadoEmPreservado': json_safe(current.get('criadoEm')) == unit['antes'].get('criadoEm'),
            'historicoAnteriorPreservado': any(h.get('hashPlano') == plan['hashPlano'] and h.get('dadosAnteriores') == unit['antes'] for h in current.get('historicoValidacaoAnterior', [])),
            'aprovacaoDocumental': current.get('aprovacaoDocumental', {}).get('status') == 'aprovado',
            'aprovacaoGeografica': current.get('aprovacaoGeografica', {}).get('status') == 'aprovado',
            'timestampServidor': isinstance(current.get('coordenadasVerificadasEm'), dt.datetime),
        }
        if not all(checks[identifier].values()): raise UpdateConflict('Falha na leitura: ' + identifier + str(checks[identifier]))
    query = collection
    for key, value in [('ativo', True), ('publicado', True), ('cidadeBusca', 'aracaju'), ('estado', 'SE')]:
        query = query.where(filter=FieldFilter(key, '==', value))
    city_ids = [s.id for s in query.order_by('__name__').limit(50).stream()]
    if set(city_ids) != expected_ids: raise UpdateConflict('Consulta municipal divergente: ' + str(city_ids))
    untouched = {k: v for k, v in actual.items() if k not in expected_ids}
    if any(v.get('ativo') or v.get('publicado') for v in untouched.values()):
        raise UpdateConflict('Registro externo publicado; investigar sem alterar.')
    if len({normalize(actual[k]['nome']) for k in expected_ids}) != len(expected_ids):
        raise UpdateConflict('Nomes duplicados.')
    save(args.output, {'projeto': args.project, 'consultadoEm': dt.datetime.now(dt.timezone.utc),
        'somenteLeitura': True, 'hashPlano': plan['hashPlano'], 'verificacoes': checks,
        'consultaMunicipalIds': city_ids, 'totalDocumentosColecao': len(snapshots),
        'documentos': actual, 'versoes': {s.id: s.update_time for s in snapshots},
        'registrosExternosInativos': list(untouched), 'aprovado': True})
    print(f'Leitura real confirmada: {len(city_ids)} publicados na consulta municipal; {len(untouched)} externos inativos; nenhuma escrita.')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest='command', required=True)
    before = sub.add_parser('preview')
    before.add_argument('--output', type=Path, required=True)
    after = sub.add_parser('apply')
    after.add_argument('--plan', type=Path, required=True)
    after.add_argument('--approval', type=Path, required=True)
    after.add_argument('--output', type=Path, required=True)
    check = sub.add_parser('verify')
    check.add_argument('--plan', type=Path, required=True)
    check.add_argument('--approval', type=Path, required=True)
    check.add_argument('--output', type=Path, required=True)
    for command in (before, after, check):
        command.add_argument('--project', required=True)
        command.add_argument('--firebase-cli-auth', action='store_true', help=argparse.SUPPRESS)
    args = parser.parse_args()
    if args.command == 'preview': preview(args)
    elif args.command == 'apply': apply(args)
    else: verify(args)


if __name__ == '__main__': main()
