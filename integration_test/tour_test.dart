// Visite guidée de l'appli (gestionnaire puis employé) pour produire les
// captures de la vidéo de présentation. Lancée avec un serveur de démonstration.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:foodly/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> wait(WidgetTester t, [double seconds = 1.5]) async {
    final steps = (seconds * 10).round();
    for (var i = 0; i < steps; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> shot(WidgetTester t, String name, [double w = 2.2]) async {
    await wait(t, w);
    await binding.takeScreenshot(name);
  }

  Future<void> tapText(WidgetTester t, String text, {bool last = false}) async {
    final f = last ? find.text(text).last : find.text(text).first;
    await t.tap(f);
  }

  Future<void> login(WidgetTester t, String user, String pass) async {
    final fields = find.byType(TextField);
    await t.enterText(fields.at(0), user);
    await t.enterText(fields.at(1), pass);
    await t.pump(const Duration(milliseconds: 300));
    await t.tap(find.text('Se connecter').first);
    await wait(t, 3.5);
  }

  Future<void> closeSheet(WidgetTester t) async {
    Navigator.of(t.element(find.byType(Scaffold).first), rootNavigator: true)
        .pop();
    await wait(t, 1);
  }

  void goTab(int i) => Get.offAllNamed('/dashboard', arguments: {'tab': i});

  testWidgets('visite guidée', timeout: const Timeout(Duration(minutes: 15)),
      (t) async {
    app.main();
    await wait(t, 4);

    // ----- Gestionnaire -----
    await shot(t, 'm01-login');
    await login(t, 'issa.ouedraogo', 'Selio2026!');
    await shot(t, 'm02-accueil-gestionnaire', 3);
    await t.drag(find.byType(CustomScrollView).first, const Offset(0, -420));
    await wait(t, 0.6);
    await shot(t, 'm03-accueil-bas', 1);
    await t.drag(find.byType(CustomScrollView).first, const Offset(0, 420));
    await wait(t, 0.6);
    await t.tap(find.text('Période').first);
    await shot(t, 'm03b-periode', 2);
    await closeSheet(t);

    goTab(1);
    await shot(t, 'm04-produits', 3);
    await t.tap(find.byIcon(LucideIcons.moreVertical).first);
    await shot(t, 'm05-produit-menu', 1);
    await tapText(t, 'Modifier');
    await shot(t, 'm05b-produit-modifier', 2.5);
    Get.back();
    await wait(t, 1);
    await t.tap(find.byType(FloatingActionButton).first);
    await shot(t, 'm06-produit-nouveau', 2);
    Get.back();
    await wait(t, 1);

    goTab(2);
    await shot(t, 'm07-employes', 3);
    await t.tap(find.byType(FloatingActionButton).first);
    await shot(t, 'm08-employe-nouveau', 1.5);
    await closeSheet(t);
    await t.tap(find.byType(PopupMenuButton<String>).first);
    await shot(t, 'm08b-employe-menu', 1);
    await tapText(t, 'Changer le mot de passe');
    await shot(t, 'm08c-employe-mdp', 1.5);
    await closeSheet(t);
    await tapText(t, 'Aminata Sawadogo');
    await shot(t, 'm09-employe-detail', 3);
    Get.back();
    await wait(t, 1);

    goTab(3);
    await shot(t, 'm10-parametres', 2);
    await tapText(t, 'Mon numéro de téléphone');
    await shot(t, 'm10b-telephone', 1.5);
    await closeSheet(t);
    Get.toNamed('/sales-history');
    await shot(t, 'm11-historique', 3);
    await t.tap(find.textContaining('Mme Ilboudo').first);
    await shot(t, 'm12-vente-credit', 2);
    Get.back();
    await wait(t, 1);
    Get.back();
    await wait(t, 1);
    Get.toNamed('/daily-report');
    await shot(t, 'm13-rapport', 3.5);
    Get.back();
    await wait(t, 1);
    Get.toNamed('/archived-products');
    await shot(t, 'm14-archives', 2.5);
    Get.back();
    await wait(t, 1);
    Get.toNamed('/selectLanguageScreen');
    await shot(t, 'm15-langue', 1.5);
    Get.back();
    await wait(t, 1);

    // Mode sombre
    await tapText(t, 'Apparence');
    await shot(t, 'm16-apparence', 1);
    await tapText(t, 'Sombre');
    await wait(t, 1);
    await closeSheet(t);
    await wait(t, 1);
    goTab(0);
    await shot(t, 'm17-accueil-sombre', 3);
    goTab(1);
    await shot(t, 'm18-produits-sombre', 2.5);
    goTab(3);
    await wait(t, 1.5);
    await tapText(t, 'Apparence');
    await wait(t, 1);
    await tapText(t, 'Clair');
    await wait(t, 1);
    await closeSheet(t);
    await wait(t, 1);

    // ----- Déconnexion → employé -----
    await tapText(t, 'Se déconnecter');
    await wait(t, 1);
    await shot(t, 'm19-deconnexion', 0.8);
    await tapText(t, 'Oui');
    await wait(t, 3);
    await shot(t, 'e01-login-compte-enregistre', 2);
    await t.tap(find.text('Se connecter avec un autre compte').first);
    await wait(t, 1);
    await login(t, 'aminata', 'Selio2026!');
    await shot(t, 'e02-accueil-employe', 3);

    goTab(1);
    await shot(t, 'e03-vente', 3);
    final plus = find.byIcon(LucideIcons.plus);
    await t.tap(plus.at(0));
    await wait(t, 0.4);
    await t.tap(plus.at(0));
    await wait(t, 0.4);
    await t.tap(plus.at(2));
    await shot(t, 'e04-vente-panier', 1.5);
    await tapText(t, 'Voir le détail');
    await shot(t, 'e05-vente-detail', 1.5);
    await t.tap(find.byType(Switch).first);
    await wait(t, 0.8);
    await t.enterText(find.byType(TextField).last, 'Mme Ilboudo');
    await shot(t, 'e06-vente-credit', 1);
    await t.tap(find.text('Enregistrer la vente à crédit').first);
    await shot(t, 'e07-vente-confirmee', 1.2);
    await shot(t, 'e07b-vente-confirmee', 2.5);

    goTab(2);
    await shot(t, 'e08-parametres-employe', 2);
  });
}
