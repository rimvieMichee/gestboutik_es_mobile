import 'package:foodly/views/apps/employees/employee_detail_screen.dart';
import 'package:foodly/views/apps/products/archived_products_screen.dart';
import 'package:foodly/views/apps/products/product_form_screen.dart';
import 'package:foodly/views/apps/reports/daily_report_screen.dart';
import 'package:foodly/views/apps/profile/edit_profile.dart';
import 'package:foodly/views/apps/sales/sales_history_screen.dart';
import 'package:foodly/views/apps/settings/widget/select_language.dart';
import 'package:foodly/views/auth/login_page.dart';
import 'package:foodly/views/onboarding/onboarding_screen.dart';
import 'package:foodly/views/layouts/main_shell.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'helpers/services/auth_services.dart';
import 'views/error_pages/coming_soon_page.dart';
import 'views/error_pages/error_404.dart';
import 'views/error_pages/error_500.dart';
import 'views/error_pages/maintenance_page.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    if (route == '/auth/login') {
      print("Autorisation route login");
      return null;
    }
    if (!AuthService.isLoggedIn) {
      print("Redirection forcée vers /auth/login");
      return const RouteSettings(name: '/auth/login');
    }
    print("Autorisation route protégée: $route");
    return null;
  }
}

getPageRoute() {
  var routes = [
    GetPage(name: '/onboarding', page: () => const OnboardingScreen()),
    GetPage(
        name: '/dashboard',
        page: () => const MainShell(),
        middlewares: [AuthMiddleware()]),
    GetPage(
        name: '/profileDetail',
        page: () => const ProfileDetails(),
        middlewares: [AuthMiddleware()]),

    GetPage(
        name: '/selectLanguageScreen',
        page: () => const SelectLanguageScreen(),
        middlewares: [AuthMiddleware()]),

    ///---------------- Ventes ----------------///
    GetPage(
        name: '/employee-detail',
        page: () => const EmployeeDetailScreen(),
        middlewares: [AuthMiddleware()]),
    GetPage(
        name: '/archived-products',
        page: () => const ArchivedProductsScreen(),
        middlewares: [AuthMiddleware()]),
    GetPage(
        name: '/daily-report',
        page: () => const DailyReportScreen(),
        middlewares: [AuthMiddleware()]),
    GetPage(
        name: '/product-form',
        page: () => const ProductFormScreen(),
        middlewares: [AuthMiddleware()]),
    GetPage(
        name: '/sales-history',
        page: () => const SalesHistoryScreen(),
        middlewares: [AuthMiddleware()]),

    ///---------------- Auth ----------------///
    GetPage(name: '/auth/login', page: () => const LoginPage()),

    ///---------------- Error ----------------///
    GetPage(
        name: '/coming-soon',
        page: () => const ComingSoonPage(),
        middlewares: [AuthMiddleware()]),
    GetPage(
        name: '/error-404',
        page: () => const Error404(),
        middlewares: [AuthMiddleware()]),
    GetPage(
        name: '/error-500',
        page: () => const Error500(),
        middlewares: [AuthMiddleware()]),
    GetPage(
        name: '/maintenance',
        page: () => const MaintenancePage(),
        middlewares: [AuthMiddleware()]),
  ];
  return routes
      .map(
        (e) => GetPage(
            name: e.name,
            page: e.page,
            middlewares: e.middlewares,
            transition: Transition.cupertino,
            transitionDuration: const Duration(milliseconds: 280)),
      )
      .toList();
}
