"""Etapa 8: candidatas administrativas, revisão humana e exportação sem escrita no Firebase."""
import argparse
import datetime as dt
import hashlib
import json
import math
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

from import_blh import load_records, validate_record, official_url, parse_date, json_safe, normalize

PROVIDER = 'https://photon.komoot.io/api/'
POLICY = 'https://github.com/komoot/photon#demo-server'
ATTRIBUTION = '© OpenStreetMap contributors — https://www.openstreetmap.org/copyright — dados sob ODbL'
ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / 'data/blh/sergipe.json'
ADDRESSES = ROOT / 'data/blh/geografia/enderecos-pesquisa.json'
DIRECTORY = ROOT / 'data/blh/geografia'
STATE_NAMES = dict(zip(
    'AC AL AP AM BA CE DF ES GO MA MT MS MG PA PB PR PE PI RJ RN RS RO RR SC SP SE TO'.split(),
    ['Acre', 'Alagoas', 'Amapá', 'Amazonas', 'Bahia', 'Ceará', 'Distrito Federal',
     'Espírito Santo', 'Goiás', 'Maranhão', 'Mato Grosso', 'Mato Grosso do Sul',
     'Minas Gerais', 'Pará', 'Paraíba', 'Paraná', 'Pernambuco', 'Piauí',
     'Rio de Janeiro', 'Rio Grande do Norte', 'Rio Grande do Sul', 'Rondônia',
     'Roraima', 'Santa Catarina', 'São Paulo', 'Sergipe', 'Tocantins']))


def digest(value):
    raw = json.dumps(json_safe(value), ensure_ascii=False, sort_keys=True, separators=(',', ':'))
    return hashlib.sha256(raw.encode('utf-8')).hexdigest()


