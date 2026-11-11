"""Catálogo BLH: validação sem rede por padrão; importação administrativa explícita."""
import argparse
import datetime as dt
import hashlib
import json
import math
import os
import re
import sys
import unicodedata
from collections import Counter
from pathlib import Path
from urllib.parse import urlparse

STATES = set('AC AL AP AM BA CE DF ES GO MA MT MS MG PA PB PR PE PI RJ RN RS RO RR SC SP SE TO'.split())
INPUT_FIELDS = set('id chaveUnidade nome tipo endereco cidade estado latitude longitude telefone horarioFuncionamento ativo fonte fontesCampos consultadoEm verificacao verificadoEm coordenadasVerificadas fonteCoordenadas pendencias'.split())
GENERATED_FIELDS = {'cidadeBusca', 'geohash', 'publicado', 'versaoSchema'}
OWNED_FIELDS = (INPUT_FIELDS - {'id'}) | GENERATED_FIELDS
FILLABLE = set('nome tipo endereco cidade estado telefone horarioFuncionamento fonte consultadoEm fontesCampos'.split())


class UpdateConflict(ValueError):
    pass


def normalize(value):
    text = unicodedata.normalize('NFD', value.strip().lower())
    return ' '.join(''.join(c for c in text if not unicodedata.combining(c)).split())


def geohash(lat, lon, precision=9):
    south, north, west, east = -90., 90., -180., 180.
    alphabet, result, value = '0123456789bcdefghjkmnpqrstuvwxyz', '', 0
    for bit in range(precision * 5):
        lng = bit % 2 == 0
        mid = (west + east) / 2 if lng else (south + north) / 2
        upper = (lon if lng else lat) >= mid
        value = (value << 1) | int(upper)
        if lng:
            if upper: west = mid
            else: east = mid
        else:
            if upper: south = mid
            else: north = mid
        if bit % 5 == 4:
            result += alphabet[value]
            value = 0
    return result


def official_url(value, extra_hosts=()):
    if not isinstance(value, str):
        raise ValueError('Fonte oficial obrigatória.')
    parsed = urlparse(value)
    host = (parsed.hostname or '').lower()
    if parsed.scheme != 'https' or parsed.username or parsed.password or not (
        host in {'fiocruz.br', *extra_hosts} or host.endswith(('.fiocruz.br', '.gov.br', '.edu.br'))
    ):
        raise ValueError('Fonte deve usar HTTPS em domínio oficial aprovado.')
    return value


def parse_date(value, label):
    if not isinstance(value, str):
        raise ValueError(f'{label}: informe data ISO 8601 com fuso.')
    date = dt.datetime.fromisoformat(value.replace('Z', '+00:00'))
    if date.tzinfo is None or date > dt.datetime.now(dt.timezone.utc):
        raise ValueError(f'{label}: data sem fuso ou futura.')
    return date.astimezone(dt.timezone.utc)


def json_safe(value):
    if isinstance(value, dt.datetime):
        return value.astimezone(dt.timezone.utc).isoformat()
    if isinstance(value, dict):
        return {k: json_safe(v) for k, v in value.items()}
    if isinstance(value, list):
        return [json_safe(v) for v in value]
    return value


def content_hash(data):
    owned = {k: v for k, v in data.items() if k in OWNED_FIELDS}
    text = json.dumps(json_safe(owned), ensure_ascii=False, sort_keys=True, separators=(',', ':'))
    return hashlib.sha256(text.encode('utf-8')).hexdigest()


