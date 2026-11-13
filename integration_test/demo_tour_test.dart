// Parcours scénarisé de l'appli (gestionnaire puis employé) pendant que le
// simulateur est filmé. Chaque scène est encadrée par des marqueurs
// `MARK start:<id>` / `MARK end:<id>` ; chaque touche ou balayage est journalisé
// (`TAP`, `SWIPE`) pour pouvoir dessiner le doigt dans la vidéo.
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:foodly/main.dart' as app;

int _now() => DateTime.now().millisecondsSinceEpoch;
void _log(String s) => debugPrint(s);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> wait(WidgetTester t, [double s = 1.0]) async {
    final n = (s * 10).round();
    for (var i = 0; i < n; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
  }

  Finder scroller() => find.byWidgetPredicate((w) => w is ScrollView).first;

  Future<void> tapF(WidgetTester t, Finder f, {double after = 1.0, int pick = 0}) async {
    if (f.evaluate().isEmpty) {
      _log('MISS ${f.description}');
      return;
    }
    // Un utilisateur referme le clavier avant d'appuyer sur un bouton masqué.
    if (FocusManager.instance.primaryFocus?.hasFocus == true) {
      FocusManager.instance.primaryFocus?.unfocus();
      await wait(t, 0.9);
    }
    final n = f.evaluate().length;
    final el = pick < 0 ? f.at(n - 1) : (n > pick ? f.at(pick) : f.first);
    final c = t.getCenter(el);
    _log('TAP ${_now()} ${c.dx.toStringAsFixed(1)} ${c.dy.toStringAsFixed(1)}');
    await t.pump(const Duration(milliseconds: 120));
    await t.tap(el, warnIfMissed: false);
    await wait(t, after);
  }

  Future<void> swipe(WidgetTester t, Finder f, Offset d, {int ms = 650, double after = 0.6}) async {
    if (f.evaluate().isEmpty) {
      _log('MISS swipe');
      return;
    }
    final c = t.getCenter(f.first);
    final start = c - Offset(d.dx / 2, d.dy / 2);
    _log('SWIPE ${_now()} ${start.dx.toStringAsFixed(1)} ${start.dy.toStringAsFixed(1)} ${d.dx.toStringAsFixed(1)} ${d.dy.toStringAsFixed(1)} $ms');
    await t.timedDragFrom(start, d, Duration(milliseconds: ms));
    await wait(t, after);
  }

  Future<void> typeText(WidgetTester t, Finder f, String text, {int ms = 75, double after = 0.5}) async {
    if (f.evaluate().isEmpty) {
      _log('MISS type ${f.description}');
      return;
    }
    final c = t.getCenter(f.first);
    _log('TAP ${_now()} ${c.dx.toStringAsFixed(1)} ${c.dy.toStringAsFixed(1)}');
    await wait(t, 0.35);
    for (var i = 1; i <= text.length; i++) {
      await t.enterText(f.first, text.substring(0, i));
      await t.pump(Duration(milliseconds: ms));
    }
    await wait(t, after);
  }

  Future<void> closeSheet(WidgetTester t, [double after = 1.0]) async {
    Navigator.of(t.element(find.byType(Scaffold).first), rootNavigator: true).pop();
    await wait(t, after);
  }

  Finder eye() => find.byWidgetPredicate(
      (w) => w is Icon && (w.icon == LucideIcons.eye || w.icon == LucideIcons.eyeOff));

  void tab(int i) => Get.offAllNamed('/dashboard', arguments: {'tab': i});

  Future<void> scene(WidgetTester t, String id, Future<void> Function() body) async {
    try {
      await wait(t, 1.3);
      _log('MARK start:$id ${_now()}');
      await body();
      await wait(t, 1.2);
      _log('MARK end:$id ${_now()}');
    } catch (e) {
      _log('SCENE_FAIL $id $e');
      _log('MARK end:$id ${_now()}');
    }
  }

  testWidgets('démo', timeout: const Timeout(Duration(minutes: 25)), (t) async {
    app.main();
    await wait(t, 5);
    _log('MARK warmup ${_now()}');
    await wait(t, 14);

    // ---------------------------------------------------------- connexion
    await scene(t, 'login', () async {
      final fields = find.byType(TextField);
      await typeText(t, fields.at(0), 'issa.ouedraogo', after: 0.4);
      await typeText(t, fields.at(1), 'Selio2026!', after: 0.4);
      await tapF(t, eye(), after: 1.1);
      await tapF(t, find.text('Se connecter').first, after: 4.0);
    });

    // ------------------------------------------------------------ accueil
    await scene(t, 'accueil', () async {
      await swipe(t, scroller(), const Offset(0, -380), ms: 900, after: 0.9);
      await tapF(t, find.text('Mois').first, after: 1.3);
      await tapF(t, find.text('Année').first, after: 1.3);
      await tapF(t, find.text('Jour').first, after: 1.0);
      await tapF(t, find.byIcon(LucideIcons.chevronLeft), after: 1.4);
      await tapF(t, find.byIcon(LucideIcons.chevronRight), after: 1.2);
      await tapF(t, find.text('Période').first, after: 1.8);
      final cal = find.byType(CalendarDatePicker);
      await tapF(t, find.descendant(of: cal, matching: find.text('3')), after: 1.2);
      await tapF(t, find.descendant(of: cal, matching: find.text('9')), after: 1.2);
      await tapF(t, find.text('Valider').first, after: 2.4);
      await swipe(t, scroller(), const Offset(0, 380), ms: 800, after: 0.8);
    });

    // ------------------------------------------------------------ produits
    await scene(t, 'produits', () async {
      tab(1);
      await wait(t, 3.0);
      await swipe(t, scroller(), const Offset(0, -520), ms: 1000, after: 0.8);
      await swipe(t, scroller(), const Offset(0, 520), ms: 800, after: 0.6);
      await typeText(t, find.byType(TextField).first, 'riz', after: 1.6);
      await t.enterText(find.byType(TextField).first, '');
      await wait(t, 1.2);
      await tapF(t, find.text('Stock bas').first, after: 1.6);
      await tapF(t, find.text('Rupture').first, after: 1.6);
      await tapF(t, find.text('Tous').first, after: 1.2);
    });

    await scene(t, 'restock', () async {
      await tapF(t, find.byType(PopupMenuButton<String>), after: 1.2);
      await tapF(t, find.text('Réapprovisionner').first, after: 1.2);
      await typeText(t, find.byType(TextFormField).first, '12', after: 0.7);
      await tapF(t, find.text('Valider').first, after: 2.6);
    });

    await scene(t, 'nouveau', () async {
      await tapF(t, find.byType(FloatingActionButton), after: 1.6);
      final f = find.byType(TextFormField);
      await typeText(t, f.at(0), 'Huile végétale 20 L', after: 0.3);
      await typeText(t, f.at(2), '21000', after: 0.3);
      await typeText(t, f.at(3), '17500', after: 0.3);
      await swipe(t, scroller(), const Offset(0, -330), ms: 800, after: 0.6);
      await typeText(t, f.at(4), '20', after: 0.3);
      await typeText(t, f.at(5), '5', after: 0.8);
      await tapF(t, find.text('Créer le produit').first, after: 3.2);
    });

    await scene(t, 'archive', () async {
      tab(1);
      await wait(t, 2.6);
      await tapF(t, find.byType(PopupMenuButton<String>), after: 1.2);
      await tapF(t, find.text('Archiver (mettre de côté)').first, after: 1.6);
      await tapF(t, find.text('Archiver').last, after: 2.4);
      tab(3);
      await wait(t, 1.8);
      await tapF(t, find.text('Produits archivés').first, after: 2.4);
      await tapF(t, find.text('Restaurer').first, after: 2.6);
      Get.back();
    });

    // ----------------------------------------------------------- employés
    await scene(t, 'employes', () async {
      tab(2);
      await wait(t, 2.8);
      await tapF(t, find.byType(FloatingActionButton), after: 1.5);
      final f = find.byType(TextFormField);
      await typeText(t, f.at(0), 'Awa', after: 0.3);
      await typeText(t, f.at(1), 'Ouattara', after: 0.3);
      await typeText(t, f.at(2), '70445566', after: 0.3);
      await typeText(t, f.at(3), 'awa', after: 0.3);
      await typeText(t, f.at(4), 'Selio2026!', after: 0.5);
      await tapF(t, eye(), after: 1.0);
      await tapF(t, find.text('Créer le compte').first, after: 3.0);
      await tapF(t, find.byType(PopupMenuButton<String>), after: 1.3);
      await tapF(t, find.text('Désactiver').first, after: 2.2);
      await tapF(t, find.text('Annuler').first, after: 1.4);
      await tapF(t, find.text('Aminata Sawadogo').first, after: 3.0);
      await swipe(t, scroller(), const Offset(0, -380), ms: 900, after: 1.2);
      Get.back();
    });

    // --------------------------------------------------------- historique
    await scene(t, 'historique', () async {
      tab(3);
      await wait(t, 2.0);
      await tapF(t, find.text('Historique des ventes').first, after: 2.8);
      await tapF(t, find.text('Crédit en cours').first, after: 1.8);
      await tapF(t, find.textContaining('Mme Ilboudo').first, after: 2.2);
      await swipe(t, scroller(), const Offset(0, -200), ms: 600, after: 0.8);
      await tapF(t, find.text('Marquer comme payé').first, after: 1.6);
      await tapF(t, find.text('Oui, marquer payé').first, after: 3.0);
      Get.back();
      await wait(t, 1.0);
      Get.back();
    });

    // ------------------------------------------------------------- rapport
    await scene(t, 'rapport', () async {
      tab(3);
      await wait(t, 1.8);
      await tapF(t, find.text('Rapport journalier').first, after: 3.0);
      await swipe(t, scroller(), const Offset(0, -420), ms: 1000, after: 1.0);
      await swipe(t, scroller(), const Offset(0, 420), ms: 800, after: 0.8);
      await tapF(t, find.byIcon(LucideIcons.calendar), after: 1.8);
      await tapF(t, find.descendant(of: find.byType(CalendarDatePicker), matching: find.text('5')), after: 1.2);
      await tapF(t, find.text('Valider').first, after: 2.6);
      await tapF(t, find.byIcon(LucideIcons.chevronRight), after: 1.6, pick: -1);
      Get.back();
    });

    // ---------------------------------------------- thème (clair → sombre)
    await scene(t, 'theme', () async {
      tab(3);
      await wait(t, 1.8);
      await tapF(t, find.text('Apparence').first, after: 1.6);
      await tapF(t, find.text('Sombre').first, after: 1.4);
      await closeSheet(t, 1.2);
      tab(0);
      await wait(t, 2.8);
      tab(1);
      await wait(t, 2.8);
      tab(3);
      await wait(t, 1.8);
      await tapF(t, find.text('Apparence').first, after: 1.4);
      await tapF(t, find.text('Clair').first, after: 1.4);
      await closeSheet(t, 1.0);
    });

    // ---------------------------------------------------------- langue (EN)
    await scene(t, 'langue', () async {
      tab(3);
      await wait(t, 1.8);
      await tapF(t, find.text('Langue').first, after: 1.8);
      await tapF(t, find.text('English').first, after: 2.0);
      if (find.text('Français').evaluate().isNotEmpty && find.byIcon(LucideIcons.chevronLeft).evaluate().isNotEmpty) {
        Get.back();
        await wait(t, 1.2);
      }
      tab(0);
      await wait(t, 3.0);
      tab(3);
      await wait(t, 1.8);
      await tapF(t, find.text('Language').first, after: 1.6);
      await tapF(t, find.text('Français').first, after: 1.4);
      Get.back();
    });

    // --------------------------------------------------- employé : connexion
    await scene(t, 'e_login', () async {
      tab(3);
      await wait(t, 1.8);
      await tapF(t, find.text('Se déconnecter').first, after: 1.5);
      await tapF(t, find.text('Oui').first, after: 3.2);
      await tapF(t, find.text('Se connecter avec un autre compte').first, after: 1.4);
      final fields = find.byType(TextField);
      await typeText(t, fields.at(0), 'aminata', after: 0.3);
      await typeText(t, fields.at(1), 'Selio2026!', after: 0.4);
      await tapF(t, find.text('Se connecter').first, after: 4.2);
    });

    // ------------------------------------------------------ employé : vente
    await scene(t, 'e_vente', () async {
      tab(1);
      await wait(t, 3.0);
      await typeText(t, find.byType(TextField).first, 'carton', after: 1.5);
      await tapF(t, find.byIcon(LucideIcons.plus), after: 0.8);
      await tapF(t, find.byIcon(LucideIcons.plus), after: 0.8, pick: 0);
      await t.enterText(find.byType(TextField).first, '');
      await wait(t, 1.2);
      await typeText(t, find.byType(TextField).first, 'sac', after: 1.5);
      await tapF(t, find.byIcon(LucideIcons.plus), after: 1.0);
      await t.enterText(find.byType(TextField).first, '');
      await wait(t, 1.2);
      await typeText(t, find.byType(TextField).first, 'glen', after: 1.5);
      await tapF(t, find.byIcon(LucideIcons.plus), after: 1.2);
      await t.enterText(find.byType(TextField).first, '');
      await wait(t, 1.2);
      await tapF(t, find.text('Voir le détail').first, after: 2.0);
      await tapF(t, find.byType(Switch), after: 1.0);
      await typeText(t, find.byType(TextField).last, 'Mme Ilboudo', after: 0.9);
      await tapF(t, find.text('Enregistrer la vente à crédit').first, after: 3.6);
      await tapF(t, find.text("Retour à l'accueil").first, after: 3.4);
    });

    _log('MARK done ${_now()}');
    await wait(t, 3);
  });
}
