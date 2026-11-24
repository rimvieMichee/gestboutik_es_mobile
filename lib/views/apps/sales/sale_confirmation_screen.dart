import 'package:foodly/helpers/extensions/string.dart';
import 'package:flutter/material.dart';
import 'package:foodly/widgets/gesboutik/gb_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart' hide Trans;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:foodly/helpers/theme/app_theme.dart';
import 'package:foodly/models/sale_model.dart';
import 'package:foodly/controller/apps/dashboard/dashboard_controller.dart';
import 'package:foodly/controller/apps/sales/new_sale_controller.dart';
import 'package:foodly/controller/layouts/main_shell_controller.dart';

class SaleConfirmationScreen extends StatefulWidget {
  final SaleModel sale;

  const SaleConfirmationScreen({super.key, required this.sale});

  @override
  State<SaleConfirmationScreen> createState() => _SaleConfirmationScreenState();
}

class _SaleConfirmationScreenState extends State<SaleConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _checkScale;
  late final Animation<double> _contentFade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _checkScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.65, curve: Curves.elasticOut),
    );
    _contentFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _backToShell({required int tab}) {
    Navigator.of(context).pop();
    if (Get.isRegistered<MainShellController>()) {
      Get.find<MainShellController>().changeTab(tab);
    }
    if (Get.isRegistered<NewSaleController>()) {
      Get.find<NewSaleController>().loadProducts();
    }
    if (Get.isRegistered<DashboardController>()) {
      Get.find<DashboardController>().loadDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sale = widget.sale;
    return Scaffold(
      backgroundColor: context.gb.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            children: [
              SizedBox(height: 32.h),
              ScaleTransition(
                scale: _checkScale,
                child: Container(
                  width: 96.w,
                  height: 96.w,
                  decoration: const BoxDecoration(
                      color: Color(0xFFDCFCE7), shape: BoxShape.circle),
                  child: Icon(LucideIcons.check,
                      color: const Color(0xFF16A34A), size: 48.sp),
                ),
              ),
              SizedBox(height: 24.h),
              FadeTransition(
                opacity: _contentFade,
                child: Column(
                  children: [
                    Text(
                      'sale_saved'.tr(),
                      style: TextStyle(
                          fontSize: 22.sp, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      sale.numeroVente,
                      style:
                          TextStyle(fontSize: 15.sp, color: context.gb.subtext),
                    ),
                    if (sale.isCredit) ...[
                      SizedBox(height: 10.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(
                          'credit_borrower'
                              .trp({'name': sale.clientNom ?? '—'}),
                          style: TextStyle(
                              fontSize: 12.5.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.orange),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 24.h),
              FadeTransition(
                opacity: _contentFade,
                child: SlideTransition(
                  position: Tween<Offset>(
                          begin: const Offset(0, 0.08), end: Offset.zero)
                      .animate(_contentFade),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: context.gb.fill,
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: context.gb.skeleton),
                    ),
                    child: Column(
                      children: [
                        ...sale.items.map(
                          (item) => Padding(
                            padding: EdgeInsets.symmetric(vertical: 4.h),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item.quantite} × ${item.product.nom}',
                                    style: TextStyle(fontSize: 13.sp),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text('${item.sousTotal.toInt()} FCFA',
                                    style: TextStyle(fontSize: 13.sp)),
                              ],
                            ),
                          ),
                        ),
                        Divider(height: 20.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('total'.tr(),
                                style: TextStyle(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.bold)),
                            Text(
                              '${sale.montantTotal.toInt()} FCFA',
                              style: TextStyle(
                                fontSize: 17.sp,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Spacer(),
              FadeTransition(
                opacity: _contentFade,
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 52.h,
                      child: ElevatedButton(
                        onPressed: () =>
                            _backToShell(tab: MainShellController.saleTab),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.theme.colorScheme.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r)),
                        ),
                        child: Text(
                          'new_sale'.tr(),
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15.sp),
                        ),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    SizedBox(
                      width: double.infinity,
                      height: 52.h,
                      child: OutlinedButton(
                        onPressed: () => _backToShell(tab: 0),
                        child: Text('back_home'.tr(),
                            style: TextStyle(fontSize: 15.sp)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
