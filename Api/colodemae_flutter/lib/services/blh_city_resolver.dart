import 'dart:convert';
import 'package:flutter/services.dart';
import '../core/utils/location.dart';

class BlhMunicipality {
  const BlhMunicipality(this.city, this.state);
  final String city, state;
}

abstract class BlhCityResolver {
  Future<BlhMunicipality> resolve(AppCoordinates coordinates);
}

/// Geocodificação reversa municipal offline: ponto na malha oficial do IBGE.
/// Não envia nem armazena a posição e não substitui um ponto externo por Aracaju.
class AracajuCityResolver implements BlhCityResolver {
  AracajuCityResolver({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;
  final AssetBundle _bundle;
  Future<Map<String, dynamic>>? _geometry;

  @override
  Future<BlhMunicipality> resolve(AppCoordinates coordinates) async {
    _geometry ??= _load();
    Map<String, dynamic> document;
    try {
      document = await _geometry!;
    } catch (_) {
      _geometry = null;
      rethrow;
    }
    final features = document['features'] as List;
    if (features.length != 1 ||
        features.first['properties']['codarea'] != '2800308') {
      throw const FormatException('Malha municipal de Aracaju inválida.');
    }
    final geometry = features.first['geometry'] as Map<String, dynamic>;
    final polygons = geometry['type'] == 'Polygon'
        ? [geometry['coordinates']]
        : geometry['type'] == 'MultiPolygon'
            ? geometry['coordinates'] as List
            : throw const FormatException('Geometria municipal inválida.');
    for (final polygon in polygons) {
      final rings = polygon as List;
      if (_inside(coordinates, rings.first as List) &&
          !rings.skip(1).any((hole) => _inside(coordinates, hole as List))) {
        return const BlhMunicipality('Aracaju', 'SE');
      }
    }
    throw StateError(
        'Sua localização não foi identificada em Aracaju/SE. A demonstração está disponível para esse município.');
  }

  Future<Map<String, dynamic>> _load() async =>
      jsonDecode(await _bundle.loadString('assets/blh_demo/aracaju.geojson'))
          as Map<String, dynamic>;

  bool _inside(AppCoordinates p, List ring) {
    if (!p.latitude.isFinite || !p.longitude.isFinite) return false;
    var inside = false;
    for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
      final a = ring[i] as List, b = ring[j] as List;
      final ax = (a[0] as num).toDouble(), ay = (a[1] as num).toDouble();
      final bx = (b[0] as num).toDouble(), by = (b[1] as num).toDouble();
      if ((ay > p.latitude) != (by > p.latitude) &&
          p.longitude < (bx - ax) * (p.latitude - ay) / (by - ay) + ax) {
        inside = !inside;
      }
    }
    return inside;
  }
}
