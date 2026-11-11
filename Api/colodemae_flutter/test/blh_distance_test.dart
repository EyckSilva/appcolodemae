// Coordenadas sintéticas exclusivas dos testes; nunca publicadas ou usadas no app.
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colodemae_flutter/core/utils/geohash.dart';
import 'package:colodemae_flutter/core/utils/location.dart';
import 'package:colodemae_flutter/models/milk_bank.dart';
import 'package:colodemae_flutter/services/blh_city_resolver.dart';
import 'package:colodemae_flutter/services/blh_demo_repository.dart';
import 'package:colodemae_flutter/services/blh_distance.dart';
import 'package:colodemae_flutter/services/milk_bank_controller.dart';
import 'package:colodemae_flutter/services/milk_bank_repository.dart';
import 'package:colodemae_flutter/screens/blh/widgets/bank_list_card.dart';
import 'package:colodemae_flutter/app/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

MilkBank fixture(String id,
        {double? lat, double? lon, bool verified = false}) =>
    MilkBank(
        id: id,
        name: 'Unidade artificial de teste',
        type: 'BLH',
        city: 'Aracaju',
        state: 'SE',
        source: 'https://saude.gov.br/fixture',
        verifiedAt: DateTime.utc(2026),
        latitude: lat,
        longitude: lon,
        coordinatesVerified: verified);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'One equatorial degree is about 111 km; units over 50 km and unknown units remain',
      () {
    final banks = [
      fixture('far', lat: 0, lon: 1, verified: true),
      fixture('unknown')
    ];
    final result = withBlhDistances(banks, const AppCoordinates(0, 0));
    expect(result.map((r) => r.bank.id), ['far', 'unknown']);
    expect(result.first.distanceKm, closeTo(111.2, .3));
    expect(result.last.distanceKm, isNull);
  });
  test(
      'Kilometers have decimal comma; zero is valid; invalid estimates have no label',
      () {
    final bank = fixture('fixture');
    expect(MilkBankResult(bank, distanceKm: 3.24).distanceLabel, '3,2 km');
    expect(MilkBankResult(bank, distanceKm: 0).distanceLabel, '0,0 km');
    for (final value in [null, double.nan, double.infinity, -1.0]) {
      expect(MilkBankResult(bank, distanceKm: value).distanceLabel, isNull);
    }
  });
  test(
      'Missing permission/origin, invalid positions and unverified coordinates never yield estimates',
      () {
    final untrusted = fixture('candidate', lat: 0, lon: 1);
    final invalid = fixture('invalid', lat: 91, lon: 0, verified: true);
    final verified = fixture('approved', lat: 0, lon: 1, verified: true);
    expect(
        withBlhDistances([untrusted, invalid], const AppCoordinates(0, 0))
            .every((r) => r.distanceKm == null),
        isTrue);
    expect(withBlhDistances([verified], null).single.distanceKm, isNull);
    expect(
        withBlhDistances([verified], const AppCoordinates(double.nan, 0))
            .single
            .distanceKm,
        isNull);
  });
  test(
      'Firestore raw candidates are ignored even when their numeric coordinates exist',
      () {
    final bank = MilkBank.fromFirestore('fixture', {
      'nome': 'Unidade de teste',
      'tipo': 'BLH',
      'cidade': 'Aracaju',
      'estado': 'SE',
      'fonte': 'https://saude.gov.br/fixture',
      'verificadoEm': Timestamp.fromDate(DateTime.utc(2026)),
      'ativo': true,
      'publicado': true,
      'coordenadasVerificadas': false,
      'latitude': 0,
      'longitude': 1
    });
    expect(bank.hasVerifiedCoordinates, isFalse);
    expect(
        withBlhDistances([bank], const AppCoordinates(0, 0))
            .single
            .distanceLabel,
        isNull);
  });
  test(
      'Position refresh and pagination reuse authorized origin and never call radius search',
      () async {
    final gps = _Gps();
    final repo = _CityRepository(
        [fixture('known', lat: 0, lon: 1, verified: true), fixture('unknown')]);
    final controller = MilkBankController(
        repository: repo,
        location: AppLocationService(gateway: gps),
        cityResolver: _City());
    await controller.locate();
    expect(repo.city, 'Aracaju');
    expect(repo.state, 'SE');
    expect(controller.results.length, 2);
    final before = controller.results.first.distanceKm!;
    controller.updateLocation(const AppCoordinates(0, .5));
    expect(controller.results.first.distanceKm!, closeTo(before / 2, .01));
    expect(gps.reads, 1);
    expect(gps.permissionRequests, 0);
    await controller.searchCity('Aracaju', 'SE', more: true);
    expect(controller.results.length, 2);
    expect(controller.results.first.distanceKm!, closeTo(before / 2, .01));
    gps.positionValue = const AppCoordinates(0, 1);
    await controller.locate();
    expect(controller.results.first.distanceLabel, '0,0 km');
    expect(gps.reads, 2);
    expect(gps.permissionRequests, 0);
    expect(repo.radiusCalls, 0);
    controller.dispose();
  });
  test('Malformed point never hides an otherwise published municipal unit', () {
    final data = <String, dynamic>{
      'nome': 'Unidade de teste',
      'tipo': 'BLH',
      'cidade': 'Aracaju',
      'estado': 'SE',
      'fonte': 'https://saude.gov.br/fixture',
      'verificadoEm': Timestamp.fromDate(DateTime.utc(2026)),
      'ativo': true,
      'publicado': true,
      'coordenadasVerificadas': true,
      'latitude': 0,
      'longitude': 1,
      'geohash': 'incorrect'
    };
    final bank = MilkBank.fromFirestore('fixture', data);
    expect(bank.id, 'fixture');
    expect(bank.hasVerifiedCoordinates, isFalse);
    expect(
        withBlhDistances([bank], const AppCoordinates(0, 0))
            .single
            .distanceLabel,
        isNull);
    final verified = MilkBank.fromFirestore(
        'fixture', {...data, 'geohash': encodeGeohash(0, 1)});
    expect(verified.hasVerifiedCoordinates, isTrue);
    expect(
        withBlhDistances([verified], const AppCoordinates(0, 0))
            .single
            .distanceKm,
        greaterThan(100));
  });
  test(
      'Real demo units currently have no approved points: no fabricated estimates',
      () async {
    final page = await DemoMilkBankRepository().byCity('Aracaju', 'SE');
    expect(page.banks.length, 3);
    expect(
        withBlhDistances(page.banks, const AppCoordinates(-10.9, -37.08))
            .every((r) => r.distanceKm == null),
        isTrue);
  });
  test(
      'Demo accepts only separately audited points; candidates and duplicates remain unestimated',
      () async {
    final point = <String, Object>{
      'id': 'se-blh-marly-sarney',
      'latitude': 0,
      'longitude': 1,
      'coordenadasVerificadas': true,
      'fonteCoordenadas': 'https://saude.gov.br/fixture',
      'verificadoEm': '2026-01-01T00:00:00Z',
      'geohash': encodeGeohash(0, 1),
      'aprovacaoManual': {
        'revisadoPor': 'fixture-admin',
        'observacoesValidacao':
            'Ponto artificial validado somente para este teste.'
      }
    };
    var repo = DemoMilkBankRepository(bundle: _PointBundle([point]));
    var page = await repo.byCity('Aracaju', 'SE');
    expect(page.banks.first.hasVerifiedCoordinates, isTrue);
    expect(page.banks.skip(1).every((b) => !b.hasVerifiedCoordinates), isTrue);
    for (final rows in [
      [
        {...point, 'coordenadasVerificadas': false}
      ],
      [
        {...point, 'aprovacaoManual': {}}
      ],
      [point, point]
    ]) {
      repo = DemoMilkBankRepository(bundle: _PointBundle(rows));
      page = await repo.byCity('Aracaju', 'SE');
      expect(page.banks.length, 3);
      expect(page.banks.every((b) => !b.hasVerifiedCoordinates), isTrue);
    }
  });
  testWidgets(
      'Original card switches badge text only; unknown location keeps original placeholder',
      (tester) async {
    final bank = fixture('fixture');
    Widget card(String? label) => MaterialApp(
        theme: ThemeData(extensions: const [AppPalette.light]),
        home: Scaffold(
            body: BankListCard(
                bank: bank, distanceOverride: label, onOpenDetails: () {})));
    await tester.pumpWidget(card(null));
    expect(find.text('sem estimativa'), findsOneWidget);
    await tester.pumpWidget(card('3,2 km'));
    expect(find.text('3,2 km'), findsOneWidget);
    expect(find.text('sem estimativa'), findsNothing);
    expect(find.text('Ver detalhes'), findsOneWidget);
  });
}

