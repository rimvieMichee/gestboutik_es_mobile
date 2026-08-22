import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:foodly/controller/apps/sales/sales_history_controller.dart';
import 'package:foodly/helpers/theme/app_theme.dart';
import 'package:foodly/models/sale_model.dart';
import 'package:foodly/views/apps/sales/sale_detail_screen.dart';
import 'package:foodly/widgets/gesboutik/gb_empty_state.dart';
import 'package:foodly/widgets/gesboutik/gb_shimmer_tile.dart';
import 'package:foodly/widgets/gesboutik/gb_staggered_item.dart';

class SalesHistoryScreen extends StatelessWidget {
  const SalesHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SalesHistoryController());
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Historique des ventes'),
        backgroundColor: AppTheme.theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const GbShimmerList();
        }
        if (controller.sales.isEmpty) {
          return GbEmptyState(
            icon: LucideIcons.receipt,
            title: 'Aucune vente enregistrée',
            subtitle: 'Les ventes que vous encaissez apparaîtront ici.',
          );
        }
        return RefreshIndicator(
          onRefresh: controller.loadSales,
          child: ListView.separated(
            padding: EdgeInsets.all(16.w),
            itemCount: controller.sales.length,
            separatorBuilder: (_, __) => SizedBox(height: 10.h),
            itemBuilder: (context, index) {
              final sale = controller.sales[index];
              return GbStaggeredItem(
                index: index,
                child: _SaleTile(sale: sale, dateFormat: dateFormat),
              );
            },
          ),
        );
      }),
    );
  }
}

class _SaleTile extends StatelessWidget {
  final SaleModel sale;
  final DateFormat dateFormat;

  const _SaleTile({required this.sale, required this.dateFormat});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12.r),
      onTap: () => Get.to(() => SaleDetailScreen(sale: sale)),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: AppTheme.theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(LucideIcons.receipt, color: AppTheme.theme.colorScheme.primary, size: 18.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sale.numeroVente, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
                  SizedBox(height: 4.h),
                  Text(
                    dateFormat.format(DateTime.parse(sale.date).toLocal()),
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Text(
              '${sale.montantTotal.toInt()} FCFA',
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
                color: AppTheme.theme.colorScheme.primary,
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14.sp, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
