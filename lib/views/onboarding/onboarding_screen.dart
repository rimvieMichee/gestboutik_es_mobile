import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart' hide Trans;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:foodly/helpers/extensions/string.dart';
import 'package:foodly/helpers/storage/local_storage.dart';
import 'package:foodly/helpers/theme/app_theme.dart';
import 'package:foodly/widgets/gesboutik/gb_colors.dart';

/// Présentation de SELIO au premier lancement : quatre écrans qui montrent
/// ce que l'application apporte au commerçant. Rejouable depuis les Paramètres
/// (`Get.toNamed('/onboarding', arguments: {'replay': true})`).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pages = PageController();
  int _index = 0;
  static const _count = 4;

  bool get _replay {
    final a = Get.arguments;
    return a is Map && a['replay'] == true;
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await LocalStorage.setOnboardingDone();
    if (_replay) {
      Get.back();
    } else {
      Get.offAllNamed('/auth/login');
    }
  }

  void _next() {
    HapticFeedback.selectionClick();
    if (_index == _count - 1) {
      _finish();
    } else {
      _pages.nextPage(
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.gb;
    final primary = AppTheme.theme.colorScheme.primary;
    final last = _index == _count - 1;
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 8.h, 12.w, 0),
              child: Row(
                children: [
                  Text('SELIO',
                      style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          color: primary)),
                  const Spacer(),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: last ? 0 : 1,
                    child: TextButton(
                      onPressed: last ? null : _finish,
                      child: Text('ob_skip'.tr(),
                          style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: c.subtext)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                onPageChanged: (i) => setState(() => _index = i),
                children: const [
                  _Slide(index: 0),
                  _Slide(index: 1),
                  _Slide(index: 2),
                  _Slide(index: 3),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_count, (i) {
                final on = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                  width: on ? 26.w : 8.w,
                  height: 8.w,
                  decoration: BoxDecoration(
                    color: on ? primary : c.border,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                );
              }),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 22.h, 24.w, 22.h),
              child: SizedBox(
                width: double.infinity,
                height: 56.h,
                child: FilledButton(
                  onPressed: _next,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.r)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text((last ? 'ob_start' : 'ob_next').tr(),
                          style: TextStyle(
                              fontSize: 16.sp, fontWeight: FontWeight.w800)),
                      SizedBox(width: 8.w),
                      Icon(last ? LucideIcons.check : LucideIcons.arrowRight,
                          size: 20.sp),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  final int index;
  const _Slide({required this.index});

  @override
  Widget build(BuildContext context) {
    final c = context.gb;
    final primary = AppTheme.theme.colorScheme.primary;
    final illustrations = [
      const _ControlArt(),
      const _TeamArt(),
      const _StockArt(),
      const _MoreArt(),
    ];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        children: [
          SizedBox(height: 12.h),
          Expanded(
            flex: 11,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32.r),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primary.withOpacity(c.isDark ? 0.22 : 0.14),
                    primary.withOpacity(c.isDark ? 0.08 : 0.04),
                  ],
                ),
              ),
              child: Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, child) => Opacity(
                    opacity: v,
                    child: Transform.translate(
                        offset: Offset(0, (1 - v) * 24), child: child),
                  ),
                  child: illustrations[index],
                ),
              ),
            ),
          ),
          SizedBox(height: 24.h),
          // Hauteur fixe : l'illustration ne saute pas d'un écran à l'autre.
          SizedBox(
            height: 168.h,
            child: Column(
              children: [
                Text('ob_t${index + 1}'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 25.sp,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                        color: c.text)),
                SizedBox(height: 12.h),
                Text('ob_d${index + 1}'.tr(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 14.5.sp, height: 1.5, color: c.subtext)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------- illustrations

BoxDecoration _card(BuildContext context, {Color? color, double radius = 20}) {
  final c = context.gb;
  return BoxDecoration(
    color: color ?? c.surface,
    borderRadius: BorderRadius.circular(radius.r),
    boxShadow: [
      BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 22,
          offset: const Offset(0, 10)),
    ],
  );
}

/// 1 · Tout est au même endroit : chiffre du jour, ventes, crédits.
class _ControlArt extends StatelessWidget {
  const _ControlArt();

  @override
  Widget build(BuildContext context) {
    final c = context.gb;
    final primary = AppTheme.theme.colorScheme.primary;
    Widget tile(IconData icon, String label, String value, Color col) => Expanded(
          child: Container(
            padding: EdgeInsets.all(12.w),
            decoration: _card(context, radius: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 18.sp, color: col),
                SizedBox(height: 8.h),
                Text(value,
                    style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w800,
                        color: c.text)),
                Text(label,
                    style: TextStyle(fontSize: 11.sp, color: c.subtext)),
              ],
            ),
          ),
        );
    return SizedBox(
      width: 290.w,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(18.w),
            decoration: _card(context, color: primary, radius: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.store, size: 18.sp, color: Colors.white70),
                    SizedBox(width: 8.w),
                    Text('ob_m_sales_today'.tr(),
                        style:
                            TextStyle(fontSize: 13.sp, color: Colors.white70)),
                  ],
                ),
                SizedBox(height: 10.h),
                Text('84 500 FCFA',
                    style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white)),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              tile(LucideIcons.shoppingBag, 'ob_m_sales'.tr(), '12', primary),
              SizedBox(width: 12.w),
              tile(LucideIcons.package, 'ob_m_products'.tr(), '48',
                  const Color(0xff3B5BDB)),
              SizedBox(width: 12.w),
              tile(LucideIcons.users, 'ob_m_team'.tr(), '3',
                  const Color(0xffD97706)),
            ],
          ),
        ],
      ),
    );
  }
}

