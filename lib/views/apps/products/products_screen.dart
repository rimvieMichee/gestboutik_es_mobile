import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:foodly/controller/apps/products/products_controller.dart';
import 'package:foodly/helpers/theme/app_theme.dart';
import 'package:foodly/models/product_model.dart';
import 'package:foodly/widgets/gesboutik/gb_empty_state.dart';
import 'package:foodly/widgets/gesboutik/gb_shimmer_tile.dart';
import 'package:foodly/widgets/gesboutik/gb_staggered_item.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProductsController());

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Produits'),
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
                  hintText: 'Rechercher un produit ou une référence...',
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
              if (controller.isLoading.value) {
                return const GbShimmerList();
              }
              if (controller.products.isEmpty) {
                return GbEmptyState(
                  icon: LucideIcons.packageSearch,
                  title: 'Aucun produit trouvé',
                  subtitle: controller.search.value.isNotEmpty
                      ? 'Essayez une autre recherche.'
                      : 'Le catalogue de la boutique est vide pour le moment.',
                );
              }
              return RefreshIndicator(
                onRefresh: controller.loadProducts,
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                  itemCount: controller.products.length,
                  separatorBuilder: (_, __) => SizedBox(height: 10.h),
                  itemBuilder: (context, index) => GbStaggeredItem(
                    index: index,
                    child: _ProductTile(product: controller.products[index]),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final ProductModel product;

  const _ProductTile({required this.product});

  @override
  Widget build(BuildContext context) {
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
                if (product.sku != null && product.sku!.isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  Text(
                    product.sku!,
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                  ),
                ],
                SizedBox(height: 6.h),
                Text(
                  '${product.prixVente.toInt()} FCFA',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${product.quantiteDisponible} en stock',
                style: TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
              ),
              if (product.enRupture)
                _badge('Rupture', Colors.red)
              else if (product.stockBas)
                _badge('Stock bas', Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      margin: EdgeInsets.only(top: 4.h),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}
