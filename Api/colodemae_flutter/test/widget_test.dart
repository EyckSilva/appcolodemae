import 'package:flutter_test/flutter_test.dart';

import 'package:colodemae_flutter/app/app.dart';

void main() {
  testWidgets('App shows the splash screen on launch', (WidgetTester tester) async {
    await tester.pumpWidget(const ColoDeMaeApp());
    await tester.pump();

    expect(find.text('Colo de Mãe'), findsOneWidget);
    expect(find.text('apoio, amor e amamentação'), findsOneWidget);
  });
}
