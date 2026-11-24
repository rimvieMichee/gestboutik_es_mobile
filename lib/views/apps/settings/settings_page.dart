import 'package:foodly/views/apps/shops/shop_switcher_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart' hide Trans;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:foodly/controller/apps/settings/settings_controller.dart';
import 'package:foodly/helpers/extensions/string.dart';
import 'package:foodly/helpers/localizations/language.dart';
import 'package:foodly/helpers/services/biometric_service.dart';
import 'package:foodly/helpers/storage/local_storage.dart';
import 'package:foodly/helpers/theme/app_notifier.dart';
import 'package:foodly/helpers/theme/app_theme.dart';
import 'package:foodly/helpers/utils/app_snackbar.dart';
import 'package:foodly/views/apps/settings/widget/biometric_sheet.dart';
import 'package:foodly/views/apps/settings/widget/logout_bottom_sheet.dart';
import 'package:foodly/views/apps/settings/widget/password_sheet.dart';
import 'package:foodly/views/apps/settings/widget/phone_sheet.dart';
import 'package:foodly/widgets/gesboutik/gb_app_bar.dart';
import 'package:foodly/widgets/gesboutik/gb_colors.dart';
import 'package:foodly/widgets/gesboutik/gb_staggered_item.dart';

/// Paramètres : en-tête (avatar, nom, rôle) puis une seule carte qui regroupe
/// toutes les lignes, séparées par de fins traits : icône, titre, sous-titre
/// et chevron ou interrupteur.
class SettingScreen extends StatelessWidget {
  SettingScreen({super.key});

  final controller = Get.put(SettingsController());

  bool get _isManager => LocalStorage.getUserRole() == 'ADMIN';

  String get _roleLabel {
    switch (LocalStorage.getUserRole()) {
      case 'SUPER_ADMIN':
        return 'role_technician'.tr();
      case 'ADMIN':
        return 'role_manager'.tr();
      case 'EMPLOYEE':
        return 'role_employee'.tr();
      default:
        return '—';
    }
  }

  String get _themeLabel => switch (LocalStorage.getThemeMode()) {
        ThemeMode.system => 'theme_system'.tr(),
        ThemeMode.light => 'theme_light'.tr(),
        ThemeMode.dark => 'theme_dark'.tr(),
      };

