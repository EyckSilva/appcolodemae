import 'dart:async';
import 'package:colodemae_flutter/app/theme/app_palette.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colodemae_flutter/core/widgets/circle_back_button.dart';
import 'package:colodemae_flutter/core/utils/location.dart';
import 'package:colodemae_flutter/models/milk_bank.dart';
import 'package:colodemae_flutter/screens/blh/blh_screen.dart';
import 'package:colodemae_flutter/screens/blh/widgets/bank_list_card.dart';
import 'package:colodemae_flutter/services/blh_city_resolver.dart';
import 'package:colodemae_flutter/services/blh_demo_repository.dart';
import 'package:colodemae_flutter/services/milk_bank_controller.dart';
import 'package:colodemae_flutter/services/milk_bank_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final repo = DemoMilkBankRepository();
  final resolver = AracajuCityResolver();
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await repo.byCity('Aracaju', 'SE');
    await resolver.resolve(const AppCoordinates(-10.90613, -37.07967));
  });
  MilkBankController controller(
          {LocationGateway? gateway,
          BlhCityResolver? city,
          MilkBankRepository? repository,
          bool demo = true}) =>
      MilkBankController(
          repository: repository ?? repo,
          location: AppLocationService(
              gateway: gateway ?? _Location(),
              operationTimeout: const Duration(milliseconds: 10),
              permissionTimeout: const Duration(milliseconds: 10),
              positionTimeout: const Duration(milliseconds: 10)),
          demoMode: demo,
          cityResolver: city ?? resolver,
          locationTimeout: const Duration(milliseconds: 80),
          reverseTimeout: const Duration(milliseconds: 10),
          queryTimeout: const Duration(milliseconds: 10));

  test(
      'Demo is opt-in and document data has no geographic approval or distances',
      () async {
    expect(blhDemoEnabled, isFalse);
    final page = await repo.byCity(' ARACAJU ', ' Sergipe ');
    expect(page.banks.length, 3);
    for (final bank in page.banks) {
      expect(bank.isDemonstration, isTrue);
      expect(bank.verifiedAt, isNull);
      expect(bank.hasCoordinates, isFalse);
      expect(bank.hours, isNotEmpty);
      expect(bank.canUseAddressForDirections, isTrue);
    }
    expect(page.banks.last.formattedPhone, '(79) 3142-2776');
    expect(page.banks.last.phoneNote, 'Contato da maternidade');
    expect((await repo.byCity('Aracaju', 'BR-SE')).banks.length, 3);
    expect((await repo.byCity('Lagarto', 'SE')).banks, isEmpty);
    expect(() => repo.nearby(0, 0), throwsUnsupportedError);
  });
  test('Offline reverse geocoding identifies Aracaju and rejects another city',
      () async {
    expect(
        (await resolver.resolve(const AppCoordinates(-10.90613, -37.07967)))
            .city,
        'Aracaju');
    await expectLater(
        resolver.resolve(const AppCoordinates(-10.6899469, -37.4270522)),
        throwsStateError);
  });
  test(
      'Granted permission loads documented units by city without calling nearby',
      () async {
    final c = controller();
    await c.locate();
    expect(c.city, 'Aracaju');
    expect(c.state, 'SE');
    expect(c.located, isTrue);
    expect(c.results.length, 3);
    expect(c.results.every((r) => r.distanceKm == null), isTrue);
    expect(c.busy, isFalse);
    expect(c.locating, isFalse);
    c.dispose();
  });
  test('Denied, permanently denied and disabled GPS always finish loading',
      () async {
    for (final location in [
      _Location()..status = LocationPermission.denied,
      _Location()..status = LocationPermission.deniedForever,
      _Location()..enabled = false
    ]) {
      final c = controller(gateway: location);
      await c.locate();
      expect(c.error, isNotNull);
      expect(c.busy || c.locating, isFalse);
      expect(c.results, isEmpty);
      c.dispose();
    }
  });
  for (final phase in ['service', 'permission', 'request', 'position']) {
    test('A hanging $phase operation times out and clears loading', () async {
      final c = controller(gateway: _Location()..hang = phase);
      await c.locate();
      expect(c.error, contains('demorou'));
      expect(c.busy || c.locating, isFalse);
      c.dispose();
    });
  }
  test('Reverse geocoding errors and timeout clear loading', () async {
    for (final reverse in [
      _Resolver()..error = StateError('Falha de geocodificação'),
      _Resolver()..hang = true
    ]) {
      final c = controller(city: reverse);
      await c.locate();
      expect(c.error, isNotNull);
      expect(c.busy || c.locating, isFalse);
      c.dispose();
    }
  });
  test(
      'Firestore errors and hanging queries clear loading in production and demo path',
      () async {
    for (final demo in [false, true]) {
      for (final source in [
        _FailureRepository(),
        _FailureRepository()..hang = true
      ]) {
        final c = controller(repository: source, demo: demo);
        await c.locate();
        expect(c.error, isNotNull);
        expect(c.busy || c.locating, isFalse);
        c.dispose();
      }
    }
  });
  test(
      'Repeated requests do not duplicate GPS work and late completion after dispose is ignored',
      () async {
    final location = _Location()..pending = Completer<AppCoordinates>();
    final c = controller(gateway: location);
    final first = c.locate();
    await Future<void>.delayed(Duration.zero);
    await c.locate();
    expect(location.reads, 1);
    c.dispose();
    location.pending!.complete(const AppCoordinates(-10.90613, -37.07967));
    await first;
    expect(c.results, isEmpty);
  });
  testWidgets(
      'Original cards, details, address route, phone, donation and back retain data',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final location = _Location();
    final calls = <Uri>[];
    await tester.pumpWidget(MaterialApp(
        theme: ThemeData(extensions: const [AppPalette.light]),
        home: Scaffold(
            body: BlhScreen(
          demoMode: true,
          repository: repo,
          cityResolver: resolver,
          locationService: AppLocationService(gateway: location),
          launcher: (uri, mode) async {
            calls.add(uri);
            return true;
          },
        ))));
    expect(location.reads, 0);
    await tester.tap(find.text('Usar minha localização'));
    await tester
        .runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
    expect(find.text('Localizando...'), findsNothing);
    expect(find.byType(BankListCard), findsNWidgets(3));
    expect(find.textContaining('Distâncias estimadas'), findsNothing);
    await tester.tap(find.text('Ver detalhes').first);
    await tester.pumpAndSettle();
    expect(find.text('Banco de Leite Humano Marly Sarney'), findsOneWidget);
    for (final label in ['Iniciar Rota', 'Ligar']) {
      await tester.ensureVisible(find.text(label));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }
    expect(calls.first.host, 'www.google.com');
    expect(calls.first.queryParameters['destination'],
        contains('Rua Mato Grosso'));
    expect(calls.first.queryParameters.containsKey('origin'), isFalse);
    expect(calls.last.scheme, 'tel');
    expect(calls.last.path, '7932266301');
    await tester.ensureVisible(find.text('Quero doar leite'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Quero doar leite'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    Navigator.of(tester.element(find.byType(BottomSheet))).pop();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(CircleBackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CircleBackButton));
    await tester.pumpAndSettle();
    expect(find.byType(BankListCard), findsNWidgets(3));
    expect(location.reads, 1);
  });
}

