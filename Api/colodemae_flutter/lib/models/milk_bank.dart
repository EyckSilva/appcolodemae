import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/geohash.dart';
import '../core/utils/blh_text_format.dart';

class MilkBank {
  const MilkBank(
      {required this.id,
      required this.name,
      required this.type,
      required this.city,
      required this.state,
      required this.source,
      required this.verifiedAt,
      this.isDemonstration = false,
      this.coordinatesVerified = false,
      this.address = '',
      this.hours = '',
      this.phone = '',
      this.phoneNote = '',
      this.latitude,
      this.longitude});

  final String id, name, type, city, state, address, hours, phone, source;
  final String phoneNote;
  String get summaryAddress => BlhAddressText(address).summary;
  String get formattedAddress => address.isEmpty
      ? 'Endereço não informado\n$locality'
      : BlhAddressText(address).details(locality);
  String get formattedPhone => formatBlhPhone(phone);
  String get contactText =>
      [formattedPhone, phoneNote].where((s) => s.isNotEmpty).join('\n');
  final DateTime? verifiedAt;
  final bool isDemonstration;
  final bool coordinatesVerified;
  bool get hasVerifiedCoordinates =>
      coordinatesVerified &&
      hasCoordinates &&
      latitude!.isFinite &&
      longitude!.isFinite &&
      latitude!.abs() <= 90 &&
      longitude!.abs() <= 180;
  bool get canUseAddressForDirections =>
      address.trim().isNotEmpty && (isDemonstration || !hasVerifiedCoordinates);
  final double? latitude, longitude;
  bool get hasCoordinates => latitude != null && longitude != null;
  List<String> get tags => [type];
  String get locality => '$city — $state';

  factory MilkBank.fromFirestore(String id, Map<String, dynamic> data) {
    String requiredText(String key) {
      final value = data[key];
      if (value is! String || value.trim().isEmpty) {
        throw FormatException('Campo inválido: $key');
      }
      return value.trim();
    }

    final source = requiredText('fonte');
    final uri = Uri.tryParse(source);
    final date = data['verificadoEm'];
    final type = requiredText('tipo');
    if (data['ativo'] != true ||
        data['publicado'] != true ||
        date is! Timestamp ||
        date.toDate().isAfter(DateTime.now().add(const Duration(minutes: 5))) ||
        uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        !const ['BLH', 'Posto de Coleta'].contains(type)) {
      throw const FormatException('Unidade não publicada ou não verificada.');
    }
    double? lat, lon;
    var validPoint = false;
    if (data['coordenadasVerificadas'] == true) {
      final a = data['latitude'], b = data['longitude'];
      if (a is num &&
          b is num &&
          a.isFinite &&
          b.isFinite &&
          a.abs() <= 90 &&
          b.abs() <= 180 &&
          data['geohash'] == encodeGeohash(a.toDouble(), b.toDouble())) {
        lat = a.toDouble();
        lon = b.toDouble();
        validPoint = true;
      }
    }
    String optional(String key) =>
        data[key] is String ? (data[key] as String).trim() : '';
    final address = optional('endereco');
    final cep = optional('cep');
    return MilkBank(
        id: id,
        name: requiredText('nome'),
        type: type,
        city: requiredText('cidade'),
        state: requiredText('estado'),
        source: source,
        verifiedAt: date.toDate(),
        address: cep.isNotEmpty &&
                !RegExp(r'\bCEP\b', caseSensitive: false).hasMatch(address)
            ? '$address, CEP $cep'
            : address,
        hours: optional('horarioFuncionamento'),
        phone: optional('telefone'),
        phoneNote: optional('descricaoTelefone'),
        coordinatesVerified: validPoint,
        latitude: lat,
        longitude: lon);
  }
}

class MilkBankResult {
  const MilkBankResult(this.bank, {this.distanceKm});
  final MilkBank bank;
  final double? distanceKm;
  String? get distanceLabel =>
      distanceKm == null || !distanceKm!.isFinite || distanceKm! < 0
          ? null
          : '${distanceKm!.toStringAsFixed(1).replaceAll('.', ',')} km';
}