  @override
  Widget build(BuildContext context) {
    return Consumer<AppNotifier>(
      builder: (_, __, ___) {
        final c = GbColors.of(context);
        return Scaffold(
          backgroundColor: c.background,
          appBar: gbAppBar(title: 'settings_title'.tr(), showBack: false),
          body: Obx(() => controller.isLoading.value
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 120.h),
                  children: [
                    GbStaggeredItem(index: 0, child: _header(c)),
                    SizedBox(height: 22.h),
                    GbStaggeredItem(index: 1, child: _mainCard(context, c)),
                  ],
                )),
        );
      },
    );
  }

  // ---------------------------------------------------------------- en-tête

  Widget _header(GbColors c) {
    final primary = AppTheme.theme.colorScheme.primary;
    final name = LocalStorage.getUserName() ?? '';
    final boutique = LocalStorage.getBoutiqueName() ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Row(
      children: [
        Container(
          width: 60.w,
          height: 60.w,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: primary.withOpacity(0.14), shape: BoxShape.circle),
          child: Text(initial,
              style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: primary)),
        ),
        SizedBox(width: 15.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name.isNotEmpty ? name : _roleLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w600,
                      color: c.text)),
              SizedBox(height: 2.h),
              Text(
                boutique.isNotEmpty ? '$_roleLabel · $boutique' : _roleLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14.sp, color: c.subtext),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------ carte unique

  Widget _mainCard(BuildContext context, GbColors c) {
    final language =
        Language.getLanguageFromCode(LocalStorage.getLanguage() ?? 'fr')
            .languageName;
    final tiles = <Widget>[
      // Gestionnaire de plusieurs boutiques : changer de boutique.
      if (LocalStorage.isMultiShop)
        _tile(c,
            icon: LucideIcons.store,
            title: 'shops_title'.tr(),
            subtitle:
                '${LocalStorage.getBoutiqueName() ?? ''} · ${'shops_count'.trp({
                  'n': '${LocalStorage.getShopCount()}'
                })}',
            onTap: () => showShopSwitcher(context)),
      _tile(c,
          icon: LucideIcons.sunMoon,
          title: 'appearance'.tr(),
          subtitle: _themeLabel,
          onTap: () => _showThemeSheet(context)),
      _tile(c,
          icon: LucideIcons.globe,
          title: 'language'.tr(),
          subtitle: language,
          onTap: () => Get.toNamed('/selectLanguageScreen')),
      _tile(c,
          icon: LucideIcons.history,
          title: 'sales_history'.tr(),
          subtitle: (_isManager ? 'whole_shop' : 'dash_my_sales').tr(),
          onTap: () => Get.toNamed('/sales-history')),
      if (_isManager) ...[
        _tile(c,
            icon: LucideIcons.fileText,
            title: 'daily_report'.tr(),
            subtitle: 'download_pdf'.tr(),
            onTap: () => Get.toNamed('/daily-report')),
        _tile(c,
            icon: LucideIcons.archive,
            title: 'archived_products'.tr(),
            subtitle: 'archive_set_aside'.tr(),
            onTap: () => Get.toNamed('/archived-products')),
        _tile(c,
            icon: LucideIcons.phone,
            title: 'my_phone'.tr(),
            subtitle: 'phone_sheet_desc'.tr(),
            onTap: () => showPhoneSheet(context)),
        _tile(c,
            icon: LucideIcons.keyRound,
            title: 'change_password'.tr(),
            subtitle: 'change_password_hint'.tr(),
            onTap: () => showPasswordSheet(context)),
      ],
      if (controller.biometricSupported.value) _biometricTile(context, c),
      _tile(c,
          icon: LucideIcons.logOut,
          title: 'logout'.tr(),
          onTap: () => _confirmLogout(context)),
    ];
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: c.isDark ? Border.all(color: c.border) : null,
        boxShadow: c.shadow,
      ),
      child: Column(
        children: [
          for (var i = 0; i < tiles.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: c.border),
            tiles[i],
          ],
        ],
      ),
    );
  }

  /// Ligne type : icône, titre, sous-titre, puis chevron ou [trailing].
  Widget _tile(
    GbColors c, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        child: Row(
          children: [
            Icon(icon, size: 24.sp, color: c.text),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          color: c.text)),
                  if (subtitle != null) ...[
                    SizedBox(height: 3.h),
                    Text(subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.sp, color: c.subtext)),
                  ],
                ],
              ),
            ),
            trailing ??
                Icon(Icons.keyboard_arrow_right, size: 24.sp, color: c.text),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------- apparence

  void _showThemeSheet(BuildContext context) {
    final c = context.gb;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26.r)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w,
            MediaQuery.of(sheetContext).padding.bottom + 20.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 16.h),
                decoration: BoxDecoration(
                    color: c.skeleton,
                    borderRadius: BorderRadius.circular(4.r)),
              ),
            ),
            Text('appearance'.tr(),
                style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: c.text)),
            SizedBox(height: 14.h),
            _ThemeSelector(onChanged: () {
              Provider.of<AppNotifier>(context, listen: false).changeTheme();
            }),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------- biométrie

  /// Connexion par empreinte / Face ID : interrupteur. L'activer demande le
  /// mot de passe (stocké de façon sécurisée) puis une confirmation biométrique.
  Widget _biometricTile(BuildContext context, GbColors c) {
    final primary = AppTheme.theme.colorScheme.primary;
    final enabled = controller.biometricEnabled.value;
    return _tile(
      c,
      icon: BiometricService.isIOS
          ? Icons.face_unlock_outlined
          : Icons.fingerprint,
      title: 'biometric_login'.tr(),
      subtitle: (enabled ? 'biometric_enabled' : 'biometric_disabled').tr(),
      trailing: Switch.adaptive(
        value: enabled,
        activeColor: primary,
        onChanged: controller.biometricBusy.value
            ? null
            : (v) => _toggleBiometric(context, v),
      ),
      onTap: () => _toggleBiometric(context, !enabled),
    );
  }

  Future<void> _toggleBiometric(BuildContext context, bool enable) async {
    if (!enable) {
      await controller.setBiometric(false);
      return;
    }
    final status = await BiometricService.status();
    if (status != BiometricStatus.available) {
      appSnackbar(
        heading: 'biometric_unavailable'.tr(),
        message: (status == BiometricStatus.notEnrolled
                ? 'biometric_not_enrolled'
                : 'biometric_not_supported')
            .tr(),
        snackbarState: SnackbarState.warning,
      );
      return;
    }
    if (!context.mounted) return;
    final password = await showBiometricPasswordSheet(context,
        verify: controller.verifyPassword);
    if (password == null) return;
    await controller.setBiometric(true, password: password);
  }

  // ------------------------------------------------------------- déconnexion

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (_) => LogoutDeleteBottomSheet(
        title: 'logout'.tr(),
        subTitle: 'are_you_sure_you_want_to_logout'.tr(),
      ),
    );
    if (confirmed == true) {
      controller.isLoading(true);
      await controller.onLogout();
    }
  }
}

