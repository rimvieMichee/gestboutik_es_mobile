import 'package:flutter/material.dart';
import 'package:foodly/widgets/gesboutik/gb_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:foodly/helpers/theme/app_theme.dart';

/// Champ de recherche commun (listes de produits, employés, vente).
class GbSearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;

  const GbSearchField({super.key, required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.theme.colorScheme.primary;
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: c, width: w),
        );
    return TextField(
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: TextStyle(fontSize: 14.sp, color: context.gb.text),
      cursorColor: primary,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13.sp, color: context.gb.subtext),
        prefixIcon:
            Icon(LucideIcons.search, color: context.gb.subtext, size: 20.sp),
        filled: true,
        fillColor: context.gb.surface,
        contentPadding: EdgeInsets.symmetric(vertical: 13.h),
        border: border(context.gb.border),
        enabledBorder: border(context.gb.border),
        focusedBorder: border(primary, 1.5),
      ),
    );
  }
}
