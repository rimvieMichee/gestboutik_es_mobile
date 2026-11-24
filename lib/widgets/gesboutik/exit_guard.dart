import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:foodly/helpers/extensions/string.dart';
import 'package:foodly/helpers/utils/app_snackbar.dart';
import 'package:foodly/widgets/gesboutik/gb_sheets.dart';

/// Empêche le bouton retour du téléphone de fermer l'application d'un coup.
///
/// 1er appui : un message prévient qu'un second appui ferme l'application.
/// 2e appui (dans les 2 secondes) : une feuille demande de confirmer. Les
/// écrans empilés au-dessus (détail, formulaire, feuille ouverte) se ferment
/// normalement : le garde ne s'applique qu'à l'écran racine qui l'enveloppe.
class ExitGuard extends StatefulWidget {
  final Widget child;
  const ExitGuard({super.key, required this.child});

  @override
  State<ExitGuard> createState() => _ExitGuardState();
}

class _ExitGuardState extends State<ExitGuard> {
  DateTime? _lastBack;
  bool _asking = false;

  Future<void> _onBack() async {
    if (_asking) return;
    final now = DateTime.now();
    final again = _lastBack != null &&
        now.difference(_lastBack!) < const Duration(seconds: 2);
    if (!again) {
      _lastBack = now;
      appSnackbar(
        heading: 'exit_hint_title'.tr(),
        message: 'exit_hint'.tr(),
        snackbarState: SnackbarState.info,
      );
      return;
    }
    _lastBack = null;
    _asking = true;
    // L'avertissement ne doit pas recouvrir les boutons de la feuille.
    if (Get.isSnackbarOpen) await Get.closeCurrentSnackbar();
    final quit = await showGbConfirmSheet(
      context,
      title: 'exit_title'.tr(),
      message: 'exit_body'.tr(),
      confirmLabel: 'exit_confirm'.tr(),
      cancelLabel: 'exit_stay'.tr(),
      destructive: true,
      icon: LucideIcons.logOut,
    );
    _asking = false;
    if (quit == true) SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: widget.child,
    );
  }
}
