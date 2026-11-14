import 'package:foodly/widgets/gesboutik/gb_sheets.dart';
import 'package:foodly/helpers/extensions/string.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart' hide Trans;
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:foodly/controller/apps/dashboard/dashboard_controller.dart';
import 'package:foodly/controller/apps/sales/sales_history_controller.dart';
import 'package:foodly/helpers/services/error_handling.dart';
import 'package:foodly/helpers/services/sale_service.dart';
import 'package:foodly/helpers/storage/local_storage.dart';
import 'package:foodly/helpers/theme/app_theme.dart';
import 'package:foodly/helpers/utils/app_snackbar.dart';
import 'package:foodly/models/sale_model.dart';
import 'package:foodly/widgets/gesboutik/gb_app_bar.dart';
import 'package:foodly/widgets/gesboutik/gb_colors.dart';
import 'package:foodly/widgets/gesboutik/gb_format.dart';

class SaleDetailScreen extends StatefulWidget {
  final SaleModel sale;

  const SaleDetailScreen({super.key, required this.sale});

  @override
  State<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends State<SaleDetailScreen> {
  late SaleModel _sale = widget.sale;
  bool _settling = false;

  Future<void> _settle() async {
    final confirmed = await showGbConfirmSheet(
      context,
      title: 'credit_settled_q'.tr(),
      message: 'settle_confirm_body'.trp({
        'name': _sale.clientNom ?? 'the_customer'.tr(),
        'amount': formatFcfa(_sale.montantTotal),
        'num': _sale.numeroVente,
      }),
      confirmLabel: 'yes_mark_paid'.tr(),
      icon: LucideIcons.checkCircle,
    );
    if (confirmed != true) return;

    setState(() => _settling = true);
    try {
      final updated = await SaleService.settleCredit(_sale.id);
      if (!mounted) return;
      setState(() => _sale = updated);
      appSnackbar(
        heading: 'credit_settled'.tr(),
        message: 'settled_snack'.trp({
          'name': updated.clientNom ?? 'the_customer'.tr(),
          'num': updated.numeroVente,
        }),
        snackbarState: SnackbarState.success,
      );
      // Rafraîchit les écrans qui affichent ce crédit.
      if (Get.isRegistered<SalesHistoryController>()) {
        Get.find<SalesHistoryController>().loadSales();
      }
      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().loadDashboard();
      }
    } on DioException catch (e) {
      letMeHandleAllErrors(e);
    } finally {
      if (mounted) setState(() => _settling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final primary = AppTheme.theme.colorScheme.primary;
    final sale = _sale;

    return Scaffold(
      backgroundColor: context.gb.background,
      appBar: gbAppBar(title: sale.numeroVente),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(
                  offset: Offset(0, (1 - value) * 12), child: child),
            ),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(18.w),
              decoration: BoxDecoration(
                color: context.gb.surface,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: context.gb.shadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44.w,
                        height: 44.w,
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(LucideIcons.receipt,
                            color: primary, size: 20.sp),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(sale.numeroVente,
                                style: TextStyle(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.bold)),
                            SizedBox(height: 2.h),
                            Text(
                              dateFormat
                                  .format(DateTime.parse(sale.date).toLocal()),
                              style: TextStyle(
                                  fontSize: 12.5.sp, color: context.gb.subtext),
                            ),
                            if (sale.vendeur != null) ...[
                              SizedBox(height: 2.h),
                              Text(
                                'sold_by'.trp({'name': sale.vendeur ?? ''}),
                                style: TextStyle(
                                    fontSize: 12.5.sp,
                                    color: context.gb.subtext),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 18.h),
                  ...sale.items.map(
                    (item) => Padding(
                      padding: EdgeInsets.symmetric(vertical: 6.h),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 7.w, vertical: 3.h),
                            decoration: BoxDecoration(
                              color: context.gb.fill,
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text('${item.quantite}×',
                                style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w700,
                                    color: context.gb.subtext)),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.product.nom,
                                    style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w600)),
                                Text(
                                  'per_unit_price'.trp(
                                      {'n': '${item.prixUnitaire.toInt()}'}),
                                  style: TextStyle(
                                      fontSize: 11.5.sp,
                                      color: context.gb.subtext),
                                ),
                              ],
                            ),
                          ),
                          Text('${item.sousTotal.toInt()} FCFA',
                              style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    child: CustomPaint(
                      size: const Size(double.infinity, 1),
                      painter: _DashedLinePainter(color: context.gb.skeleton),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('total'.tr(),
                          style: TextStyle(
                              fontSize: 16.sp, fontWeight: FontWeight.bold)),
                      Text(
                        '${sale.montantTotal.toInt()} FCFA',
                        style: TextStyle(
                          fontSize: 19.sp,
                          fontWeight: FontWeight.bold,
                          color: primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (sale.isCredit) ...[
            SizedBox(height: 14.h),
            _creditCard(sale),
          ],
        ],
      ),
    );
  }

  Widget _creditCard(SaleModel sale) {
    final settled = sale.creditRegleAt != null;
    final color = settled ? Colors.green : Colors.orange;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.creditCard, size: 20.sp, color: color),
              SizedBox(width: 10.w),
              Text('credit_sale'.tr(),
                  style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: context.gb.text)),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  settled ? 'settled'.tr() : 'unsettled'.tr(),
                  style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Text('borrower'.tr(),
              style: TextStyle(fontSize: 12.sp, color: context.gb.subtext)),
          SizedBox(height: 2.h),
          Text(sale.clientNom ?? '—',
              style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w800,
                  color: context.gb.text)),
          SizedBox(height: 10.h),
          Text(
            settled
                ? 'paid_on'.trp({
                    'date': DateFormat('dd/MM/yyyy HH:mm')
                        .format(sale.creditRegleAt!)
                  })
                : 'remaining_to_pay'
                    .trp({'amount': formatFcfa(sale.montantTotal)}),
            style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: context.gb.text),
          ),
          if (!settled) ...[
            SizedBox(height: 14.h),
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: FilledButton.icon(
                onPressed: _settling ? null : _settle,
                icon: _settling
                    ? SizedBox(
                        width: 18.w,
                        height: 18.w,
                        child: const CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(LucideIcons.checkCircle2),
                label: Text(_settling ? 'saving'.tr() : 'mark_paid'.tr()),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const dashWidth = 5.0;
    const dashSpace = 4.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
