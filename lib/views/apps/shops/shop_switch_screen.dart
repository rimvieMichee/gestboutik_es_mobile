import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart' hide Trans;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:foodly/helpers/extensions/string.dart';
import 'package:foodly/helpers/services/auth_services.dart';
import 'package:foodly/helpers/services/error_handling.dart';
import 'package:foodly/helpers/theme/app_theme.dart';
import 'package:foodly/helpers/utils/app_snackbar.dart';
import 'package:foodly/models/shop_model.dart';
import 'package:foodly/widgets/gesboutik/gb_colors.dart';

class ShopSwitchScreen extends StatefulWidget {
  final ShopModel shop;
  const ShopSwitchScreen({super.key, required this.shop});

  @override
  State<ShopSwitchScreen> createState() => _ShopSwitchScreenState();
}

class _ShopSwitchScreenState extends State<ShopSwitchScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _switch());
  }

  Future<void> _switch() async {
    final started = DateTime.now();
    try {
      await AuthService.switchBoutique(widget.shop.id);
      final elapsed = DateTime.now().difference(started);
      if (elapsed < const Duration(milliseconds: 900)) {
        await Future<void>.delayed(const Duration(milliseconds: 900) - elapsed);
      }
      Get.offAllNamed('/dashboard', arguments: {'tab': 0});
      appSnackbar(
        message: 'shop_opened'.trp({'name': widget.shop.nom}),
        snackbarState: SnackbarState.success,
      );
    } on DioException catch (e) {
      letMeHandleAllErrors(e);
      if (AuthService.isLoggedIn) {
        Get.offAllNamed('/dashboard', arguments: {'tab': 0});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.gb;
    final primary = AppTheme.theme.colorScheme.primary;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: c.background,
        body: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 36.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.8, end: 1),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutBack,
                  builder: (_, v, child) =>
                      Transform.scale(scale: v, child: child),
                  child: Container(
                    width: 92.w,
                    height: 92.w,
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(LucideIcons.store, size: 42.sp, color: primary),
                  ),
                ),
                SizedBox(height: 26.h),
                Text(
                  'shop_opening'.trp({'name': widget.shop.nom}),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 19.sp,
                      fontWeight: FontWeight.bold,
                      color: c.text),
                ),
                if ((widget.shop.ville ?? '').isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Text(widget.shop.ville!,
                      style: TextStyle(fontSize: 13.sp, color: c.subtext)),
                ],
                SizedBox(height: 26.h),
                SizedBox(
                  width: 160.w,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: LinearProgressIndicator(
                      minHeight: 5.h,
                      color: primary,
                      backgroundColor: primary.withOpacity(0.15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
