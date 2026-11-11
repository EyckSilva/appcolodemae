"""DEMAS/CNES administrativo: coleta auditável e atualização manual de rascunhos.

Sem chamadas no Flutter, sem publicação, sem criação de documentos ou mudanças no Auth.
"""
import argparse
import datetime as dt
import hashlib
import json
import re
import time
import urllib.parse
import urllib.request
from pathlib import Path

from import_blh import (normalize, official_url, parse_date, json_safe, initialize_db,
                        content_hash, UpdateConflict)
from geocode_blh import ROOT, read_json, write_json, digest
from blh_preservation import preserved

BASE_URL = 'https://apidadosabertos.saude.gov.br'
DIRECTORY = ROOT / 'data/blh/demas'
SERVICES = '/assistencia-a-saude/cnes-servicos-especializados'


def cnes(value):
    if type(value) not in (int, str) or not re.fullmatch(r'\d{1,7}', str(value)):
        raise ValueError('CNES inválido; não converter booleanos nem códigos com mais de 7 dígitos.')
    return str(value).zfill(7)


def preserve():
    hashes = read_json(DIRECTORY / 'preservacao.sha256.json')
    changed = [p for p, sha in hashes.items() if not preserved(ROOT, p, sha)]
    if changed: raise ValueError(f'Fontes ou protótipo alterados: {changed}')
    return len(hashes)


class DemasClient:
    def __init__(self, cache, online=False, refresh=False):
        self.cache, self.online, self.refresh = cache, online, refresh
        self.schema = read_json(DIRECTORY / 'swagger.json')
        self.requests, self.last = 0, 0.
        cache.mkdir(parents=True, exist_ok=True)

    def get(self, path, params=None):
        params = params or {}
        template = '/cnes/estabelecimentos/{codigo_cnes}' if re.fullmatch(r'/cnes/estabelecimentos/\d{7}', path) else path
        if template not in self.schema['paths']: raise ValueError('Endpoint não documentado no Swagger oficial.')
        allowed = {p['name'] for p in self.schema['paths'][template]['get'].get('parameters', []) if p['in'] == 'query'}
        if set(params) - allowed: raise ValueError('Filtro não documentado: não confiar em parâmetros ignorados pela API.')
        url = BASE_URL + path + ('?' + urllib.parse.urlencode(params) if params else '')
        cached = self.cache / (digest(url) + '.json')
        if cached.exists() and not self.refresh:
            result = read_json(cached)
            if result['url'] != url or result['hashResposta'] != digest(result['dados']): raise ValueError('Cache DEMAS inconsistente.')
            return result
        if not self.online: raise ValueError('Consulta não encontrada no cache. Use collect --online explicitamente.')
        if self.requests >= 100: raise ValueError('Limite conservador de 100 consultas atingido; não insistir.')
        time.sleep(max(0, .5 - (time.monotonic() - self.last)))
        self.last = time.monotonic()
        self.requests += 1
        with urllib.request.urlopen(urllib.request.Request(url, headers={'Accept': 'application/json',
                'User-Agent': 'ColoDeMae-DemasAdministrativeIntegration/1.0'}), timeout=30) as response:
            data = json.loads(response.read(8_000_000).decode('utf-8'))
        result = {'url': url, 'consultadoEm': dt.datetime.now(dt.timezone.utc).isoformat(),
                  'dados': data, 'hashResposta': digest(data)}
        write_json(cached, result)
        return result

    def pages(self, path, key, params, limit=1000):
        rows, sources, seen, offset = [], [], set(), 0
        # O offset real observado é de LINHAS, apesar do Swagger descrever páginas.
        # Não encerrar por len(página)<limit: serviços retornam páginas curtas.
        for _ in range(80):
            response = self.get(path, {**params, 'limit': limit, 'offset': offset})
            part = response['dados'].get(key)
            if not isinstance(part, list): raise ValueError('Envelope de paginação inesperado.')
            sources.append({k: response[k] for k in ('url', 'consultadoEm', 'hashResposta')})
            if not part: return rows, sources
            for row in part:
                identity = digest(row)
                if identity in seen: raise ValueError('Página repetida; interromper para não afirmar cobertura completa.')
                if 'co_cnes' in params and cnes(row.get('co_cnes')) != cnes(params['co_cnes']): raise ValueError('Filtro CNES não foi respeitado.')
                if 'co_ibge' in params and row.get('co_ibge') != params['co_ibge']: raise ValueError('Filtro município não foi respeitado.')
                if 'nu_comp' in params and row.get('nu_comp') != params['nu_comp']: raise ValueError('Filtro competência não foi respeitado.')
                seen.add(identity)
                rows.append(row)
            offset += len(part)
        raise ValueError('Paginação excedeu limite; relatório incompleto não será exportado como completo.')


