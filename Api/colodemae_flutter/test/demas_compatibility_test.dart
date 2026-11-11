// Compatibilidade dos componentes originais com dados públicos capturados.
// Autorização/publicação são simuladas apenas neste teste; nenhum Firebase real.
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:colodemae_flutter/app/theme/app_theme.dart';
import 'package:colodemae_flutter/models/milk_bank.dart';
import 'package:colodemae_flutter/screens/blh/bank_detail_screen.dart';
import 'package:colodemae_flutter/screens/blh/widgets/bank_list_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  final report = jsonDecode(
      File('data/blh/demas/coleta-aracaju-validada/relatorio.json')
          .readAsStringSync()) as Map<String, dynamic>;
  final unit = (report['unidades'] as List).first as Map<String, dynamic>;
  final recovered = unit['recuperado'] as Map<String, dynamic>;
  final fixture = <String, dynamic>{
    'nome': unit['nomeUnidadePreservado'],
    'tipo': 'BLH',
    'cidade': recovered['cidade'],
    'estado': recovered['estado'],
    'endereco': recovered['endereco'],
    'telefone': recovered['telefone'],
    'fonte': unit['fonte']['url'],
    'ativo': true,
    'publicado': true,
    'verificadoEm': Timestamp.now(),
    'coordenadasVerificadas': false,
  };
  test('Pending DEMAS data is rejected by the unchanged model', () {
    expect(
        () => MilkBank.fromFirestore(
            unit['id'], {...fixture, 'ativo': false, 'publicado': false}),
        throwsFormatException);
  });
  testWidgets('Original card and details display recovered data and use tel',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final bank = MilkBank.fromFirestore(unit['id'], fixture);
    final calls = <Uri>[];
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
            builder: (context) => Scaffold(
                  body: BankListCard(
                      bank: bank,
                      onOpenDetails: () =>
                          Navigator.of(context).push(MaterialPageRoute<void>(
                            builder: (_) => BankDetailScreen(
                                bank: bank,
                                launcher: (uri, mode) async {
                                  calls.add(uri);
                                  return true;
                                }),
                          ))),
                ))));
    expect(find.text(bank.name), findsOneWidget);
    await tester.tap(find.text('Ver detalhes'));
    await tester.pumpAndSettle();
    expect(find.text(bank.formattedAddress), findsOneWidget);
    expect(find.text(bank.formattedPhone), findsOneWidget);
    expect(find.text('Horário não informado'), findsOneWidget);
    final button = find.text('Ligar');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(calls.single.scheme, 'tel');
    expect(calls.single.path, '7932266301');
  });
}
