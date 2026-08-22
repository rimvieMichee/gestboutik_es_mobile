import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:foodly/controller/layouts/main_shell_controller.dart';
import 'package:foodly/views/apps/dashboard/dashboard_screen.dart';
import 'package:foodly/views/apps/profile/profile.dart';
import 'package:foodly/views/apps/settings/settings_page.dart';
import 'package:foodly/widgets/bottom_bar/bottom_nav_bar.dart';

/// Coquille principale affichée après connexion : Dashboard / Profil / Paramètres.
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  static final _tabs = [
    const DashboardScreen(),
    const ProfilePage(),
    SettingScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MainShellController());

    return Obx(
      () => Scaffold(
        extendBody: true,
        body: IndexedStack(
          index: controller.currentIndex.value,
          children: _tabs,
        ),
        bottomNavigationBar: AppBottomNavBar(
          currentIndex: controller.currentIndex.value,
          onTabChange: controller.changeTab,
        ),
      ),
    );
  }
}
