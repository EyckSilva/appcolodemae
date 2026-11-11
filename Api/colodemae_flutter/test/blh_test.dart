import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colodemae_flutter/app/theme/app_theme.dart';
import 'package:colodemae_flutter/core/utils/external_links.dart';
import 'package:colodemae_flutter/core/utils/geohash.dart';
import 'package:colodemae_flutter/core/utils/location.dart';
import 'package:colodemae_flutter/core/utils/maps_launcher.dart';
import 'package:colodemae_flutter/core/utils/phone_launcher.dart';
import 'package:colodemae_flutter/models/milk_bank.dart';
import 'package:colodemae_flutter/screens/blh/blh_screen.dart';
import 'package:colodemae_flutter/screens/blh/bank_detail_screen.dart';
import 'package:colodemae_flutter/services/milk_bank_controller.dart';
import 'package:colodemae_flutter/services/milk_bank_repository.dart';
import 'package:colodemae_flutter/services/blh_city_resolver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

// Dados artificiais exclusivos de teste; nunca usados pelo app ou importados.
Map<String, dynamic> record({double? lat = -10.9, double? lon = -37.0}) => {
      'nome': 'Unidade de teste',
      'tipo': 'BLH',
      'cidade': 'Cidade de teste',
      'estado': 'AC',
      'fonte': 'https://rblh.fiocruz.br/localizacao-dos-blhs',
      'verificadoEm':
          Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
      'ativo': true,
      'publicado': true,
      'telefone': '(11) 1234-5678',
      if (lat != null && lon != null) ...{
        'coordenadasVerificadas': true,
        'latitude': lat,
        'longitude': lon,
        'geohash': encodeGeohash(lat, lon),
      },
    };

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('Granted location is obtained only on request', () async {
    final gateway = _Gateway();
    final location = AppLocationService(gateway: gateway);
    expect(gateway.reads, 0);
    final position = await location.currentPosition();
    expect(position.latitude, -10.9);
    expect(gateway.requests, 0);
    expect(gateway.reads, 1);
  });

  test('Denied, permanently denied and disabled location are distinct',
      () async {
    final gateway = _Gateway()..status = LocationPermission.denied;
    final location = AppLocationService(gateway: gateway);
    await expectLater(location.currentPosition(),
        throwsA(isA<AppLocationPermissionDeniedException>()));
    expect(gateway.requests, 1);
    gateway.status = LocationPermission.deniedForever;
    await expectLater(location.currentPosition(),
        throwsA(isA<AppLocationPermissionDeniedForeverException>()));
    expect(gateway.requests, 1);
    gateway.enabled = false;
    await expectLater(location.currentPosition(),
        throwsA(isA<AppLocationServiceDisabledException>()));
    expect(gateway.reads, 0);
  });

  test('GPS timeout allows manual search without another location request',
      () async {
    final gateway = _Gateway()..failure = TimeoutException('GPS');
    final repo = _Repository();
    final controller = MilkBankController(
        repository: repo, location: AppLocationService(gateway: gateway));
    await controller.locate();
    expect(controller.error, isNotNull);
    expect(controller.busy, false);
    await controller.searchCity('Cidade de teste', 'AC');
    expect(controller.error, isNull);
    expect(gateway.reads, 1);
    expect(repo.city, 'Cidade de teste');
    controller.dispose();
  });

  test('Geohash standard vector, normalization and query coverage', () {
    expect(encodeGeohash(42.6, -5.6, precision: 5), 'ezs42');
    expect(normalizeCity('  São   Luís '), 'sao luis');
    for (final center in [
      (-34.0, -53.0),
      (-10.9, -37.0),
      (5.0, -60.0),
      (0.0, 179.9),
      (0.0, -179.9)
    ]) {
      final cells = nearbyGeohashPrefixes(center.$1, center.$2);
      for (var degrees = 0; degrees < 360; degrees += 5) {
        final lat = center.$1 * math.pi / 180, lon = center.$2 * math.pi / 180;
        final bearing = degrees * math.pi / 180, arc = 49.999 / 6371;
        final a = math.asin(math.sin(lat) * math.cos(arc) +
            math.cos(lat) * math.sin(arc) * math.cos(bearing));
        final b = lon +
            math.atan2(math.sin(bearing) * math.sin(arc) * math.cos(lat),
                math.cos(arc) - math.sin(lat) * math.sin(a));
        final lng = (b * 180 / math.pi + 540) % 360 - 180;
        expect(cells,
            contains(encodeGeohash(a * 180 / math.pi, lng, precision: 3)));
      }
    }
  });

  test('Distance ordering excludes unverified coordinates and far units', () {
    final far = MilkBank.fromFirestore('far', record(lat: -11.0));
    final near = MilkBank.fromFirestore('near', record());
    final missing =
        MilkBank.fromFirestore('missing', record(lat: null, lon: null));
    final outside = MilkBank.fromFirestore('outside', record(lat: -20.0));
    final results = rankMilkBanks([far, missing, outside, near], -10.9, -37);
    expect(results.map((r) => r.bank.id), ['near', 'far']);
    expect(results.first.distanceLabel, '0,0 km');
    expect(missing.hasCoordinates, false);
  });

  test('Unpublished, inactive or unverified records are rejected', () {
    for (final changes in [
      {'publicado': false},
      {'ativo': false},
      {'verificadoEm': null},
      {'fonte': 'http://example.test'}
    ]) {
      expect(() => MilkBank.fromFirestore('bad', {...record(), ...changes}),
          throwsFormatException);
    }
  });

  test('Manual search accepts units without coordinates and paginates',
      () async {
    final repo = _Repository()
      ..page = MilkBankPage(
          [MilkBank.fromFirestore('no-coords', record(lat: null, lon: null))],
          cursor: 'next');
    final controller = MilkBankController(
        repository: repo, location: AppLocationService(gateway: _Gateway()));
    await controller.searchCity('Cidade de teste', 'AC');
    expect(controller.results.single.distanceKm, isNull);
    expect(controller.hasMore, true);
    repo.page = const MilkBankPage([]);
    await controller.searchCity('Cidade de teste', 'AC', more: true);
    expect(repo.cursor, 'next');
    expect(controller.results.length, 1);
    controller.dispose();
  });

  test('Map destination uses coordinates without origin; phone uses tel',
      () async {
    final calls = <Uri>[];
    Future<bool> launch(Uri uri, LaunchMode mode) async {
      calls.add(uri);
      return true;
    }

    await openMapsDirections(
        latitude: -10.9, longitude: -37.0, launcher: launch);
    expect(calls.first.queryParameters['destination'], '-10.9,-37.0');
    expect(calls.first.queryParameters.containsKey('origin'), false);
    await callPhone('(11) 1234-5678', launcher: launch);
    expect(calls.last.toString(), 'tel:1112345678');
    await expectLater(
        callPhone('indisponível', launcher: launch), throwsArgumentError);
    await expectLater(
        openMapsDirections(
            latitude: 0, longitude: 0, launcher: (_, __) async => false),
        throwsA(isA<ExternalLinkException>()));
  });

  Future<void> tap(WidgetTester tester, String text) async {
    final target = find.text(text);
    if (target.evaluate().isEmpty) {
      await tester.scrollUntilVisible(target, 200,
          scrollable: find.byType(Scrollable).last);
    }
    await Scrollable.ensureVisible(tester.element(target), alignment: .3);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  testWidgets('BLH initial screen is empty and does not request location',
      (tester) async {
    final gateway = _Gateway();
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
            body: BlhScreen(
                cityResolver: _FixedMunicipality(),
                repository: _Repository(),
                locationService: AppLocationService(gateway: gateway)))));
    expect(gateway.reads, 0);
    expect(find.text('Use sua localização.'), findsOneWidget);
    expect(find.text('BLH Marly Sarney'), findsNothing);
    await tap(tester, 'Usar minha localização');
    expect(find.textContaining('Nenhuma unidade verificada'), findsOneWidget);
  });

  testWidgets(
      'Denied location displays error without the removed manual search button',
      (tester) async {
    final gateway = _Gateway()..status = LocationPermission.denied;
    final repo = _Repository()
      ..page = MilkBankPage(
          [MilkBank.fromFirestore('fixture', record(lat: null, lon: null))]);
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
            body: BlhScreen(
                cityResolver: _FixedMunicipality(),
                repository: repo,
                locationService: AppLocationService(gateway: gateway)))));
    await tap(tester, 'Usar minha localização');
    expect(
        find.textContaining('Permissão de localização negada'), findsOneWidget);
    expect(find.text('Buscar por cidade e estado'), findsNothing);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.text('Unidade de teste'), findsNothing);
    expect(find.text('Mais próximo'), findsNothing);
    expect(gateway.reads, 0);
  });

  testWidgets('Loading and offline error render without fictional results',
      (tester) async {
    final repo = _Repository()..pending = Completer<List<MilkBankResult>>();
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
            body: BlhScreen(
                cityResolver: _FixedMunicipality(),
                repository: repo,
                locationService: AppLocationService(gateway: _Gateway())))));
    await tester.tap(find.text('Usar minha localização'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    repo.pending!.completeError(
        FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Verifique sua conexão'), findsOneWidget);
    expect(find.text('Unidade de teste'), findsNothing);
  });

  testWidgets('Detail route and phone errors are handled', (tester) async {
    final calls = <Uri>[];
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light(),
        home: BankDetailScreen(
            bank: MilkBank.fromFirestore('fixture', record()),
            launcher: (uri, mode) async {
              calls.add(uri);
              return false;
            })));
    await tap(tester, 'Iniciar Rota');
    expect(calls.first.host, 'www.google.com');
    expect(find.text('Não foi possível abrir o aplicativo. Tente novamente.'),
        findsOneWidget);
    await tap(tester, 'Ligar');
    expect(calls.last.scheme, 'tel');
  });

  testWidgets('Detail without coordinates or address disables route',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.dark(),
        home: BankDetailScreen(
            bank: MilkBank.fromFirestore('fixture',
                {...record(lat: null, lon: null), 'endereco': ''}))));
    await tester.scrollUntilVisible(
        find.widgetWithText(ElevatedButton, 'Iniciar Rota'), 250);
    final route = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Iniciar Rota'));
    expect(route.onPressed, isNull);
  });
}

