import 'package:colodemae_flutter/models/baby.dart';
import 'package:colodemae_flutter/services/baby_controller.dart';
import 'package:colodemae_flutter/services/settings_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/memory_account_settings.dart';

void main() {
  test('Rapid switch changes are persisted in order and failures roll back',
      () async {
    final storage = MemoryAccountSettings();
    final controller = SettingsController(uid: 'mother', service: storage);
    await Future<void>.delayed(Duration.zero);
    await Future.wait([
      controller.setPreference('lembretesEducativos', false),
      controller.setPreference('lembretesEducativos', true),
      controller.setPreference('desafio15Dias', false),
    ]);
    expect(storage.preferences['mother']?['lembretesEducativos'], true);
    expect(storage.preferences['mother']?['desafio15Dias'], false);
    storage.failWrites = true;
    await expectLater(
        controller.setPreference('desafio15Dias', true), throwsStateError);
    expect(controller.fifteenDayChallenge, false);
    storage.failWrites = false;
    await controller.setPreference('desafio15Dias', true);
    expect(controller.fifteenDayChallenge, true);
    controller.dispose();
    await storage.dispose();
  });

  test(
      'Controllers reload persisted data for the same UID and isolate another UID',
      () async {
    final storage = MemoryAccountSettings();
    final first = BabyController(uid: 'mother-a', service: storage);
    await first.update(Baby(name: 'Lia', birthDate: DateTime(2026, 1, 1)));
    first.dispose();
    final other = BabyController(uid: 'mother-b', service: storage);
    await other.ensureLoaded();
    expect(other.baby, isNull);
    other.dispose();
    final restored = BabyController(uid: 'mother-a', service: storage);
    await restored.ensureLoaded();
    expect(restored.baby?.name, 'Lia');
    expect(storage.babies['mother-a']?.length, 1);
    restored.dispose();
    await storage.dispose();
  });

  test('Age uses calendar dates and clamps future births', () {
    final now = DateTime.now();
    expect(Baby(name: 'Lia', birthDate: now).daysSinceBirth, 0);
    expect(
        Baby(name: 'Lia', birthDate: now.add(const Duration(days: 10)))
            .daysSinceBirth,
        0);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    expect(Baby(name: 'Lia', birthDate: yesterday).daysSinceBirth, 1);
  });
}
