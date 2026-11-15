// Présentation de premier lancement, puis barre de navigation du gestionnaire.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:foodly/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> wait(WidgetTester t, [double s = 1.0]) async {
    for (var i = 0; i < (s * 10).round(); i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> shot(WidgetTester t, String name, [double w = 1.2]) async {
    await wait(t, w);
    await binding.takeScreenshot(name);
  }

  testWidgets('onboarding puis navigation gestionnaire',
      timeout: const Timeout(Duration(minutes: 6)), (t) async {
    app.main();
    await wait(t, 6);
    expect(find.text('Passer'), findsOneWidget);
    await shot(t, 'o1');
    await t.tap(find.text('Suivant'));
    await shot(t, 'o2', 1.5);
    await t.tap(find.text('Suivant'));
    await shot(t, 'o3', 1.5);
    await t.tap(find.text('Suivant'));
    await shot(t, 'o4', 1.5);
    expect(find.text('Commencer'), findsOneWidget);
    await t.tap(find.text('Commencer'));
    await wait(t, 2.5);
    final fields = find.byType(TextField);
    await t.enterText(fields.at(0), 'issa');
    await t.enterText(fields.at(1), 'Selio2026!');
    FocusManager.instance.primaryFocus?.unfocus();
    await wait(t, 0.8);
    await t.tap(find.text('Se connecter').first);
    await wait(t, 5);
    await shot(t, 'o5-accueil', 1.5);
    // Onglet central : la vente.
    await t.tap(find.text('Vente'));
    await shot(t, 'o6-vente', 2.5);
    await t.tap(find.text('Produits'));
    await shot(t, 'o7-produits', 2.0);
  });
}