/// 2 · L'employé vend, le gestionnaire voit la vente arriver en direct.
class _TeamArt extends StatefulWidget {
  const _TeamArt();

  @override
  State<_TeamArt> createState() => _TeamArtState();
}

class _TeamArtState extends State<_TeamArt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1800))
    ..repeat();

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.gb;
    final primary = AppTheme.theme.colorScheme.primary;
    Widget person(IconData icon, String label, Color col) => Column(
          children: [
            Container(
              width: 66.w,
              height: 66.w,
              decoration: BoxDecoration(
                  color: col.withOpacity(0.14), shape: BoxShape.circle),
              child: Icon(icon, size: 30.sp, color: col),
            ),
            SizedBox(height: 8.h),
            Text(label,
                style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: c.text)),
          ],
        );
    return SizedBox(
      width: 300.w,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              person(LucideIcons.shoppingCart, 'ob_m_employee'.tr(), primary),
              Expanded(
                child: SizedBox(
                  height: 40.h,
                  child: AnimatedBuilder(
                    animation: _ctl,
                    builder: (_, __) => CustomPaint(
                        painter: _FlowPainter(_ctl.value, primary)),
                  ),
                ),
              ),
              person(LucideIcons.layoutDashboard, 'ob_m_manager'.tr(),
                  const Color(0xff3B5BDB)),
            ],
          ),
          SizedBox(height: 26.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(14.w),
            decoration: _card(context),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                      color: primary.withOpacity(0.14), shape: BoxShape.circle),
                  child: Icon(LucideIcons.check, size: 18.sp, color: primary),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ob_m_sale_saved'.tr(),
                          style: TextStyle(
                              fontSize: 13.5.sp,
                              fontWeight: FontWeight.w800,
                              color: c.text)),
                      Text('ob_m_live'.tr(),
                          style:
                              TextStyle(fontSize: 11.5.sp, color: c.subtext)),
                    ],
                  ),
                ),
                Container(
                  width: 10.w,
                  height: 10.w,
                  decoration: BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: primary.withOpacity(0.5), blurRadius: 8)
                      ]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowPainter extends CustomPainter {
  final double t;
  final Color color;
  _FlowPainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2 - 12;
    final line = Paint()
      ..color = color.withOpacity(0.25)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(8, y), Offset(size.width - 8, y), line);
    for (var i = 0; i < 3; i++) {
      final p = ((t + i / 3) % 1.0);
      final x = 8 + (size.width - 16) * p;
      canvas.drawCircle(
          Offset(x, y), 6, Paint()..color = color.withOpacity(math.sin(p * math.pi)));
    }
  }

  @override
  bool shouldRepaint(_FlowPainter old) => old.t != t;
}

/// 3 · Alerte avant la rupture de stock.
class _StockArt extends StatelessWidget {
  const _StockArt();

  @override
  Widget build(BuildContext context) {
    final c = context.gb;
    const red = Color(0xffE5484D);
    const amber = Color(0xffF59E0B);
    return SizedBox(
      width: 300.w,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(14.w),
            decoration: _card(context),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                      color: amber.withOpacity(0.16), shape: BoxShape.circle),
                  child: Icon(LucideIcons.bell, size: 22.sp, color: amber),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ob_m_low_stock'.tr(),
                          style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w800,
                              color: red)),
                      SizedBox(height: 2.h),
                      Text('ob_m_low_body'.tr(),
                          style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: c.text)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 18.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: _card(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('ob_m_rice'.tr(),
                        style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                            color: c.text)),
                    const Spacer(),
                    Text('2 / 24',
                        style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w800,
                            color: red)),
                  ],
                ),
                SizedBox(height: 10.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: LinearProgressIndicator(
                    value: 2 / 24,
                    minHeight: 10.h,
                    backgroundColor: c.fill,
                    valueColor: const AlwaysStoppedAnimation(red),
                  ),
                ),
                SizedBox(height: 14.h),
                Row(
                  children: [
                    Icon(LucideIcons.packagePlus,
                        size: 16.sp, color: AppTheme.theme.colorScheme.primary),
                    SizedBox(width: 8.w),
                    Text('ob_m_restock'.tr(),
                        style: TextStyle(
                            fontSize: 12.5.sp,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.theme.colorScheme.primary)),
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

/// 4 · Crédits, rapport du jour et plusieurs boutiques.
class _MoreArt extends StatelessWidget {
  const _MoreArt();

  @override
  Widget build(BuildContext context) {
    final c = context.gb;
    final primary = AppTheme.theme.colorScheme.primary;
    Widget row(IconData icon, String title, String sub, Color col) => Container(
          width: double.infinity,
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(14.w),
          decoration: _card(context),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                    color: col.withOpacity(0.14), shape: BoxShape.circle),
                child: Icon(icon, size: 20.sp, color: col),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                            color: c.text)),
                    Text(sub,
                        style: TextStyle(fontSize: 11.5.sp, color: c.subtext)),
                  ],
                ),
              ),
            ],
          ),
        );
    return SizedBox(
      width: 300.w,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          row(LucideIcons.creditCard, 'ob_m_credit'.tr(), 'ob_m_credit_sub'.tr(),
              const Color(0xffD97706)),
          row(LucideIcons.fileText, 'ob_m_pdf'.tr(), 'ob_m_pdf_sub'.tr(), primary),
          row(LucideIcons.store, 'ob_m_shops'.tr(), 'ob_m_shops_sub'.tr(),
              const Color(0xff3B5BDB)),
        ],
      ),
    );
  }
}