def establishment(data, expected_cnes, terms):
    if cnes(data.get('codigo_cnes')) != expected_cnes: raise ValueError('CNES divergente no detalhe do estabelecimento.')
    if data.get('codigo_municipio') != 280030 or data.get('codigo_uf') != 28:
        raise ValueError('Estabelecimento não pertence a Aracaju/SE.')
    name = data.get('nome_fantasia')
    if not isinstance(name, str) or not all(term in normalize(name) for term in terms):
        raise ValueError('Nome não corresponde à unidade ou mantenedora documentada.')
    def text(key):
        value = data.get(key)
        if value is not None and not isinstance(value, str): raise ValueError(f'Campo textual inválido: {key}')
        return value.strip() if isinstance(value, str) and value.strip() else None
    address = ', '.join(filter(None, (text('endereco_estabelecimento'), text('numero_estabelecimento'), text('bairro_estabelecimento'))))
    phone_raw = text('numero_telefone_estabelecimento')
    phone_digits = re.sub(r'\D', '', phone_raw or '')
    # Não completar DDD nem publicar número institucional como contato direto do posto.
    phone = phone_raw if len(phone_digits) in (10, 11, 12, 13) and re.fullmatch(r'[0-9+().\s-]+', phone_raw) else None
    return {'cnes': expected_cnes, 'nomeEstabelecimento': name, 'endereco': address or None,
            'telefone': phone, 'telefoneOriginal': phone_raw, 'cep': text('codigo_cep_estabelecimento'),
            'cidade': 'Aracaju', 'estado': 'SE', 'codigoMunicipio': 280030,
            'atualizadoNaDemas': text('data_atualizacao'),
            'coordenadasCadastraisNaoVerificadas': {'latitude': data.get('latitude_estabelecimento_decimo_grau'),
                'longitude': data.get('longitude_estabelecimento_decimo_grau')}, 'horariosConfirmados': None}


def compare(old, recovered, relation):
    conflicts = []
    for field in ('endereco', 'telefone'):
        a, b = old.get(field), recovered.get(field)
        if a and b:
            equal = re.sub(r'\D', '', a) == re.sub(r'\D', '', b) if field == 'telefone' else normalize(a) == normalize(b)
            if not equal: conflicts.append({'campo': field, 'anterior': a, 'demas': b})
    if relation == 'mantenedora':
        conflicts.append({'campo': 'escopo', 'anterior': old['nome'], 'demas': recovered['nomeEstabelecimento'],
            'observacao': 'Cadastro da instituição mantenedora não comprova contato/endereço específico do posto.'})
    return conflicts


