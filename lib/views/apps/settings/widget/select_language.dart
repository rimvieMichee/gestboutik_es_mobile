import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart' hide Trans;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:foodly/controller/apps/settings/settings_controller.dart';
import 'package:foodly/helpers/extensions/string.dart';
import 'package:foodly/helpers/localizations/language.dart';
import 'package:foodly/helpers/storage/local_storage.dart';
import 'package:foodly/helpers/theme/app_notifier.dart';
import 'package:foodly/helpers/theme/app_theme.dart';
import 'package:foodly/widgets/gesboutik/gb_app_bar.dart';
import 'package:foodly/widgets/gesboutik/gb_colors.dart';

/// Choix de la langue (Français / Mooré). S'ouvre par-dessus les Paramètres ;
/// le bouton retour (barre ou geste système) revient simplement à l'écran précédent.
class SelectLanguageScreen extends StatelessWidget {
  const SelectLanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SettingsController());
    final primary = AppTheme.theme.colorScheme.primary;

    return Consumer<AppNotifier>(
      builder: (context, notifier, _) {
        final c = context.gb;
        return Scaffold(
          backgroundColor: c.background,
          appBar: gbAppBar(title: 'language'.tr()),
          body: ListView(
            padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 24.h),
            children: [
              Obx(
                () => Container(
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(16.r),
                    border: c.isDark ? Border.all(color: c.border) : null,
                    boxShadow: c.shadow,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (var i = 0; i < Language.languages.length; i++) ...[
                        if (i > 0)
                          Divider(
                              height: 1,
                              indent: 16.w,
                              endIndent: 16.w,
                              color: c.border),
                        _LanguageTile(
                          name: Language.languages[i].languageName,
                          selected: controller.selectedLanguageIndex.value == i,
                          onTap: () async {
                            final language = Language.languages[i];
                            controller.selectedLanguageIndex.value = i;
                            await LocalStorage.setLanguage(language);
                            await notifier.changeLanguage(language);
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(height: 14.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(LucideIcons.info, size: 16.sp, color: primary),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'language_hint'.tr(),
                      style: TextStyle(
                          fontSize: 12.sp, color: c.subtext, height: 1.4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String name;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageTile(
      {required this.name, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.gb;
    final primary = AppTheme.theme.colorScheme.primary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? primary : c.text,
                ),
              ),
            ),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: selected ? 1 : 0,
              child:
                  Icon(LucideIcons.checkCircle2, size: 22.sp, color: primary),
            ),
          ],
        ),
      ),
    );
  }
}
