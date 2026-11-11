// Simula exclusivamente a projeção revisada; nenhuma autorização ou escrita real.
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colodemae_flutter/app/theme/app_palette.dart';
import 'package:colodemae_flutter/core/utils/geohash.dart';
import 'package:colodemae_flutter/core/utils/location.dart';
import 'package:colodemae_flutter/core/widgets/circle_back_button.dart';
import 'package:colodemae_flutter/models/milk_bank.dart';
import 'package:colodemae_flutter/screens/blh/blh_screen.dart';
import 'package:colodemae_flutter/screens/blh/bank_detail_screen.dart';
import 'package:colodemae_flutter/screens/blh/widgets/bank_list_card.dart';
import 'package:colodemae_flutter/services/blh_city_resolver.dart';
import 'package:colodemae_flutter/services/blh_demo_repository.dart';
import 'package:colodemae_flutter/services/milk_bank_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final plan = jsonDecode(
      File('data/blh/publicacao-aracaju/previa-02/plano.json')
          .readAsStringSync()) as Map<String, dynamic>;
  final banks = (plan['unidades'] as List).map((raw) {
    final unit = raw as Map<String, dynamic>;
    final point = unit['coordenadasFornecidas'] as Map<String, dynamic>;
    return MilkBank.fromFirestore(unit['id'], {
      ...unit['dadosRevisadosPropostos'],
      ...point,
      'ativo': true,
      'publicado': true,
      'verificadoEm': Timestamp.fromDate(DateTime.utc(2026)),
      'coordenadasVerificadas': true,
      'geohash': encodeGeohash(point['latitude'], point['longitude'])
    });
  }).toList();
  test('Production parser retains reviewed phones hours CEP and no demo flags',
      () {
    expect(blhDemoEnabled, isFalse);
    expect(banks.length, 3);
    expect(banks.every((b) => !b.isDemonstration && b.hasVerifiedCoordinates),
        isTrue);
    final lourdes = banks.singleWhere((b) => b.id.contains('lourdes-nogueira'));
    expect(lourdes.formattedPhone, '(79) 3142-2776');
    expect(lourdes.phoneNote, 'Contato da maternidade');
    expect(lourdes.formattedAddress, contains('49003-247'));
    expect(lourdes.hours, contains('Internadas'));
  });
  testWidgets(
      'Default non-demo screen queries municipal source and displays three reviewed fixtures',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _PublishedCity(banks);
    final urls = <Uri>[];
    await tester.pumpWidget(MaterialApp(
        theme: ThemeData(extensions: const [AppPalette.light]),
        home: Scaffold(
            body: BlhScreen(
                repository: repository,
                cityResolver: _Municipality(),
                locationService: AppLocationService(gateway: _Gps()),
                launcher: (uri, mode) async {
                  urls.add(uri);
                  return true;
                }))));
    expect(tester.widget<BlhScreen>(find.byType(BlhScreen)).demoMode, isFalse);
    await tester.tap(find.text('Usar minha localização'));
    await tester.pumpAndSettle();
    expect(repository.city, 'Aracaju');
    expect(repository.state, 'SE');
    expect(find.byType(BankListCard), findsNWidgets(3));
    expect(find.text('0,0 km'), findsOneWidget);
    expect(find.text('sem estimativa'), findsNothing);
    await tester.tap(find.text('Ver detalhes').first);
    await tester.pumpAndSettle();
    expect(find.byType(BankDetailScreen), findsOneWidget);
    expect(find.textContaining('(79) 3226-6301'), findsOneWidget);
    for (final label in ['Ligar', 'Iniciar Rota']) {
      await tester.ensureVisible(find.text(label));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }
    expect(urls.first.scheme, 'tel');
    expect(urls.last.host, 'www.google.com');
    await tester.ensureVisible(find.byType(CircleBackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CircleBackButton));
    await tester.pumpAndSettle();
    expect(find.byType(BankListCard), findsNWidgets(3));
  });
}

class _Municipality implements BlhCityResolver {
  @override
  Future<BlhMunicipality> resolve(AppCoordinates coordinates) async =>
      const BlhMunicipality('Aracaju', 'SE');
}

class _Gps implements LocationGateway {
  @override
  Future<bool> serviceEnabled() async => true;
  @override
  Future<LocationPermission> permission() async =>
      LocationPermission.whileInUse;
  @override
  Future<LocationPermission> requestPermission() =>
      throw StateError('No repeated permission');
  @override
  Future<AppCoordinates> position() async =>
      const AppCoordinates(-10.90619346346821, -37.07967947461301);
}

class _PublishedCity implements MilkBankRepository {
  _PublishedCity(this.banks);
  final List<MilkBank> banks;
  String? city, state;
  @override
  Future<MilkBankPage> byCity(String city, String state,
      {Object? cursor}) async {
    this.city = city;
    this.state = state;
    return MilkBankPage(banks);
  }

  @override
  Future<List<MilkBankResult>> nearby(double latitude, double longitude) =>
      throw StateError('No radius query');
}
