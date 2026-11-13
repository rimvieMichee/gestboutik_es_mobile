import 'package:foodly/helpers/extensions/string.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart' hide Trans;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:foodly/controller/apps/sales/new_sale_controller.dart';
import 'package:foodly/helpers/theme/app_theme.dart';
import 'package:foodly/views/apps/sales/sale_confirmation_screen.dart';
import 'package:foodly/widgets/gesboutik/gb_colors.dart';
import 'package:foodly/widgets/gesboutik/gb_format.dart';

/// Détail de la vente : produits choisis (quantités modifiables), total, option
/// « vente à crédit » avec le nom de l'emprunteur, et bouton d'enregistrement.
class CartBottomSheet extends StatefulWidget {
  final NewSaleController controller;

  const CartBottomSheet({super.key, required this.controller});

  @override
  State<CartBottomSheet> createState() => _CartBottomSheetState();
}

class _CartBottomSheetState extends State<CartBottomSheet> {
  final TextEditingController _clientName = TextEditingController();
  bool _credit = false;
  String? _nameError;

  NewSaleController get controller => widget.controller;

  @override
  void dispose() {
    _clientName.dispose();
    super.dispose();
  }

  /// Vente enregistrée : le panier se vide, mais la feuille n'a plus à se
  /// refermer d'elle-même (elle fermerait l'écran de confirmation au-dessus).
  bool _submitted = false;

  Future<void> _validate() async {
    final name = _clientName.text.trim();
    if (_credit && name.isEmpty) {
      setState(() => _nameError = 'enter_borrower'.tr());
      return;
    }

    _submitted = true;
    final sale = await controller.submitSale(
      estCredit: _credit,
      clientNom: _credit ? name : null,
    );
    if (sale == null) {
      _submitted =
          false; // échec : le panier est intact, on reste sur la feuille
      return;
    }
    if (!mounted) return;

    Navigator.of(context).pop(); // ferme le bottom sheet
    // Get.to (et non Get.off) : l'onglet Vente reste en dessous de la confirmation.
    Get.to(() => SaleConfirmationScreen(sale: sale));
  }

  Widget _stepper(CartLine line) {
    final primary = AppTheme.theme.colorScheme.primary;
    Widget btn(IconData icon, VoidCallback onTap) => InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 26.w,
            height: 26.w,
            decoration: BoxDecoration(
              color: primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 15.sp, color: primary),
          ),
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        btn(LucideIcons.minus,
            () => controller.decrementFromCart(line.product)),
        SizedBox(
          width: 24.w,
          child: Text('${line.quantite}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w800)),
        ),
        btn(LucideIcons.plus, () => controller.addToCart(line.product)),
      ],
    );
  }

  Widget _creditSection() {
    final c = context.gb;
    const color = Colors.orange;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: _credit ? color.withOpacity(0.10) : c.fill,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: _credit ? color.withOpacity(0.45) : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.creditCard,
                  size: 20.sp, color: _credit ? color : c.subtext),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('credit_sale'.tr(),
                        style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: c.text)),
                    Text(
                      _credit ? 'pays_later'.tr() : 'pays_now'.tr(),
                      style: TextStyle(fontSize: 11.5.sp, color: c.subtext),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _credit,
                activeColor: color,
                onChanged: (value) => setState(() {
                  _credit = value;
                  _nameError = null;
                }),
              ),
            ],
          ),
          if (_credit) ...[
            SizedBox(height: 10.h),
            TextField(
              controller: _clientName,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
              decoration: InputDecoration(
                labelText: 'borrower_name_required'.tr(),
                errorText: _nameError,
                prefixIcon: Icon(LucideIcons.user, size: 19.sp),
                filled: true,
                fillColor: c.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: const BorderSide(color: color, width: 1.6),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.gb;
    return Padding(
      padding: EdgeInsets.only(
        left: 16.w,
        right: 16.w,
        top: 12.h,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16.h,
      ),
      child: Obx(() {
        if (controller.cartLines.isEmpty && !_submitted) {
          // Panier vidé depuis la feuille : on la referme.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.of(context).maybePop();
          });
        }
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: c.skeleton,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Text('sale_detail'.tr(),
                  style:
                      TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 12.h),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 260.h),
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
                                  style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600)),
                              SizedBox(height: 2.h),
                              Text(
                                'price_each'.trp({
                                  'price': formatFcfa(line.product.prixVente)
                                }),
                                style: TextStyle(
                                    fontSize: 12.sp, color: c.subtext),
                              ),
                            ],
                          ),
                        ),
                        _stepper(line),
                        SizedBox(width: 10.w),
                        SizedBox(
                          width: 78.w,
                          child: Text(formatFcfa(line.sousTotal),
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.bold)),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(20.r),
                          onTap: () =>
                              controller.removeFromCart(line.product.id),
                          child: Padding(
                            padding: EdgeInsets.all(6.w),
                            child: Icon(LucideIcons.trash2,
                                size: 17.sp, color: Colors.red[400]),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Divider(height: 24.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('total'.tr(),
                      style: TextStyle(
                          fontSize: 16.sp, fontWeight: FontWeight.bold)),
                  Text(
                    formatFcfa(controller.totalAmount),
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              _creditSection(),
              SizedBox(height: 16.h),
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: FilledButton(
                  onPressed: controller.isSubmitting.value ||
                          controller.cartLines.isEmpty
                      ? null
                      : _validate,
                  child: controller.isSubmitting.value
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          _credit ? 'save_credit_sale'.tr() : 'save_sale'.tr(),
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15.sp),
                        ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
