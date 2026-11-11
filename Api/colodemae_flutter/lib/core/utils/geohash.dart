import 'dart:math' as math;

const _alphabet = '0123456789bcdefghjkmnpqrstuvwxyz';

String encodeGeohash(double latitude, double longitude, {int precision = 9}) {
  if (!latitude.isFinite ||
      !longitude.isFinite ||
      latitude.abs() > 90 ||
      longitude.abs() > 180 ||
      precision < 1 ||
      precision > 12) {
    throw ArgumentError('Coordenadas inválidas.');
  }
  var south = -90.0, north = 90.0, west = -180.0, east = 180.0;
  var value = 0;
  final result = StringBuffer();
  for (var bit = 0; bit < precision * 5; bit++) {
    final longitudeBit = bit.isEven;
    final mid = longitudeBit ? (west + east) / 2 : (south + north) / 2;
    final upper = (longitudeBit ? longitude : latitude) >= mid;
    value = (value << 1) | (upper ? 1 : 0);
    if (longitudeBit) {
      if (upper) {
        west = mid;
      } else {
        east = mid;
      }
    } else {
      if (upper) {
        south = mid;
      } else {
        north = mid;
      }
    }
    if (bit % 5 == 4) {
      result.write(_alphabet[value]);
      value = 0;
    }
  }
  return result.toString();
}

/// Células geohash de precisão 3 que cobrem o círculo de busca. A distância
/// exata é filtrada depois; não se consulta a coleção nacional inteira.
Set<String> nearbyGeohashPrefixes(double lat, double lon,
    {double radiusKm = 50}) {
  encodeGeohash(lat, lon);
  if (!radiusKm.isFinite || radiusKm <= 0 || radiusKm > 100) {
    throw ArgumentError('Raio inválido.');
  }
  final angular = radiusKm / 6371;
  final latitude = lat * math.pi / 180;
  final south = math.max(-90.0, lat - angular * 180 / math.pi);
  final north = math.min(90.0, lat + angular * 180 / math.pi);
  final allLongitudes = south <= -90 || north >= 90;
  final deltaLon = allLongitudes
      ? 180.0
      : math.asin((math.sin(angular) / math.cos(latitude)).clamp(-1.0, 1.0)) *
          180 /
          math.pi;
  const step = 180 / 128; // 7 bits de latitude, 8 de longitude.
  final prefixes = <String>{};
  final minY = ((south + 90) / step).floor().clamp(0, 127);
  final maxY = ((north + 90) / step).floor().clamp(0, 127);
  final minX = ((lon - deltaLon + 180) / step).floor();
  final maxX = ((lon + deltaLon + 180) / step).floor();
  if ((maxX - minX + 1) * (maxY - minY + 1) > 64) {
    throw StateError('Busque por cidade e estado nesta região.');
  }
  for (var y = minY; y <= maxY; y++) {
    for (var x = minX; x <= maxX; x++) {
      final wrapped = x % 256;
      prefixes.add(encodeGeohash(
          -90 + (y + 0.5) * step, -180 + (wrapped + 0.5) * step,
          precision: 3));
    }
  }
  return prefixes;
}

String normalizeCity(String value) {
  const accented = 'áàâãäéèêëíìîïóòôõöúùûüç';
  const plain = 'aaaaaeeeeiiiiooooouuuuc';
  final text =
      value.trim().toLowerCase().replaceAll(RegExp(r'[\u0300-\u036f]'), '');
  return text
      .split('')
      .map((c) {
        final index = accented.indexOf(c);
        return index < 0 ? c : plain[index];
      })
      .join()
      .replaceAll(RegExp(r'\s+'), ' ');
}
