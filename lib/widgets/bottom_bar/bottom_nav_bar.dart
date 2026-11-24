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

  /// Gestionnaire : Accueil, Produits, Vente (bouton central surélevé), Employés,
  /// Paramètres.
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
          // Au milieu, le bouton surélevé : la vente est l'action principale.
          _NavItem(icon: LucideIcons.shoppingCart, label: 'nav_sell'.tr()),
          _NavItem(icon: LucideIcons.users, label: 'nav_employees'.tr()),
        ] else
          _NavItem(icon: LucideIcons.shoppingCart, label: 'nav_sell'.tr()),
        _NavItem(icon: LucideIcons.settings, label: 'nav_settings'.tr()),
      ];

  /// Bouton rond surélevé de l'onglet central (comme l'appli client).
  Widget _centerButton(
      _NavItem item, bool active, Color primary, GbColors c) {
    return GestureDetector(
      onTap: () {
        if (!active) HapticFeedback.selectionClick();
        onTabChange(2);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: active ? primary : c.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: active ? primary : primary.withOpacity(0.35),
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: primary.withOpacity(active ? 0.38 : 0.16),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(item.icon, size: 26, color: active ? Colors.white : primary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.theme.colorScheme.primary;
    final c = GbColors.of(context);
    final items = _items;
    final count = items.length;
    // 5 onglets : celui du milieu est un bouton rond surélevé.
    final centerIndex = isManager ? 2 : -1;

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        clipBehavior: Clip.none,
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
          clipBehavior: Clip.none,
          children: [
            if (centerIndex >= 0)
              Positioned(
                top: -40,
                left: 0,
                right: 0,
                child: Center(
                  child: _centerButton(
                      items[centerIndex], currentIndex == centerIndex, primary, c),
                ),
              ),
            AnimatedAlign(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              alignment: Alignment(
                count > 1 ? -1 + 2 * currentIndex / (count - 1) : 0,
                0,
              ),
              child: FractionallySizedBox(
                widthFactor: 1 / count,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: currentIndex == centerIndex ? 0 : 1,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            ),
            Row(
              children: List.generate(count, (index) {
                final item = items[index];
                final isActive = index == currentIndex;
                if (index == centerIndex) {
                  // Le bouton rond est dessiné au-dessus ; ici, seulement le libellé.
                  return Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        if (!isActive) HapticFeedback.selectionClick();
                        onTabChange(index);
                      },
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isActive ? primary : c.subtext,
                              fontWeight:
                                  isActive ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }
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
