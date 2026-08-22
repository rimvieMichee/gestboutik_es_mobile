import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:foodly/controller/apps/sales/new_sale_controller.dart';
import 'package:foodly/helpers/theme/app_theme.dart';
import 'package:foodly/models/product_model.dart';
import 'package:foodly/views/apps/sales/widget/cart_bottom_sheet.dart';
import 'package:foodly/widgets/gesboutik/gb_empty_state.dart';
import 'package:foodly/widgets/gesboutik/gb_shimmer_tile.dart';
import 'package:foodly/widgets/gesboutik/gb_staggered_item.dart';

class NewSaleScreen extends StatefulWidget {
  const NewSaleScreen({super.key});

  @override
  State<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends State<NewSaleScreen> {
  late final String _tag;
  late final NewSaleController controller;

  @override
  void initState() {
    super.initState();
    // Toujours une session de vente fraîche à l'ouverture de l'écran.
    _tag = 'new-sale-${DateTime.now().microsecondsSinceEpoch}';
    controller = Get.put(NewSaleController(), tag: _tag);
  }

  @override
  void dispose() {
    Get.delete<NewSaleController>(tag: _tag);
    super.dispose();
  }

  void _openCart() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) => CartBottomSheet(controller: controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Nouvelle vente'),
        backgroundColor: AppTheme.theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                onChanged: controller.onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Rechercher un produit à vendre...',
                  hintStyle: TextStyle(fontSize: 13.sp, color: Colors.grey[400]),
                  prefixIcon: Icon(LucideIcons.search, color: Colors.grey[500]),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 4.w),
                ),
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoadingProducts.value) {
                return const GbShimmerList();
              }
              if (controller.products.isEmpty) {
                return GbEmptyState(
                  icon: LucideIcons.packageSearch,
                  title: 'Aucun produit trouvé',
                  subtitle: 'Essayez une autre recherche.',
                );
              }
              return ListView.separated(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 100.h),
                itemCount: controller.products.length,
                separatorBuilder: (_, __) => SizedBox(height: 10.h),
                itemBuilder: (context, index) {
                  final product = controller.products[index];
                  return GbStaggeredItem(
                    index: index,
                    child: Obx(() => _SelectableProductTile(
                          product: product,
                          quantity: controller.quantityOf(product.id),
                          onAdd: () => controller.addToCart(product),
                          onRemove: () => controller.decrementFromCart(product),
                        )),
                  );
                },
              );
            }),
          ),
        ],
      ),
      bottomNavigationBar: Obx(() {
        return AnimatedSlide(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          offset: controller.totalItems == 0 ? const Offset(0, 1.2) : Offset.zero,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 220),
            opacity: controller.totalItems == 0 ? 0 : 1,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: ElevatedButton(
                  onPressed: controller.totalItems == 0 ? null : _openCart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.theme.colorScheme.primary,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    elevation: 4,
                    shadowColor: AppTheme.theme.colorScheme.primary.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(4.w),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(LucideIcons.shoppingCart, color: Colors.white, size: 16.sp),
                          ),
                          SizedBox(width: 10.w),
                          Text(
                            '${controller.totalItems} article${controller.totalItems > 1 ? 's' : ''} · ${controller.totalAmount.toInt()} FCFA',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5.sp,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Voir le panier',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _SelectableProductTile extends StatelessWidget {
  final ProductModel product;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _SelectableProductTile({
    required this.product,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = product.enRupture && quantity == 0;

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.nom,
                  style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${product.prixVente.toInt()} FCFA · ${product.quantiteDisponible} en stock',
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          if (disabled)
            Text(
              'Rupture',
              style: TextStyle(color: Colors.red, fontSize: 12.sp, fontWeight: FontWeight.bold),
            )
          else if (quantity == 0)
            _RoundIconButton(icon: LucideIcons.plus, onTap: onAdd, filled: true)
          else
            Row(
              children: [
                _RoundIconButton(icon: LucideIcons.minus, onTap: onRemove, filled: false),
                SizedBox(width: 10.w),
                Text('$quantity', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold)),
                SizedBox(width: 10.w),
                _RoundIconButton(icon: LucideIcons.plus, onTap: onAdd, filled: true),
              ],
            ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  const _RoundIconButton({required this.icon, required this.onTap, required this.filled});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.theme.colorScheme.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.all(6.w),
        decoration: BoxDecoration(
          color: filled ? color : color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16.sp, color: filled ? Colors.white : color),
      ),
    );
  }
}
