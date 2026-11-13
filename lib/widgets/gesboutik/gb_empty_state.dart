import 'package:flutter/material.dart';
import 'package:foodly/widgets/gesboutik/gb_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// État vide générique (liste sans résultat, historique vide, etc.), avec
/// une légère animation d'apparition pour éviter un contenu qui "saute".
class GbEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const GbEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 12),
          child: child,
        ),
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84.w,
                height: 84.w,
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 36.sp, color: primary.withOpacity(0.6)),
              ),
              SizedBox(height: 18.h),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: context.gb.text,
                ),
              ),
              if (subtitle != null) ...[
                SizedBox(height: 6.h),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13.sp, color: context.gb.subtext),
                ),
              ],
              if (action != null) ...[
                SizedBox(height: 20.h),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
