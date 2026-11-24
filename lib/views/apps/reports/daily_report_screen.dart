import 'package:foodly/widgets/gesboutik/gb_sheets.dart';
import 'package:foodly/helpers/extensions/string.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart' hide Trans;
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:foodly/controller/apps/reports/daily_report_controller.dart';
import 'package:foodly/helpers/storage/local_storage.dart';
import 'package:foodly/helpers/theme/app_theme.dart';
import 'package:foodly/helpers/utils/period.dart';
import 'package:foodly/models/daily_report_model.dart';
import 'package:foodly/views/apps/settings/widget/phone_sheet.dart';
import 'package:foodly/widgets/gesboutik/gb_app_bar.dart';
import 'package:foodly/widgets/gesboutik/gb_colors.dart';
import 'package:foodly/widgets/gesboutik/gb_empty_state.dart';
import 'package:foodly/widgets/gesboutik/gb_format.dart';
import 'package:foodly/widgets/gesboutik/gb_skeleton.dart';
import 'package:foodly/widgets/gesboutik/gb_staggered_item.dart';

class DailyReportScreen extends StatelessWidget {
  const DailyReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DailyReportController());

    return Scaffold(
      backgroundColor: context.gb.background,
      appBar: gbAppBar(title: 'daily_report'.tr()),
      bottomNavigationBar: _ExportBar(controller: controller),
      body: RefreshIndicator(
        onRefresh: controller.load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
          children: [
            if (LocalStorage.isMultiShop) ...[
              _ScopeToggle(controller: controller),
              SizedBox(height: 12.h),
            ],
            _KindChips(controller: controller),
            SizedBox(height: 10.h),
            _DateBar(controller: controller),
            SizedBox(height: 14.h),
            Obx(() {
              if (controller.isLoading.value &&
                  controller.report.value == null) {
                return _loadingBody();
              }
              final report = controller.report.value;
              if (report == null) {
                return GbEmptyState(
                  icon: LucideIcons.fileWarning,
                  title: 'report_unavailable'.tr(),
                  subtitle: 'pull_to_retry'.tr(),
                );
              }
              return Opacity(
                opacity: controller.isLoading.value ? 0.45 : 1,
                child: _body(context, report),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _loadingBody() {
    return Column(
      children: [
        GbSkeletonCard(child: GbSkeleton.periodResult()),
        SizedBox(height: 14.h),
        for (var i = 0; i < 4; i++) ...[
          GbSkeleton.saleRow(),
          SizedBox(height: 10.h),
        ],
      ],
    );
  }

  Widget _body(BuildContext context, DailyReport report) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (report.gestionnaireSansNumero) _phoneHint(context),
        _SummaryCard(report: report),
        if (report.consolide && report.parBoutique.isNotEmpty) ...[
          SizedBox(height: 16.h),
          _ShopBreakdown(shops: report.parBoutique),
        ],
        SizedBox(height: 20.h),
        Text(
          'sales_detail_count'.trp({'n': '${report.nombreVentes}'}),
          style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
              color: context.gb.text),
        ),
        SizedBox(height: 10.h),
        if (report.ventes.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: context.gb.surface,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: context.gb.shadow,
            ),
            child: Text(
              'no_sale_that_day'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.sp, color: context.gb.subtext),
            ),
          )
        else
          for (var i = 0; i < report.ventes.length; i++)
            GbStaggeredItem(
              index: i,
              child: Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: _SaleCard(
                    sale: report.ventes[i], showShop: report.consolide),
              ),
            ),
      ],
    );
  }

  /// Invite à renseigner son numéro, qui figure en en-tête du PDF.
  Widget _phoneHint(BuildContext context) {
    const color = Colors.orange;
    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.phone, size: 18.sp, color: color),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'phone_missing_pdf'.tr(),
              style: TextStyle(fontSize: 12.sp, color: context.gb.text),
            ),
          ),
          TextButton(
            onPressed: () async {
              final saved = await showPhoneSheet(context);
              if (saved == true) Get.find<DailyReportController>().load();
            },
            child: Text('add'.tr()),
          ),
        ],
      ),
    );
  }
}

class _ScopeToggle extends StatelessWidget {
  final DailyReportController controller;
  const _ScopeToggle({required this.controller});

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.theme.colorScheme.primary;
    Widget option(String label, bool all) {
      final on = controller.allShops.value == all;
      return Expanded(
        child: GestureDetector(
          onTap: () => controller.setAll(all),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.symmetric(vertical: 10.h),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? primary : Colors.transparent,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(label,
                style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: on ? Colors.white : context.gb.subtext)),
          ),
        ),
      );
    }

    return Obx(() => Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: context.gb.fill,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Row(children: [
            option('report_scope_current'.tr(), false),
            option('report_scope_all'.tr(), true),
          ]),
        ));
  }
}

/// Détail du rapport consolidé : chiffre d'affaires et crédit de chaque boutique.
class _ShopBreakdown extends StatelessWidget {
  final List<ReportShop> shops;
  const _ShopBreakdown({required this.shops});

