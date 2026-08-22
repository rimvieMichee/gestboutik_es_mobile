import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart' hide Trans;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:foodly/controller/apps/settings/settings_controller.dart';
import 'package:foodly/helpers/extensions/string.dart';
import 'package:foodly/helpers/storage/local_storage.dart';
import 'package:foodly/helpers/theme/app_notifier.dart';
import 'package:foodly/helpers/theme/app_theme.dart';
import 'package:foodly/views/apps/settings/widget/logout_bottom_sheet.dart';
import 'package:foodly/widgets/gesboutik/gb_staggered_item.dart';

class SettingScreen extends StatelessWidget {
  SettingScreen({super.key});

  final controller = Get.put(SettingsController());

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.theme.colorScheme.primary;
    final userName = LocalStorage.getUserName() ?? 'Employé';
    final boutiqueName = LocalStorage.getBoutiqueName() ?? '';
    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : '?';

    return Consumer<AppNotifier>(
      builder: (_, __, ___) => Scaffold(
        backgroundColor: Colors.grey[50],
        body: Obx(() => controller.isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 110.h),
                  children: [
                    Text(
                      'Réglages',
                      style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 18.h),
                    GbStaggeredItem(
                      index: 0,
                      child: Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14.r),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48.w,
                              height: 48.w,
                              decoration: BoxDecoration(color: primary.withOpacity(0.1), shape: BoxShape.circle),
                              alignment: Alignment.center,
                              child: Text(initial,
                                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: primary)),
                            ),
                            SizedBox(width: 14.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(userName, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700)),
                                  if (boutiqueName.isNotEmpty) ...[
                                    SizedBox(height: 2.h),
                                    Text(boutiqueName, style: TextStyle(fontSize: 12.5.sp, color: Colors.grey[600])),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),
                    _sectionLabel('Préférences'),
                    SizedBox(height: 10.h),
                    _card([
                      _buildLanguageTile(context),
                      _divider(),
                      _buildDarkModeTile(context),
                    ]),
                    SizedBox(height: 24.h),
                    _sectionLabel('Session'),
                    SizedBox(height: 10.h),
                    _card([
                      _buildLogoutTile(context),
                    ]),
                  ],
                ),
              )),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, color: Colors.grey[500], letterSpacing: 0.5),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _divider() => Divider(height: 1, indent: 56, endIndent: 16, color: Colors.grey[100]);

  Widget _tile({
    required IconData icon,
    required Color iconColor,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(9.r)),
              child: Icon(icon, size: 18.sp, color: iconColor),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Text(title, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
            ),
            trailing ?? Icon(Icons.arrow_forward_ios, size: 15.sp, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageTile(BuildContext context) {
    return _tile(
      icon: LucideIcons.globe,
      iconColor: AppTheme.theme.colorScheme.primary,
      title: 'language'.tr(),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            LocalStorage.getLanguage() == "en"
                ? "english".tr()
                : LocalStorage.getLanguage() == "fr"
                    ? "french".tr()
                    : LocalStorage.getLanguage() == "mos"
                        ? "moore".tr()
                        : "dioula".tr(),
            style: TextStyle(fontSize: 12.5.sp, color: Colors.grey[600]),
          ),
          SizedBox(width: 6.w),
          Icon(Icons.arrow_forward_ios, size: 15.sp, color: Colors.grey[400]),
        ],
      ),
      onTap: () => Get.offNamed('/selectLanguageScreen'),
    );
  }

  Widget _buildDarkModeTile(BuildContext context) {
    return _tile(
      icon: LucideIcons.moon,
      iconColor: Colors.indigo,
      title: 'dark_mode'.tr(),
      trailing: Transform.scale(
        scale: 0.85,
        child: CupertinoSwitch(
          onChanged: (value) async {
            await LocalStorage.setTheme(value ? "Dark" : "Light");
            Provider.of<AppNotifier>(context, listen: false).changeTheme();
          },
          value: LocalStorage.getTheme() == "Dark",
          activeColor: AppTheme.theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildLogoutTile(BuildContext context) {
    return _tile(
      icon: LucideIcons.logOut,
      iconColor: Colors.red,
      title: 'logout'.tr(),
      trailing: const SizedBox.shrink(),
      onTap: () async {
        final confirmed = await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
          builder: (_) => LogoutDeleteBottomSheet(
            title: 'logout'.tr(),
            subTitle: 'are_you_sure_you_want_to_logout'.tr(),
          ),
        );

        if (confirmed == true) {
          controller.isLoading(true);
          await controller.onLogout();
        }
      },
    );
  }
}
