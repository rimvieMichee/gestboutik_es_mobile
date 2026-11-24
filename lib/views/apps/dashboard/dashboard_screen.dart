import 'package:foodly/views/apps/shops/shop_switcher_sheet.dart';
import 'package:foodly/widgets/gesboutik/gb_sheets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart' hide Trans;
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:foodly/controller/apps/dashboard/dashboard_controller.dart';
import 'package:foodly/controller/layouts/main_shell_controller.dart';
import 'package:foodly/helpers/extensions/string.dart';
import 'package:foodly/helpers/services/realtime_service.dart';
import 'package:foodly/helpers/services/shop_badge_service.dart';
import 'package:foodly/helpers/storage/local_storage.dart';
import 'package:foodly/helpers/theme/app_theme.dart';
import 'package:foodly/helpers/utils/period.dart';
import 'package:foodly/models/sale_model.dart';
import 'package:foodly/widgets/gesboutik/gb_app_bar.dart';
import 'package:foodly/widgets/gesboutik/gb_colors.dart';
import 'package:foodly/widgets/gesboutik/gb_format.dart';
import 'package:foodly/widgets/gesboutik/gb_skeleton.dart';
import 'package:foodly/widgets/gesboutik/gb_staggered_item.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late DashboardController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(DashboardController());
    ShopBadgeService.start();
  }

  @override
  void dispose() {
    ShopBadgeService.stop();
    super.dispose();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'greeting_morning'.tr();
    if (hour < 18) return 'greeting_afternoon'.tr();
    return 'greeting_evening'.tr();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.gb.background,
      appBar: gbAppBar(
        title: LocalStorage.getUserName() ?? 'nav_home'.tr(),
        subtitle: [
          _greeting,
          if ((LocalStorage.getBoutiqueName() ?? '').isNotEmpty)
            LocalStorage.getBoutiqueName()!,
        ].join(' · '),
        showBack: false,
        actions: [
          LocalStorage.isMultiShop
              ? _buildShopChip()
              : _buildAvatar(LocalStorage.getUserName() ?? ''),
        ],
      ),
      body: GetBuilder<DashboardController>(
        builder: (controller) {
          return RefreshIndicator(
            onRefresh: controller.loadDashboard,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _sliver(_buildTotals(controller), top: 20),
                if (controller.hasLoaded)
                  _sliver(_buildWeekCard(controller), top: 12),
                if (controller.hasLoaded && controller.creditDu > 0)
                  _sliver(_buildCreditCard(controller), top: 14),
                _sliver(_buildPeriodSection(controller), top: 26),
                if (controller.isManager)
                  _sliver(_buildShopTiles(controller), top: 22),
                if (controller.isManager && LocalStorage.isMultiShop)
                  _sliver(_buildAllShopsCard(), top: 12),
                _buildQuickActions(),
                SliverToBoxAdapter(child: SizedBox(height: 120.h)),
              ],
            ),
          );
        },
      ),
    );
  }

  SliverToBoxAdapter _sliver(Widget child, {double top = 0}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, top.h, 16.w, 0),
        child: child,
      ),
    );
  }

  Widget _buildAllShopsCard() {
    final primary = AppTheme.theme.colorScheme.primary;
    return Material(
      color: primary.withOpacity(0.10),
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: () => Get.toNamed('/daily-report', arguments: {'all': true}),
        child: Padding(
          padding: EdgeInsets.all(14.w),
          child: Row(
            children: [
              Icon(LucideIcons.layers, size: 22.sp, color: primary),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('all_shops_report'.tr(),
                        style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: primary)),
                    SizedBox(height: 2.h),
                    Text('all_shops_report_hint'.tr(),
                        style: TextStyle(
                            fontSize: 12.sp, color: context.gb.subtext)),
                  ],
                ),
              ),
              Icon(Icons.keyboard_arrow_right, size: 24.sp, color: primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShopChip() {
    final primary = AppTheme.theme.colorScheme.primary;
    return Padding(
      padding: EdgeInsets.only(right: 4.w),
      child: ValueListenableBuilder<int>(
        valueListenable: ShopBadgeService.unseen,
        builder: (context, unseen, chip) => Badge(
          isLabelVisible: unseen > 0,
          label: Text(unseen > 9 ? '9+' : '$unseen'),
          backgroundColor: const Color(0xffEF4444),
          child: chip,
        ),
        child: Material(
          color: primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20.r),
          child: InkWell(
            borderRadius: BorderRadius.circular(20.r),
            onTap: () => showShopSwitcher(context),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.store, size: 16.sp, color: primary),
                  SizedBox(width: 6.w),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 110.w),
                    child: Text(
                      LocalStorage.getBoutiqueName() ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: primary,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Icon(LucideIcons.chevronsUpDown, size: 15.sp, color: primary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String name) {
    final primary = AppTheme.theme.colorScheme.primary;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 38.w,
      height: 38.w,
      decoration: BoxDecoration(
          color: primary.withOpacity(0.12), shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
            color: primary, fontSize: 16.sp, fontWeight: FontWeight.bold),
      ),
    );
  }

  BoxDecoration get _cardDecoration => BoxDecoration(
        color: context.gb.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: context.gb.isDark ? Border.all(color: context.gb.border) : null,
        boxShadow: context.gb.shadow,
      );

  // ---------------------------------------------------- totaux jour/mois/année

  Widget _buildTotals(DashboardController c) {
    final title = c.isManager ? 'dash_shop_sales'.tr() : 'dash_my_sales'.tr();
    final items = [
      ('today'.tr(), LucideIcons.sun, c.today),
      ('this_month'.tr(), LucideIcons.calendarDays, c.month),
      ('this_year'.tr(), LucideIcons.calendarRange, c.year),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(title,
                  style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: context.gb.text)),
            ),
            const _LiveBadge(),
          ],
        ),
        SizedBox(height: 12.h),
        if (c.isLoading && !c.hasLoaded)
          GbSkeleton.dashboardTotalsRow()
        else
          Row(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) SizedBox(width: 10.w),
                Expanded(
                  child: GbStaggeredItem(
                    index: i,
                    child: _totalCard(items[i].$1, items[i].$2, items[i].$3),
                  ),
                ),
              ],
            ],
          ),
      ],
    );
  }

  // ------------------------------------------------------ semaine en cours

  Widget _buildWeekCard(DashboardController c) {
    final primary = AppTheme.theme.colorScheme.primary;
    final p = Period.week(DateTime.now());
    final f = DateFormat('d MMM', LocalStorage.dateLocale);
    final range = '${f.format(p.start)} – ${f.format(p.end)}';
    final now = c.week.chiffreAffaires;
    final before = c.lastWeek.chiffreAffaires;
    // Variation par rapport à la semaine dernière (absente s'il n'y avait rien).
    final delta = before > 0 ? (now - before) / before * 100 : null;
    final up = delta != null && delta >= 0;
    final chipColor = up ? const Color(0xff16A34A) : const Color(0xffDC2626);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: _cardDecoration,
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(13.r),
            ),
            child: Icon(LucideIcons.calendarClock, size: 22.sp, color: primary),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('week_revenue'.tr(),
                    style: TextStyle(
                        fontSize: 12.5.sp, color: context.gb.subtext)),
                SizedBox(height: 3.h),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(formatFcfa(now),
                      style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w800,
                          color: context.gb.text)),
                ),
                SizedBox(height: 3.h),
                Text(
                  '$range · ${(c.week.nombreVentes > 1 ? 'n_sales_other' : 'n_sales_one').trp({
                        'n': '${c.week.nombreVentes}'
                      })}',
                  style: TextStyle(fontSize: 11.5.sp, color: context.gb.subtext),
                ),
              ],
            ),
          ),
          if (delta != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: chipColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(up ? LucideIcons.trendingUp : LucideIcons.trendingDown,
                      size: 14.sp, color: chipColor),
                  SizedBox(width: 4.w),
                  Text('${up ? '+' : ''}${delta.round()} %',
                      style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w800,
                          color: chipColor)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _totalCard(String label, IconData icon, SalesSummary s) {
    final primary = AppTheme.theme.colorScheme.primary;
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15.sp, color: primary),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(fontSize: 11.sp, color: context.gb.subtext)),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatFcfa(s.chiffreAffaires),
              style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                  color: context.gb.text),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            (s.nombreVentes > 1 ? 'n_sales_other' : 'n_sales_one')
                .trp({'n': '${s.nombreVentes}'}),
            style: TextStyle(fontSize: 11.sp, color: context.gb.subtext),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------- crédits en cours

  Widget _buildCreditCard(DashboardController c) {
    const color = Colors.orange;
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: () =>
              Get.toNamed('/sales-history', arguments: {'credit': 'unpaid'}),
          child: Padding(
            padding: EdgeInsets.all(14.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(9.w),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(11.r),
                  ),
                  child:
                      Icon(LucideIcons.creditCard, color: color, size: 20.sp),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('credits_ongoing'.tr(),
                          style: TextStyle(
                              fontSize: 12.sp, color: context.gb.subtext)),
                      SizedBox(height: 2.h),
                      Text(
                        formatFcfa(c.creditDu),
                        style: TextStyle(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w800,
                            color: context.gb.text),
                      ),
                      Text(
                        (c.creditDuNombre > 1
                                ? 'n_unsettled_other'
                                : 'n_unsettled_one')
                            .trp({'n': '${c.creditDuNombre}'}),
                        style: TextStyle(
                            fontSize: 11.5.sp, color: context.gb.subtext),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios,
                    size: 15.sp, color: context.gb.subtext),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------ période au choix

  Widget _buildPeriodSection(DashboardController c) {
    final kinds = {
      PeriodKind.day: 'period_day'.tr(),
      PeriodKind.month: 'period_month'.tr(),
      PeriodKind.year: 'period_year'.tr(),
      PeriodKind.custom: 'period_range'.tr(),
    };
    final primary = AppTheme.theme.colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('dash_view_period'.tr(),
            style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: context.gb.text)),
        SizedBox(height: 12.h),
        Row(
          children: kinds.entries.map((e) {
            final selected = c.period.kind == e.key;
            return Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: ChoiceChip(
                label: Text(e.value),
                selected: selected,
                showCheckmark: false,
                onSelected: (_) {
                  if (e.key == PeriodKind.custom) {
                    _pickRange(c);
                  } else {
                    c.selectKind(e.key);
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
        SizedBox(height: 12.h),
        Container(
          decoration: _cardDecoration,
          padding: EdgeInsets.all(14.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _periodNavigator(c),
              Divider(height: 24.h, color: context.gb.border),
              if (c.isPeriodLoading)
                GbSkeleton.periodResult()
              else
                _periodResult(c.periodSummary),
            ],
          ),
        ),
      ],
    );
  }

  Widget _periodNavigator(DashboardController c) {
    final primary = AppTheme.theme.colorScheme.primary;
    Widget arrow(IconData icon, VoidCallback? onTap) => InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 34.w,
            height: 34.w,
            decoration: BoxDecoration(
              color:
                  onTap == null ? context.gb.fill : primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                size: 18.sp,
                color: onTap == null ? context.gb.subtext : primary),
          ),
        );

    return Row(
      children: [
        arrow(LucideIcons.chevronLeft, () => c.shift(-1)),
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(10.r),
            onTap: () => _pickPeriod(c),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 6.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.calendar, size: 15.sp, color: primary),
                  SizedBox(width: 8.w),
                  Flexible(
                    child: Text(
                      c.period.label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 14.sp,
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
            c.period.canGoNext ? () => c.shift(1) : null),
      ],
    );
  }

  Widget _periodResult(SalesSummary s) {
    final primary = AppTheme.theme.colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('revenue'.tr(),
            style: TextStyle(fontSize: 12.sp, color: context.gb.subtext)),
        SizedBox(height: 4.h),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            formatFcfa(s.chiffreAffaires),
            style: TextStyle(
                fontSize: 26.sp, fontWeight: FontWeight.w800, color: primary),
          ),
        ),
        SizedBox(height: 14.h),
        Row(
          children: [
            _miniStat(LucideIcons.receipt, 'sales'.tr(), '${s.nombreVentes}'),
            SizedBox(width: 10.w),
            _miniStat(
              LucideIcons.creditCard,
              'on_credit'.tr(),
              s.nombreCredits == 0
                  ? '—'
                  : '${formatFcfa(s.creditMontant)} (${s.nombreCredits})',
              color: Colors.orange,
            ),
          ],
        ),
      ],
    );
  }

  Widget _miniStat(IconData icon, String label, String value, {Color? color}) {
    final tint = color ?? AppTheme.theme.colorScheme.primary;
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: tint.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Icon(icon, size: 17.sp, color: tint),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 11.sp, color: context.gb.subtext)),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(value,
                        style: TextStyle(
                            fontSize: 12.5.sp,
                            fontWeight: FontWeight.w700,
                            color: context.gb.text)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- sélecteurs

  Future<void> _pickPeriod(DashboardController c) async {
    switch (c.period.kind) {
      case PeriodKind.day:
        final picked = await showGbDateSheet(
          context,
          title: 'pick_day'.tr(),
          initial: c.period.start,
          first: DateTime(2020),
          last: DateTime.now(),
        );
        if (picked != null) c.setPeriod(Period.day(picked));
      case PeriodKind.month:
        final picked = await _pickMonth(c.period.start);
        if (picked != null) c.setPeriod(Period.month(picked));
      case PeriodKind.year:
        final picked = await _pickYear(c.period.start.year);
        if (picked != null) c.setPeriod(Period.year(DateTime(picked, 1, 1)));
      case PeriodKind.custom:
        await _pickRange(c);
    }
  }

  Future<void> _pickRange(DashboardController c) async {
    final now = DateTime.now();
    final picked = await showGbRangeSheet(
      context,
      title: 'pick_period'.tr(),
      first: DateTime(2020),
      last: now,
      initial: c.period.kind == PeriodKind.custom
          ? DateTimeRange(start: c.period.start, end: c.period.end)
          : null,
    );
    if (picked != null) c.setPeriod(Period.custom(picked.start, picked.end));
  }

  Future<DateTime?> _pickMonth(DateTime current) {
    var year = current.year;
    final now = DateTime.now();
    return showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: context.gb.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26.r)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (_, setState) {
          final primary = AppTheme.theme.colorScheme.primary;
          return Padding(
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => setState(() => year--),
                      icon: const Icon(LucideIcons.chevronLeft),
                    ),
                    Text('$year',
                        style: TextStyle(
                            fontSize: 18.sp, fontWeight: FontWeight.bold)),
                    IconButton(
                      onPressed:
                          year < now.year ? () => setState(() => year++) : null,
                      icon: const Icon(LucideIcons.chevronRight),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 2.3,
                  mainAxisSpacing: 10.h,
                  crossAxisSpacing: 10.w,
                  children: List.generate(12, (i) {
                    final date = DateTime(year, i + 1, 1);
                    final future = date.isAfter(now);
                    final selected =
                        year == current.year && i + 1 == current.month;
                    final name =
                        DateFormat('MMM', LocalStorage.dateLocale).format(date);
                    return OutlinedButton(
                      onPressed: future
                          ? null
                          : () => Navigator.pop(sheetContext, date),
                      style: OutlinedButton.styleFrom(
                        backgroundColor:
                            selected ? primary : Colors.transparent,
                        foregroundColor:
                            selected ? Colors.white : context.gb.text,
                        side: BorderSide(
                            color: selected ? primary : context.gb.border),
                      ),
                      child: Text(name[0].toUpperCase() + name.substring(1)),
                    );
                  }),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<int?> _pickYear(int current) {
    final now = DateTime.now().year;
    final years = [for (var y = now; y >= now - 5; y--) y];
    return showModalBottomSheet<int>(
      context: context,
      backgroundColor: context.gb.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26.r)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('pick_year'.tr(),
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 12.h),
            for (final y in years)
              ListTile(
                title: Text('$y',
                    style: TextStyle(
                        fontWeight:
                            y == current ? FontWeight.w800 : FontWeight.w500)),
                trailing: y == current
                    ? Icon(LucideIcons.check,
                        color: AppTheme.theme.colorScheme.primary)
                    : null,
                onTap: () => Navigator.pop(sheetContext, y),
              ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------- effectifs (gestionnaire)

  Widget _buildShopTiles(DashboardController c) {
    final tiles = [
      ('employees'.tr(), '${c.employeeCount}', LucideIcons.users),
      ('products'.tr(), '${c.productCount}', LucideIcons.package),
    ];
    final primary = AppTheme.theme.colorScheme.primary;
    return Row(
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          if (i > 0) SizedBox(width: 10.w),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(12.w),
              decoration: _cardDecoration,
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(tiles[i].$3, size: 17.sp, color: primary),
                  ),
                  SizedBox(width: 10.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tiles[i].$2,
                          style: TextStyle(
                              fontSize: 17.sp,
                              fontWeight: FontWeight.w800,
                              color: context.gb.text)),
                      Text(tiles[i].$1,
                          style: TextStyle(
                              fontSize: 11.sp, color: context.gb.subtext)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  // -------------------------------------------------------------- raccourcis

  Widget _buildQuickActions() {
    final actions = [
      _QuickAction(
        icon: LucideIcons.plusCircle,
        label: 'new_sale'.tr(),
        subtitle: 'new_sale_desc'.tr(),
        onTap: () => Get.find<MainShellController>()
            .changeTab(MainShellController.saleTab),
      ),
    ];
    if (actions.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 26.h, 16.w, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'quick_actions'.tr(),
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: context.gb.text,
              ),
            ),
            SizedBox(height: 12.h),
            ...actions.asMap().entries.map(
                  (entry) => GbStaggeredItem(
                    index: entry.key,
                    child: _buildActionTile(entry.value),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(_QuickAction action) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: context.gb.surface,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: context.gb.shadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(14.r),
          onTap: action.onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: AppTheme.theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(action.icon,
                      color: AppTheme.theme.colorScheme.primary),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        action.label,
                        style: TextStyle(
                            fontSize: 14.sp, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        action.subtitle,
                        style: TextStyle(
                            fontSize: 11.5.sp, color: context.gb.subtext),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios,
                    size: 16, color: context.gb.subtext),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pastille « En direct » : visible tant que le flux temps réel est connecté.
class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final live = RealtimeService.instance.connected.value;
      final color = live ? Colors.green : context.gb.subtext;
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7.w,
              height: 7.w,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            SizedBox(width: 5.w),
            Text(
              live ? 'live'.tr() : 'offline'.tr(),
              style: TextStyle(
                fontSize: 10.5.sp,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  _QuickAction({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });
}
