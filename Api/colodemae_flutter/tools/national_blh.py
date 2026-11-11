"""Etapa 9: catálogo nacional offline, rastreável e sem publicação automática.

Não acessa Firebase e não geocodifica em massa. Reutiliza import_blh/geocode_blh.
"""
import argparse
import hashlib
import json
import re
from collections import Counter
from html.parser import HTMLParser
from pathlib import Path

from import_blh import STATES, load_records, normalize, validate_record
from geocode_blh import read_json, write_json, digest, generate, PROVIDER
from types import SimpleNamespace
from blh_preservation import preserved

ROOT = Path(__file__).resolve().parents[1]
DIRECTORY = ROOT / 'data/blh/nacional'
ALIASES = {
    ('SE', '5714397'): 'blh-marly-sarney',
    ('SE', '2503824'): 'blh-zoed-bittencourt',
    ('SE', '2546027'): 'blh-irma-rafaela-pepel',
}
CLASSES = ('aprovados_verificados', 'aguardando_validacao', 'ambiguos_conflitantes', 'sem_coordenadas')


class AnnexParser(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.rows, self.row, self.cell = [], None, None

    def handle_starttag(self, tag, attrs):
        if tag == 'tr': self.row = []
        if tag in ('td', 'th') and self.row is not None: self.cell = []
        if tag == 'br' and self.cell is not None: self.cell.append(' ')

    def handle_data(self, data):
        if self.cell is not None: self.cell.append(data)

    def handle_endtag(self, tag):
        if tag in ('td', 'th') and self.cell is not None:
            self.row.append(' '.join(''.join(self.cell).split()))
            self.cell = None
        if tag == 'tr' and self.row is not None:
            self.rows.append(self.row)
            self.row = None


def parse_annex(text):
    parser = AnnexParser()
    parser.feed(text)
    headers = [row for row in parser.rows if len(row) == 11 and row[0] == 'UF']
    if len(headers) != 1 or normalize(headers[0][3]) != 'municipio do blh' or headers[0][6] != 'CNES':
        raise ValueError('Estrutura do anexo mudou: revisar mapeamento antes de importar.')
    rows = [row for row in parser.rows if row and row[0] in STATES]
    if not rows or any(len(row) != 11 or not re.fullmatch(r'\d{7}', row[6]) for row in rows):
        raise ValueError('Linha oficial incompleta ou CNES inválido.')
    keys = [(row[0], row[6]) for row in rows]
    if len(set(keys)) != len(keys): raise ValueError('CNES repetido no anexo; resolver identidade manualmente.')
    return rows


def check_unique(raw_records):
    ids, names = set(), set()
    for raw in raw_records:
        record = validate_record(raw)
        key = (record['estado'], normalize(record['cidade']), normalize(record['nome']), record['tipo'])
        if record['id'] in ids or key in names:
            raise ValueError(f"Possível duplicata: {record['id']}; resolver identidade antes de importar.")
        ids.add(record['id'])
        names.add(key)


def classify(record, candidates=()):
    if record.get('ativo') and record.get('coordenadasVerificadas') and record.get('verificacao') == 'verificado':
        validate_record(record)
        return CLASSES[0]
    usable = [item for item in candidates if item.get('passivelRevisao')]
    if len(usable) > 1 or (candidates and not usable): return CLASSES[2]
    if usable or ('latitude' in record and 'longitude' in record): return CLASSES[1]
    return CLASSES[3]


def verify_preservation():
    hashes = read_json(DIRECTORY / 'preservacao-etapa9.sha256.json')
    changed = [name for name, expected in hashes.items()
               if not preserved(ROOT, name, expected)]
    if changed: raise ValueError(f'Arquivo protegido alterado nesta etapa: {changed}')
    return len(hashes)


def build():
    manifest = read_json(DIRECTORY / 'fontes/manifesto.json')
    sources = {entry['arquivo']: entry for entry in manifest}
    for entry in manifest:
        if hashlib.sha256((DIRECTORY / 'fontes' / entry['arquivo']).read_bytes()).hexdigest() != entry['sha256']:
            raise ValueError('Snapshot alterado: fonte precisa ser novamente documentada.')
    source = sources['portaria-11175-2026.html']
    annex = parse_annex((DIRECTORY / 'fontes' / source['arquivo']).read_text(encoding='utf-8-sig'))
    existing = read_json(ROOT / 'data/blh/sergipe.json')
    records = list(existing)
    traces = {}
    existing_keys = {r['chaveUnidade']: r for r in existing}
    for position, row in enumerate(annex, 1):
        uf, cnes = row[0], row[6]
        key = ALIASES.get((uf, cnes), 'blh-cnes-' + cnes)
        identifier = uf.lower() + '-' + key
        if (uf, cnes) in ALIASES:
            if key not in existing_keys: raise ValueError('Alias sem registro de Sergipe correspondente.')
        else:
            records.append({'chaveUnidade': key, 'nome': row[8], 'tipo': 'BLH',
                'cidade': row[3], 'estado': uf, 'ativo': False, 'coordenadasVerificadas': False,
                'verificacao': 'pendente', 'fonte': source['url'], 'consultadoEm': source['consultadoEm'],
                'fontesCampos': {field: source['url'] for field in ('nome', 'tipo', 'cidade', 'estado')},
                'pendencias': ['Registro documental no anexo federal, referência fevereiro de 2026; confirmar funcionamento atual',
                    'Obter endereço operacional completo, CEP, telefone e horários em fonte oficial',
                    'Obter coordenadas candidatas de endereço oficial e aprovação manual documentada']})
        traces[identifier] = {'fonte': source['url'], 'snapshot': 'fontes/' + source['arquivo'],
            'sha256Fonte': source['sha256'], 'linhaAnexo': position, 'cnesInformadoNoAnexo': cnes,
            'mantenedora': row[7], 'municipioEntidade': row[1], 'municipioBLH': row[3],
            'nomeNoAnexo': row[8], 'referenciaTemporal': 'fevereiro de 2026',
            'observacao': 'CNES do anexo pode identificar a maternidade mantenedora; não é georreferenciamento.',
            'aliasPreservado': (uf, cnes) in ALIASES}
    extras = read_json(DIRECTORY / 'fontes/complementos-df.json')
    for raw in extras:
        records.append(raw)
        identifier = validate_record(raw)['id']
        traces[identifier] = {'fonte': raw['fonte'], 'snapshot': 'fontes/amamenta-brasilia.html',
            'sha256Fonte': sources['amamenta-brasilia.html']['sha256'],
            'observacao': 'Contato também consta na página Banco de Leite da SES-DF; endereço exige confirmação operacional.'}
    check_unique(records)
    records.sort(key=lambda row: row['estado'])
    if {row['estado'] for row in records} != STATES: raise ValueError('Base sem representação das 27 UFs.')
    geography = read_json(ROOT / 'data/blh/geografia/sergipe.candidatas.json')
    geo_units = {row['id']: row for row in geography['unidades']}
    grouped, table, all_traces = {}, {}, []
    for uf in sorted(STATES):
        units = [r for r in records if r['estado'] == uf]
        grouped[uf] = units
        folder = DIRECTORY / uf
        # SE referencia a base histórica, sem copiar nem alterar os cinco registros.
        if uf != 'SE': write_json(folder / 'unidades.json', units)
        national_geo = folder / 'coordenadas.candidatas.json'
        if uf != 'SE' and national_geo.exists():
            report = read_json(national_geo)
            if report['hashBase'] != digest(units):
                raise ValueError(f'{uf}: base mudou; gerar novo relatório e preservar revisão anterior.')
            geo_units.update({unit['id']: unit for unit in report['unidades']})
        unit_traces = []
        for raw in units:
            record = validate_record(raw)
            identifier = record['id']
            geo = geo_units.get(identifier)
            candidates = geo['candidatos'] if geo else []
            item = {'id': identifier, 'nome': record['nome'], 'tipo': record['tipo'],
                'cidade': record['cidade'], 'estado': uf, 'classe': classify(raw, candidates),
                'ativo': record['ativo'], 'coordenadasAprovadas': record['coordenadasVerificadas'],
                'quantidadeResultadosGeocodificador': len(candidates),
                'quantidadeCandidatasRevisaveis': sum(c.get('passivelRevisao', False) for c in candidates),
                'pendencias': raw.get('pendencias', []),
                'documentacao': traces.get(identifier, {'fonte': raw['fonte']}),
                'relatorioGeografico': ('../../geografia/sergipe.candidatas.json' if uf == 'SE'
                    else 'coordenadas.candidatas.json') if geo else None,
                'aprovacaoManual': ('../../geografia/sergipe.aprovacao-manual.json' if uf == 'SE'
                    else 'aprovacao-manual.json') if geo else None,
                'candidatos': [{'id': c['candidatoId'], 'latitude': c['latitude'], 'longitude': c['longitude'],
                    'fonte': c['fonte'], 'passivelRevisao': c['passivelRevisao']} for c in candidates]}
            unit_traces.append(item)
            all_traces.append(item)
        write_json(folder / 'rastreabilidade.json', unit_traces)
        table[uf] = {'BLH': sum(r['tipo'] == 'BLH' for r in units),
            'PCLH': sum(r['tipo'] == 'Posto de Coleta' for r in units), 'total': len(units),
            **{label: sum(t['classe'] == label for t in unit_traces) for label in CLASSES}}
    paths = ['../sergipe.json' if uf == 'SE' else uf + '/unidades.json' for uf in sorted(STATES)]
    write_json(DIRECTORY / 'manifesto.json', {'colecao': 'bancos_leite', 'arquivos': paths,
        'politica': 'create-only; nunca publicar automaticamente', 'fontes': manifest,
        'limitacao': 'Base documental parcial; não representa inventário completo da rede brasileira nem funcionamento atual.'})
    write_json(DIRECTORY / 'importacao-rascunhos.json', records)
    write_json(DIRECTORY / 'relatorio.json', {'porUF': table, 'total': len(records),
        'BLH': sum(row['BLH'] for row in table.values()), 'PCLH': sum(row['PCLH'] for row in table.values()),
        'resultadosGeocodificador': sum(t['quantidadeResultadosGeocodificador'] for t in all_traces),
        'candidatasRevisaveis': sum(t['quantidadeCandidatasRevisaveis'] for t in all_traces),
        'aprovadas': sum(t['coordenadasAprovadas'] for t in all_traces),
        'classes': {label: sum(t['classe'] == label for t in all_traces) for label in CLASSES},
        'arquivosProtegidosIntactos': verify_preservation(),
        'limitacao': '210 BLHs do anexo federal e PCLHs documentados em SE/DF; completar inventário e revisão por UF.'})
    print(json.dumps({'unidades': len(records), 'UFs': len(grouped), 'fontesLocaisValidadas': len(manifest),
                      'publicacao': False}, ensure_ascii=False))


def aggregate(manifest_path, output):
    manifest = read_json(manifest_path)
    records = []
    for name in manifest['arquivos']:
        path = (manifest_path.parent / name).resolve()
        if not path.is_relative_to((ROOT / 'data/blh').resolve()): raise ValueError('Arquivo fora da base administrativa.')
        load_records(path)
        records.extend(read_json(path))
    check_unique(records)
    if any(row.get('ativo') for row in records): raise ValueError('Agregação de rascunhos não aceita registros ativos. Use export-approved.')
    protected = {(manifest_path.parent / name).resolve() for name in manifest['arquivos']}
    protected.add(manifest_path.resolve())
    if output.resolve() in protected: raise ValueError('Saída não pode sobrescrever fonte ou manifesto.')
    write_json(output, records)
    print(f'{len(records)} rascunhos validados; nenhuma conexão com Firebase.')


def prepare_geography():
    """Cria filas sem rede. Revisões já existentes nunca são regeneradas aqui."""
    for uf in sorted(STATES - {'SE'}):
        folder = DIRECTORY / uf
        base = folder / 'unidades.json'
        addresses = folder / 'enderecos-pesquisa.json'
        report = folder / 'coordenadas.candidatas.json'
        review = folder / 'aprovacao-manual.json'
        if not addresses.exists():
            write_json(addresses, [{'id': row['id'],
                'enderecoPesquisa': f"{row['endereco']}, {row['cidade']}, {uf}, Brasil" if row.get('endereco') else '',
                'fonteEndereco': row.get('fontesCampos', {}).get('endereco', row['fonte']),
                'termosIdentificacao': [],
                'pendencias': row.get('pendencias', [])} for row in load_records(base)])
        if report.exists() or review.exists(): continue
        generate(SimpleNamespace(base=base, addresses=addresses, report=report, review=review,
            endpoint=PROVIDER, cache=ROOT / 'data/blh/geografia/cache', online=False, reset_pending_review=False))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest='command', required=True)
    sub.add_parser('build')
    sub.add_parser('check-preservation')
    sub.add_parser('prepare-geography')
    aggregate_cmd = sub.add_parser('aggregate')
    aggregate_cmd.add_argument('--manifest', type=Path, default=DIRECTORY / 'manifesto.json')
    aggregate_cmd.add_argument('--output', type=Path, default=DIRECTORY / 'importacao-rascunhos.json')
    args = parser.parse_args()
    if args.command == 'build': build()
    elif args.command == 'aggregate': aggregate(args.manifest, args.output)
    elif args.command == 'prepare-geography': prepare_geography()
    else: print(f'{verify_preservation()} arquivos protegidos intactos.')


if __name__ == '__main__':
    main()
