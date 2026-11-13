import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:foodly/helpers/theme/app_theme.dart';

/// Bouton d'ajout rond (icône « + » dans un cercle), en bas à droite.
/// [aboveNavBar] relève le bouton quand l'écran est un onglet de la barre du bas.
class GbAddButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String tooltip;
  final bool aboveNavBar;

  const GbAddButton({
    super.key,
    required this.onPressed,
    required this.tooltip,
    this.aboveNavBar = true,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.theme.colorScheme.primary;
    return Padding(
      padding: EdgeInsets.only(bottom: aboveNavBar ? 90.h : 0),
      child: SizedBox(
        width: 62.w,
        height: 62.w,
        child: FloatingActionButton(
          // Plusieurs boutons « + » coexistent dans les onglets : sans étiquette
          // Hero propre à chacun, Flutter lève une erreur à chaque transition.
          heroTag: null,
          onPressed: onPressed,
          tooltip: tooltip,
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: const CircleBorder(),
          child: Icon(LucideIcons.plus, size: 28.sp),
        ),
      ),
    );
  }
}