def validate_record(record, extra_hosts=()):
    if not isinstance(record, dict) or set(record) - INPUT_FIELDS:
        raise ValueError('Registro inválido ou campos desconhecidos.')
    data = dict(record)
    for key, maximum in [('chaveUnidade', 100), ('nome', 200), ('cidade', 100), ('estado', 2), ('tipo', 30)]:
        value = data.get(key)
        if not isinstance(value, str) or not 2 <= len(value.strip()) <= maximum:
            raise ValueError(f'Campo obrigatório ou inválido: {key}')
        data[key] = value.strip()
    if not re.fullmatch(r'[a-z0-9]+(?:-[a-z0-9]+)*', data['chaveUnidade']):
        raise ValueError('chaveUnidade deve ser uma chave imutável em minúsculas, sem acentos.')
    if data['estado'] not in STATES or data['tipo'] not in ('BLH', 'Posto de Coleta'):
        raise ValueError('UF ou tipo inválido.')
    identifier = f"{data['estado'].lower()}-{data['chaveUnidade']}"
    if 'id' in data and data['id'] != identifier:
        raise ValueError('ID incompatível com UF e chaveUnidade. Não renomeie documentos existentes.')
    data['id'] = identifier
    if type(data.get('ativo')) is not bool:
        raise ValueError('ativo deve ser um booleano explícito.')
    official_url(data.get('fonte'), extra_hosts)
    if 'consultadoEm' in data:
        data['consultadoEm'] = parse_date(data['consultadoEm'], 'consultadoEm')
    data.setdefault('verificacao', 'pendente')
    if data['verificacao'] not in ('pendente', 'verificado'):
        raise ValueError('verificacao deve ser pendente ou verificado.')
    if 'verificadoEm' in data:
        data['verificadoEm'] = parse_date(data['verificadoEm'], 'verificadoEm')
    for key in ('endereco', 'telefone', 'horarioFuncionamento'):
        if key in data:
            if not isinstance(data[key], str) or not 1 <= len(data[key].strip()) <= 500:
                raise ValueError(f'Omita {key} se não estiver confirmado.')
            data[key] = data[key].strip()
    if 'endereco' in data and len(data['endereco']) < 5:
        raise ValueError('Endereço incompleto.')
    if 'telefone' in data:
        raw = data['telefone']
        digits = re.sub(r'[^0-9+]', '', raw)
        if not re.fullmatch(r'[+0-9().\s-]+', raw) or not re.fullmatch(r'\+?[0-9]{8,15}', digits):
            raise ValueError('Informe um único telefone oficial, sem ramal ou texto livre.')
    sources = data.get('fontesCampos', {})
    if not isinstance(sources, dict) or set(sources) - {'nome', 'tipo', 'endereco', 'cidade', 'estado', 'telefone', 'horarioFuncionamento', 'situacao'}:
        raise ValueError('fontesCampos inválido.')
    for value in sources.values():
        official_url(value, extra_hosts)
    if type(data.get('coordenadasVerificadas', False)) is not bool:
        raise ValueError('coordenadasVerificadas deve ser booleano.')
    data.setdefault('coordenadasVerificadas', False)
    has_coords = 'latitude' in data or 'longitude' in data
    if has_coords:
        lat, lon = data.get('latitude'), data.get('longitude')
        if not all(type(v) in (float, int) and math.isfinite(v) for v in (lat, lon)) or abs(lat) > 90 or abs(lon) > 180:
            raise ValueError('Coordenadas inválidas ou incompletas.')
    if data['coordenadasVerificadas']:
        if not has_coords:
            raise ValueError('Faltam coordenadas verificadas.')
        official_url(data.get('fonteCoordenadas'), extra_hosts)
        data['geohash'] = geohash(data['latitude'], data['longitude'])
    elif 'fonteCoordenadas' in data:
        official_url(data['fonteCoordenadas'], extra_hosts)
    if data['ativo']:
        if data['verificacao'] != 'verificado' or 'verificadoEm' not in data:
            raise ValueError('Unidades não verificadas precisam permanecer com ativo: false.')
        if not all(data.get(k) for k in ('endereco', 'telefone')) or not data['coordenadasVerificadas']:
            raise ValueError('Publicação exige endereço, telefone e coordenadas verificadas.')
        for key in ('nome', 'tipo', 'endereco', 'cidade', 'estado', 'telefone', 'situacao'):
            if key not in sources:
                raise ValueError(f'Publicação exige fonte para {key}.')
    if data['verificacao'] == 'verificado' and 'verificadoEm' not in data:
        raise ValueError('Uma verificação concluída exige verificadoEm.')
    notes = data.get('pendencias', [])
    if not isinstance(notes, list) or any(not isinstance(x, str) or not x.strip() for x in notes):
        raise ValueError('pendencias precisa ser uma lista de textos.')
    if data['ativo'] and notes:
        raise ValueError('Não publique unidade com pendências abertas.')
    data['publicado'] = data['ativo']
    data['cidadeBusca'] = normalize(data['cidade'])
    data['versaoSchema'] = 2
    data['hashConteudo'] = content_hash(data)
    return data