def collect(args):
    preserve()
    if args.output.exists(): raise ValueError('Use diretório novo para preservar fontes/decisões.')
    client = DemasClient(args.cache, args.online, args.refresh)
    units = read_json(DIRECTORY / 'vinculos-aracaju.json')
    original = {f"se-{r['chaveUnidade']}": r for r in read_json(ROOT / 'data/blh/sergipe.json')}
    geographical = {row['id']: row for row in read_json(ROOT / 'data/blh/geografia/enderecos-pesquisa.json')}
    output = []
    for link in units:
        old = original[link['id']]
        detail = client.get('/cnes/estabelecimentos/' + link['cnes'])
        recovered = establishment(detail['dados'], link['cnes'], link['termosNome'])
        # Série completa do Marly identifica a última competência disponível sem inventar mês atual.
        if link['relacao'] == 'proprio':
            series = client.get(SERVICES, {'co_cnes': link['cnes'], 'limit': 1000, 'offset': 0})
            competencies = [row['nu_comp'] for row in series['dados']['cnes_servicos_especializados'] if cnes(row['co_cnes']) == link['cnes']]
            competence = max(competencies) if competencies else None
        else:
            competence = output[0]['competenciaServicos']
        services, pages = client.pages(SERVICES, 'cnes_servicos_especializados',
            {'co_cnes': link['cnes'], 'co_ibge': 280030, 'nu_comp': competence}) if competence else ([], [])
        milk = [row for row in services if 'leite' in normalize(row.get('ds_servico', '') + ' ' + row.get('ds_classificacao', ''))]
        history = client.get('/assistencia-a-saude/cnes-estabelecimentos', {'co_cnes': link['cnes'], 'limit': 2, 'offset': 0})
        conflicts = compare(old, recovered, link['relacao'])
        for prior in history['dados']['cnes_estabelecimentos']:
            if cnes(prior.get('co_cnes')) != link['cnes'] or prior.get('co_ibge') != 280030:
                raise ValueError('Filtro de estabelecimento histórico não foi respeitado.')
            previous_point = {'latitude': prior.get('nu_latitude'), 'longitude': prior.get('nu_longitude')}
            if all(value is not None for value in previous_point.values()) and previous_point != recovered['coordenadasCadastraisNaoVerificadas']:
                conflicts.append({'campo': 'coordenadasCadastrais', 'competenciaHistorica': prior['nu_comp'],
                    'anterior': previous_point, 'demas': recovered['coordenadasCadastraisNaoVerificadas'],
                    'observacao': 'Pontos diferentes entre séries; nenhum deles foi validado como localização operacional.'})
        research_address = geographical[link['id']]['enderecoPesquisa']
        number = re.search(r',\s*(\d+)\s*,', research_address)
        if number and str(detail['dados'].get('numero_estabelecimento')).strip() != number.group(1):
            conflicts.append({'campo': 'numeroEnderecoPesquisaAnterior', 'anterior': number.group(1),
                'demas': detail['dados'].get('numero_estabelecimento'),
                'fonteAnterior': geographical[link['id']]['fonteEndereco']})
        output.append({'id': link['id'], 'nomeUnidadePreservado': old['nome'], 'relacao': link['relacao'],
            'evidenciaVinculo': old['fonte'], 'recuperado': recovered,
            'fonte': {k: detail[k] for k in ('url', 'consultadoEm', 'hashResposta')},
            'competenciaServicos': competence, 'servicos': services, 'fontesServicos': pages,
            'codigosLeiteIdentificados': [{'servico': row['co_servico'], 'classificacao': row['co_classificacao'],
                'descricaoServico': row['ds_servico'], 'descricaoClassificacao': row['ds_classificacao']} for row in milk],
            'conflitos': conflicts,
            'amostraHistoricaEstabelecimento': history, 'ativo': False, 'publicado': False,
            'coordenadasVerificadas': False,
            'pendencias': ['Revisão humana do vínculo e de cada campo antes de atualizar',
                'Confirmar funcionamento e acesso operacional atuais',
                'Não tratar coordenadas cadastrais como GPS aprovado nem turno como horário de doação']})
    # Provas de filtros e de offset, mantidas com datas/URLs.
    probes = []
    for offset in (0, 1):
        probes.append(client.get('/cnes/estabelecimentos', {'codigo_municipio': 280030,
            'codigo_tipo_unidade': 5, 'limit': 2, 'offset': offset}))
    probes.append(client.get('/cnes/estabelecimentos', {'codigo_municipio': 999999, 'limit': 2, 'offset': 0}))
    probes.append(client.get('/cnes/tipounidades'))
    args.output.mkdir(parents=True)
    write_json(args.output / 'relatorio.json', {'unidades': output, 'provasFiltros': probes,
        'requisicoesHTTP': client.requests, 'hashSwagger': digest(client.schema),
        'gravacaoFirebase': False, 'arquivosPreservados': preserve()})
    write_json(args.output / 'revisao.pendente.json', {'hashRelatorio': digest(output), 'revisoes': [
        {'id': row['id'], 'cnes': row['recuperado']['cnes'], 'status': 'pendente', 'campos': [],
         'vinculoBlhConfirmado': False, 'conflitosRevisados': False, 'contatoConfirmado': False,
         'enderecoOperacionalConfirmado': False, 'revisadoPor': None, 'revisadoEm': None,
         'justificativa': None, 'fontesComplementares': [], 'valoresAnteriores': {}}
        for row in output]})
    print(f'{len(output)} vínculos documentais analisados; {client.requests} consultas DEMAS; nenhuma gravação Firebase.')


