import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:foodly/helpers/theme/app_theme.dart';
import 'package:foodly/widgets/gesboutik/gb_colors.dart';

/// AppBar commune à tous les écrans : fond blanc, titre aligné à gauche,
/// fine ligne de séparation, bouton retour discret. Simple et sans dégradé.
PreferredSizeWidget gbAppBar({
  required String title,
  String? subtitle,
  bool showBack = true,
  List<Widget>? actions,
}) {
  return _GbAppBar(
      title: title, subtitle: subtitle, showBack: showBack, actions: actions);
}

class _GbAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final bool showBack;
  final List<Widget>? actions;

  const _GbAppBar({
    required this.title,
    required this.subtitle,
    required this.showBack,
    required this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.theme.colorScheme.primary;
    final c = GbColors.of(context);
    return AppBar(
      toolbarHeight: 64,
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      systemOverlayStyle:
          c.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      automaticallyImplyLeading: false,
      titleSpacing: showBack ? 4 : 20.w,
      leading: showBack
          ? Padding(
              padding: EdgeInsets.only(left: 12.w),
              child: Center(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12.r),
                  onTap: () => Navigator.of(context).maybePop(),
                  child: Container(
                    width: 38.w,
                    height: 38.w,
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(LucideIcons.chevronLeft,
                        size: 22.sp, color: primary),
                  ),
                ),
              ),
            )
          : null,
      leadingWidth: showBack ? 58.w : 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: c.text,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.sp, color: c.subtext),
            ),
        ],
      ),
      actions: [...?actions, SizedBox(width: 12.w)],
      shape: Border(bottom: BorderSide(color: c.border)),
    );
  }
}