def read_json(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def write_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(json_safe(value), ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


class PhotonClient:
    def __init__(self, endpoint, cache, online=False):
        parsed = urllib.parse.urlparse(endpoint)
        if parsed.scheme != 'https' or parsed.username or parsed.password or parsed.query:
            raise ValueError('Informe endpoint Photon HTTPS sem credenciais ou query string.')
        if parsed.hostname == 'nominatim.openstreetmap.org':
            raise ValueError('Este cliente implementa Photon, não a API pública do Nominatim.')
        self.endpoint = endpoint.rstrip('/') + '/'
        self.cache, self.online = cache, online
        self.last_request = 0.
        self.blocked = False
        self.requests = 0

    def search(self, query):
        params = {'q': query, 'limit': '5', 'countrycode': 'BR'}
        url = self.endpoint + '?' + urllib.parse.urlencode(params)
        cache_path = self.cache / (digest(url) + '.json')
        if cache_path.exists():
            return read_json(cache_path)
        if not self.online or self.blocked:
            return {'url': url, 'features': [], 'erro': 'Consulta não disponível no cache; execute --online ou aguarde o serviço.'}
        # Uma única sequência, uma máquina, intervalo conservador de 2 segundos.
        time.sleep(max(0, 2 - (time.monotonic() - self.last_request)))
        request = urllib.request.Request(url, headers={
            'User-Agent': 'ColoDeMae-BLH-AdministrativeReview/1.0 (one-off institutional address review)',
            'Accept': 'application/json', 'Accept-Language': 'pt-BR,pt;q=0.9,en;q=0.5',
        })
        self.last_request = time.monotonic()
        self.requests += 1
        result = {'url': url, 'consultadoEm': dt.datetime.now(dt.timezone.utc).isoformat(), 'features': []}
        try:
            with urllib.request.urlopen(request, timeout=25) as response:
                body = json.loads(response.read(2_000_000).decode('utf-8'))
            if not isinstance(body.get('features'), list):
                raise ValueError('Resposta Photon inválida.')
            result['features'] = body['features'][:5]
        except (urllib.error.URLError, TimeoutError, ValueError) as error:
            # Não insistir após indisponibilidade, bloqueio ou limitação do serviço.
            self.blocked = True
            result['erro'] = f'{type(error).__name__}: {error}'
        write_json(cache_path, result)
        return result


def candidate(feature, query_url, expected_city, required_name_terms, expected_state='SE'):
    if not isinstance(feature, dict): return None
    props = feature.get('properties', {})
    geometry = feature.get('geometry', {})
    coords = geometry.get('coordinates', [])
    if geometry.get('type') != 'Point' or not isinstance(coords, list) or len(coords) != 2:
        return None
    lon, lat = coords
    if not all(type(x) in (int, float) and math.isfinite(x) for x in (lat, lon)) or abs(lat) > 90 or abs(lon) > 180:
        return None
    kind = str(props.get('type', ''))
    osm_key, osm_value = props.get('osm_key'), props.get('osm_value')
    generic = kind in ('country', 'state', 'county', 'city', 'district', 'locality', 'street') or osm_key in ('place', 'boundary', 'highway')
    health_poi = osm_key in ('amenity', 'healthcare') and osm_value in ('hospital', 'clinic', 'doctors', 'blood_bank', 'health_centre')
    address_point = kind == 'house' or bool(props.get('housenumber'))
    returned_city = props.get('city') or props.get('county') or ''
    same_city = normalize(returned_city) == normalize(expected_city)
    same_state = expected_state in STATE_NAMES and normalize(props.get('state') or '') in (
        normalize(STATE_NAMES[expected_state]), expected_state.lower())
    returned_name = normalize(props.get('name') or '')
    name_matches = bool(required_name_terms) and all(normalize(term) in returned_name for term in required_name_terms)
    # Um endereço não nomeado pode ser pesquisado, mas não é certificado como POI.
    reviewable = not generic and same_city and same_state and (health_poi or address_point or osm_key == 'building') and (name_matches or (address_point and not returned_name))
    precision = 'POI/edificação de saúde; confirmar ponto e acesso da unidade' if health_poi else (
        'Ponto de endereço/edificação; correspondência com a unidade não confirmada' if reviewable else
        'Via ou referência genérica: não utilizar como localização da unidade')
    osm_type = {'N': 'node', 'W': 'way', 'R': 'relation'}.get(props.get('osm_type'))
    osm_id = props.get('osm_id')
    source = f'https://www.openstreetmap.org/{osm_type}/{osm_id}' if osm_type and osm_id else query_url
    identifier = digest({'source': source, 'latitude': lat, 'longitude': lon})[:16]
    issues = []
    if not same_city: issues.append('Município divergente ou não informado pelo provedor')
    if not same_state: issues.append('Estado divergente ou não informado pelo provedor')
    if not name_matches: issues.append('Nome não confirma a instituição procurada')
    if generic: issues.append('Referência genérica de via/área; não corresponde ao ponto da unidade')
    return {'candidatoId': identifier, 'nomeRetornado': props.get('name'),
            'latitude': lat, 'longitude': lon, 'fonte': source, 'consulta': query_url,
            'enderecoRetornado': props, 'precisaoEstimada': precision,
            'margemErroMetros': None,
            'observacaoPrecisao': 'O provedor não informa margem de erro em metros; classificação qualitativa, não certificação.',
            'coordenadasVerificadas': False, 'passivelRevisao': reviewable,
            'municipioCompativel': same_city, 'estadoCompativel': same_state,
            'nomeInstituicaoCompativel': name_matches, 'divergencias': issues,
            'rotaCandidata': 'https://www.google.com/maps/dir/?' + urllib.parse.urlencode({'api': '1', 'destination': f'{lat},{lon}'}),
            'mapaCandidato': f'https://www.openstreetmap.org/?mlat={lat}&mlon={lon}#map=18/{lat}/{lon}'}


def markdown_report(report):
    lines = ['# Coordenadas candidatas — revisão administrativa de BLHs', '',
             '**Nenhuma coordenada deste relatório foi aprovada automaticamente.**', '',
             ATTRIBUTION, '', f'Provedor e política: {POLICY}', '',
             'A precisão é qualitativa. Não é fornecida uma margem de erro numérica pelo serviço.', '']
    for unit in report['unidades']:
        lines += [f"## {unit['nome']}", '', f"ID: `{unit['id']}`", '',
                  f"Endereço pesquisado: {unit['enderecoPesquisa']}", '',
                  f"Fonte do endereço: {unit['fonteEndereco']}", '',
                  'Situação: **pendente de confirmação humana e operacional**.', '']
        if unit.get('confirmacaoDocumental'):
            lines += ['Endereço e vinculação do BLH confirmados documentalmente pela usuária; essa confirmação não valida o ponto GPS nem o funcionamento atual.', '']
        if not unit['candidatos']:
            lines += ['Nenhuma coordenada candidata retornada. Não foi usado centro de cidade como substituto.', '']
        for item in unit['candidatos']:
            status = 'candidata a revisão' if item['passivelRevisao'] else 'resultado divergente/genérico descartado para aprovação'
            lines += [f"- `{item['candidatoId']}` — {item['latitude']}, {item['longitude']} — {status}",
                      f"  - Nome retornado: {item['nomeRetornado'] or 'não informado'}",
                      f"  - Endereço retornado: {', '.join(str(item['enderecoRetornado'][key]) for key in ('street', 'housenumber', 'city', 'state') if item['enderecoRetornado'].get(key)) or 'não informado'}",
                      f"  - Precisão: {item['precisaoEstimada']}",
                      f"  - Divergências: {'; '.join(item['divergencias']) or 'nenhuma divergência automática; confirmação manual continua obrigatória'}",
                      f"  - Fonte: {item['fonte']}",
                      f"  - [Ver ponto no mapa]({item['mapaCandidato']}) | [Testar rota candidata]({item['rotaCandidata']})"]
        lines += ['', 'Pendências:', ''] + [f'- {note}' for note in unit['pendencias']] + ['']
        if unit['erros']:
            lines += ['Erros de consulta:', ''] + [f'- {error}' for error in unit['erros']] + ['']
    return '\n'.join(lines)


def review_template(report):
    return {'hashRevisao': report['hashRevisao'], 'revisoes': [
        {'id': unit['id'], 'status': 'pendente', 'candidatoId': None,
         'pontoRealConfirmado': False, 'enderecoOperacionalConfirmado': False,
         'funcionamentoConfirmado': False, 'contatoConfirmado': False,
         'revisadoPor': None, 'revisadoEm': None,
         'latitudeVerificada': None, 'longitudeVerificada': None, 'fonteCoordenadas': None,
         'enderecoConfirmado': None, 'telefoneConfirmado': None,
         'fontesCampos': {}, 'observacoesValidacao': None,
         'pendencias': unit['pendencias']} for unit in report['unidades']]}


def generate(args):
    previous_report = read_json(args.report) if args.report.exists() else None
    records = load_records(args.base)
    addresses = read_json(args.addresses)
    lookup = {entry['id']: entry for entry in addresses}
    if len(lookup) != len(addresses) or set(lookup) != {row['id'] for row in records}:
        raise ValueError('O arquivo de endereços precisa corresponder exatamente aos IDs da base.')
    queries_count = sum(bool(entry.get(key)) for entry in addresses
                        for key in ('enderecoPesquisa', 'instituicaoPesquisa'))
    if args.online and urllib.parse.urlparse(args.endpoint).hostname == 'photon.komoot.io' and queries_count > 10:
        raise ValueError('Servidor de demonstração não pode receber lote nacional. Use instância própria/contratada e respeite sua política.')
    args.cache.mkdir(parents=True, exist_ok=True)
    lock = args.cache / '.geocode.lock'
    with lock.open('x', encoding='utf-8') as stream:
        stream.write('Execução administrativa exclusiva; não iniciar outro processo simultâneo.')
    try:
        client = PhotonClient(args.endpoint, args.cache, args.online)
        units = []
        for row in records:
            entry = lookup[row['id']]
            official_url(entry['fonteEndereco'])
            results, errors, queries = {}, [], []
            for key in ('enderecoPesquisa', 'instituicaoPesquisa'):
                query = entry.get(key)
                if not query or not isinstance(query, str):
                    continue
                response = client.search(query)
                queries.append({'texto': query, 'url': response['url'], 'consultadoEm': response.get('consultadoEm')})
                if response.get('erro'): errors.append(response['erro'])
                for feature in response['features']:
                    parsed = candidate(feature, response['url'], row['cidade'], entry.get('termosIdentificacao', []), row['estado'])
                    if parsed: results[parsed['candidatoId']] = parsed
            units.append({'id': row['id'], 'nome': row['nome'],
                          'enderecoPesquisa': entry['enderecoPesquisa'], 'fonteEndereco': entry['fonteEndereco'],
                          'confirmacaoDocumental': entry.get('confirmacaoDocumental'),
                          'enderecoOperacionalConfirmado': False, 'consultas': queries,
                          'candidatos': list(results.values()), 'erros': errors,
                          'pendencias': list(dict.fromkeys([*row.get('pendencias', []), *entry.get('pendencias', []),
                              'Conferir manualmente se o ponto é a unidade real e confirmar funcionamento atual']))})
        report = {'geradoEm': dt.datetime.now(dt.timezone.utc).isoformat(), 'provedor': client.endpoint,
                  'politicaProvedor': POLICY, 'atribuicao': ATTRIBUTION, 'licenca': 'ODbL',
                  'hashBase': digest(read_json(args.base)), 'hashEnderecos': digest(addresses),
                  'unidades': units, 'requisicoesNestaExecucao': client.requests,
                  'coordenadasAutomaticasSaoVerificadas': False}
        # A identidade permanece estável ao regenerar somente a partir do cache.
        report['hashRevisao'] = digest({'hashBase': report['hashBase'], 'hashEnderecos': report['hashEnderecos'],
                                       'unidades': units, 'provedor': client.endpoint})
        write_json(args.report, report)
        args.report.with_suffix('.md').write_text(markdown_report(report), encoding='utf-8')
        review = review_template(report)
        if args.review.exists():
            existing_review = read_json(args.review)
            if existing_review.get('hashRevisao') != report['hashRevisao']:
                if args.reset_pending_review and previous_report and existing_review == review_template(previous_report):
                    write_json(args.review, review)
                else:
                    raise ValueError('Relatório mudou; use outro --review. Uma revisão editada nunca é sobrescrita.')
        else:
            write_json(args.review, review)
        print(f'Relatório: {args.report}; {sum(len(u["candidatos"]) for u in units)} resultados candidatos; nenhuma aprovação ou gravação no Firebase.')
    finally:
        lock.unlink(missing_ok=True)


def export_approved(args):
    records = load_records(args.base)
    report, reviews = read_json(args.report), read_json(args.review)
    if report.get('hashBase') != digest(read_json(args.base)) or reviews.get('hashRevisao') != report.get('hashRevisao'):
        raise ValueError('A base ou o relatório mudou desde a preparação da revisão.')
    # Detecta edição do relatório que tentaria trocar pontos ou remover avisos.
    expected = digest({key: report[key] for key in ('hashBase', 'hashEnderecos', 'unidades', 'provedor')})
    if expected != report['hashRevisao']:
        raise ValueError('Conteúdo do relatório inconsistente.')
    source_rows = {validated['id']: raw for validated, raw in zip(records, read_json(args.base))}
    review_rows = reviews.get('revisoes', [])
    if len({r['id'] for r in review_rows}) != len(review_rows) or {r['id'] for r in review_rows} != set(source_rows):
        raise ValueError('Revisões duplicadas ou IDs divergentes da base.')
    approved, audit = [], []
    lookup = {unit['id']: unit for unit in report['unidades']}
    for review in review_rows:
        if review.get('status') not in ('pendente', 'rejeitado', 'aprovado'):
            raise ValueError('Status de revisão inválido.')
        if review.get('status') != 'aprovado':
            continue
        identifier = review['id']
        for key in ('pontoRealConfirmado', 'enderecoOperacionalConfirmado', 'funcionamentoConfirmado', 'contatoConfirmado'):
            if review.get(key) is not True: raise ValueError(f'{identifier}: confirmação necessária: {key}.')
        if not isinstance(review.get('revisadoPor'), str) or len(review['revisadoPor'].strip()) < 3:
            raise ValueError(f'{identifier}: identifique a função/alias administrativo do revisor.')
        reviewed = parse_date(review.get('revisadoEm'), 'revisadoEm')
        if review.get('pendencias') != []:
            raise ValueError(f'{identifier}: não aprovar enquanto houver pendências.')
        if not isinstance(review.get('observacoesValidacao'), str) or len(review['observacoesValidacao'].strip()) < 20:
            raise ValueError(f'{identifier}: documente como o ponto e o funcionamento foram confirmados.')
        selected = review.get('candidatoId')
        if selected:
            candidates = {item['candidatoId']: item for item in lookup[identifier]['candidatos']}
            if selected not in candidates or not candidates[selected]['passivelRevisao']:
                raise ValueError(f'{identifier}: centro de cidade/via genérica não é ponto de unidade aprovável.')
        lat, lon = review.get('latitudeVerificada'), review.get('longitudeVerificada')
        if not all(type(value) in (int, float) and math.isfinite(value) for value in (lat, lon)) or abs(lat) > 90 or abs(lon) > 180:
            raise ValueError(f'{identifier}: informe coordenadas confirmadas, não apenas uma candidata.')
        # Exige fonte oficial independente para a coordenada finalmente cadastrada;
        # não converte um resultado OSM automaticamente em coordenada oficial.
        official_url(review.get('fonteCoordenadas'))
        row = dict(source_rows[identifier])
        row.update({'latitude': lat, 'longitude': lon, 'fonteCoordenadas': review['fonteCoordenadas'],
                    'coordenadasVerificadas': True, 'verificadoEm': reviewed.isoformat(),
                    'verificacao': 'verificado', 'ativo': True, 'pendencias': [],
                    'endereco': review.get('enderecoConfirmado'), 'telefone': review.get('telefoneConfirmado'),
                    'fontesCampos': review.get('fontesCampos', {})})
        validate_record(row)
        approved.append(row)
        audit.append({'id': identifier, 'revisadoPor': review['revisadoPor'], 'revisadoEm': reviewed.isoformat(),
                      'observacoesValidacao': review['observacoesValidacao'], 'candidatoId': selected})
    if not approved:
        raise ValueError('Nenhuma unidade foi aprovada manualmente. Nenhum arquivo de publicação foi gerado.')
    # Não sobrescreve base ou revisão nem apaga documentos não aprovados.
    protected = {args.base.resolve(), args.report.resolve(), args.review.resolve(), ADDRESSES.resolve()}
    if args.output.resolve() in protected: raise ValueError('Use um arquivo de saída separado da base e da revisão.')
    write_json(args.output, approved)
    write_json(args.output.with_suffix('.auditoria.json'), {'hashRevisao': report['hashRevisao'], 'revisoes': audit})
    print(f'{len(approved)} unidades aprovadas exportadas para {args.output}. Firebase não foi alterado.')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest='command', required=True)
    generate_cmd = sub.add_parser('generate', help='Gera relatório e revisão pendente; nunca publica.')
    generate_cmd.add_argument('--base', type=Path, default=BASE)
    generate_cmd.add_argument('--addresses', type=Path, default=ADDRESSES)
    generate_cmd.add_argument('--endpoint', default=PROVIDER)
    generate_cmd.add_argument('--cache', type=Path, default=DIRECTORY / 'cache')
    generate_cmd.add_argument('--report', type=Path, default=DIRECTORY / 'sergipe.candidatas.json')
    generate_cmd.add_argument('--review', type=Path, default=DIRECTORY / 'sergipe.aprovacao-manual.json')
    generate_cmd.add_argument('--online', action='store_true', help='Autoriza a pequena consulta pontual; sem repetição periódica.')
    generate_cmd.add_argument('--reset-pending-review', action='store_true', help='Regenera somente template pendente intacto; nunca substitui uma revisão editada.')
    export_cmd = sub.add_parser('export-approved', help='Valida aprovação manual e gera JSON separado para o importador existente.')
    export_cmd.add_argument('--base', type=Path, default=BASE)
    export_cmd.add_argument('--report', type=Path, default=DIRECTORY / 'sergipe.candidatas.json')
    export_cmd.add_argument('--review', type=Path, default=DIRECTORY / 'sergipe.aprovacao-manual.json')
    export_cmd.add_argument('--output', type=Path, default=DIRECTORY / 'sergipe.aprovados.json')
    args = parser.parse_args()
    if args.command == 'generate': generate(args)
    else: export_approved(args)


if __name__ == '__main__':
    if hasattr(sys.stdout, 'reconfigure'):
        sys.stdout.reconfigure(encoding='utf-8')
        sys.stderr.reconfigure(encoding='utf-8')
    try:
        main()
    except Exception as error:
        print(f'Processo interrompido: {type(error).__name__}: {error}', file=sys.stderr)
        sys.exit(1)
