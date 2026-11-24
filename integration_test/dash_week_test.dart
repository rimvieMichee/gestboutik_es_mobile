// Accueil du gestionnaire : carte « Chiffre d'affaires de la semaine ».
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

  testWidgets('carte semaine', timeout: const Timeout(Duration(minutes: 4)), (t) async {
    app.main();
    await wait(t, 6);
    final fields = find.byType(TextField);
    await t.enterText(fields.at(0), 'gestionnaire1');
    await t.enterText(fields.at(1), 'Gestion123!');
    FocusManager.instance.primaryFocus?.unfocus();
    await wait(t, 0.8);
    await t.tap(find.text('Se connecter').first);
    await wait(t, 6);
    expect(find.text("Chiffre d'affaires de la semaine"), findsOneWidget);
    await wait(t, 1.5);
    await binding.takeScreenshot('week');
  });
}
