import 'package:foodly/helpers/extensions/string.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart' hide Trans;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:foodly/controller/apps/products/archived_products_controller.dart';
import 'package:foodly/controller/apps/products/products_controller.dart';
import 'package:foodly/helpers/theme/app_theme.dart';
import 'package:foodly/models/product_model.dart';
import 'package:foodly/widgets/gesboutik/gb_app_bar.dart';
import 'package:foodly/widgets/gesboutik/gb_colors.dart';
import 'package:foodly/widgets/gesboutik/gb_empty_state.dart';
import 'package:foodly/widgets/gesboutik/gb_format.dart';
import 'package:foodly/widgets/gesboutik/gb_skeleton.dart';
import 'package:foodly/widgets/gesboutik/gb_staggered_item.dart';

class ArchivedProductsScreen extends StatelessWidget {
  const ArchivedProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ArchivedProductsController());

    return Scaffold(
      backgroundColor: context.gb.background,
      appBar: gbAppBar(title: 'archived_products'.tr()),
      body: Obx(() {
        if (controller.isLoading.value) return GbSkeleton.archivedList();
        if (controller.products.isEmpty) {
          return GbEmptyState(
            icon: LucideIcons.archive,
            title: 'no_archived'.tr(),
            subtitle: 'archived_empty_hint'.tr(),
          );
        }
        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
            itemCount: controller.products.length,
            separatorBuilder: (_, __) => SizedBox(height: 10.h),
            itemBuilder: (context, index) {
              final product = controller.products[index];
              return GbStaggeredItem(
                index: index,
                child: _ArchivedTile(
                  product: product,
                  onRestore: () async {
                    await controller.restore(product);
                    // La liste principale doit réafficher le produit.
                    if (Get.isRegistered<ProductsController>()) {
                      Get.find<ProductsController>().loadProducts(silent: true);
                    }
                  },
                ),
              );
            },
          ),
        );
      }),
    );
  }
}

class _ArchivedTile extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onRestore;

  const _ArchivedTile({required this.product, required this.onRestore});

  @override
  Widget build(BuildContext context) {
    final c = context.gb;
    final primary = AppTheme.theme.colorScheme.primary;
    final placeholder = Container(
      width: 56.w,
      height: 56.w,
      color: primary.withOpacity(0.08),
      alignment: Alignment.center,
      child: Icon(LucideIcons.package,
          size: 22.sp, color: primary.withOpacity(0.45)),
    );

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: c.isDark ? Border.all(color: c.border) : null,
        boxShadow: c.shadow,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: ColorFiltered(
              colorFilter:
                  const ColorFilter.mode(Colors.grey, BlendMode.saturation),
              child: (product.image ?? '').isEmpty
                  ? placeholder
                  : CachedNetworkImage(
                      imageUrl: product.image!,
                      width: 56.w,
                      height: 56.w,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => placeholder,
                    ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.nom,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 14.sp, fontWeight: FontWeight.w600)),
                SizedBox(height: 3.h),
                Text(formatFcfa(product.prixVente),
                    style: TextStyle(fontSize: 12.5.sp, color: c.subtext)),
                Text(
                  product.enRupture
                      ? 'out_of_stock'.tr()
                      : 'n_in_stock'
                          .trp({'n': '${product.quantiteDisponible}'}),
                  style: TextStyle(
                      fontSize: 11.5.sp,
                      color: product.enRupture ? Colors.red : c.subtext),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: onRestore,
            child: Text('restore'.tr()),
            style: OutlinedButton.styleFrom(
              foregroundColor: primary,
              side: BorderSide(color: primary.withOpacity(0.5)),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r)),
            ),
          ),
        ],
      ),
    );
  }
}
