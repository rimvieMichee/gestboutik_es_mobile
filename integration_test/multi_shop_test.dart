// Gestionnaire de deux boutiques : sélecteur, changement, reprise de la
// dernière boutique. Lancé avec un serveur local de démonstration.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:foodly/main.dart' as app;
import 'package:foodly/widgets/bottom_bar/bottom_nav_bar.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> wait(WidgetTester t, [double s = 1.0]) async {
    for (var i = 0; i < (s * 10).round(); i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> shot(WidgetTester t, String name, [double w = 1.5]) async {
    await wait(t, w);
    await binding.takeScreenshot(name);
  }

  Finder navItem(String label) => find.descendant(
      of: find.byType(AppBottomNavBar), matching: find.text(label));

  testWidgets('changer de boutique',
      timeout: const Timeout(Duration(minutes: 8)), (t) async {
    app.main();
    await wait(t, 6);
    final fields = find.byType(TextField);
    await t.enterText(fields.at(0), 'issa');
    await t.enterText(fields.at(1), 'Selio2026!');
    FocusManager.instance.primaryFocus?.unfocus();
    await wait(t, 0.8);
    await t.tap(find.text('Se connecter').first);
    await wait(t, 4.5);

    await shot(t, 'k00-apres-connexion', 0.5);
    // 1. Accueil : la boutique ouverte est une pastille cliquable.
    expect(find.byIcon(LucideIcons.chevronsUpDown), findsOneWidget);
    expect(find.text('Boutique A'), findsWidgets);
    await shot(t, 'k01-accueil-boutique-A');

    // 2. Le sélecteur.
    await t.tap(find.byIcon(LucideIcons.chevronsUpDown));
    await shot(t, 'k02-selecteur', 2.5);
    expect(find.text('Boutique B'), findsOneWidget);

    // 3. On ouvre la boutique B.
    await t.tap(find.text('Boutique B'));
    await shot(t, 'k03-ouverture', 0.4);
    await wait(t, 3.5);
    await shot(t, 'k04-accueil-boutique-B', 1.5);
    expect(find.text('Boutique B'), findsWidgets);
    expect(find.text('Boutique A'), findsNothing);

    // 4. Les autres écrans portent le nom de la boutique ouverte.
    await t.tap(navItem('Produits'));
    await shot(t, 'k05-produits-boutique-B', 2.5);
    expect(find.text('Huile B'), findsWidgets); // produits de B, pas de A
    expect(find.text('Riz A'), findsNothing);

    await t.tap(navItem('Paramètres'));
    await shot(t, 'k06-parametres', 2.0);
    expect(find.text('Mes boutiques'), findsOneWidget);
    // Le réglage ouvre le même sélecteur ; on repasse sur A.
    await t.tap(find.text('Mes boutiques'));
    await shot(t, 'k07-selecteur-depuis-parametres', 2.5);
    await t.tap(find.text('Boutique A'));
    await wait(t, 5);
    await shot(t, 'k08-retour-boutique-A', 1.5);
    expect(find.text('Boutique A'), findsWidgets);
    // 5. Rapport consolidé, depuis le total du sélecteur.
    await t.tap(navItem('Accueil'));
    await wait(t, 2);
    await t.tap(find.byIcon(LucideIcons.chevronsUpDown));
    await wait(t, 2.5);
    await t.tap(find.text('Total du jour, toutes boutiques'));
    await shot(t, 'k09-rapport-toutes-boutiques', 3.0);
    expect(find.text('Par boutique'), findsOneWidget);
    expect(find.text('Boutique B'), findsWidgets);
    await t.tap(find.text('Cette boutique'));
    await shot(t, 'k10-rapport-cette-boutique', 2.5);
    expect(find.text('Par boutique'), findsNothing);
  });
}
