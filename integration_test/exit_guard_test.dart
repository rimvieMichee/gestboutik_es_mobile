import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:foodly/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  Future<void> wait(WidgetTester t, double s) async {
    for (var i = 0; i < (s * 10).round(); i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('retour : prévenir puis confirmer', timeout: const Timeout(Duration(minutes: 3)), (t) async {
    app.main();
    await wait(t, 6);
    expect(find.text('Passer'), findsOneWidget);
    // 1er retour : simple avertissement, l'écran reste.
    await binding.handlePopRoute();
    await wait(t, 1.2);
    expect(find.text('Appuyez encore une fois sur retour pour quitter.'), findsOneWidget);
    expect(find.text('Passer'), findsOneWidget);
    await binding.takeScreenshot('e1-avertissement');
    // 2e retour : feuille de confirmation.
    await binding.handlePopRoute();
    await wait(t, 1.5);
    expect(find.text('Quitter SELIO ?'), findsOneWidget);
    await binding.takeScreenshot('e2-confirmation');
    await t.tap(find.text('Rester'));
    await wait(t, 1.2);
    expect(find.text('Quitter SELIO ?'), findsNothing);
    expect(find.text('Passer'), findsOneWidget);
  });
}