class _Gps implements LocationGateway {
  int reads = 0, permissionRequests = 0;
  AppCoordinates positionValue = const AppCoordinates(0, 0);
  @override
  Future<bool> serviceEnabled() async => true;
  @override
  Future<LocationPermission> permission() async =>
      LocationPermission.whileInUse;
  @override
  Future<LocationPermission> requestPermission() async {
    permissionRequests++;
    return LocationPermission.whileInUse;
  }

  @override
  Future<AppCoordinates> position() async {
    reads++;
    return positionValue;
  }
}

class _City implements BlhCityResolver {
  @override
  Future<BlhMunicipality> resolve(AppCoordinates coordinates) async =>
      const BlhMunicipality('Aracaju', 'Sergipe');
}

class _CityRepository implements MilkBankRepository {
  _CityRepository(this.banks);
  final List<MilkBank> banks;
  String? city, state;
  int radiusCalls = 0;
  @override
  Future<MilkBankPage> byCity(String city, String state,
      {Object? cursor}) async {
    this.city = city;
    this.state = state;
    return MilkBankPage(banks);
  }

  @override
  Future<List<MilkBankResult>> nearby(double latitude, double longitude) async {
    radiusCalls++;
    throw StateError('Radius search must never be used for the municipal list');
  }
}

class _PointBundle extends CachingAssetBundle {
  _PointBundle(this.rows);
  final List<Object> rows;
  @override
  Future<ByteData> load(String key) async => key
          .endsWith('coordenadas-aprovadas.json')
      ? ByteData.sublistView(Uint8List.fromList(utf8.encode(jsonEncode(rows))))
      : rootBundle.load(key);
}
