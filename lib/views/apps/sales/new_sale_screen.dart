import 'package:foodly/helpers/extensions/string.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart' hide Trans;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:foodly/controller/apps/sales/new_sale_controller.dart';
import 'package:foodly/helpers/theme/app_theme.dart';
import 'package:foodly/models/product_model.dart';
import 'package:foodly/views/apps/sales/widget/cart_bottom_sheet.dart';
import 'package:foodly/widgets/gesboutik/gb_app_bar.dart';
import 'package:foodly/widgets/gesboutik/gb_colors.dart';
import 'package:foodly/widgets/gesboutik/gb_empty_state.dart';
import 'package:foodly/widgets/gesboutik/gb_format.dart';
import 'package:foodly/widgets/gesboutik/gb_search_field.dart';
import 'package:foodly/widgets/gesboutik/gb_skeleton.dart';
import 'package:foodly/widgets/gesboutik/gb_staggered_item.dart';

class NewSaleScreen extends StatefulWidget {
  const NewSaleScreen({super.key});

  @override
  State<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends State<NewSaleScreen> {
  late final NewSaleController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(NewSaleController());
  }

  void _openCart() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26.r)),
      ),
      builder: (_) => CartBottomSheet(controller: controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.gb.background,
      appBar: gbAppBar(title: 'new_sale'.tr(), showBack: false),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 8.h),
                child: GbSearchField(
                  hint: 'search_product_to_sell'.tr(),
                  onChanged: controller.onSearchChanged,
                ),
              ),
              Expanded(
                child: Obx(() {
                  if (controller.isLoadingProducts.value) {
                    return GbSkeleton.productGrid();
                  }
                  if (controller.products.isEmpty) {
                    return GbEmptyState(
                      icon: LucideIcons.packageSearch,
                      title: 'no_product_found'.tr(),
                      subtitle: controller.search.value.isNotEmpty
                          ? 'try_other_search'.tr()
                          : 'manager_no_product'.tr(),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: controller.loadProducts,
                    child: GridView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        16.w,
                        6.h,
                        16.w,
                        // Laisse la place à la barre de panier et à la barre du bas.
                        controller.totalItems == 0 ? 120.h : 200.h,
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 14.h,
                        crossAxisSpacing: 14.w,
                        childAspectRatio: 0.72,
                      ),
                      itemCount: controller.products.length,
                      itemBuilder: (context, index) {
                        final product = controller.products[index];
                        return GbStaggeredItem(
                          index: index,
                          child: Obx(
                            () => _SaleProductCard(
                              product: product,
                              quantity: controller.quantityOf(product.id),
                              onAdd: () => controller.addToCart(product),
                              onRemove: () =>
                                  controller.decrementFromCart(product),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
          Positioned(
            left: 16.w,
            right: 16.w,
            bottom: 98.h,
            child: Obx(
              () => _CartBar(
                visible: controller.totalItems > 0,
                items: controller.totalItems,
                total: controller.totalAmount,
                onTap: _openCart,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Barre du panier : apparaît dès qu'un produit est choisi.
class _CartBar extends StatelessWidget {
  final bool visible;
  final int items;
  final double total;
  final VoidCallback onTap;

  const _CartBar({
    required this.visible,
    required this.items,
    required this.total,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.theme.colorScheme.primary;
    return AnimatedSlide(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      offset: visible ? Offset.zero : const Offset(0, 1.5),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: visible ? 1 : 0,
        child: IgnorePointer(
          ignoring: !visible,
          child: Material(
            color: primary,
            elevation: 6,
            shadowColor: primary.withOpacity(0.4),
            borderRadius: BorderRadius.circular(18.r),
            child: InkWell(
              borderRadius: BorderRadius.circular(18.r),
              onTap: onTap,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(9.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(LucideIcons.shoppingCart,
                          color: Colors.white, size: 18.sp),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (items > 1 ? 'n_items_other' : 'n_items_one')
                                .trp({'n': '$items'}),
                            style: TextStyle(
                                color: Colors.white70, fontSize: 12.sp),
                          ),
                          Text(
                            formatFcfa(total),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'see_detail'.tr(),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.sp,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Icon(LucideIcons.chevronUp,
                        color: Colors.white, size: 18.sp),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Carte produit de la vente : image, nom, prix, stock, et « + » (ou − quantité +).
class _SaleProductCard extends StatelessWidget {
  final ProductModel product;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _SaleProductCard({
    required this.product,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.gb;
    final primary = AppTheme.theme.colorScheme.primary;
    final soldOut = product.enRupture || product.statut != 'ACTIVE';
    final selected = quantity > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color:
              selected ? primary : (c.isDark ? c.border : Colors.transparent),
          width: selected ? 1.8 : 1,
        ),
        boxShadow: c.shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 6,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Opacity(opacity: soldOut ? 0.45 : 1, child: _image(primary)),
                if (soldOut)
                  Positioned(
                      top: 8.h,
                      left: 8.w,
                      child: _pill('out_of_stock_short'.tr(), Colors.red))
                else
                  Positioned(
                    left: 8.w,
                    bottom: 8.h,
                    child: _pill(
                      'n_in_stock'.trp({'n': '${product.quantiteDisponible}'}),
                      product.stockBas ? Colors.orange : Colors.black54,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: EdgeInsets.fromLTRB(12.w, 10.h, 10.w, 10.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    product.nom,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                      color: c.text,
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            formatFcfa(product.prixVente),
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w800,
                              color: primary,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 6.w),
                      if (!soldOut) _control(primary),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _control(Color primary) {
    if (quantity == 0) {
      return _RoundButton(icon: LucideIcons.plus, filled: true, onTap: onAdd);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RoundButton(icon: LucideIcons.minus, filled: false, onTap: onRemove),
        SizedBox(
          width: 22.w,
          child: Text(
            '$quantity',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.w800),
          ),
        ),
        _RoundButton(icon: LucideIcons.plus, filled: true, onTap: onAdd),
      ],
    );
  }

  Widget _image(Color primary) {
    final placeholder = Container(
      color: primary.withOpacity(0.08),
      alignment: Alignment.center,
      child: Icon(LucideIcons.package,
          size: 34.sp, color: primary.withOpacity(0.45)),
    );
    if (product.image == null || product.image!.isEmpty) return placeholder;
    return CachedNetworkImage(
      imageUrl: product.image!,
      fit: BoxFit.cover,
      placeholder: (_, __) => placeholder,
      errorWidget: (_, __, ___) => placeholder,
    );
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 10.sp, fontWeight: FontWeight.w700, color: Colors.white),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  const _RoundButton(
      {required this.icon, required this.filled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.theme.colorScheme.primary;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 30.w,
        height: 30.w,
        decoration: BoxDecoration(
          color: filled ? color : color.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 17.sp, color: filled ? Colors.white : color),
      ),
    );
  }
}
