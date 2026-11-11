"""Prepara revisão geográfica e exporta somente pontos com aprovação manual.

Não acessa Firebase, não geocodifica online e não muda o status das unidades.
"""
import argparse
import tempfile
from pathlib import Path
from types import SimpleNamespace

from geocode_blh import ROOT, read_json, export_approved, digest
from import_blh import load_records


def save_new(path, value):
    import json
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open('x', encoding='utf-8') as stream:
        json.dump(value, stream, ensure_ascii=False, indent=2)
        stream.write('\n')


def prepare(output):
    if output.exists(): raise ValueError('Use diretório novo; preservar revisões anteriores.')
    demo = read_json(ROOT / 'assets/blh_demo/unidades-aracaju.json')
    ids = {r['id'] for r in demo}
    base = [r for r in read_json(ROOT / 'data/blh/sergipe.json') if 'se-' + r['chaveUnidade'] in ids]
    addresses = [{'id': row['id'],
        'enderecoPesquisa': f"{row['endereco']}, {row['cidade']}, {row['estado']}, Brasil",
        'fonteEndereco': row['fonte'], 'instituicaoPesquisa': f"{row['nome']}, {row['endereco']}, Aracaju, SE",
        'termosIdentificacao': ['marly', 'sarney'] if row['cnes'] == '0002569' else
            ['santa', 'isabel'] if row['cnes'] == '0002232' else ['lourdes', 'nogueira'],
        'pendencias': ['Confirmar acesso operacional e se o ponto corresponde à unidade real',
            'Preservar divergências e rejeições anteriores; não aprovar resultado genérico']} for row in demo]
    save_new(output / 'base.json', base)
    save_new(output / 'enderecos-pesquisa.json', addresses)
    save_new(output / 'pendencias.json', {'coordenadasAprovadas': 0, 'ids': sorted(ids),
        'fluxoRevisao': 'tools/geocode_blh.py generate/export-approved',
        'historicosPreservados': ['data/blh/geografia/sergipe.candidatas.json',
            'data/blh/geografia/sergipe.aprovacao-manual.json',
            'data/blh/demas/coleta-aracaju-validada/relatorio.json'],
        'observacao': 'Coordenadas cadastrais DEMAS e candidatas não são importadas como verificadas.'})
    print(f'{len(base)} unidades preparadas para revisão; nenhuma coordenada aprovada ou escrita Firebase.')


def export(args):
    if args.output.exists() or args.output.with_suffix('.origem.json').exists():
        raise ValueError('Não sobrescrever registro de pontos já aprovados ou sua origem.')
    with tempfile.TemporaryDirectory() as directory:
        approved = Path(directory) / 'aprovadas.json'
        export_approved(SimpleNamespace(base=args.base, report=args.report, review=args.review, output=approved))
        records = load_records(approved)
        audit = read_json(approved.with_suffix('.auditoria.json'))
        by_id = {r['id']: r for r in audit['revisoes']}
        known = {r['id']: r for r in read_json(ROOT / 'assets/blh_demo/unidades-aracaju.json')}
        if any(r['id'] not in known for r in records): raise ValueError('Ponto sem unidade correspondente na demonstração.')
        if any(r['nome'] != known[r['id']]['nome'] or r['cidade'] != known[r['id']]['cidade'] or r['estado'] != known[r['id']]['estado'] for r in records):
            raise ValueError('Nome/município/UF divergentes da unidade documentada.')
        result = []
        for row in records:
            result.append({k: row[k].isoformat() if k == 'verificadoEm' else row[k]
                for k in ('id', 'latitude', 'longitude', 'coordenadasVerificadas', 'fonteCoordenadas', 'verificadoEm', 'geohash')})
            result[-1]['aprovacaoManual'] = {**by_id[row['id']], 'hashRevisao': audit['hashRevisao']}
        save_new(args.output, result)
        save_new(args.output.with_suffix('.origem.json'), {'hashBase': digest(read_json(args.base)),
            'hashRelatorio': digest(read_json(args.report)), 'hashRevisaoManual': digest(read_json(args.review)),
            'gravacaoFirebase': False, 'ativoPublicadoAlterados': False})
    print('Somente pontos revisados exportados. Instalação no asset é etapa explícita; nada foi publicado.')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest='command', required=True)
    queue = sub.add_parser('prepare')
    queue.add_argument('--output', type=Path, required=True)
    approved = sub.add_parser('export')
    for name in ('base', 'report', 'review', 'output'):
        approved.add_argument('--' + name, type=Path, required=True)
    args = parser.parse_args()
    if args.command == 'prepare': prepare(args.output)
    else: export(args)


if __name__ == '__main__': main()