def pending_items(record):
    pending = list(record.get('pendencias', []))
    if record['verificacao'] != 'verificado': pending.append('Confirmar situação e dados cadastrais atuais')
    for key in ('endereco', 'telefone'):
        if not record.get(key): pending.append(f'Confirmar {key}')
    if not record['coordenadasVerificadas']: pending.append('Obter coordenadas verificadas em fonte oficial')
    return list(dict.fromkeys(pending))


def plan_update(record, existing, mode='create-only'):
    """Função pura: sem sobrescrita por padrão; decisões auditáveis e testáveis."""
    candidate = {k: v for k, v in record.items() if k != 'id'}
    if existing is None:
        return 'create', candidate
    for key in ('estado', 'chaveUnidade'):
        if key in existing and existing[key] != candidate[key]:
            raise UpdateConflict(f'Identidade divergente em {record["id"]}: {key}.')
    compared = {k: v for k, v in candidate.items() if k != 'hashConteudo'}
    if all(k in existing and existing[k] == v for k, v in compared.items()):
        return 'unchanged', {}
    if mode == 'create-only':
        raise UpdateConflict(f'{record["id"]}: documento existente diferente; escolha uma política explícita.')
    if mode == 'fill-missing':
        if existing.get('ativo') or existing.get('publicado'):
            raise UpdateConflict('fill-missing não altera unidades já publicadas; use update-verified.')
        patch = {k: v for k, v in candidate.items() if k in FILLABLE and (k not in existing or existing[k] is None or existing[k] == '')}
        if not patch:
            return 'preserved', {}
    elif mode == 'update-draft':
        if existing.get('ativo') or existing.get('publicado') or candidate.get('ativo') or candidate.get('publicado'):
            raise UpdateConflict('update-draft só permite alterar rascunhos inativos.')
        consulted = candidate.get('consultadoEm')
        previous = existing.get('consultadoEm')
        if not isinstance(consulted, dt.datetime) or previous is not None and (not isinstance(previous, dt.datetime) or consulted <= previous):
            raise UpdateConflict('Atualizar rascunho exige consultadoEm posterior ao existente.')
        patch = {k: v for k, v in candidate.items() if k != 'hashConteudo' and (k not in existing or existing[k] != v)}
    elif mode == 'update-verified':
        verified = candidate.get('verificadoEm')
        if candidate['verificacao'] != 'verificado' or not isinstance(verified, dt.datetime):
            raise UpdateConflict('Atualização exige nova verificação concluída e datada.')
        previous = existing.get('verificadoEm')
        if previous is not None and (not isinstance(previous, dt.datetime) or verified <= previous):
            raise UpdateConflict('Atualização precisa de verificação posterior à existente.')
        # Somente campos fornecidos; omissões nunca apagam dados existentes.
        patch = {k: v for k, v in candidate.items() if k != 'hashConteudo' and (k not in existing or existing[k] != v)}
    else:
        raise ValueError('Política desconhecida.')
    merged = {**existing, **patch}
    if merged.get('ativo') and merged.get('pendencias'):
        raise UpdateConflict('Encerre explicitamente as pendências existentes com pendencias: [] antes de ativar.')
    patch['hashConteudo'] = content_hash(merged)
    return 'update', patch


def initialize_db(project, cli_auth=False):
    import firebase_admin
    from firebase_admin import credentials, firestore
    credential = None
    if cli_auth:
        # Token de curta duração recebido apenas do helper. Não é escrito em disco.
        from google.oauth2.credentials import Credentials
        token = os.environ.pop('BLH_FIREBASE_ACCESS_TOKEN', None)
        if not token:
            raise ValueError('Use tools/run_blh_with_firebase_cli.cjs para autenticação efêmera.')
        class EphemeralCredential(credentials.Base):
            def get_credential(self):
                return Credentials(token=token)
        credential = EphemeralCredential()
    app = firebase_admin.initialize_app(credential, options={'projectId': project})
    return firestore.client(app=app)