  @override
  Widget build(BuildContext context) {
    final c = context.gb;
    final primary = AppTheme.theme.colorScheme.primary;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: c.isDark ? Border.all(color: c.border) : null,
        boxShadow: c.shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('report_by_shop'.tr(),
              style: TextStyle(
                  fontSize: 14.sp, fontWeight: FontWeight.bold, color: c.text)),
          SizedBox(height: 10.h),
          for (final s in shops)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 6.h),
              child: Row(
                children: [
                  Icon(LucideIcons.store, size: 16.sp, color: primary),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(s.nom,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.w600,
                            color: c.text)),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(formatFcfa(s.chiffreAffaires),
                          style: TextStyle(
                              fontSize: 13.5.sp,
                              fontWeight: FontWeight.w800,
                              color: primary)),
                      Text(
                        '${(s.nombreVentes > 1 ? 'n_sales_other' : 'n_sales_one').trp({
                              'n': '${s.nombreVentes}'
                            })}${s.creditDu > 0 ? ' · ${formatFcfa(s.creditDu)}' : ''}',
                        style: TextStyle(fontSize: 11.sp, color: c.subtext),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Jour / Semaine / Mois / Année / Période libre.
class _KindChips extends StatelessWidget {
  final DailyReportController controller;
  const _KindChips({required this.controller});

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.theme.colorScheme.primary;
    final kinds = {
      PeriodKind.day: 'period_day'.tr(),
      PeriodKind.week: 'period_week'.tr(),
      PeriodKind.month: 'period_month'.tr(),
      PeriodKind.year: 'period_year'.tr(),
      PeriodKind.custom: 'period_range'.tr(),
    };
    return Obx(() {
      final current = controller.period.value.kind;
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: kinds.entries.map((e) {
            final selected = current == e.key;
            return Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: ChoiceChip(
                label: Text(e.value),
                selected: selected,
                showCheckmark: false,
                onSelected: (_) async {
                  if (e.key == PeriodKind.custom) {
                    await _DateBar.pickRange(context, controller);
                  } else {
                    controller.setKind(e.key);
                  }
                },
                selectedColor: primary,
                backgroundColor: context.gb.surface,
                side: BorderSide(color: selected ? primary : context.gb.border),
                labelStyle: TextStyle(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : context.gb.text,
                ),
              ),
            );
          }).toList(),
        ),
      );
    });
  }
}

class _DateBar extends StatelessWidget {
  final DailyReportController controller;
  const _DateBar({required this.controller});

  static Future<void> pickRange(
      BuildContext context, DailyReportController controller) async {
    final cur = controller.period.value;
    final picked = await showGbRangeSheet(
      context,
      title: 'pick_period'.tr(),
      first: DateTime(2020),
      last: DateTime.now(),
      initial: cur.kind == PeriodKind.custom
          ? DateTimeRange(start: cur.start, end: cur.end)
          : null,
    );
    if (picked != null) {
      controller.setPeriod(Period.custom(picked.start, picked.end));
    }
  }

  /// Le libellé ouvre le bon sélecteur : un jour pour jour/semaine/mois/année
  /// (la période qui le contient), ou début et fin pour une plage libre.
  Future<void> _pick(BuildContext context) async {
    final period = controller.period.value;
    if (period.kind == PeriodKind.custom) {
      return pickRange(context, controller);
    }
    final picked = await showGbDateSheet(
      context,
      title: 'pick_report_day'.tr(),
      initial: period.start,
      first: DateTime(2020),
      last: DateTime.now(),
    );
    if (picked != null) controller.setPeriod(Period.of(period.kind, picked));
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.theme.colorScheme.primary;

    Widget arrow(IconData icon, VoidCallback? onTap) => InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color:
                  onTap == null ? context.gb.fill : primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                size: 19.sp,
                color: onTap == null ? context.gb.subtext : primary),
          ),
        );

    return Obx(() {
      final period = controller.period.value;
      return Container(
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: context.gb.surface,
          borderRadius: BorderRadius.circular(16.r),
          border:
              context.gb.isDark ? Border.all(color: context.gb.border) : null,
          boxShadow: context.gb.shadow,
        ),
        child: Row(
          children: [
            arrow(LucideIcons.chevronLeft, () => controller.shift(-1)),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(10.r),
                onTap: () => _pick(context),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.calendar, size: 16.sp, color: primary),
                      SizedBox(width: 8.w),
                      Flexible(
                        child: Text(
                          period.label,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 14.5.sp,
                              fontWeight: FontWeight.w700,
                              color: context.gb.text),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            arrow(LucideIcons.chevronRight,
                period.canGoNext ? () => controller.shift(1) : null),
          ],
        ),
      );
    });
  }
}

