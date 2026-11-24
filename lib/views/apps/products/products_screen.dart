import 'package:foodly/helpers/storage/local_storage.dart';
import 'package:foodly/widgets/gesboutik/gb_sheets.dart';
import 'package:foodly/helpers/extensions/string.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:foodly/widgets/gesboutik/gb_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart' hide Trans;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:foodly/controller/apps/products/products_controller.dart';
import 'package:foodly/helpers/theme/app_theme.dart';
import 'package:foodly/models/product_model.dart';
import 'package:foodly/widgets/gesboutik/gb_dispose.dart';
import 'package:foodly/widgets/gesboutik/gb_empty_state.dart';
import 'package:foodly/widgets/gesboutik/gb_format.dart';
import 'package:foodly/widgets/gesboutik/gb_add_button.dart';
import 'package:foodly/widgets/gesboutik/gb_app_bar.dart';
import 'package:foodly/widgets/gesboutik/gb_search_field.dart';
import 'package:foodly/widgets/gesboutik/gb_skeleton.dart';
import 'package:foodly/widgets/gesboutik/gb_staggered_item.dart';

class ProductsScreen extends StatelessWidget {
  final bool embedded;
  const ProductsScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProductsController());

    return Scaffold(
      backgroundColor: context.gb.background,
      appBar: gbAppBar(
        title: 'products'.tr(),
        subtitle:
            LocalStorage.isMultiShop ? LocalStorage.getBoutiqueName() : null,
        showBack: !embedded,
      ),
      floatingActionButton: controller.isManager
          ? GbAddButton(
              tooltip: 'new_product'.tr(),
              aboveNavBar: embedded,
              onPressed: () => Get.toNamed('/product-form'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 0),
            child: GbSearchField(
              hint: 'search_product'.tr(),
              onChanged: controller.onSearchChanged,
            ),
          ),
          _FilterBar(controller: controller),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return GbSkeleton.productGrid();
              }
              final items = controller.filtered;
              if (items.isEmpty) {
                return GbEmptyState(
                  icon: LucideIcons.packageSearch,
                  title: 'no_product_found'.tr(),
                  subtitle: controller.search.value.isNotEmpty ||
                          controller.filter.value != 'all'
                      ? 'try_other_search_filter'.tr()
                      : controller.isManager
                          ? 'add_first_product'.tr()
                          : 'catalog_empty'.tr(),
                );
              }
              return RefreshIndicator(
                onRefresh: controller.loadProducts,
                child: GridView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                      16.w, 6.h, 16.w, controller.isManager ? 180.h : 24.h),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14.h,
                    crossAxisSpacing: 14.w,
                    childAspectRatio: 0.74,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) => GbStaggeredItem(
                    index: index,
                    child: _ProductCard(
                        product: items[index], controller: controller),
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

class _FilterBar extends StatelessWidget {
  final ProductsController controller;
  const _FilterBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final filters = {
      'all': 'all'.tr(),
      'low': 'low_stock'.tr(),
      'out': 'out_of_stock_short'.tr()
    };
    final primary = AppTheme.theme.colorScheme.primary;
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 6.h),
      child: Obx(
        () => Row(
          children: [
            ...filters.entries.map((e) {
              final selected = controller.filter.value == e.key;
              return Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: ChoiceChip(
                  label: Text(e.value),
                  selected: selected,
                  showCheckmark: false,
                  onSelected: (_) => controller.filter.value = e.key,
                  selectedColor: primary,
                  backgroundColor: context.gb.surface,
                  side:
                      BorderSide(color: selected ? primary : context.gb.border),
                  labelStyle: TextStyle(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : context.gb.subtext,
                  ),
                ),
              );
            }),
            const Spacer(),
            Text(
              (controller.filtered.length > 1
                      ? 'n_products_other'
                      : 'n_products_one')
                  .trp({'n': '${controller.filtered.length}'}),
              style: TextStyle(fontSize: 12.sp, color: context.gb.subtext),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final ProductsController controller;

  const _ProductCard({required this.product, required this.controller});

  Color get _stockColor {
    if (product.enRupture) return Colors.red;
    if (product.stockBas) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.theme.colorScheme.primary;
    final inactive = product.statut != 'ACTIVE';

    return Container(
      decoration: BoxDecoration(
        color: context.gb.surface,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: context.gb.shadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18.r),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: controller.isManager
              ? () => Get.toNamed('/product-form', arguments: product)
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColorFiltered(
                      colorFilter: inactive
                          ? const ColorFilter.mode(
                              Colors.grey, BlendMode.saturation)
                          : const ColorFilter.mode(
                              Colors.transparent, BlendMode.dst),
                      child: _image(primary),
                    ),
                    Positioned(top: 8.h, left: 8.w, child: _statusBadge()),
                    if (controller.isManager)
                      Positioned(top: 2.h, right: 2.w, child: _menu(context)),
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 10.h),
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
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formatFcfa(product.prixVente),
                            style: TextStyle(
                              fontSize: 14.5.sp,
                              fontWeight: FontWeight.w800,
                              color: primary,
                            ),
                          ),
                          SizedBox(height: 3.h),
                          Row(
                            children: [
                              Container(
                                width: 7.w,
                                height: 7.w,
                                decoration: BoxDecoration(
                                    color: _stockColor, shape: BoxShape.circle),
                              ),
                              SizedBox(width: 5.w),
                              Text(
                                product.enRupture
                                    ? 'out_of_stock'.tr()
                                    : 'n_in_stock'.trp(
                                        {'n': '${product.quantiteDisponible}'}),
                                style: TextStyle(
                                  fontSize: 11.5.sp,
                                  color: context.gb.subtext,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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

  Widget _statusBadge() {
    String? label;
    Color color = Colors.grey;
    if (product.statut != 'ACTIVE') {
      label = 'inactive'.tr();
    } else if (product.enRupture) {
      label = 'out_of_stock_short'.tr();
      color = Colors.red;
    } else if (product.stockBas) {
      label = 'low_stock'.tr();
      color = Colors.orange;
    }
    if (label == null) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(20.r)),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 10.sp, fontWeight: FontWeight.w700, color: Colors.white),
      ),
    );
  }

  Widget _menu(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        shape: BoxShape.circle,
      ),
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        iconSize: 18.sp,
        constraints: BoxConstraints(minWidth: 0, minHeight: 0),
        icon: Icon(LucideIcons.moreVertical, size: 18.sp),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
        onSelected: (v) {
          switch (v) {
            case 'edit':
              Get.toNamed('/product-form', arguments: product);
            case 'restock':
              _showStockSheet(context, adjustment: false);
            case 'adjust':
              _showStockSheet(context, adjustment: true);
            case 'archive':
              _confirmArchive(context);
            case 'delete':
              _confirmDelete(context);
          }
        },
        itemBuilder: (_) => [
          _item('edit', LucideIcons.pencil, 'edit'.tr()),
          _item('restock', LucideIcons.packagePlus, 'restock'.tr()),
          _item('adjust', LucideIcons.slidersHorizontal, 'adjust_stock'.tr()),
          _item('archive', LucideIcons.archive, 'archive_set_aside'.tr()),
          _item('delete', LucideIcons.trash2, 'delete_product'.tr()),
        ],
      ),
    );
  }

  Future<void> _confirmArchive(BuildContext context) async {
    final ok = await showGbConfirmSheet(
      context,
      title: 'archive_this_product'.tr(),
      message: 'archive_confirm_body'.trp({'name': product.nom}),
      confirmLabel: 'archive'.tr(),
      icon: LucideIcons.archive,
    );
    if (ok == true) controller.archive(product);
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showGbConfirmSheet(
      context,
      title: 'delete_this_product'.tr(),
      message: 'delete_confirm_body'.trp({'name': product.nom}),
      confirmLabel: 'delete'.tr(),
      icon: LucideIcons.trash2,
      destructive: true,
    );
    if (ok == true) controller.remove(product);
  }

  PopupMenuItem<String> _item(String value, IconData icon, String label) =>
      PopupMenuItem(
        value: value,
        child: Row(children: [
          Icon(icon, size: 18),
          const SizedBox(width: 10),
          Text(label),
        ]),
      );

  void _showStockSheet(BuildContext context, {required bool adjustment}) {
    final qty = TextEditingController();
    final note = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var busy = false;
    InputDecoration deco(BuildContext ctx, String label) => InputDecoration(
          labelText: label,
          filled: true,
          fillColor: ctx.gb.fill,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(
                color: AppTheme.theme.colorScheme.primary, width: 1.6),
          ),
        );
    showGbSheet<void>(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (_, setState) => Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(adjustment ? 'adjust_stock'.tr() : 'restock'.tr(),
                  style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: ctx.gb.text)),
              SizedBox(height: 4.h),
              Text(product.nom,
                  style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: ctx.gb.text)),
              SizedBox(height: 2.h),
              Text('stock_current'.trp({'n': '${product.quantiteDisponible}'}),
                  style: TextStyle(fontSize: 12.sp, color: ctx.gb.subtext)),
              SizedBox(height: 16.h),
              TextFormField(
                controller: qty,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(signed: true),
                decoration: deco(
                    ctx,
                    adjustment
                        ? 'variation_hint'.tr()
                        : 'quantity_received'.tr()),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n == 0) return 'invalid_quantity'.tr();
                  if (!adjustment && n < 0) return 'must_be_positive'.tr();
                  return null;
                },
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: note,
                decoration: deco(ctx,
                    adjustment ? 'reason_required'.tr() : 'note_optional'.tr()),
                validator: (v) => adjustment && (v == null || v.trim().isEmpty)
                    ? 'reason_error'.tr()
                    : null,
              ),
              SizedBox(height: 18.h),
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: FilledButton(
                  onPressed: busy
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setState(() => busy = true);
                          final ok = await controller.changeStock(
                            product,
                            quantite: int.parse(qty.text),
                            adjustment: adjustment,
                            note: note.text.trim(),
                          );
                          if (ok && ctx.mounted) {
                            Navigator.pop(ctx);
                          } else if (ctx.mounted) {
                            setState(() => busy = false);
                          }
                        },
                  child: Text(busy ? 'saving'.tr() : 'confirm'.tr(),
                      style: TextStyle(
                          fontSize: 15.sp, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() => disposeAfterClose([qty, note]));
  }
}
