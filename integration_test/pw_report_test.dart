// Mot de passe (Paramètres), barre de navigation, rapport par période.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:foodly/main.dart' as app;
import 'package:foodly/widgets/bottom_bar/bottom_nav_bar.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  Future<void> wait(WidgetTester t, double s) async {
    for (var i = 0; i < (s * 10).round(); i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> shot(WidgetTester t, String n, [double w = 1.5]) async {
    await wait(t, w);
    await binding.takeScreenshot(n);
  }

  testWidgets('mot de passe, barre, rapport', timeout: const Timeout(Duration(minutes: 5)), (t) async {
    app.main();
    await wait(t, 6);
    final fields = find.byType(TextField);
    await t.enterText(fields.at(0), 'gestionnaire1');
    await t.enterText(fields.at(1), 'Gestion123!');
    FocusManager.instance.primaryFocus?.unfocus();
    await wait(t, 0.8);
    await t.tap(find.text('Se connecter').first);
    await wait(t, 5);
    await shot(t, 'p1-barre');
    final nav = find.descendant(of: find.byType(AppBottomNavBar), matching: find.text('Paramètres'));
    await t.tap(nav);
    await shot(t, 'p2-parametres', 2.0);
    await t.scrollUntilVisible(find.text('Changer le mot de passe'), 200,
        scrollable: find.byType(Scrollable).first);
    await shot(t, 'p3-tuile', 1.0);
    await t.tap(find.text('Changer le mot de passe'));
    await shot(t, 'p4-feuille', 1.5);
    await t.enterText(find.byType(TextField).at(0), 'Gestion123!');
    await t.enterText(find.byType(TextField).at(1), 'court');
    await t.enterText(find.byType(TextField).at(2), 'court');
    await t.tap(find.text('Mettre à jour'));
    await shot(t, 'p5-erreur', 1.0);
    expect(find.text('Le nouveau mot de passe doit contenir au moins 8 caractères.'), findsOneWidget);
    await t.tapAt(const Offset(20, 80)); // ferme la feuille
    await wait(t, 1);
    await t.scrollUntilVisible(find.text('Rapport des ventes'), -200,
        scrollable: find.byType(Scrollable).first);
    await t.tap(find.text('Rapport des ventes'));
    await shot(t, 'p6-rapport', 2.5);
    await t.tap(find.text('Semaine'));
    await shot(t, 'p7-semaine', 2.0);
    await t.tap(find.text('Année'));
    await shot(t, 'p8-annee', 2.0);
  });
}
