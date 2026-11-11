"""Etapa 10: lotes administrativos, cache e confiança; nunca escreve no Firebase."""
import argparse
import datetime as dt
import hashlib
import json
import math
import re
import sys
import tempfile
import time
import urllib.error
import urllib.parse
import urllib.request
from collections import Counter
from pathlib import Path
from types import SimpleNamespace

from import_blh import STATES, normalize, official_url, parse_date, load_records
from geocode_blh import (ROOT, PROVIDER, POLICY, ATTRIBUTION, candidate, digest,
    read_json, review_template, export_approved)
from national_blh import check_unique
from blh_preservation import preserved

NATIONAL = ROOT / 'data/blh/nacional'
OUTPUT = ROOT / 'data/blh/validacao-nacional'
LEVELS = ('alta', 'media', 'baixa', 'conflito', 'nao_encontrado')
GENERIC_NAMES = set('banco leite humano posto coleta hospital maternidade municipal estadual regional de da do das dos e fundacao associacao unidade saude'.split())


def immutable_json(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open('x', encoding='utf-8') as stream:
        json.dump(data, stream, ensure_ascii=False, indent=2)
        stream.write('\n')


def verify_preservation():
    manifest = read_json(OUTPUT / 'preservacao-etapa10.sha256.json')
    changed = [name for name, expected in manifest.items()
        if not preserved(ROOT, name, expected)]
    if changed: raise ValueError(f'Arquivos protegidos alterados: {changed}')
    return len(manifest)


def text_tokens(value):
    return set(re.findall(r'[a-z0-9]+', normalize(value)))


def name_terms(value):
    return sorted(token for token in text_tokens(value) - GENERIC_NAMES if len(token) > 2)


def street_tokens(value):
    return text_tokens(value) - set('rua avenida av travessa estrada rodovia alameda praca r de da do dos das'.split())


def address_parts(entry):
    # Componentes explícitos têm prioridade. Inferência textual é apenas comparativa.
    address = entry.get('enderecoPesquisa', '')
    street = entry.get('logradouroOficial') or address.split(',')[0]
    number = entry.get('numeroOficial')
    if number is None:
        match = re.search(r',\s*(\d+[a-zA-Z]?)\s*(?:,|$)', address)
        number = match.group(1) if match else None
    return street, str(number).lower() if number is not None else None


def assess_candidate(item, record, entry, auxiliary=''):
    if not isinstance(item, dict) or not isinstance(item.get('enderecoRetornado'), dict): return None
    props = item.get('enderecoRetornado', {})
    feature = {'geometry': {'type': 'Point', 'coordinates': [item.get('longitude'), item.get('latitude')]},
               'properties': props}
    anchors = entry.get('termosIdentificacao') or name_terms(record['nome'])
    parsed = candidate(feature, item.get('consulta', item.get('fonte', '')), record['cidade'], anchors, record['estado'])
    if parsed is None: return None
    returned_name = text_tokens(props.get('name') or '')
    identities = [set(anchors), set(name_terms(record['nome'])), set(name_terms(auxiliary))]
    name_match = any(terms and terms <= returned_name for terms in identities)
    street, number = address_parts(entry)
    expected_street, returned_street = street_tokens(street), street_tokens(props.get('street') or '')
    # Não confundir rua ausente com rua correspondente.
    street_match = bool(expected_street and returned_street) and expected_street == returned_street
    street_conflict = bool(expected_street and returned_street) and not street_match
    returned_number = str(props.get('housenumber') or '').strip().lower()
    number_match = bool(number and returned_number) and number == returned_number
    number_conflict = bool(number and returned_number) and number != returned_number
    wrong_name = bool(returned_name) and not name_match
    generic = props.get('type') in ('country', 'state', 'county', 'city', 'district', 'locality', 'street') or props.get('osm_key') in ('place', 'boundary', 'highway')
    specific = props.get('osm_key') in ('amenity', 'healthcare', 'building') or props.get('type') == 'house'
    region = parsed['municipioCompativel'] and parsed['estadoCompativel']
    compatible = region and not generic and specific and not wrong_name and not street_conflict and not number_conflict
    if compatible and name_match and street_match and number_match:
        level = 'alta'
    elif compatible and street_match and (number_match or not number):
        level = 'media'
    else:
        level = 'baixa'
    issues = []
    if street_conflict: issues.append('Logradouro retornado diverge do endereço oficial de pesquisa')
    if number_conflict: issues.append('Número retornado diverge do endereço oficial de pesquisa')
    if not props.get('street'): issues.append('Provedor não informa logradouro')
    if not returned_number: issues.append('Provedor não informa número')
    if wrong_name: issues.append('Estabelecimento retornado não corresponde aos nomes de referência')
    original_issues = [issue for issue in parsed['divergencias']
                       if not (name_match and issue == 'Nome não confirma a instituição procurada')]
    parsed.update({'nivelConfianca': level, 'nomeInstituicaoCompativel': bool(name_match),
        'logradouroCompativel': street_match, 'numeroCompativel': number_match,
        'conflitoEndereco': street_conflict or number_conflict,
        'passivelRevisao': bool(compatible and (name_match or street_match)),
        'origemAnterior': item.get('fonte'), 'coordenadasVerificadas': False,
        'divergencias': list(dict.fromkeys([*original_issues, *issues]))})
    return parsed


def distance_meters(a, b):
    lat1, lat2 = map(math.radians, (a['latitude'], b['latitude']))
    dl = math.radians(b['longitude'] - a['longitude'])
    value = math.sin((lat2 - lat1) / 2) ** 2 + math.cos(lat1) * math.cos(lat2) * math.sin(dl / 2) ** 2
    return 6371000 * 2 * math.asin(min(1, math.sqrt(value)))


def confidence(items):
    eligible = [item for item in items if item['passivelRevisao']]
    address_conflict = any(item['nomeInstituicaoCompativel'] and item['municipioCompativel']
        and item['estadoCompativel'] and item['conflitoEndereco'] for item in items)
    separated = any(distance_meters(a, b) > 150 for index, a in enumerate(eligible) for b in eligible[index + 1:])
    if address_conflict or separated: return 'conflito'
    if eligible:
        return min((item['nivelConfianca'] for item in eligible), key=('alta', 'media', 'baixa').index)
    # Referências genéricas e estabelecimentos diferentes não são localizações adequadas.
    return 'nao_encontrado'


class BatchClient:
    """Photon sequencial, orçamento persistente, cache por URL e bloqueio após erro."""
    def __init__(self, cache, config=None, online=False):
        self.cache, self.online = cache, online
        self.config = config or {'endpoint': PROVIDER, 'politica': POLICY, 'atribuicao': ATTRIBUTION,
            'licenca': 'ODbL', 'cachePermitido': True, 'cacheDias': 30, 'intervaloSegundos': 2,
            'maxRequisicoesExecucao': 100, 'maxRequisicoesDia': 100, 'tamanhoLote': 25}
        c = self.config
        allowed = {'endpoint', 'politica', 'atribuicao', 'licenca', 'cachePermitido', 'cacheDias',
                   'intervaloSegundos', 'maxRequisicoesExecucao', 'maxRequisicoesDia', 'tamanhoLote'}
        if set(c) != allowed: raise ValueError('Configuração contém campos ausentes/desconhecidos; não inclua segredos.')
        url = urllib.parse.urlparse(c['endpoint'])
        if url.scheme != 'https' or not url.hostname or url.username or url.password or url.query or url.fragment:
            raise ValueError('Endpoint HTTPS sem credenciais, query ou fragmento obrigatório.')
        if online and url.hostname in ('photon.komoot.io', 'nominatim.openstreetmap.org'):
            raise ValueError('Lote nacional exige Photon próprio/contratado; servidor público não autorizado.')
        if c.get('cachePermitido') is not True: raise ValueError('Operador deve autorizar cache na política configurada.')
        if not all(isinstance(c.get(key), str) and c[key].strip() for key in ('politica', 'atribuicao', 'licenca')):
            raise ValueError('Documente política, atribuição e licença do provedor.')
        policy = urllib.parse.urlparse(c['politica'])
        if policy.scheme != 'https' or not policy.hostname or policy.username or policy.password or policy.query:
            raise ValueError('Política deve ser URL HTTPS pública sem credenciais.')
        for key in ('cacheDias', 'maxRequisicoesExecucao', 'maxRequisicoesDia', 'tamanhoLote'):
            if type(c.get(key)) is not int or c[key] < 1: raise ValueError(f'Limite inválido: {key}')
        if c['tamanhoLote'] > 50 or type(c.get('intervaloSegundos')) not in (int, float) or not 2 <= c['intervaloSegundos'] <= 60:
            raise ValueError('Lotes de até 50 unidades e intervalo entre 2 e 60 segundos obrigatórios.')
        self.endpoint = c['endpoint'].rstrip('/') + '/'
        self.requests, self.hits, self.last, self.blocked, self.memory = 0, 0, 0., False, {}
        self.cache.mkdir(parents=True, exist_ok=True)
        self.quota = cache / ('quota-' + digest(self.endpoint) + '.json')

    def search(self, query):
        query = ' '.join(query.split())
        url = self.endpoint + '?' + urllib.parse.urlencode({'q': query, 'limit': '5', 'countrycode': 'BR'})
        if url in self.memory: return self.memory[url]
        path = self.cache / (digest(url) + '.json')
        if path.exists():
            try:
                cached = read_json(path)
                date = parse_date(cached.get('consultadoEm'), 'consultadoEm do cache') if cached.get('consultadoEm') else None
            except (ValueError, TypeError, AttributeError):
                cached, date = {}, None
            age = (dt.datetime.now(dt.timezone.utc) - date).total_seconds() / 86400 if date else math.inf
            if cached.get('url') == url and not cached.get('erro') and isinstance(cached.get('features'), list) and age <= self.config['cacheDias']:
                self.hits += 1
                self.memory[url] = cached
                return cached
        missing = {'url': url, 'features': [], 'erro': 'Cache ausente/expirado; pesquisa online não executada.'}
        if not self.online or self.blocked: return missing
        today = dt.datetime.now(dt.timezone.utc).date().isoformat()
        quota = read_json(self.quota) if self.quota.exists() else {}
        if quota.get('bloqueadoAte') and dt.datetime.fromisoformat(quota['bloqueadoAte']) > dt.datetime.now(dt.timezone.utc):
            missing['erro'] = 'Provedor bloqueado após falha anterior; respeite Retry-After e confira o operador.'
            self.blocked = True
            return missing
        used = quota.get('requisicoes', 0) if quota.get('dia') == today else 0
        if self.requests >= self.config['maxRequisicoesExecucao'] or used >= self.config['maxRequisicoesDia']:
            missing['erro'] = 'Orçamento de requisições atingido; lote preservado como pendente.'
            return missing
        time.sleep(max(0, self.config['intervaloSegundos'] - (time.monotonic() - self.last)))
        self.last = time.monotonic()
        self.requests += 1
        quota = {'dia': today, 'requisicoes': used + 1}
        self.quota.write_text(json.dumps(quota), encoding='utf-8')
        request = urllib.request.Request(url, headers={'User-Agent': 'ColoDeMae-BLH-AdministrativeBatch/1.0', 'Accept': 'application/json'})
        try:
            with urllib.request.urlopen(request, timeout=25) as response:
                body = json.loads(response.read(2_000_001).decode('utf-8'))
            if not isinstance(body.get('features'), list): raise ValueError('Resposta Photon inválida.')
            result = {'url': url, 'consultadoEm': dt.datetime.now(dt.timezone.utc).isoformat(), 'features': body['features'][:5]}
            path.write_text(json.dumps(result, ensure_ascii=False), encoding='utf-8')
            self.memory[url] = result
            return result
        except (urllib.error.URLError, TimeoutError, ValueError) as error:
            self.blocked = True
            delay = 3600
            if isinstance(error, urllib.error.HTTPError):
                retry = error.headers.get('Retry-After', '')
                if retry.isdigit(): delay = max(delay, int(retry))
                elif retry:
                    from email.utils import parsedate_to_datetime
                    try: delay = max(delay, (parsedate_to_datetime(retry) - dt.datetime.now(dt.timezone.utc)).total_seconds())
                    except (ValueError, TypeError): pass
            quota['bloqueadoAte'] = (dt.datetime.now(dt.timezone.utc) + dt.timedelta(seconds=delay)).isoformat()
            self.quota.write_text(json.dumps(quota), encoding='utf-8')
            # Sem corpo HTTP, tokens, cabeçalhos ou URL de erro no relatório.
            missing['erro'] = f'Falha {type(error).__name__}; execução online interrompida, sem repetição automática.'
            return missing


def load_inputs(overlays=None):
    manifest = read_json(NATIONAL / 'manifesto.json')
    records, lookup = [], {}
    for name in manifest['arquivos']:
        path = (NATIONAL / name).resolve()
        if not path.is_relative_to((ROOT / 'data/blh').resolve()): raise ValueError('Fonte fora da base administrativa.')
        validated, raw = load_records(path), read_json(path)
        uf = validated[0]['estado']
        folder = ROOT / 'data/blh/geografia' if uf == 'SE' else NATIONAL / uf
        addresses = read_json(folder / 'enderecos-pesquisa.json')
        report_path = folder / ('sergipe.candidatas.json' if uf == 'SE' else 'coordenadas.candidatas.json')
        review_path = folder / ('sergipe.aprovacao-manual.json' if uf == 'SE' else 'aprovacao-manual.json')
        previous = read_json(report_path)
        expected = digest({key: previous[key] for key in ('hashBase', 'hashEnderecos', 'unidades', 'provedor')})
        if previous['hashBase'] != digest(raw) or expected != previous['hashRevisao'] or previous['hashEnderecos'] != digest(addresses):
            raise ValueError(f'{uf}: fonte geográfica anterior inconsistente; não substituir histórico.')
        entries = {entry['id']: entry for entry in addresses}
        if len(entries) != len(addresses) or set(entries) != {row['id'] for row in validated}:
            raise ValueError('Fila geográfica contém duplicatas ou IDs divergentes.')
        traces = {entry['id']: entry for entry in read_json(NATIONAL / uf / 'rastreabilidade.json')}
        old_units = {entry['id']: entry for entry in previous['unidades']}
        old_review = read_json(review_path)
        if old_review['hashRevisao'] != previous['hashRevisao']: raise ValueError('Revisão anterior sem vínculo com relatório.')
        for record, original in zip(validated, raw):
            identifier = record['id']
            records.append(original)
            lookup[identifier] = {'endereco': entries[identifier], 'anterior': old_units[identifier],
                'mantenedora': traces[identifier]['documentacao'].get('mantenedora', ''),
                'historico': {'relatorio': report_path.relative_to(ROOT).as_posix(),
                    'hashRelatorio': digest(previous), 'revisao': review_path.relative_to(ROOT).as_posix(),
                    'hashRevisao': digest(old_review), 'decisaoAnterior': next(r for r in old_review['revisoes'] if r['id'] == identifier)}}
    check_unique(records)
    if overlays:
        additions = read_json(overlays)
        if not isinstance(additions, list) or any(not isinstance(row, dict) for row in additions):
            raise ValueError('Complementos precisam ser uma lista de documentos oficiais por ID.')
        ids = [row.get('id') for row in additions]
        if any(not isinstance(identifier, str) for identifier in ids) or len(set(ids)) != len(ids) or not set(ids) <= set(lookup):
            raise ValueError('Complementos duplicados ou com ID desconhecido.')
        allowed = {'id', 'enderecoPesquisa', 'fonteEndereco', 'consultadoEm', 'logradouroOficial',
                   'numeroOficial', 'termosIdentificacao', 'instituicaoPesquisa', 'motivoAlteracao'}
        for row in additions:
            if set(row) - allowed: raise ValueError('Campo desconhecido no complemento; confirmações anteriores são protegidas.')
            official_url(row.get('fonteEndereco'))
            parse_date(row.get('consultadoEm'), 'consultadoEm do complemento')
            if not isinstance(row.get('enderecoPesquisa'), str) or len(row['enderecoPesquisa'].strip()) < 8:
                raise ValueError('Complemento exige endereço documental completo.')
            terms = row.get('termosIdentificacao', [])
            if not isinstance(terms, list) or any(not isinstance(term, str) or not term.strip() for term in terms):
                raise ValueError('Termos de identificação inválidos.')
            for key in ('logradouroOficial', 'numeroOficial', 'instituicaoPesquisa', 'motivoAlteracao'):
                if key in row and (not isinstance(row[key], str) or not row[key].strip()):
                    raise ValueError(f'Componente documental inválido: {key}')
            source = lookup[row['id']]
            old = source['endereco']
            if old.get('enderecoPesquisa') and row['enderecoPesquisa'] != old['enderecoPesquisa'] and len(row.get('motivoAlteracao', '')) < 20:
                raise ValueError('Mudança de endereço exige justificativa documental; histórico não será removido.')
            source['historico']['complementoDocumental'] = row
            source['historico']['enderecoAnterior'] = old
            source['endereco'] = {**old, **{k: v for k, v in row.items() if k != 'id'}}
    return records, lookup


def markdown(uf, units):
    lines = [f'# Revisão geográfica — {uf}', '', 'Confiança não é aprovação. Nenhuma publicação foi executada.', '', ATTRIBUTION, '']
    for unit in units:
        lines += [f"## {unit['nome']}", '', f"ID: `{unit['id']}` — confiança: **{unit['confianca']}**",
            f"Endereço: {unit['enderecoPesquisa'] or 'ausente; obter fonte oficial antes de consultar'}",
            f"Fonte: {unit['fonteEndereco']}", '', 'Pendências:', '']
        lines += [f'- {p}' for p in unit['pendencias']]
        for item in unit['candidatos']:
            lines += ['', f"- `{item['candidatoId']}`: {item['latitude']}, {item['longitude']} — {item['nivelConfianca']}",
                f"  - [Mapa]({item['mapaCandidato']}) — [fonte]({item['fonte']})",
                f"  - Nome: {item['nomeRetornado'] or 'ausente'}; revisão possível: {item['passivelRevisao']}",
                f"  - Divergências: {'; '.join(item['divergencias']) or 'nenhuma automática; confirmação humana obrigatória'}"]
        lines += ['']
    return '\n'.join(lines)


def run(args):
    verify_preservation()
    records, lookup = load_inputs(args.addresses)
    client = BatchClient(args.cache, read_json(args.provider) if args.provider else None, args.online)
    # Mesmo offline, o lock impede concorrência com a ferramenta das Etapas 8/9.
    lock = args.cache / '.geocode.lock'
    with lock.open('x', encoding='utf-8') as stream: stream.write('Lote administrativo exclusivo.')
    try:
        args.output.mkdir(parents=True, exist_ok=False)
        all_units, by_uf, summaries = [], {}, {}
        for offset in range(0, len(records), client.config['tamanhoLote']):
            batch = records[offset:offset + client.config['tamanhoLote']]
            for raw in batch:
                identifier = f"{raw['estado'].lower()}-{raw['chaveUnidade']}"
                source = lookup[identifier]
                entry = source['endereco']
                official_url(entry['fonteEndereco'])
                items, queries, errors = {}, [], []
                address = entry.get('enderecoPesquisa', '').strip()
                institution = entry.get('instituicaoPesquisa') or source['mantenedora'] or raw['nome']
                # Reavaliar evidência anterior sem alterar relatório/decisão original.
                for item in source['anterior']['candidatos']:
                    parsed = assess_candidate(item, raw, entry, institution)
                    if parsed: items[parsed['candidatoId']] = parsed
                if address:
                    texts = [address]
                    texts.append(f'{institution}, {address}')
                    for query in dict.fromkeys(texts):
                        response = client.search(query)
                        queries.append({'texto': query, 'url': response['url'], 'consultadoEm': response.get('consultadoEm')})
                        if response.get('erro'): errors.append(response['erro'])
                        for feature in response['features']:
                            if not isinstance(feature, dict) or not isinstance(feature.get('properties'), dict) or not isinstance(feature.get('geometry'), dict):
                                errors.append('Resultado malformado descartado do cache/provedor.')
                                continue
                            old = candidate(feature, response['url'], raw['cidade'], entry.get('termosIdentificacao', []), raw['estado'])
                            parsed = assess_candidate(old, raw, entry, institution) if old else None
                            if parsed: items[parsed['candidatoId']] = parsed
                candidates = list(items.values())
                unit = {'id': identifier, 'nome': raw['nome'], 'estado': raw['estado'], 'cidade': raw['cidade'],
                    'enderecoPesquisa': address, 'fonteEndereco': entry['fonteEndereco'],
                    'confirmacaoDocumental': entry.get('confirmacaoDocumental'), 'historicoAnterior': source['historico'],
                    'consultasAnteriores': source['anterior'].get('consultas', []),
                    'confianca': confidence(candidates), 'candidatos': candidates, 'consultas': queries,
                    'erros': list(dict.fromkeys(errors)), 'coordenadasVerificadas': False,
                    'pendencias': list(dict.fromkeys([*raw.get('pendencias', []), *entry.get('pendencias', []),
                        *([] if address else ['Obter endereço oficial completo antes de geocodificar']),
                        'Confirmar ponto real, endereço operacional, funcionamento e contato antes de aprovar']))}
                all_units.append(unit)
                by_uf.setdefault(raw['estado'], []).append(unit)
            immutable_json(args.output / 'lotes' / f'{offset // client.config["tamanhoLote"] + 1:03d}.json',
                {'ids': [f"{r['estado'].lower()}-{r['chaveUnidade']}" for r in batch], 'concluido': True,
                 'requisicoesAcumuladas': client.requests, 'consultasCacheAcumuladas': client.hits})
        for uf, units in sorted(by_uf.items()):
            folder = args.output / uf
            base = [raw for raw in records if raw['estado'] == uf]
            report = {'geradoEm': dt.datetime.now(dt.timezone.utc).isoformat(), 'provedor': client.endpoint,
                'politicaProvedor': client.config['politica'], 'atribuicao': client.config['atribuicao'],
                'licenca': client.config['licenca'], 'hashBase': digest(base),
                'hashEnderecos': digest([lookup[u['id']]['endereco'] for u in units]), 'unidades': units,
                'coordenadasAutomaticasSaoVerificadas': False}
            report['hashRevisao'] = digest({key: report[key] for key in ('hashBase', 'hashEnderecos', 'unidades', 'provedor')})
            immutable_json(folder / 'base.json', base)
            immutable_json(folder / 'candidatas.json', report)
            immutable_json(folder / 'revisao.pendente.json', review_template(report))
            (folder / 'relatorio.md').write_text(markdown(uf, units), encoding='utf-8')
            summaries[uf] = {'total': len(units), 'pendentes': len(units),
                'semEnderecoOficial': sum(not u['enderecoPesquisa'] for u in units),
                **{level: sum(u['confianca'] == level for u in units) for level in LEVELS}}
        summary = {'totalAnalisado': len(all_units), 'porUF': summaries,
            'confianca': {level: sum(u['confianca'] == level for u in all_units) for level in LEVELS},
            'resultadosBrutosValidos': sum(len(u['candidatos']) for u in all_units),
            'candidatasParaRevisao': sum(c['passivelRevisao'] for u in all_units for c in u['candidatos']),
            'unidadesComCandidataAdequada': sum(any(c['passivelRevisao'] for c in u['candidatos']) for u in all_units),
            'semLocalizacaoAdequada': sum(not any(c['passivelRevisao'] for c in u['candidatos']) for u in all_units),
            'coordenadasAprovadasNestaEtapa': 0, 'pendentes': len(all_units), 'requisicoesHTTP': client.requests,
            'consultasCache': client.hits, 'somenteCache': not args.online, 'gravacaoFirebase': False,
            'arquivosProtegidosIntactos': verify_preservation(), 'hashBaseNacional': digest(records),
            'provedor': client.config, 'fontesDocumentais': read_json(NATIONAL / 'fontes/manifesto.json')}
        immutable_json(args.output / 'resumo.json', summary)
        print(json.dumps(summary, ensure_ascii=False, indent=2))
    finally:
        lock.unlink(missing_ok=True)


def snapshot_review(run_dir, uf, decision_file):
    if uf not in STATES: raise ValueError('UF inválida.')
    folder = run_dir / uf
    report, review = read_json(folder / 'candidatas.json'), read_json(decision_file)
    expected = digest({key: report[key] for key in ('hashBase', 'hashEnderecos', 'unidades', 'provedor')})
    if expected != report['hashRevisao']: raise ValueError('Relatório adulterado; preservar evidência original.')
    if review.get('hashRevisao') != report['hashRevisao']: raise ValueError('Decisão não corresponde a esta versão do relatório.')
    ids = {u['id'] for u in report['unidades']}
    rows = review.get('revisoes', [])
    if len(rows) != len(ids) or {r['id'] for r in rows} != ids: raise ValueError('Revisões duplicadas ou incompletas.')
    for row in rows:
        if row.get('status') not in ('pendente', 'rejeitado', 'aprovado'): raise ValueError('Status inválido.')
        if row['status'] != 'pendente':
            if len((row.get('revisadoPor') or '').strip()) < 3 or len((row.get('observacoesValidacao') or '').strip()) < 20:
                raise ValueError('Aprovação/reprovação exige revisor e justificativa documentada.')
            parse_date(row.get('revisadoEm'), 'revisadoEm')
    # "aprovado" só entra no histórico depois de passar por toda a validação existente.
    if any(row['status'] == 'aprovado' for row in rows):
        with tempfile.TemporaryDirectory() as temporary:
            export_approved(SimpleNamespace(base=folder / 'base.json', report=folder / 'candidatas.json',
                review=decision_file, output=Path(temporary) / 'validacao.json'))
    history = folder / 'historico' / (digest(review) + '.json')
    immutable_json(history, {'registradoEm': dt.datetime.now(dt.timezone.utc).isoformat(),
        'hashBase': report['hashBase'], 'hashRelatorio': digest(report), 'decisao': review})
    return history


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest='command', required=True)
    process = sub.add_parser('run')
    process.add_argument('--output', type=Path, required=True, help='Diretório novo; execuções anteriores nunca são sobrescritas.')
    process.add_argument('--cache', type=Path, default=ROOT / 'data/blh/geografia/cache')
    process.add_argument('--provider', type=Path)
    process.add_argument('--addresses', type=Path, help='Complementos oficiais versionados, sem modificar fontes anteriores.')
    process.add_argument('--online', action='store_true')
    decision = sub.add_parser('record-review')
    decision.add_argument('--run', type=Path, required=True)
    decision.add_argument('--uf', required=True)
    decision.add_argument('--review', type=Path, required=True)
    export = sub.add_parser('export-approved')
    export.add_argument('--run', type=Path, required=True)
    export.add_argument('--uf', required=True)
    export.add_argument('--decision', type=Path, required=True, help='Snapshot imutável gerado por record-review.')
    export.add_argument('--output', type=Path, required=True, help='Diretório novo para exportação e auditoria.')
    args = parser.parse_args()
    location = args.output if args.command == 'run' else args.run
    if not location.resolve().is_relative_to(OUTPUT.resolve()):
        raise ValueError('Execuções devem ficar em data/blh/validacao-nacional, separadas das fontes preservadas.')
    if args.command == 'run': run(args)
    elif args.command == 'record-review': print(snapshot_review(args.run, args.uf, args.review))
    else:
        folder = args.run / args.uf
        decision_data = read_json(args.decision)
        report = read_json(folder / 'candidatas.json')
        if decision_data['hashRelatorio'] != digest(report): raise ValueError('Snapshot não corresponde ao relatório.')
        args.output.mkdir(parents=True, exist_ok=False)
        immutable_json(args.output / 'revisao.json', decision_data['decisao'])
        export_approved(SimpleNamespace(base=folder / 'base.json', report=folder / 'candidatas.json',
            review=args.output / 'revisao.json', output=args.output / 'aprovadas.json'))


if __name__ == '__main__':
    if hasattr(sys.stdout, 'reconfigure'): sys.stdout.reconfigure(encoding='utf-8')
    main()
