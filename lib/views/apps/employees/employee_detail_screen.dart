import 'package:foodly/helpers/extensions/string.dart';
import 'package:flutter/material.dart';
import 'package:foodly/widgets/gesboutik/gb_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart' hide Trans;
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:foodly/controller/apps/employees/employee_detail_controller.dart';
import 'package:foodly/controller/apps/employees/employees_controller.dart';
import 'package:foodly/helpers/theme/app_theme.dart';
import 'package:foodly/models/employee_model.dart';
import 'package:foodly/models/sale_model.dart';
import 'package:foodly/views/apps/employees/employees_screen.dart';
import 'package:foodly/views/apps/sales/sale_detail_screen.dart';
import 'package:foodly/views/ui/shimmer/shimmer_widget.dart';
import 'package:foodly/widgets/gesboutik/gb_app_bar.dart';
import 'package:foodly/widgets/gesboutik/gb_skeleton.dart';
import 'package:foodly/widgets/gesboutik/gb_format.dart';
import 'package:foodly/widgets/gesboutik/gb_staggered_item.dart';

class EmployeeDetailScreen extends StatelessWidget {
  const EmployeeDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final initial = Get.arguments as EmployeeModel;
    final list = Get.find<EmployeesController>();
    final detail =
        Get.put(EmployeeDetailController(initial.id), tag: initial.id);
    final primary = AppTheme.theme.colorScheme.primary;
    final dateTime = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      backgroundColor: context.gb.background,
      appBar: gbAppBar(
        title: 'employee_details'.tr(),
        actions: [
          IconButton(
            tooltip: 'edit'.tr(),
            icon: Icon(LucideIcons.pencil, size: 20.sp, color: primary),
            onPressed: () => EmployeesScreen.showEditSheet(
              context,
              list,
              list.employees.firstWhereOrNull((e) => e.id == initial.id) ??
                  initial,
            ),
          ),
        ],
      ),
      body: Obx(() {
        // Reprend la version la plus récente de la liste (statut modifié, etc.).
        final employee =
            list.employees.firstWhereOrNull((e) => e.id == initial.id) ??
                initial;
        return RefreshIndicator(
          onRefresh: () async {
            await Future.wait([list.loadEmployees(), detail.load()]);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
            children: [
              _identityCard(context, employee, primary),
              SizedBox(height: 16.h),
              _statsRow(context, detail, primary),
              SizedBox(height: 16.h),
              _infoCard(context, employee, primary),
              SizedBox(height: 16.h),
              _actions(context, list, employee),
              SizedBox(height: 22.h),
              Text('last_sales'.tr(),
                  style:
                      TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 10.h),
              _recentSales(context, detail, dateTime, primary),
            ],
          ),
        );
      }),
    );
  }

  BoxDecoration _card(BuildContext context) => BoxDecoration(
        color: context.gb.surface,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: context.gb.shadow,
      );

  Widget _identityCard(BuildContext context, EmployeeModel e, Color primary) {
    final statusColor = e.isActive ? Colors.green : Colors.red;
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: _card(context),
      child: Row(
        children: [
          Container(
            width: 64.w,
            height: 64.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: primary.withOpacity(0.12), shape: BoxShape.circle),
            child: Text(
              e.nomComplet.characters.first.toUpperCase(),
              style: TextStyle(
                  fontSize: 26.sp, fontWeight: FontWeight.bold, color: primary),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.nomComplet,
                    style: TextStyle(
                        fontSize: 17.sp, fontWeight: FontWeight.bold)),
                SizedBox(height: 2.h),
                Text('@${e.username}',
                    style: TextStyle(
                        fontSize: 12.5.sp, color: context.gb.subtext)),
                SizedBox(height: 6.h),
                Row(
                  children: [
                    Icon(LucideIcons.phone, size: 13.sp, color: primary),
                    SizedBox(width: 6.w),
                    Flexible(
                      child: Text(
                        e.telephone?.isNotEmpty == true
                            ? e.telephone!
                            : 'no_phone'.tr(),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: e.telephone?.isNotEmpty == true
                              ? context.gb.text
                              : context.gb.subtext,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    e.isActive
                        ? 'account_active'.tr()
                        : 'account_disabled'.tr(),
                    style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: statusColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsRow(
      BuildContext context, EmployeeDetailController detail, Color primary) {
    final s = detail.stats.value;
    final loading = detail.isLoading.value && s == null;

    Widget tile(IconData icon, String label, String value) => loading
        ? GbSkeleton.employeeStatTile()
        : Expanded(
            child: Container(
              padding: EdgeInsets.all(14.w),
              decoration: _card(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(icon, size: 17.sp, color: primary),
                  ),
                  SizedBox(height: 10.h),
                  Text(value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 15.sp, fontWeight: FontWeight.w800)),
                  SizedBox(height: 2.h),
                  Text(label,
                      style: TextStyle(
                          fontSize: 11.sp, color: context.gb.subtext)),
                ],
              ),
            ),
          );

    return Column(
      children: [
        Row(children: [
          tile(LucideIcons.receipt, 'sales_made'.tr(),
              '${s?.nombreVentes ?? 0}'),
          SizedBox(width: 12.w),
          tile(LucideIcons.wallet, 'revenue'.tr(),
              formatFcfa(s?.chiffreAffaires ?? 0)),
        ]),
        SizedBox(height: 12.h),
        Row(children: [
          tile(LucideIcons.sun, 'sales_today'.tr(), '${s?.ventesDuJour ?? 0}'),
          SizedBox(width: 12.w),
          tile(LucideIcons.banknote, 'revenue_today_short'.tr(),
              formatFcfa(s?.chiffreAffairesDuJour ?? 0)),
        ]),
      ],
    );
  }

  Widget _infoCard(BuildContext context, EmployeeModel e, Color primary) {
    final df = DateFormat('dd/MM/yyyy');
    final detail = Get.find<EmployeeDetailController>(tag: e.id);
    final stats = detail.stats.value;
    final loadingStats = detail.isLoading.value && stats == null;
    final rows = [
      (
        LucideIcons.phone,
        'phone'.tr(),
        e.telephone?.isNotEmpty == true ? e.telephone! : '—'
      ),
      (
        LucideIcons.calendarPlus,
        'account_created_on'.tr(),
        e.createdAt != null ? df.format(e.createdAt!) : '—'
      ),
      (
        LucideIcons.clock,
        'last_sale'.tr(),
        stats?.derniereVente != null
            ? DateFormat('dd/MM/yyyy HH:mm').format(stats!.derniereVente!)
            : 'no_sale'.tr()
      ),
    ];
    return Container(
      decoration: _card(context),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(
                  height: 1,
                  indent: 16.w,
                  endIndent: 16.w,
                  color: context.gb.fill),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 13.h),
              child: Row(
                children: [
                  Icon(rows[i].$1, size: 18.sp, color: primary),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Text(rows[i].$2,
                        style: TextStyle(
                            fontSize: 12.5.sp, color: context.gb.subtext)),
                  ),
                  if (loadingStats && i == rows.length - 1)
                    ShimmerWidget(child: const GbBone(width: 100, height: 13))
                  else
                    Text(rows[i].$3,
                        style: TextStyle(
                            fontSize: 13.sp, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _actions(
      BuildContext context, EmployeesController list, EmployeeModel e) {
    final primary = AppTheme.theme.colorScheme.primary;
    final danger = e.isActive ? Colors.red : Colors.green;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () =>
                EmployeesScreen.showPasswordSheet(context, list, e),
            icon: const Icon(LucideIcons.keyRound, size: 18),
            label: Text('login_password'.tr()),
            style: OutlinedButton.styleFrom(
              foregroundColor: primary,
              side: BorderSide(color: primary.withOpacity(0.4)),
              padding: EdgeInsets.symmetric(vertical: 14.h),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r)),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => EmployeesScreen.confirmToggle(context, list, e),
            icon: Icon(e.isActive ? LucideIcons.userX : LucideIcons.userCheck,
                size: 18),
            label: Text(e.isActive ? 'deactivate'.tr() : 'reactivate'.tr()),
            style: OutlinedButton.styleFrom(
              foregroundColor: danger,
              side: BorderSide(color: danger.withOpacity(0.4)),
              padding: EdgeInsets.symmetric(vertical: 14.h),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _recentSales(BuildContext context, EmployeeDetailController detail,
      DateFormat df, Color primary) {
    if (detail.isLoading.value && detail.recentSales.isEmpty) {
      return Column(
        children: [
          for (var i = 0; i < 3; i++) ...[
            GbSkeleton.saleRow(),
            SizedBox(height: 10.h),
          ],
        ],
      );
    }
    if (detail.recentSales.isEmpty) {
      return Container(
        padding: EdgeInsets.all(20.w),
        decoration: _card(context),
        alignment: Alignment.center,
        child: Text('employee_no_sales'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5.sp, color: context.gb.subtext)),
      );
    }
    return Column(
      children: [
        for (var i = 0; i < detail.recentSales.length; i++)
          GbStaggeredItem(
            index: i,
            child: _saleRow(context, detail.recentSales[i], df, primary),
          ),
      ],
    );
  }

  Widget _saleRow(
      BuildContext context, SaleModel sale, DateFormat df, Color primary) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: _card(context),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18.r),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Get.to(() => SaleDetailScreen(sale: sale)),
          child: Padding(
            padding: EdgeInsets.all(14.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(9.w),
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(11.r),
                  ),
                  child: Icon(LucideIcons.receipt, size: 18.sp, color: primary),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(sale.numeroVente,
                          style: TextStyle(
                              fontSize: 13.5.sp, fontWeight: FontWeight.w600)),
                      SizedBox(height: 2.h),
                      Text(df.format(DateTime.parse(sale.date).toLocal()),
                          style: TextStyle(
                              fontSize: 11.5.sp, color: context.gb.subtext)),
                    ],
                  ),
                ),
                Text(formatFcfa(sale.montantTotal),
                    style: TextStyle(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w800,
                        color: primary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