def remote_plan(db, records, mode):
    result, conflicts = [], []
    for record in records:
        snapshot = db.collection('bancos_leite').document(record['id']).get()
        existing = snapshot.to_dict() if snapshot.exists else None
        try:
            action, _ = plan_update(record, existing, mode)
            row = {'id': record['id'], 'action': action, 'existeNoFirebase': snapshot.exists}
            if existing is not None:
                row.update({
                    'ativoPersistido': existing.get('ativo'),
                    'publicadoPersistido': existing.get('publicado'),
                    'coordenadasVerificadasPersistidas': existing.get('coordenadasVerificadas'),
                    'criadoEm': existing.get('criadoEm'),
                    'atualizadoEm': existing.get('atualizadoEm'),
                    'criadoNoFirestoreEm': snapshot.create_time,
                    'ultimaGravacaoFirestoreEm': snapshot.update_time,
                })
            result.append(row)
        except UpdateConflict as error:
            conflicts.append(str(error))
    if conflicts:
        raise UpdateConflict('\n'.join(conflicts))
    return result


def apply_records(db, records, mode):
    from firebase_admin import firestore
    actions = []
    for record in records:
        ref = db.collection('bancos_leite').document(record['id'])
        @firestore.transactional
        def save(transaction):
            snapshot = ref.get(transaction=transaction)
            action, patch = plan_update(record, snapshot.to_dict() if snapshot.exists else None, mode)
            if action == 'create':
                transaction.set(ref, {**patch, 'criadoEm': firestore.SERVER_TIMESTAMP, 'atualizadoEm': firestore.SERVER_TIMESTAMP})
            elif action == 'update':
                transaction.update(ref, {**patch, 'atualizadoEm': firestore.SERVER_TIMESTAMP})
            return action
        actions.append({'id': record['id'], 'action': save(db.transaction())})
    return actions


def load_records(path, extra_hosts=()):
    raw = json.loads(path.read_text(encoding='utf-8-sig'))
    if not isinstance(raw, list): raise ValueError('O arquivo deve conter uma lista JSON.')
    records = [validate_record(row, extra_hosts) for row in raw]
    if len({row['id'] for row in records}) != len(records): raise ValueError('Identidades duplicadas no arquivo.')
    return records


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('arquivo', type=Path)
    parser.add_argument('--project')
    parser.add_argument('--official-host', action='append', default=[])
    parser.add_argument('--on-existing', choices=['create-only', 'fill-missing', 'update-draft', 'update-verified'], default='create-only')
    parser.add_argument('--apply', action='store_true')
    parser.add_argument('--publish', action='store_true', help='Permite publicar somente registros completos e ativos.')
    parser.add_argument('--check-remote', action='store_true', help='Compara com Firestore, sem gravar.')
    parser.add_argument('--report', type=Path)
    parser.add_argument('--firebase-cli-auth', action='store_true', help=argparse.SUPPRESS)
    args = parser.parse_args()
    records = load_records(args.arquivo, args.official_host)
    if args.apply and any(row['ativo'] for row in records) and not args.publish:
        raise ValueError('Ativar unidades exige --publish explícito, além de --apply.')
    if (args.apply or args.check_remote) and not args.project:
        raise ValueError('Especifique --project para acessar o Firebase.')
    report = [{'id': row['id'], 'nome': row['nome'], 'ativo': row['ativo'],
               'coordenadasVerificadas': row['coordenadasVerificadas'], 'pendencias': pending_items(row)} for row in records]
    actions = []
    if args.apply or args.check_remote:
        db = initialize_db(args.project, args.firebase_cli_auth)
        actions = remote_plan(db, records, args.on_existing)
        if args.apply: actions = apply_records(db, records, args.on_existing)
    summary = {'registros': report, 'acoes': actions,
               'modoAplicacao': args.apply,
               'gravacaoExecutada': args.apply and any(row['action'] in ('create', 'update') for row in actions),
               'politica': args.on_existing, 'resumoAcoes': dict(Counter(row['action'] for row in actions))}
    summary = json_safe(summary)
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(summary, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(summary, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    if hasattr(sys.stdout, 'reconfigure'):
        sys.stdout.reconfigure(encoding='utf-8')
        sys.stderr.reconfigure(encoding='utf-8')
    try:
        main()
    except Exception as error:
        # Nunca despejar variáveis de ambiente, credenciais ou tokens no relatório.
        print(f'Importação interrompida: {type(error).__name__}: {error}', file=sys.stderr)
        sys.exit(1)
