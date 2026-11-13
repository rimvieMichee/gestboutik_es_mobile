import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart' hide Trans;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:foodly/helpers/extensions/string.dart';
import 'package:foodly/helpers/services/shop_badge_service.dart';
import 'package:foodly/helpers/services/shop_service.dart';
import 'package:foodly/helpers/theme/app_theme.dart';
import 'package:foodly/models/shop_model.dart';
import 'package:foodly/views/apps/shops/shop_switch_screen.dart';
import 'package:foodly/widgets/gesboutik/gb_colors.dart';
import 'package:foodly/widgets/gesboutik/gb_format.dart';
import 'package:foodly/widgets/gesboutik/gb_sheets.dart';
import 'package:foodly/widgets/gesboutik/gb_skeleton.dart';

/// Sélecteur de boutique d'un gestionnaire qui en gère plusieurs : chaque
/// boutique montre ses ventes du jour et ses crédits à encaisser, pour choisir
/// d'un coup d'œil sans ouvrir chacune.
Future<void> showShopSwitcher(
  BuildContext context, {
  Future<List<ShopModel>> Function()? loader,
  void Function(ShopModel shop)? onPick,
}) {
  return showGbSheet<void>(
    context,
    builder: (ctx) => ShopSwitcherContent(
      loader: loader ?? ShopService.mine,
      onPick: (shop) {
        Navigator.of(ctx).pop();
        ShopBadgeService.markSeen(shop);
        (onPick ?? _openShop)(shop);
      },
    ),
  );
}

void _openShop(ShopModel shop) {
  Get.offAll(() => ShopSwitchScreen(shop: shop),
      transition: Transition.fadeIn,
      duration: const Duration(milliseconds: 250));
}

class ShopSwitcherContent extends StatefulWidget {
  final Future<List<ShopModel>> Function() loader;
  final void Function(ShopModel shop) onPick;
  const ShopSwitcherContent(
      {super.key, required this.loader, required this.onPick});

  @override
  State<ShopSwitcherContent> createState() => _ShopSwitcherContentState();
}

class _ShopSwitcherContentState extends State<ShopSwitcherContent> {
  late Future<List<ShopModel>> _future = _load();

  /// Charge les boutiques et met à jour les pastilles « nouvelles ventes ».
  Future<List<ShopModel>> _load() => widget.loader().then((shops) {
        ShopBadgeService.ingest(shops);
        return shops;
      });

