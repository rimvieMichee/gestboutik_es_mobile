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

  testWidgets('squelettes', timeout: const Timeout(Duration(minutes: 4)), (t) async {
    app.main();
    await wait(t, 6);
    final fields = find.byType(TextField);
    await t.enterText(fields.at(0), 'gestionnaire1');
    await t.enterText(fields.at(1), 'Gestion123!');
    FocusManager.instance.primaryFocus?.unfocus();
    await wait(t, 0.8);
    await t.tap(find.text('Se connecter').first);
    await wait(t, 2.5);
    await binding.takeScreenshot('s1-accueil-chargement');
    await wait(t, 8);
    await binding.takeScreenshot('s2-accueil-charge');
    await t.tap(find.descendant(of: find.byType(AppBottomNavBar), matching: find.text('Paramètres')));
    await wait(t, 2);
    await t.scrollUntilVisible(find.text('Rapport des ventes'), 200, scrollable: find.byType(Scrollable).first);
    await t.tap(find.text('Rapport des ventes'));
    await wait(t, 2.5);
    await binding.takeScreenshot('s3-rapport-chargement');
    await wait(t, 8);
    await binding.takeScreenshot('s4-rapport-charge');
  });
}
