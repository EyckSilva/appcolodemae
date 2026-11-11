import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/milk_bank.dart';
import '../core/utils/distance.dart';
import '../core/utils/geohash.dart';

class MilkBankPage {
  const MilkBankPage(this.banks, {this.cursor});
  final List<MilkBank> banks;
  final Object? cursor;
}

abstract class MilkBankRepository {
  Future<List<MilkBankResult>> nearby(double latitude, double longitude);
  Future<MilkBankPage> byCity(String city, String state, {Object? cursor});
}

class FirestoreMilkBankRepository implements MilkBankRepository {
  FirestoreMilkBankRepository({FirebaseFirestore? firestore})
      : _providedDb = firestore;
  final FirebaseFirestore? _providedDb;
  FirebaseFirestore get _db => _providedDb ?? FirebaseFirestore.instance;
  Query<Map<String, dynamic>> get _published => _db
      .collection('bancos_leite')
      .where('ativo', isEqualTo: true)
      .where('publicado', isEqualTo: true);

  List<MilkBank> _parse(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final banks = <MilkBank>[];
    for (final doc in docs) {
      try {
        banks.add(MilkBank.fromFirestore(doc.id, doc.data()));
      } on FormatException {
        /* Registros inválidos não são apresentados como unidades reais. */
      }
    }
    return banks;
  }

  @override
  Future<List<MilkBankResult>> nearby(double latitude, double longitude) async {
    final prefixes = nearbyGeohashPrefixes(latitude, longitude);
    final responses = await Future.wait(prefixes.map((prefix) => _published
        .where('coordenadasVerificadas', isEqualTo: true)
        .orderBy('geohash')
        .startAt([prefix])
        .endAt(['$prefix\uf8ff'])
        .limit(101)
        .get(const GetOptions(source: Source.server))
        .timeout(const Duration(seconds: 25))));
    if (responses.any((page) => page.docs.length > 100)) {
      throw StateError(
          'Muitas unidades nesta região. Busque por cidade e estado.');
    }
    final unique = <String, MilkBank>{};
    for (final page in responses) {
      for (final bank in _parse(page.docs)) {
        unique[bank.id] = bank;
      }
    }
    return rankMilkBanks(unique.values, latitude, longitude, radiusKm: 50);
  }

  @override
  Future<MilkBankPage> byCity(String city, String state,
      {Object? cursor}) async {
    var query = _published
        .where('cidadeBusca', isEqualTo: normalizeCity(city))
        .where('estado', isEqualTo: state.toUpperCase())
        .orderBy(FieldPath.documentId)
        .limit(50);
    if (cursor != null) {
      query = query
          .startAfterDocument(cursor as DocumentSnapshot<Map<String, dynamic>>);
    }
    final page = await query
        .get(const GetOptions(source: Source.server))
        .timeout(const Duration(seconds: 25));
    return MilkBankPage(_parse(page.docs),
        cursor: page.docs.length == 50 ? page.docs.last : null);
  }
}

List<MilkBankResult> rankMilkBanks(
    Iterable<MilkBank> banks, double lat, double lon,
    {double radiusKm = 50}) {
  final results = <MilkBankResult>[];
  for (final bank in banks) {
    if (!bank.hasCoordinates) continue;
    final distance = haversineKm(lat, lon, bank.latitude!, bank.longitude!);
    if (distance <= radiusKm) {
      results.add(MilkBankResult(bank, distanceKm: distance));
    }
  }
  results.sort((a, b) {
    final byDistance = a.distanceKm!.compareTo(b.distanceKm!);
    return byDistance == 0 ? a.bank.id.compareTo(b.bank.id) : byDistance;
  });
  return results;
}
