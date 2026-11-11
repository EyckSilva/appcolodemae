import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../core/utils/geohash.dart';
import '../models/milk_bank.dart';
import 'milk_bank_repository.dart';

const blhDemoEnabled = kDebugMode && bool.fromEnvironment('BLH_DEMO');

String normalizeBlhState(String value) {
  final normalized = normalizeCity(value).replaceFirst(RegExp(r'^br[-\s]'), '');
  return normalized == 'sergipe' ? 'SE' : normalized.toUpperCase();
}

/// Fonte documental local, sem publicar ou simular verificação no Firestore.
class DemoMilkBankRepository implements MilkBankRepository {
  DemoMilkBankRepository({AssetBundle? bundle})
      : _bundle = bundle ?? rootBundle {
    if (!kDebugMode) {
      throw StateError('Fonte de demonstração indisponível em produção.');
    }
  }
  final AssetBundle _bundle;
  @override
  Future<List<MilkBankResult>> nearby(double latitude, double longitude) =>
      throw UnsupportedError(
          'A demonstração consulta município, sem raio ou distância.');

  @override
  Future<MilkBankPage> byCity(String city, String state,
      {Object? cursor}) async {
    if (normalizeCity(city) != 'aracaju' || normalizeBlhState(state) != 'SE') {
      return const MilkBankPage([]);
    }
    final rows = jsonDecode(
            await _bundle.loadString('assets/blh_demo/unidades-aracaju.json'))
        as List;
    final approved = await _approvedCoordinates();
    return MilkBankPage(rows.map((item) {
      final row = item as Map<String, dynamic>;
      if (row['ativo'] != false ||
          row['publicado'] != false ||
          row['coordenadasVerificadas'] != false) {
        throw const FormatException(
            'A demonstração não pode declarar publicação/verificação.');
      }
      final cep = row['cep'] as String?;
      final point = approved[row['id']];
      return MilkBank(
          id: row['id'],
          name: row['nome'],
          type: row['tipo'],
          city: row['cidade'],
          state: row['estado'],
          source: row['fonte'],
          verifiedAt: null,
          address: '${row['endereco']}${cep == null ? '' : ', CEP $cep'}',
          phone: row['telefone'],
          phoneNote: row['descricaoTelefone'] ?? '',
          hours: row['horarioFuncionamento'] ?? '',
          latitude: (point?['latitude'] as num?)?.toDouble(),
          longitude: (point?['longitude'] as num?)?.toDouble(),
          coordinatesVerified: point != null,
          isDemonstration: true);
    }).toList());
  }

  Future<Map<String, Map<String, dynamic>>> _approvedCoordinates() async {
    final result = <String, Map<String, dynamic>>{};
    final ambiguous = <String>{};
    final seen = <String>{};
    try {
      final rows = jsonDecode(await _bundle
          .loadString('assets/blh_demo/coordenadas-aprovadas.json')) as List;
      for (final item in rows) {
        if (item is! Map<String, dynamic> || item['id'] is! String) continue;
        final id = item['id'] as String;
        if (!seen.add(id)) {
          result.remove(id);
          ambiguous.add(id);
        }
        if (ambiguous.contains(id)) continue;
        final lat = item['latitude'], lon = item['longitude'];
        final date = DateTime.tryParse(item['verificadoEm']?.toString() ?? '');
        final source = Uri.tryParse(item['fonteCoordenadas']?.toString() ?? '');
        final audit = item['aprovacaoManual'];
        if (item['coordenadasVerificadas'] != true ||
            lat is! num ||
            lon is! num ||
            !lat.isFinite ||
            !lon.isFinite ||
            lat.abs() > 90 ||
            lon.abs() > 180 ||
            date == null ||
            !RegExp(r'(Z|[+-]\d{2}:\d{2})$')
                .hasMatch(item['verificadoEm'].toString()) ||
            date.isAfter(DateTime.now()) ||
            source?.scheme != 'https' ||
            !(source!.host.endsWith('.gov.br') ||
                source.host == 'fiocruz.br' ||
                source.host.endsWith('.fiocruz.br')) ||
            audit is! Map ||
            (audit['revisadoPor']?.toString().trim().length ?? 0) < 3 ||
            (audit['observacoesValidacao']?.toString().trim().length ?? 0) <
                20 ||
            item['geohash'] != encodeGeohash(lat.toDouble(), lon.toDouble())) {
          continue;
        }
        result[id] = item;
      }
    } on Object {
      // Falha/ausência da aprovação não deve esconder a unidade municipal.
      return {};
    }
    return result;
  }
}
