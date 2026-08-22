import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:foodly/controller/apps/sales/new_sale_controller.dart';
import 'package:foodly/helpers/theme/app_theme.dart';
import 'package:foodly/views/apps/sales/sale_confirmation_screen.dart';

class CartBottomSheet extends StatelessWidget {
  final NewSaleController controller;

  const CartBottomSheet({super.key, required this.controller});

  Future<void> _validate(BuildContext context) async {
    final sale = await controller.submitSale();
    if (sale == null || !context.mounted) return;

    Navigator.of(context).pop(); // ferme le bottom sheet
    Get.off(() => SaleConfirmationScreen(sale: sale));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        top: 16.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16.h,
      ),
      child: Obx(
        () => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text('Récapitulatif de la vente',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 16.h),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 320.h),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: controller.cartLines.length,
                separatorBuilder: (_, __) => Divider(height: 20.h),
                itemBuilder: (context, index) {
                  final line = controller.cartLines[index];
                  return Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(line.product.nom,
                                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
                            SizedBox(height: 2.h),
                            Text(
                              '${line.quantite} × ${line.product.prixVente.toInt()} FCFA',
                              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      Text('${line.sousTotal.toInt()} FCFA',
                          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
                      SizedBox(width: 10.w),
                      InkWell(
                        borderRadius: BorderRadius.circular(20.r),
                        onTap: () => controller.removeFromCart(line.product.id),
                        child: Padding(
                          padding: EdgeInsets.all(6.w),
                          child: Icon(LucideIcons.trash2, size: 17.sp, color: Colors.red[400]),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            Divider(height: 28.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                Text(
                  '${controller.totalAmount.toInt()} FCFA',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              height: 52.h,
              child: ElevatedButton(
                onPressed: controller.isSubmitting.value || controller.cartLines.isEmpty
                    ? null
                    : () => _validate(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                child: controller.isSubmitting.value
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Valider la vente',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15.sp),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