def plan_patch(existing, unit, decision):
    if existing is None: raise UpdateConflict('Documento inexistente; sincronização DEMAS nunca cria documentos.')
    if decision.get('status') not in ('pendente', 'rejeitado', 'aprovado'): raise UpdateConflict('Status de decisão inválido.')
    if decision['status'] != 'aprovado': return ('rejected' if decision['status'] == 'rejeitado' else 'pending'), {}
    if decision.get('id') != unit['id'] or decision.get('cnes') != unit['recuperado']['cnes']:
        raise UpdateConflict('Revisão não corresponde ao CNES/ID da unidade.')
    if existing.get('ativo') or existing.get('publicado') or existing.get('verificacao') == 'verificado':
        raise UpdateConflict('Registro publicado/verificado protegido; requer fluxo de nova verificação existente.')
    if existing.get('estado') != 'SE' or normalize(existing.get('cidade', '')) != 'aracaju': raise UpdateConflict('Localidade divergente no Firestore.')
    if existing.get('chaveUnidade') != unit['id'][3:] or normalize(existing.get('nome', '')) != normalize(unit['nomeUnidadePreservado']):
        raise UpdateConflict('Identidade do documento mudou desde a coleta.')
    for key in ('vinculoBlhConfirmado', 'conflitosRevisados'):
        if decision.get(key) is not True: raise UpdateConflict(f'Confirmação humana obrigatória: {key}')
    if len((decision.get('revisadoPor') or '').strip()) < 3 or len((decision.get('justificativa') or '').strip()) < 20:
        raise UpdateConflict('Revisor e justificativa documental obrigatórios.')
    reviewed = parse_date(decision.get('revisadoEm'), 'revisadoEm')
    if reviewed < parse_date(unit['fonte']['consultadoEm'], 'consulta'): raise UpdateConflict('Revisão anterior à coleta.')
    sources = decision.get('fontesComplementares')
    if not isinstance(sources, list) or not sources: raise UpdateConflict('Fonte oficial complementar do vínculo/contato obrigatória.')
    for source in sources: official_url(source)
    if not any(urllib.parse.urlparse(source).hostname != 'apidadosabertos.saude.gov.br' for source in sources):
        raise UpdateConflict('Usar fonte complementar independente da DEMAS para confirmar vínculo/contato operacional.')
    fields = decision.get('campos')
    if not isinstance(fields, list) or not fields or len(set(fields)) != len(fields) or set(fields) - {'telefone', 'endereco', 'demas'}:
        raise UpdateConflict('Selecionar somente telefone, endereco e/ou metadados demas.')
    desired = {}
    for field, flag in (('telefone', 'contatoConfirmado'), ('endereco', 'enderecoOperacionalConfirmado')):
        if field in fields:
            if decision.get(flag) is not True or not unit['recuperado'].get(field): raise UpdateConflict(f'{field} ausente ou não confirmado.')
            desired[field] = unit['recuperado'][field]
    metadata = {'cnes': unit['recuperado']['cnes'], 'relacao': unit['relacao'], 'fonte': unit['fonte'],
        'competenciaServicos': unit['competenciaServicos'], 'revisadoPor': decision['revisadoPor'],
        'revisadoEm': decision['revisadoEm'], 'justificativa': decision['justificativa'], 'fontesComplementares': sources}
    if 'demas' in fields: desired['demas'] = metadata
    # Repetição da mesma decisão não altera timestamps.
    if all(existing.get(field) == value for field, value in desired.items()): return 'unchanged', {}
    before = decision.get('valoresAnteriores', {})
    if any(field not in before or before[field] != existing.get(field) for field in desired):
        raise UpdateConflict('Valores anteriores divergentes/ausentes; reler e revisar antes de atualizar.')
    patch = {field: value for field, value in desired.items() if existing.get(field) != value}
    if any(field in patch for field in ('endereco', 'telefone')):
        patch['fontesCampos'] = {**existing.get('fontesCampos', {}),
            **{field: unit['fonte']['url'] for field in ('endereco', 'telefone') if field in patch}}
        patch['hashConteudo'] = content_hash({**existing, **patch})
    return 'update', patch


