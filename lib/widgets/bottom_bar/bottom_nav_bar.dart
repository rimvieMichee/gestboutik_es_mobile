import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:foodly/helpers/extensions/string.dart';
import 'package:foodly/helpers/theme/app_theme.dart';
import 'package:foodly/widgets/gesboutik/gb_colors.dart';

/// Barre de navigation flottante avec un indicateur qui glisse vers l'onglet
/// actif (au lieu d'un simple changement de couleur brut à chaque tap).
class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabChange;

  /// Gestionnaire : Accueil, Produits, Employés, Paramètres.
  /// Employé : Accueil, Vente, Paramètres.
  final bool isManager;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabChange,
    this.isManager = false,
  });

  List<_NavItem> get _items => [
        _NavItem(icon: LucideIcons.layoutDashboard, label: 'nav_home'.tr()),
        if (isManager) ...[
          _NavItem(icon: LucideIcons.package, label: 'nav_products'.tr()),
          _NavItem(icon: LucideIcons.users, label: 'nav_employees'.tr()),
        ] else
          _NavItem(icon: LucideIcons.shoppingCart, label: 'nav_sell'.tr()),
        _NavItem(icon: LucideIcons.settings, label: 'nav_settings'.tr()),
      ];

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.theme.colorScheme.primary;
    final c = GbColors.of(context);
    final items = _items;
    final count = items.length;

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        height: 66,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(6),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              alignment: Alignment(
                count > 1 ? -1 + 2 * currentIndex / (count - 1) : 0,
                0,
              ),
              child: FractionallySizedBox(
                widthFactor: 1 / count,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
            Row(
              children: List.generate(count, (index) {
                final item = items[index];
                final isActive = index == currentIndex;
                return Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      if (!isActive) HapticFeedback.selectionClick();
                      onTabChange(index);
                    },
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isActive ? primary : c.subtext,
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w500,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedScale(
                            duration: const Duration(milliseconds: 200),
                            scale: isActive ? 1.08 : 1.0,
                            child: Icon(
                              item.icon,
                              size: 21,
                              color: isActive ? primary : c.subtext,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(item.label),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({required this.icon, required this.label});
}
