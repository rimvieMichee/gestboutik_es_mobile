import 'package:foodly/widgets/gesboutik/gb_sheets.dart';
import 'package:foodly/helpers/extensions/string.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart' hide Trans;
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:foodly/controller/apps/sales/sales_history_controller.dart';
import 'package:foodly/helpers/services/sale_service.dart';
import 'package:foodly/helpers/theme/app_theme.dart';
import 'package:foodly/helpers/utils/period.dart';
import 'package:foodly/models/sale_model.dart';
import 'package:foodly/views/apps/sales/sale_detail_screen.dart';
import 'package:foodly/widgets/gesboutik/gb_app_bar.dart';
import 'package:foodly/widgets/gesboutik/gb_colors.dart';
import 'package:foodly/widgets/gesboutik/gb_empty_state.dart';
import 'package:foodly/widgets/gesboutik/gb_format.dart';
import 'package:foodly/widgets/gesboutik/gb_skeleton.dart';
import 'package:foodly/widgets/gesboutik/gb_staggered_item.dart';

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  late final SalesHistoryController controller;
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    controller = Get.put(SalesHistoryController());
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
        controller.loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _pickRange() async {
    final current = controller.period.value;
    final picked = await showGbRangeSheet(
      context,
      title: 'filter_by_period'.tr(),
      first: DateTime(2020),
      last: DateTime.now(),
      initial: current == null
          ? null
          : DateTimeRange(start: current.start, end: current.end),
    );
    if (picked != null) {
      controller.setPeriod(Period.custom(picked.start, picked.end));
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.theme.colorScheme.primary;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      backgroundColor: context.gb.background,
      appBar: gbAppBar(
        title: 'sales_history'.tr(),
        actions: [
          Obx(
            () => IconButton(
              tooltip: 'filter_by_date'.tr(),
              onPressed: _pickRange,
              icon: Icon(
                LucideIcons.calendarRange,
                size: 21.sp,
                color: controller.period.value == null
                    ? context.gb.subtext
                    : primary,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _filters(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return GbSkeleton.saleList();
              }
              if (controller.sales.isEmpty) {
                final filtered = controller.credit.value != CreditFilter.all ||
                    controller.period.value != null;
                return GbEmptyState(
                  icon: LucideIcons.receipt,
                  title: filtered
                      ? 'no_sale_filter'.tr()
                      : 'no_sale_recorded'.tr(),
                  subtitle: filtered
                      ? 'change_filter'.tr()
                      : 'sales_appear_here'.tr(),
                );
              }
              return RefreshIndicator(
                onRefresh: controller.loadSales,
                child: ListView.separated(
                  controller: _scroll,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
                  itemCount: controller.sales.length + 1,
                  separatorBuilder: (_, __) => SizedBox(height: 10.h),
                  itemBuilder: (context, index) {
                    if (index == controller.sales.length) {
                      return Obx(() => controller.isLoadingMore.value
                          ? Padding(
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              child: const Center(
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2)),
                            )
                          : const SizedBox.shrink());
                    }
                    final sale = controller.sales[index];
                    return GbStaggeredItem(
                      index: index,
                      child: _SaleTile(sale: sale, dateFormat: dateFormat),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _filters() {
    final options = {
      CreditFilter.all: 'all_f'.tr(),
      CreditFilter.cash: 'cash'.tr(),
      CreditFilter.unpaid: 'credit_ongoing'.tr(),
      CreditFilter.paid: 'credit_settled'.tr(),
    };
    final primary = AppTheme.theme.colorScheme.primary;
    return Column(
      children: [
        SizedBox(
          height: 54.h,
          child: Obx(
            () => ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 6.h),
              children: options.entries.map((e) {
                final selected = controller.credit.value == e.key;
                return Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: ChoiceChip(
                    label: Text(e.value),
                    selected: selected,
                    showCheckmark: false,
                    onSelected: (_) => controller.setCredit(e.key),
                    selectedColor: primary,
                    backgroundColor: context.gb.surface,
                    side: BorderSide(
                        color: selected ? primary : context.gb.border),
                    labelStyle: TextStyle(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : context.gb.text,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Obx(() {
          final period = controller.period.value;
          if (period == null) return const SizedBox.shrink();
          return Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 4.h),
            child: Container(
              padding: EdgeInsets.fromLTRB(12.w, 6.h, 4.w, 6.h),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.calendarRange, size: 16.sp, color: primary),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(period.label,
                        style: TextStyle(
                            fontSize: 12.5.sp,
                            fontWeight: FontWeight.w700,
                            color: context.gb.text)),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'remove_filter'.tr(),
                    onPressed: () => controller.setPeriod(null),
                    icon: Icon(LucideIcons.x, size: 18.sp, color: primary),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _SaleTile extends StatelessWidget {
  final SaleModel sale;
  final DateFormat dateFormat;

  const _SaleTile({required this.sale, required this.dateFormat});

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.theme.colorScheme.primary;
    final subtitle = [
      dateFormat.format(DateTime.parse(sale.date).toLocal()),
      if (sale.vendeur != null) sale.vendeur!,
    ].join(' · ');

    return InkWell(
      borderRadius: BorderRadius.circular(12.r),
      onTap: () => Get.to(() => SaleDetailScreen(sale: sale)),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: context.gb.surface,
          borderRadius: BorderRadius.circular(12.r),
          border:
              context.gb.isDark ? Border.all(color: context.gb.border) : null,
          boxShadow: context.gb.shadow,
        ),
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color:
                    (sale.isCredit ? Colors.orange : primary).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                sale.isCredit ? LucideIcons.creditCard : LucideIcons.receipt,
                color: sale.isCredit ? Colors.orange : primary,
                size: 18.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sale.numeroVente,
                      style: TextStyle(
                          fontSize: 14.sp, fontWeight: FontWeight.w600)),
                  SizedBox(height: 3.h),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(fontSize: 11.5.sp, color: context.gb.subtext),
                  ),
                  if (sale.isCredit) ...[
                    SizedBox(height: 6.h),
                    _creditBadge(),
                  ],
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              formatFcfa(sale.montantTotal),
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: primary,
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 14.sp, color: context.gb.subtext),
          ],
        ),
      ),
    );
  }

  Widget _creditBadge() {
    final settled = sale.creditRegleAt != null;
    final color = settled ? Colors.green : Colors.orange;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        '${settled ? 'credit_settled'.tr() : 'credit'.tr()} · ${sale.clientNom ?? '—'}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
            fontSize: 10.5.sp, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}
