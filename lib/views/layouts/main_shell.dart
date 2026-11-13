import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:foodly/controller/layouts/main_shell_controller.dart';
import 'package:foodly/helpers/storage/local_storage.dart';
import 'package:foodly/views/apps/dashboard/dashboard_screen.dart';
import 'package:foodly/views/apps/employees/employees_screen.dart';
import 'package:foodly/views/apps/products/products_screen.dart';
import 'package:foodly/views/apps/sales/new_sale_screen.dart';
import 'package:foodly/views/apps/settings/settings_page.dart';
import 'package:foodly/widgets/bottom_bar/bottom_nav_bar.dart';

/// Coquille principale affichée après connexion.
/// - Gestionnaire : Accueil / Produits / Employés / Paramètres
/// - Employé : Accueil / Vente / Paramètres
/// L'historique des ventes est dans les Paramètres.
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  static bool get _isManager => LocalStorage.getUserRole() == 'ADMIN';

  @override
  Widget build(BuildContext context) {
    // Onglet de départ optionnel : Get.offAllNamed('/dashboard', arguments: {'tab': 1}).
    final args = Get.arguments;
    final initialTab =
        args is Map && args['tab'] is int ? args['tab'] as int : 0;
    final controller = Get.put(MainShellController(initialIndex: initialTab));
    final tabs = [
      const DashboardScreen(),
      if (_isManager) ...[
        const ProductsScreen(embedded: true),
        const EmployeesScreen(),
      ] else
        const NewSaleScreen(),
      SettingScreen(),
    ];

    return Obx(
      () => Scaffold(
        extendBody: true,
        body: IndexedStack(
          index: controller.currentIndex.value.clamp(0, tabs.length - 1),
          children: tabs,
        ),
        bottomNavigationBar: AppBottomNavBar(
          isManager: _isManager,
          currentIndex: controller.currentIndex.value,
          onTabChange: controller.changeTab,
        ),
      ),
    );
  }
}