/// Choix d'apparence : Système / Clair / Sombre. Le choix s'applique tout de
/// suite et est mémorisé ; « Système » suit le réglage de l'appareil.
class _ThemeSelector extends StatefulWidget {
  final VoidCallback onChanged;
  const _ThemeSelector({required this.onChanged});

  @override
  State<_ThemeSelector> createState() => _ThemeSelectorState();
}

class _ThemeSelectorState extends State<_ThemeSelector> {
  ThemeMode _mode = LocalStorage.getThemeMode();

  Future<void> _select(ThemeMode mode) async {
    if (mode == _mode) return;
    setState(() => _mode = mode);
    await LocalStorage.setThemeMode(mode);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final c = GbColors.of(context);
    final options = [
      (ThemeMode.system, LucideIcons.smartphone, 'theme_system'.tr()),
      (ThemeMode.light, LucideIcons.sun, 'theme_light'.tr()),
      (ThemeMode.dark, LucideIcons.moon, 'theme_dark'.tr()),
    ];
    final description = switch (_mode) {
      ThemeMode.system => 'theme_system_desc'.tr(),
      ThemeMode.light => 'theme_light_desc'.tr(),
      ThemeMode.dark => 'theme_dark_desc'.tr(),
    };
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: c.isDark ? Border.all(color: c.border) : null,
        boxShadow: c.shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var i = 0; i < options.length; i++) ...[
                if (i > 0) SizedBox(width: 10.w),
                Expanded(child: _option(c, options[i])),
              ],
            ],
          ),
          SizedBox(height: 12.h),
          Text(description,
              style: TextStyle(fontSize: 12.sp, color: c.subtext)),
        ],
      ),
    );
  }

  Widget _option(GbColors c, (ThemeMode, IconData, String) option) {
    final primary = AppTheme.theme.colorScheme.primary;
    final selected = option.$1 == _mode;
    return GestureDetector(
      onTap: () => _select(option.$1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 14.h),
        decoration: BoxDecoration(
          color: selected ? primary.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: selected ? primary : c.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(option.$2, size: 22.sp, color: selected ? primary : c.subtext),
            SizedBox(height: 6.h),
            Text(
              option.$3,
              style: TextStyle(
                fontSize: 12.5.sp,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? primary : c.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
