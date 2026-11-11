import 'package:colodemae_flutter/core/utils/blh_text_format.dart';
import 'package:colodemae_flutter/services/blh_demo_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Phones use Brazilian punctuation without changing or inventing digits',
      () {
    expect(formatBlhPhone('(79)32266301'), '(79) 3226-6301');
    expect(formatBlhPhone('79 32124900'), '(79) 3212-4900');
    expect(formatBlhPhone('+55 79 99191-5356'), '(79) 99191-5356');
    expect(formatBlhPhone('32266301'), '32266301');
    expect(formatBlhPhone(''), '');
  });
  test(
      'Summary shows street and neighborhood only; details separate address and postcode',
      () {
    final value = BlhAddressText(
        'RUA MATO GROSSO, S/N, JOSE CONRADO DE ARAU, CEP 49085220');
    expect(value.summary, 'Rua Mato Grosso — Jose Conrado de Arau');
    expect(value.summary, isNot(contains('CEP')));
    expect(value.summary, isNot(contains('s/n')));
    expect(value.details('Aracaju — SE'),
        'Rua Mato Grosso, s/n\nJose Conrado de Arau\nAracaju — SE · CEP 49085-220');
  });
  test(
      'Demo source preserves provenance and missing external donation schedule is explicit',
      () async {
    final banks =
        (await DemoMilkBankRepository().byCity('Aracaju', 'SE')).banks;
    expect(banks[0].summaryAddress, 'Rua Mato Grosso — José Conrado de Araújo');
    expect(banks[1].summaryAddress, 'Avenida Simeão Sobral — Dezoito do Forte');
    expect(banks[2].summaryAddress,
        'Rua Procurador José Costa Cavalcante — 17 de Março');
    expect(banks[0].hours, 'Segunda a sexta\n7h às 19h');
    expect(banks[1].hours, 'Todos os dias\n8h às 12h e 14h às 18h');
    expect(banks[2].hours, contains('Internadas'));
    expect(banks[2].hours, contains('Doação externa: confirme'));
    expect(banks[2].contactText, '(79) 3142-2776\nContato da maternidade');
    expect(
        banks.every((b) => b.verifiedAt == null && !b.hasCoordinates), isTrue);
  });
}