def sync(args):
    report = read_json(args.report)
    review = read_json(args.review)
    if review['hashRelatorio'] != digest(report['unidades']): raise ValueError('Relatório mudou desde a revisão.')
    decisions = {row['id']: row for row in review['revisoes']}
    if len(decisions) != len(review['revisoes']) or set(decisions) != {u['id'] for u in report['unidades']}:
        raise ValueError('Revisões duplicadas ou incompletas.')
    if args.output.exists(): raise ValueError('Use um novo arquivo de auditoria; não sobrescrever histórico.')
    db = initialize_db(args.project, args.firebase_cli_auth)
    planned = []
    for unit in report['unidades']:
        snapshot = db.collection('bancos_leite').document(unit['id']).get()
        action, patch = plan_patch(snapshot.to_dict() if snapshot.exists else None, unit, decisions[unit['id']])
        planned.append({'id': unit['id'], 'acao': action, 'patch': patch, 'versaoFirestore': snapshot.update_time})
    actions = []
    if args.apply:
        if not any(row.get('status') == 'aprovado' for row in decisions.values()):
            raise ValueError('Nenhuma atualização humana autorizada; nada a aplicar.')
        from firebase_admin import firestore
        for unit in report['unidades']:
            ref = db.collection('bancos_leite').document(unit['id'])
            @firestore.transactional
            def commit(transaction):
                snapshot = ref.get(transaction=transaction)
                action, patch = plan_patch(snapshot.to_dict() if snapshot.exists else None, unit, decisions[unit['id']])
                if action == 'update': transaction.update(ref, {**patch, 'atualizadoEm': firestore.SERVER_TIMESTAMP})
                return action
            actions.append(commit(db.transaction()))
    write_json(args.output, json_safe({'aplicado': args.apply, 'colecao': 'bancos_leite',
        'gravacaoExecutada': args.apply and 'update' in actions,
        'hashRelatorio': digest(report), 'decisao': review, 'plano': planned}))
    print('Plano/auditoria salvo. Publicação, coordenadas e Firebase Authentication não são alterados.')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest='command', required=True)
    collect_cmd = sub.add_parser('collect')
    collect_cmd.add_argument('--cache', type=Path, default=ROOT / 'data/blh/geografia/cache/demas')
    collect_cmd.add_argument('--output', type=Path, required=True)
    collect_cmd.add_argument('--online', action='store_true')
    collect_cmd.add_argument('--refresh', action='store_true')
    sync_cmd = sub.add_parser('sync')
    sync_cmd.add_argument('--report', type=Path, required=True)
    sync_cmd.add_argument('--review', type=Path, required=True)
    sync_cmd.add_argument('--project', required=True)
    sync_cmd.add_argument('--output', type=Path, required=True)
    sync_cmd.add_argument('--apply', action='store_true')
    sync_cmd.add_argument('--firebase-cli-auth', action='store_true', help=argparse.SUPPRESS)
    args = parser.parse_args()
    if args.command == 'collect': collect(args)
    else: sync(args)


if __name__ == '__main__': main()