class _Location implements LocationGateway {
  bool enabled = true;
  LocationPermission status = LocationPermission.whileInUse;
  String? hang;
  int reads = 0;
  Completer<AppCoordinates>? pending;
  @override
  Future<bool> serviceEnabled() =>
      hang == 'service' ? Completer<bool>().future : Future.value(enabled);
  @override
  Future<LocationPermission> permission() => hang == 'permission'
      ? Completer<LocationPermission>().future
      : Future.value(hang == 'request' ? LocationPermission.denied : status);
  @override
  Future<LocationPermission> requestPermission() => hang == 'request'
      ? Completer<LocationPermission>().future
      : Future.value(status);
  @override
  Future<AppCoordinates> position() {
    reads++;
    return pending?.future ??
        (hang == 'position'
            ? Completer<AppCoordinates>().future
            : Future.value(const AppCoordinates(-10.90613, -37.07967)));
  }
}

class _Resolver implements BlhCityResolver {
  bool hang = false;
  Object? error;
  @override
  Future<BlhMunicipality> resolve(AppCoordinates coordinates) =>
      hang ? Completer<BlhMunicipality>().future : Future.error(error!);
}

class _FailureRepository implements MilkBankRepository {
  bool hang = false;
  @override
  Future<MilkBankPage> byCity(String city, String state, {Object? cursor}) =>
      hang
          ? Completer<MilkBankPage>().future
          : Future.error(FirebaseException(
              plugin: 'cloud_firestore', code: 'unavailable'));
  @override
  Future<List<MilkBankResult>> nearby(double latitude, double longitude) => hang
      ? Completer<List<MilkBankResult>>().future
      : Future.error(
          FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'));
}