/// Résumé : chiffre d'affaires, puis ventes, articles, encaissé, crédit.
class _SummaryCard extends StatelessWidget {
  final DailyReport report;
  const _SummaryCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.theme.colorScheme.primary;
    Widget stat(IconData icon, String label, String value, Color color) =>
        Expanded(
          child: Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.09),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Icon(icon, size: 17.sp, color: color),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: TextStyle(
                              fontSize: 10.5.sp, color: context.gb.subtext)),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(value,
                            style: TextStyle(
                                fontSize: 12.5.sp,
                                fontWeight: FontWeight.w800,
                                color: context.gb.text)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.gb.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: context.gb.isDark ? Border.all(color: context.gb.border) : null,
        boxShadow: context.gb.shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('revenue'.tr(),
              style: TextStyle(fontSize: 12.sp, color: context.gb.subtext)),
          SizedBox(height: 4.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatFcfa(report.chiffreAffaires),
              style: TextStyle(
                  fontSize: 26.sp, fontWeight: FontWeight.w800, color: primary),
            ),
          ),
          SizedBox(height: 14.h),
          Row(children: [
            stat(LucideIcons.receipt, 'sales'.tr(), '${report.nombreVentes}',
                primary),
            SizedBox(width: 10.w),
            stat(LucideIcons.package, 'items_sold'.tr(),
                '${report.articlesVendus}', Colors.blue),
          ]),
          SizedBox(height: 10.h),
          Row(children: [
            stat(LucideIcons.checkCircle2, 'collected_paid'.tr(),
                formatFcfa(report.encaisse), Colors.green),
            SizedBox(width: 10.w),
            stat(LucideIcons.creditCard, 'credit_unsettled'.tr(),
                formatFcfa(report.creditDu), Colors.orange),
          ]),
        ],
      ),
    );
  }
}

/// Une vente : numéro, heure, vendeur, statut Payé/Crédit et ses produits.
class _SaleCard extends StatelessWidget {
  final bool showShop;
  final ReportSale sale;
  const _SaleCard({required this.sale, this.showShop = false});

  @override
  Widget build(BuildContext context) {
    final color = sale.isCredit ? Colors.orange : Colors.green;
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: context.gb.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: context.gb.isDark ? Border.all(color: context.gb.border) : null,
        boxShadow: context.gb.shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sale.numeroVente,
                        style: TextStyle(
                            fontSize: 14.sp, fontWeight: FontWeight.w700)),
                    SizedBox(height: 2.h),
                    Text(
                      [
                        DateFormat('HH:mm').format(sale.date),
                        if (showShop && (sale.boutique ?? '').isNotEmpty)
                          sale.boutique!,
                        if (sale.vendeur.isNotEmpty) sale.vendeur,
                      ].join(' · '),
                      style: TextStyle(
                          fontSize: 11.5.sp, color: context.gb.subtext),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  sale.statutLabel,
                  style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: color),
                ),
              ),
            ],
          ),
          if (sale.isCredit && (sale.clientNom ?? '').isNotEmpty) ...[
            SizedBox(height: 6.h),
            Row(
              children: [
                Icon(LucideIcons.user, size: 13.sp, color: Colors.orange),
                SizedBox(width: 6.w),
                Text('borrower_label'.trp({'name': '${sale.clientNom}'}),
                    style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: context.gb.text)),
              ],
            ),
          ],
          Divider(height: 20.h, color: context.gb.border),
          for (final line in sale.lignes)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 3.h),
              child: Row(
                children: [
                  Text('${line.quantite}×',
                      style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: context.gb.subtext)),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(line.produit,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13.sp)),
                  ),
                  Text(formatFcfa(line.sousTotal),
                      style: TextStyle(
                          fontSize: 12.5.sp, color: context.gb.subtext)),
                ],
              ),
            ),
          Divider(height: 20.h, color: context.gb.border),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('total'.tr(),
                  style:
                      TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600)),
              Text(formatFcfa(sale.montantTotal),
                  style: TextStyle(
                      fontSize: 14.5.sp,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.theme.colorScheme.primary)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Barre fixe en bas : téléchargement du PDF du jour choisi.
class _ExportBar extends StatelessWidget {
  final DailyReportController controller;
  const _ExportBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16.w, 12.h, 16.w, 12.h + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: context.gb.surface,
        border: Border(top: BorderSide(color: context.gb.border)),
      ),
      child: Obx(() {
        final ready = controller.report.value != null &&
            !controller.isLoading.value &&
            !controller.isExporting.value;
        return SizedBox(
          width: double.infinity,
          height: 50.h,
          child: FilledButton.icon(
            onPressed: ready ? controller.exportPdf : null,
            icon: controller.isExporting.value
                ? SizedBox(
                    width: 18.w,
                    height: 18.w,
                    child: const CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(LucideIcons.fileSearch),
            label: Text(
              controller.isExporting.value
                  ? 'generating_pdf'.tr()
                  : 'preview_pdf'.tr(),
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700),
            ),
          ),
        );
      }),
    );
  }
}
