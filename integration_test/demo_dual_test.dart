// Parcours scénarisé à deux appareils : le gestionnaire (simulateur A) crée le
// compte de son employé et présente ses pages ; l'employé (simulateur B) se
// connecte avec ce compte, prépare une vente puis l'enregistre pendant que
// l'écran du gestionnaire se met à jour en direct. Les deux tests se
// synchronisent par de petits fichiers témoins (dossier SYNC_DIR).
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:foodly/main.dart' as app;
import 'package:foodly/widgets/bottom_bar/bottom_nav_bar.dart';

const _syncDir = '/Users/sahelys/AndroidStudioProjects/solidar/gesboutik/brag-output/work/sync';
const _employeeUdid = '2D1E7647-832B-4C64-A12F-1068840B1A76';

int _now() => DateTime.now().millisecondsSinceEpoch;
void _log(String s) => debugPrint(s);
bool _has(String n) => File('$_syncDir/$n').existsSync();
void _put(String n) {
  File('$_syncDir/$n').writeAsStringSync('${_now()}');
  _log('SYNC put $n ${_now()}');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // Le dossier temporaire d'une appli de simulateur contient l'identifiant du simulateur.
  final isEmployee = Directory.systemTemp.path.contains(_employeeUdid);

  Future<void> wait(WidgetTester t, [double s = 1.0]) async {
    final n = (s * 10).round();
    for (var i = 0; i < n; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> waitFor(WidgetTester t, String name, {int maxSec = 1500}) async {
    for (var i = 0; i < maxSec * 10; i++) {
      if (_has(name)) {
        _log('SYNC got $name ${_now()}');
        return;
      }
      await t.pump(const Duration(milliseconds: 100));
    }
    _log('SYNC timeout $name');
  }

  Finder scroller() => find.byWidgetPredicate((w) => w is ScrollView).first;
  Finder eye() => find.byWidgetPredicate(
      (w) => w is Icon && (w.icon == LucideIcons.eye || w.icon == LucideIcons.eyeOff));

  Future<void> tapF(WidgetTester t, Finder f, {double after = 1.0, int pick = 0}) async {
    bool missing(Finder x) {
      try {
        return x.evaluate().isEmpty;
      } catch (_) {
        return true;
      }
    }
    if (missing(f)) {
      _log('MISS ${f.description}');
      return;
    }
    if (FocusManager.instance.primaryFocus?.hasFocus == true) {
      FocusManager.instance.primaryFocus?.unfocus();
      await wait(t, 0.9);
    }
    if (missing(f)) {
      _log('MISS ${f.description}');
      return;
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

  // Retour réel : on referme d'abord un éventuel message (le snackbar GetX est
  // lui-même une « route » : Get.back() ne ferait que le fermer), puis la page.
  Future<void> back(WidgetTester t, {double after = 1.2}) async {
    if (Get.isSnackbarOpen) {
      Get.closeAllSnackbars();
      await wait(t, 0.9);
    }
    final nav = Navigator.of(t.element(find.byType(Scaffold).first), rootNavigator: true);
    if (nav.canPop()) nav.pop();
    await wait(t, after);
  }

  // S'assure qu'on est bien sur l'écran principal (barre du bas visible).
  Future<void> ensureShell(WidgetTester t) async {
    if (Get.isSnackbarOpen) {
      Get.closeAllSnackbars();
      await wait(t, 0.9);
    }
    for (var i = 0; i < 4; i++) {
      // Quand une page est ouverte par-dessus, la barre du bas n'est plus affichée.
      if (find.byType(AppBottomNavBar).evaluate().isNotEmpty) return;
      _log('ENSURE back');
      await back(t);
    }
  }

  // Navigation réelle : on touche l'onglet de la barre du bas (le shell, ses
  // écrans et leurs abonnements temps réel restent en place).
  Future<void> nav(WidgetTester t, String label, {double after = 1.6}) async {
    // Un message de confirmation peut recouvrir la barre : on le referme.
    if (Get.isSnackbarOpen) {
      Get.closeAllSnackbars();
      await wait(t, 0.9);
    }
    await tapF(
        t,
        find.descendant(of: find.byType(AppBottomNavBar), matching: find.text(label)),
        after: after);
  }

  Future<void> scene(WidgetTester t, String id, Future<void> Function() body) async {
    try {
      if (!id.endsWith('_login')) await ensureShell(t);
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

  Finder dayIn(String d) =>
      find.descendant(of: find.byType(CalendarDatePicker), matching: find.text(d));

  // =====================================================================
  //                              GESTIONNAIRE
  // =====================================================================
  Future<void> manager(WidgetTester t) async {
    await wait(t, 14);

    await scene(t, 'm_login', () async {
      final fields = find.byType(TextField);
      await typeText(t, fields.at(0), 'issa.ouedraogo', after: 0.4);
      await typeText(t, fields.at(1), 'Selio2026!', after: 0.4);
      await tapF(t, eye(), after: 1.1);
      await tapF(t, find.text('Se connecter').first, after: 4.0);
    });

    // Premier geste : créer le compte de l'employé.
    await scene(t, 'm_employe', () async {
      await nav(t, 'Employés');
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
    });
    _put('awa_created');

    await scene(t, 'm_accueil', () async {
      await nav(t, 'Accueil');
      await wait(t, 3.0);
      await swipe(t, scroller(), const Offset(0, -380), ms: 900, after: 0.9);
      await tapF(t, find.text('Mois').first, after: 1.3);
      await tapF(t, find.text('Année').first, after: 1.3);
      await tapF(t, find.text('Jour').first, after: 1.0);
      await tapF(t, find.byIcon(LucideIcons.chevronLeft), after: 1.4);
      await tapF(t, find.byIcon(LucideIcons.chevronRight), after: 1.2);
      await tapF(t, find.text('Période').first, after: 1.8);
      await tapF(t, dayIn('3'), after: 1.2);
      await tapF(t, dayIn('9'), after: 1.2);
      await tapF(t, find.text('Valider').first, after: 2.4);
      await swipe(t, scroller(), const Offset(0, 380), ms: 800, after: 0.8);
    });

    await scene(t, 'm_produits', () async {
      await nav(t, 'Produits');
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

    await scene(t, 'm_restock', () async {
      await tapF(t, find.byType(PopupMenuButton<String>), after: 1.2);
      await tapF(t, find.text('Réapprovisionner').first, after: 1.2);
      await typeText(t, find.byType(TextFormField).first, '12', after: 0.7);
      await tapF(t, find.text('Valider').first, after: 2.6);
    });

    await scene(t, 'm_nouveau', () async {
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

    await scene(t, 'm_archive', () async {
      await nav(t, 'Produits');
      await wait(t, 2.6);
      await tapF(t, find.text('Rupture').first, after: 1.8);
      await tapF(t, find.byType(PopupMenuButton<String>), after: 1.2);
      await tapF(t, find.text('Archiver (mettre de côté)').first, after: 1.8);
      await tapF(t, find.text('Archiver').last, after: 2.8);
      await nav(t, 'Paramètres');
      await wait(t, 1.8);
      await tapF(t, find.text('Produits archivés').first, after: 2.4);
      await tapF(t, find.text('Restaurer').first, after: 2.6);
      await back(t);
    });

    await scene(t, 'm_rapport', () async {
      await nav(t, 'Paramètres');
      await wait(t, 1.8);
      await tapF(t, find.text('Rapport journalier').first, after: 3.0);
      await swipe(t, scroller(), const Offset(0, -420), ms: 1000, after: 1.0);
      await swipe(t, scroller(), const Offset(0, 420), ms: 800, after: 0.8);
      await tapF(t, find.byIcon(LucideIcons.calendar), after: 1.8);
      await tapF(t, dayIn('5'), after: 1.2);
      await tapF(t, find.text('Valider').first, after: 2.6);
      await tapF(t, find.byIcon(LucideIcons.chevronRight), after: 1.6, pick: -1);
      await back(t);
    });

    await scene(t, 'm_theme', () async {
      await nav(t, 'Paramètres');
      await wait(t, 1.8);
      await tapF(t, find.text('Apparence').first, after: 1.6);
      await tapF(t, find.text('Sombre').first, after: 1.4);
      await closeSheet(t, 1.2);
      await nav(t, 'Accueil');
      await wait(t, 2.8);
      await nav(t, 'Produits');
      await wait(t, 2.4);
      await nav(t, 'Paramètres');
      await wait(t, 1.8);
      await tapF(t, find.text('Apparence').first, after: 1.4);
      await tapF(t, find.text('Clair').first, after: 1.4);
      await closeSheet(t, 1.0);
    });

    await scene(t, 'm_langue', () async {
      await nav(t, 'Paramètres');
      await wait(t, 1.2);
      await tapF(t, find.text('Langue').first, after: 1.8);
      await tapF(t, find.text('English').first, after: 2.0);
      if (find.text('Français').evaluate().isNotEmpty && find.byIcon(LucideIcons.chevronLeft).evaluate().isNotEmpty) {
        await back(t);
      }
      await nav(t, 'Home');
      await wait(t, 3.0);
      await nav(t, 'Settings');
      await wait(t, 1.2);
      await tapF(t, find.text('Language').first, after: 1.6);
      await tapF(t, find.text('Français').first, after: 1.8);
      await back(t);
      await wait(t, 1.0);
    });

    // L'écran du gestionnaire attend la vente de l'employé.
    await nav(t, 'Accueil');
    await wait(t, 3.5);
    _log('MARK start:live_m ${_now()}');
    _put('live_ready');
    await waitFor(t, 'sale_done');
    await wait(t, 10);
    _log('MARK end:live_m ${_now()}');

    await scene(t, 'm_vente', () async {
      await nav(t, 'Paramètres');
      await wait(t, 1.8);
      await tapF(t, find.text('Historique des ventes').first, after: 2.8);
      await tapF(t, find.textContaining('Mme Ilboudo').first, after: 2.4);
      await swipe(t, scroller(), const Offset(0, -240), ms: 700, after: 1.4);
      await back(t);
      await back(t);
    });

    await waitFor(t, 'employee_finished');
    _log('MARK done ${_now()}');
    await wait(t, 3);
  }

  // =====================================================================
  //                                EMPLOYÉ
  // =====================================================================
  Future<void> employee(WidgetTester t) async {
    await wait(t, 14);
    await waitFor(t, 'awa_created');
    await wait(t, 1.0);

    await scene(t, 'e_login', () async {
      final fields = find.byType(TextField);
      await typeText(t, fields.at(0), 'awa', after: 0.4);
      await typeText(t, fields.at(1), 'Selio2026!', after: 0.4);
      await tapF(t, eye(), after: 1.0);
      await tapF(t, find.text('Se connecter').first, after: 4.2);
    });

    await scene(t, 'e_accueil', () async {
      await nav(t, 'Accueil');
      await wait(t, 3.2);
      await swipe(t, scroller(), const Offset(0, -320), ms: 900, after: 1.2);
      await swipe(t, scroller(), const Offset(0, 320), ms: 800, after: 0.8);
    });

    await scene(t, 'e_vente', () async {
      await nav(t, 'Vente');
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
    });
    _put('employee_ready');
    await waitFor(t, 'live_ready');
    await wait(t, 2.5);

    // Vente enregistrée pendant que le gestionnaire regarde son accueil.
    _log('MARK start:live ${_now()}');
    await tapF(t, find.text('Enregistrer la vente à crédit').first, after: 3.6);
    _put('sale_done');
    await wait(t, 3.0);
    await tapF(t, find.text("Retour à l'accueil").first, after: 5.0);
    _log('MARK end:live ${_now()}');

    await scene(t, 'e_apres', () async {
      await nav(t, 'Accueil');
      await wait(t, 3.2);
      await swipe(t, scroller(), const Offset(0, -320), ms: 900, after: 1.2);
      await swipe(t, scroller(), const Offset(0, 320), ms: 800, after: 0.8);
      await nav(t, 'Paramètres');
      await wait(t, 1.8);
      await tapF(t, find.text('Historique des ventes').first, after: 3.0);
      await back(t);
    });
    _put('employee_finished');
    _log('MARK done ${_now()}');
    await wait(t, 3);
  }

  testWidgets('démo à deux appareils', timeout: const Timeout(Duration(minutes: 40)), (t) async {
    app.main();
    await wait(t, 5);
    _log('ROLE ${isEmployee ? 'employee' : 'manager'} ${Directory.systemTemp.path}');
    _log('MARK warmup ${_now()}');
    if (isEmployee) {
      await employee(t);
    } else {
      await manager(t);
    }
  });
}