class _Gateway implements LocationGateway {
  bool enabled = true;
  LocationPermission status = LocationPermission.whileInUse;
  int requests = 0, reads = 0;
  Object? failure;
  @override
  Future<bool> serviceEnabled() async => enabled;
  @override
  Future<LocationPermission> permission() async => status;
  @override
  Future<LocationPermission> requestPermission() async {
    requests++;
    return status;
  }

  @override
  Future<AppCoordinates> position() async {
    reads++;
    if (failure != null) throw failure!;
    return const AppCoordinates(-10.9, -37);
  }
}

class _Repository implements MilkBankRepository {
  MilkBankPage page = const MilkBankPage([]);
  String? city, state;
  Object? cursor;
  Completer<List<MilkBankResult>>? pending;
  @override
  Future<List<MilkBankResult>> nearby(
          double latitude, double longitude) async =>
      pending == null ? [] : await pending!.future;
  @override
  Future<MilkBankPage> byCity(String city, String state,
      {Object? cursor}) async {
    this.city = city;
    this.state = state;
    this.cursor = cursor;
    if (pending != null) {
      final entries = await pending!.future;
      return MilkBankPage(entries.map((r) => r.bank).toList());
    }
    return page;
  }
}

class _FixedMunicipality implements BlhCityResolver {
  @override
  Future<BlhMunicipality> resolve(AppCoordinates coordinates) async =>
      const BlhMunicipality('Aracaju', 'SE');
}