  void _retry() {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.gb;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('shops_title'.tr(),
            style: TextStyle(
                fontSize: 20.sp, fontWeight: FontWeight.bold, color: c.text)),
        SizedBox(height: 2.h),
        Text('shops_pick'.tr(),
            style: TextStyle(fontSize: 13.sp, color: c.subtext)),
        SizedBox(height: 16.h),
        FutureBuilder<List<ShopModel>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return _skeleton();
            }
            if (snap.hasError || snap.data == null) {
              return _error();
            }
            final shops = snap.data!;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (shops.where((s) => s.isOpen).length > 1) _totalCard(shops),
                for (final shop in shops) ...[
                  _shopTile(shop),
                  SizedBox(height: 10.h),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  // --------------------------------------------------------------- éléments

  Widget _totalCard(List<ShopModel> shops) {
    final c = context.gb;
    final primary = AppTheme.theme.colorScheme.primary;
    final open = shops.where((s) => s.isOpen);
    final ca = open.fold<double>(0, (a, s) => a + s.chiffreAffairesJour);
    final sales = open.fold<int>(0, (a, s) => a + s.ventesJour);
    final credit = open.fold<double>(0, (a, s) => a + s.creditMontant);
    return GestureDetector(
        onTap: () {
          Navigator.of(context).pop();
          Get.toNamed('/daily-report', arguments: {'all': true});
        },
        child: Container(
          width: double.infinity,
          margin: EdgeInsets.only(bottom: 14.h),
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.layers, size: 22.sp, color: primary),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('shops_total_today'.tr(),
                        style: TextStyle(fontSize: 11.5.sp, color: c.subtext)),
                    SizedBox(height: 2.h),
                    Text(formatFcfa(ca),
                        style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w800,
                            color: primary)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_salesLabel(sales),
                      style: TextStyle(fontSize: 12.sp, color: c.text)),
                  if (credit > 0) ...[
                    SizedBox(height: 2.h),
                    Text('shop_credit_due'.trp({'amount': formatFcfa(credit)}),
                        style: TextStyle(
                            fontSize: 11.5.sp, color: const Color(0xffD97706))),
                  ],
                ],
              ),
              SizedBox(width: 6.w),
              Icon(Icons.keyboard_arrow_right, size: 22.sp, color: primary),
            ],
          ),
        ));
  }

  String _salesLabel(int n) =>
      (n > 1 ? 'n_sales_other' : 'n_sales_one').trp({'n': '$n'});

  Widget _shopTile(ShopModel shop) {
    final c = context.gb;
    final primary = AppTheme.theme.colorScheme.primary;
    final enabled = shop.isOpen;
    final initial = shop.nom.isNotEmpty ? shop.nom[0].toUpperCase() : '?';
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: shop.active ? primary.withOpacity(0.08) : c.fill,
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: !enabled
              ? null
              : shop.active
                  ? () => Navigator.of(context).pop()
                  : () => widget.onPick(shop),
          child: Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                  color: shop.active ? primary : c.border,
                  width: shop.active ? 1.6 : 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 46.w,
                  height: 46.w,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: primary.withOpacity(0.14), shape: BoxShape.circle),
                  child: Text(initial,
                      style: TextStyle(
                          fontSize: 19.sp,
                          fontWeight: FontWeight.bold,
                          color: primary)),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(shop.nom,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 15.5.sp,
                              fontWeight: FontWeight.w700,
                              color: c.text)),
                      if ((shop.ville ?? '').isNotEmpty)
                        Text(shop.ville!,
                            style:
                                TextStyle(fontSize: 12.sp, color: c.subtext)),
                      if (ShopBadgeService.unseenFor(shop.id) > 0)
                        Padding(
                          padding: EdgeInsets.only(top: 5.h),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: const Color(0xffEF4444),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Text(
                              (ShopBadgeService.unseenFor(shop.id) > 1
                                      ? 'new_sales_other'
                                      : 'new_sales_one')
                                  .trp({
                                'n': '${ShopBadgeService.unseenFor(shop.id)}'
                              }),
                              style: TextStyle(
                                  fontSize: 10.5.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                      SizedBox(height: 6.h),
                      if (enabled) ...[
                        Text(
                          '${'shop_today'.tr()} : ${formatFcfa(shop.chiffreAffairesJour)} · ${_salesLabel(shop.ventesJour)}',
                          style: TextStyle(fontSize: 12.sp, color: c.text),
                        ),
                        if (shop.creditMontant > 0)
                          Padding(
                            padding: EdgeInsets.only(top: 3.h),
                            child: Text(
                              'shop_credit_due'.trp(
                                  {'amount': formatFcfa(shop.creditMontant)}),
                              style: TextStyle(
                                  fontSize: 11.5.sp,
                                  color: const Color(0xffD97706),
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                      ] else
                        Text('shop_inactive'.tr(),
                            style: TextStyle(
                                fontSize: 12.sp, color: Colors.red.shade400)),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                if (shop.active)
                  Icon(LucideIcons.checkCircle2, size: 24.sp, color: primary)
                else if (enabled)
                  Icon(Icons.keyboard_arrow_right,
                      size: 24.sp, color: c.subtext),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _skeleton() {
    return Column(
      children: [
        for (var i = 0; i < 2; i++) ...[
          GbSkeletonCard(
            child: Row(
              children: [
                const GbBone.circle(46),
                SizedBox(width: 14.w),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GbBone(width: 140, height: 14),
                      SizedBox(height: 8),
                      GbBone(height: 11),
                      SizedBox(height: 6),
                      GbBone(width: 120, height: 11),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10.h),
        ],
      ],
    );
  }

  Widget _error() {
    final c = context.gb;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 20.h),
      child: Column(
        children: [
          Icon(LucideIcons.wifiOff, size: 28.sp, color: c.subtext),
          SizedBox(height: 10.h),
          Text('shops_load_error'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.sp, color: c.subtext)),
          SizedBox(height: 12.h),
          OutlinedButton(onPressed: _retry, child: Text('retry'.tr())),
        ],
      ),
    );
  }
}
