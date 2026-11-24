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

/// Présentation de SELIO au premier lancement : quatre écrans animés qui
/// montrent ce que l'application apporte au commerçant. Rejouable depuis les
/// Paramètres (`Get.toNamed('/onboarding', arguments: {'replay': true})`).
///
/// Tout est piloté par la position du `PageView` : le fond change de teinte,
/// les halos et les illustrations défilent en parallaxe, les textes glissent
/// plus doucement que les visuels, et chaque illustration joue sa propre
/// animation d'entrée quand elle arrive à l'écran.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  static const _count = 4;

  final _pages = PageController();
  late final AnimationController _ambient = AnimationController(
      vsync: this, duration: const Duration(seconds: 8))
    ..repeat();
  double _page = 0;

  /// Teinte propre à chaque écran ; le fond glisse de l'une à l'autre.
  List<Color> get _tints => [
        AppTheme.theme.colorScheme.primary,
        const Color(0xff0EA5A4),
        const Color(0xffF59E0B),
        const Color(0xff3B5BDB),
      ];

  bool get _replay {
    final a = Get.arguments;
    return a is Map && a['replay'] == true;
  }

  @override
  void initState() {
    super.initState();
    _pages.addListener(() {
      final p = _pages.hasClients ? (_pages.page ?? 0) : 0.0;
      if (p != _page) setState(() => _page = p);
    });
  }

  @override
  void dispose() {
    _pages.dispose();
    _ambient.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    HapticFeedback.mediumImpact();
    await LocalStorage.setOnboardingDone();
    if (_replay) {
      Get.back();
    } else {
      Get.offAllNamed('/auth/login');
    }
  }

  void _next() {
    HapticFeedback.selectionClick();
    if (_page.round() >= _count - 1) {
      _finish();
    } else {
      _pages.nextPage(
          duration: const Duration(milliseconds: 520),
          curve: Curves.easeOutQuart);
    }
  }

  Color get _tint {
    final i = _page.floor().clamp(0, _count - 1);
    final j = (i + 1).clamp(0, _count - 1);
    return Color.lerp(_tints[i], _tints[j], _page - i) ?? _tints[i];
  }

  @override
  Widget build(BuildContext context) {
    final c = context.gb;
    final size = MediaQuery.of(context).size;
    final tint = _tint;
    final lastIndex = _page.round() >= _count - 1;
    return Scaffold(
      backgroundColor: c.background,
      body: Stack(
        children: [
          // Fond : dégradé teinté + halos en parallaxe.
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _ambient,
              builder: (_, __) => CustomPaint(
                painter: _BackdropPainter(
                  page: _page,
                  t: _ambient.value,
                  tint: tint,
                  dark: c.isDark,
                  base: c.background,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _header(c, tint, lastIndex),
                Expanded(
                  child: PageView.builder(
                    controller: _pages,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _count,
                    itemBuilder: (_, i) => _SlidePage(
                      index: i,
                      delta: _page - i,
                      width: size.width,
                      ambient: _ambient,
                      tint: _tints[i],
                    ),
                  ),
                ),
                _indicator(c, tint),
                _button(tint, lastIndex),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(GbColors c, Color tint, bool last) {
    final n = (_page.round() + 1).clamp(1, _count);
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 10.h, 12.w, 0),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: Image.asset('assets/images/logo/selio_icon.png',
                width: 34.w, height: 34.w),
          ),
          SizedBox(width: 10.w),
          Text('SELIO',
              style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.2,
                  color: c.text)),
          const Spacer(),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text('0$n / 0$_count',
                key: ValueKey(n),
                style: TextStyle(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: c.subtext)),
          ),
          SizedBox(width: 6.w),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 220),
            opacity: last ? 0 : 1,
            child: TextButton(
              onPressed: last ? null : _finish,
              child: Text('ob_skip'.tr(),
                  style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: tint)),
            ),
          ),
        ],
      ),
    );
  }

  /// Indicateur « liquide » : la pastille active s'étire en suivant le doigt.
  Widget _indicator(GbColors c, Color tint) {
    return Padding(
      padding: EdgeInsets.only(top: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_count, (i) {
          final near = (1 - (_page - i).abs()).clamp(0.0, 1.0);
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 4.w),
            width: 8.w + 26.w * near,
            height: 8.w,
            decoration: BoxDecoration(
              color: Color.lerp(c.border, tint, near),
              borderRadius: BorderRadius.circular(8.r),
            ),
          );
        }),
      ),
    );
  }

  Widget _button(Color tint, bool last) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 22.h),
      child: GestureDetector(
        onTap: _next,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          height: 58.h,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [tint, Color.lerp(tint, Colors.black, 0.22)!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20.r),
            boxShadow: [
              BoxShadow(
                color: tint.withOpacity(last ? 0.5 : 0.32),
                blurRadius: last ? 26 : 18,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween(
                          begin: const Offset(0, 0.4), end: Offset.zero)
                      .animate(anim),
                  child: child,
                ),
              ),
              child: Row(
                key: ValueKey(last),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text((last ? 'ob_start' : 'ob_next').tr(),
                      style: TextStyle(
                          fontSize: 16.5.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                  SizedBox(width: 10.w),
                  Icon(last ? LucideIcons.rocket : LucideIcons.arrowRight,
                      size: 20.sp, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- fond animé

class _BackdropPainter extends CustomPainter {
  final double page;
  final double t;
  final Color tint;
  final bool dark;
  final Color base;

  _BackdropPainter({
    required this.page,
    required this.t,
    required this.tint,
    required this.dark,
    required this.base,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    // Dégradé vertical teinté, très doux.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(base, tint, dark ? 0.20 : 0.12)!,
            base,
            Color.lerp(base, tint, dark ? 0.12 : 0.05)!,
          ],
          stops: const [0, 0.55, 1],
        ).createShader(Offset.zero & size),
    );
    // Halos qui flottent et défilent plus lentement que les pages.
    void blob(double fx, double fy, double r, double speed, double phase,
        double alpha) {
      final dx = -page * w * speed + math.sin((t + phase) * 2 * math.pi) * 22;
      final dy = math.cos((t + phase) * 2 * math.pi) * 18;
      final center = Offset(w * fx + dx, h * fy + dy);
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..shader = RadialGradient(colors: [
            tint.withOpacity(alpha),
            tint.withOpacity(0),
          ]).createShader(Rect.fromCircle(center: center, radius: r)),
      );
    }

    blob(0.85, 0.16, w * 0.62, 0.18, 0.0, dark ? 0.34 : 0.26);
    blob(0.10, 0.52, w * 0.55, 0.30, 0.33, dark ? 0.26 : 0.18);
    blob(0.78, 0.86, w * 0.7, 0.12, 0.66, dark ? 0.24 : 0.16);
  }

  @override
  bool shouldRepaint(_BackdropPainter o) =>
      o.page != page || o.t != t || o.tint != tint;
}

// -------------------------------------------------------------------- écrans

class _SlidePage extends StatelessWidget {
  final int index;

  /// Écart à la page courante : 0 = affichée, ±1 = voisine.
  final double delta;
  final double width;
  final Animation<double> ambient;
  final Color tint;

  const _SlidePage({
    required this.index,
    required this.delta,
    required this.width,
    required this.ambient,
    required this.tint,
  });

  /// Texte avec un passage mis en valeur : `*mots*` prend la teinte de l'écran.
  List<InlineSpan> _title(String raw, TextStyle base) {
    final spans = <InlineSpan>[];
    final parts = raw.split('*');
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty) continue;
      spans.add(TextSpan(
        text: parts[i],
        style: i.isOdd ? base.copyWith(color: tint) : base,
      ));
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.gb;
    final d = delta.clamp(-1.0, 1.0);
    final away = d.abs();
    final active = away < 0.8;
    final art = switch (index) {
      0 => _ControlArt(active: active, ambient: ambient, tint: tint),
      1 => _TeamArt(active: active, ambient: ambient, tint: tint),
      2 => _StockArt(active: active, ambient: ambient, tint: tint),
      _ => _MoreArt(active: active, ambient: ambient, tint: tint),
    };
    final base = TextStyle(
        fontSize: 27.sp, height: 1.18, fontWeight: FontWeight.w900, color: c.text);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        children: [
          SizedBox(height: 8.h),
          // Illustration : défile plus vite que les textes (profondeur).
          Expanded(
            flex: 11,
            child: Opacity(
              opacity: (1 - away * 1.3).clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(-d * width * 0.42, 0),
                child: Transform.scale(
                  scale: 1 - away * 0.12,
                  child: Center(child: art),
                ),
              ),
            ),
          ),
          SizedBox(height: 20.h),
          Opacity(
            opacity: (1 - away * 1.6).clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(-d * width * 0.14, 0),
              child: SizedBox(
                height: 172.h,
                child: Column(
                  children: [
                    Text.rich(
                      TextSpan(children: _title('ob_t${index + 1}'.tr(), base)),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 12.h),
                    Text('ob_d${index + 1}'.tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 14.5.sp,
                            height: 1.55,
                            color: c.subtext)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------- briques d'illustration

/// Joue [builder] avec une progression 0→1 chaque fois que l'écran devient actif.
class _Entrance extends StatefulWidget {
  final bool active;
  final Widget Function(BuildContext, double t) builder;
  const _Entrance({
    required this.active,
    required this.builder,
  });

  @override
  State<_Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<_Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1700));

  @override
  void initState() {
    super.initState();
    if (widget.active) _c.forward();
  }

  @override
  void didUpdateWidget(_Entrance old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) {
      _c.forward(from: 0);
    } else if (!widget.active && old.active) {
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      AnimatedBuilder(animation: _c, builder: (_, __) => widget.builder(context, _c.value));
}

/// Sous-intervalle d'une progression : 0 avant [a], 1 après [b], courbe douce.
double _seg(double t, double a, double b, [Curve curve = Curves.easeOutCubic]) =>
    curve.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

/// Apparition : fondu + glissement vertical + léger zoom.
Widget _pop(double p, Widget child, {double dy = 26, double from = 0.92}) =>
    Opacity(
      opacity: p.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, (1 - p) * dy),
        child: Transform.scale(scale: from + (1 - from) * p, child: child),
      ),
    );

BoxDecoration _glass(BuildContext context, {double radius = 22, Color? color}) {
  final c = context.gb;
  return BoxDecoration(
    color: color ?? c.surface,
    borderRadius: BorderRadius.circular(radius.r),
    border: Border.all(color: c.isDark ? c.border : Colors.white.withOpacity(0.7)),
    boxShadow: [
      BoxShadow(
          color: Colors.black.withOpacity(c.isDark ? 0.3 : 0.09),
          blurRadius: 26,
          offset: const Offset(0, 12)),
    ],
  );
}

/// Petit flottement continu (haut/bas) pour donner de la vie.
Widget _float(Animation<double> ambient, double phase, double amp, Widget child) =>
    AnimatedBuilder(
      animation: ambient,
      builder: (_, c) => Transform.translate(
        offset: Offset(0, math.sin((ambient.value + phase) * 2 * math.pi) * amp),
        child: c,
      ),
      child: child,
    );

// ----------------------------------------------------------- 1 · le contrôle

class _ControlArt extends StatelessWidget {
  final bool active;
  final Animation<double> ambient;
  final Color tint;
  const _ControlArt(
      {required this.active, required this.ambient, required this.tint});

  @override
  Widget build(BuildContext context) {
    final c = context.gb;
    return _Entrance(
      active: active,
      builder: (context, t) {
        final amount = (84500 * _seg(t, 0.15, 0.7, Curves.easeOutQuart)).round();
        String fmt(int v) => v
            .toString()
            .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ' ');
        final bars = [0.38, 0.55, 0.42, 0.72, 0.6, 0.88, 1.0];
        Widget tile(IconData icon, String label, String value, Color col, int k) =>
            Expanded(
              child: _pop(
                _seg(t, 0.45 + k * 0.1, 0.8 + k * 0.1, Curves.easeOutBack),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: _glass(context, radius: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, size: 18.sp, color: col),
                      SizedBox(height: 8.h),
                      Text(value,
                          style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w900,
                              color: c.text)),
                      Text(label,
                          style: TextStyle(fontSize: 11.sp, color: c.subtext)),
                    ],
                  ),
                ),
              ),
            );
        return SizedBox(
          width: 300.w,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _float(
                ambient,
                0,
                5,
                _pop(
                  _seg(t, 0, 0.4),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 14.h),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [tint, Color.lerp(tint, Colors.black, 0.28)!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(26.r),
                      boxShadow: [
                        BoxShadow(
                            color: tint.withOpacity(0.4),
                            blurRadius: 28,
                            offset: const Offset(0, 14)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(LucideIcons.store,
                                size: 17.sp, color: Colors.white70),
                            SizedBox(width: 8.w),
                            Text('ob_m_sales_today'.tr(),
                                style: TextStyle(
                                    fontSize: 13.sp, color: Colors.white70)),
                            const Spacer(),
                            _LiveDot(ambient: ambient),
                          ],
                        ),
                        SizedBox(height: 10.h),
                        Text('${fmt(amount)} FCFA',
                            style: TextStyle(
                                fontSize: 29.sp,
                                fontWeight: FontWeight.w900,
                                color: Colors.white)),
                        SizedBox(height: 14.h),
                        SizedBox(
                          height: 46.h,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              for (var i = 0; i < bars.length; i++) ...[
                                if (i > 0) SizedBox(width: 6.w),
                                Expanded(
                                  child: FractionallySizedBox(
                                    heightFactor: bars[i] *
                                        _seg(t, 0.25 + i * 0.05, 0.75 + i * 0.05,
                                            Curves.easeOutBack),
                                    alignment: Alignment.bottomCenter,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(
                                            i == bars.length - 1 ? 0.95 : 0.4),
                                        borderRadius: BorderRadius.circular(6.r),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  dy: 40,
                ),
              ),
              SizedBox(height: 14.h),
              Row(
                children: [
                  tile(LucideIcons.shoppingBag, 'ob_m_sales'.tr(), '12', tint, 0),
                  SizedBox(width: 12.w),
                  tile(LucideIcons.package, 'ob_m_products'.tr(), '48',
                      const Color(0xff3B5BDB), 1),
                  SizedBox(width: 12.w),
                  tile(LucideIcons.users, 'ob_m_team'.tr(), '3',
                      const Color(0xffD97706), 2),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LiveDot extends StatelessWidget {
  final Animation<double> ambient;
  const _LiveDot({required this.ambient});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ambient,
      builder: (_, __) {
        final k = (math.sin(ambient.value * 2 * math.pi * 4) + 1) / 2;
        return Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: Colors.white.withOpacity(0.3 + 0.5 * k),
                      blurRadius: 4 + 8 * k)
                ],
              ),
            ),
            SizedBox(width: 6.w),
            Text('LIVE',
                style: TextStyle(
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: Colors.white)),
          ],
        );
      },
    );
  }
}

// ------------------------------------------------------------- 2 · l'équipe

class _TeamArt extends StatelessWidget {
  final bool active;
  final Animation<double> ambient;
  final Color tint;
  const _TeamArt(
      {required this.active, required this.ambient, required this.tint});

  @override
  Widget build(BuildContext context) {
    final c = context.gb;
    Widget person(IconData icon, String label, Color col, double p) => _pop(
          p,
          Column(
            children: [
              Container(
                width: 70.w,
                height: 70.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [col, Color.lerp(col, Colors.black, 0.25)!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: col.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8)),
                  ],
                ),
                child: Icon(icon, size: 30.sp, color: Colors.white),
              ),
              SizedBox(height: 10.h),
              Text(label,
                  style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                      color: c.text)),
            ],
          ),
          from: 0.7,
        );
    return _Entrance(
      active: active,
      builder: (context, t) {
        return SizedBox(
          width: 310.w,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  person(LucideIcons.shoppingCart, 'ob_m_employee'.tr(), tint,
                      _seg(t, 0, 0.3, Curves.easeOutBack)),
                  Expanded(
                    child: SizedBox(
                      height: 56.h,
                      child: AnimatedBuilder(
                        animation: ambient,
                        builder: (_, __) => CustomPaint(
                          painter: _FlowPainter(
                              ambient.value * 3 % 1.0,
                              tint,
                              _seg(t, 0.25, 0.55, Curves.easeOut)),
                        ),
                      ),
                    ),
                  ),
                  person(LucideIcons.layoutDashboard, 'ob_m_manager'.tr(),
                      const Color(0xff3B5BDB),
                      _seg(t, 0.1, 0.4, Curves.easeOutBack)),
                ],
              ),
              SizedBox(height: 24.h),
              _pop(
                _seg(t, 0.5, 0.85, Curves.easeOutBack),
                _float(
                  ambient,
                  0.2,
                  4,
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(14.w),
                    decoration: _glass(context),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Transform.scale(
                              scale: _seg(t, 0.6, 0.9, Curves.elasticOut),
                              child: Container(
                                padding: EdgeInsets.all(8.w),
                                decoration: BoxDecoration(
                                    color: tint.withOpacity(0.15),
                                    shape: BoxShape.circle),
                                child: Icon(LucideIcons.check,
                                    size: 18.sp, color: tint),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('ob_m_sale_saved'.tr(),
                                      style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w800,
                                          color: c.text)),
                                  Text('ob_m_live'.tr(),
                                      style: TextStyle(
                                          fontSize: 11.5.sp,
                                          color: c.subtext)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        for (var i = 0; i < 2; i++)
                          Opacity(
                            opacity: _seg(t, 0.75 + i * 0.1, 1.0),
                            child: Padding(
                              padding: EdgeInsets.only(top: i == 0 ? 0 : 6.h),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                        color: i == 0
                                            ? const Color(0xffF59E0B)
                                            : const Color(0xff3B5BDB),
                                        shape: BoxShape.circle),
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(i == 0 ? 'ob_m_line1'.tr() : 'ob_m_line2'.tr(),
                                      style: TextStyle(
                                          fontSize: 12.sp, color: c.subtext)),
                                  const Spacer(),
                                  Text(i == 0 ? '18 000' : '9 000',
                                      style: TextStyle(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w800,
                                          color: c.text)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                dy: 34,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FlowPainter extends CustomPainter {
  final double t;
  final Color color;
  final double reveal;
  _FlowPainter(this.t, this.color, this.reveal);

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2 - 14;
    final from = 6.0, to = size.width - 6.0;
    final end = from + (to - from) * reveal;
    canvas.drawLine(
      Offset(from, y),
      Offset(end, y),
      Paint()
        ..color = color.withOpacity(0.22)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    if (reveal < 0.95) return;
    for (var i = 0; i < 4; i++) {
      final p = (t + i / 4) % 1.0;
      final x = from + (to - from) * p;
      final a = math.sin(p * math.pi);
      canvas.drawCircle(Offset(x, y), 9, Paint()..color = color.withOpacity(0.18 * a));
      canvas.drawCircle(Offset(x, y), 5, Paint()..color = color.withOpacity(a));
    }
  }

  @override
  bool shouldRepaint(_FlowPainter o) => o.t != t || o.reveal != reveal;
}

// --------------------------------------------------------------- 3 · le stock

class _StockArt extends StatelessWidget {
  final bool active;
  final Animation<double> ambient;
  final Color tint;
  const _StockArt(
      {required this.active, required this.ambient, required this.tint});

  @override
  Widget build(BuildContext context) {
    final c = context.gb;
    const red = Color(0xffE5484D);
    const amber = Color(0xffF59E0B);
    return _Entrance(
      active: active,
      builder: (context, t) {
        // La jauge se vide puis vire au rouge.
        final fill = 1 - (1 - 2 / 24) * _seg(t, 0.15, 0.7, Curves.easeInOutCubic);
        final gauge = Color.lerp(const Color(0xff16A34A), red, _seg(t, 0.35, 0.7))!;
        final shake = t > 0.55 && t < 0.95
            ? math.sin((t - 0.55) * 60) * 0.22 * (1 - (t - 0.55) / 0.4)
            : 0.0;
        return SizedBox(
          width: 310.w,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Notification qui tombe du haut.
              _pop(
                _seg(t, 0.5, 0.85, Curves.easeOutBack),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(14.w),
                  decoration: _glass(context),
                  child: Row(
                    children: [
                      Transform.rotate(
                        angle: shake,
                        child: Container(
                          padding: EdgeInsets.all(11.w),
                          decoration: BoxDecoration(
                              color: amber.withOpacity(0.18),
                              shape: BoxShape.circle),
                          child: Icon(LucideIcons.bell, size: 22.sp, color: amber),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ob_m_low_stock'.tr(),
                                style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w900,
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
                dy: -40,
              ),
              SizedBox(height: 16.h),
              _float(
                ambient,
                0.4,
                4,
                _pop(
                  _seg(t, 0, 0.4, Curves.easeOutBack),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.w),
                    decoration: _glass(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8.w),
                              decoration: BoxDecoration(
                                  color: const Color(0xffF2B84B).withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(11.r)),
                              child: Icon(LucideIcons.package,
                                  size: 18.sp, color: const Color(0xffB7791F)),
                            ),
                            SizedBox(width: 10.w),
                            Text('ob_m_rice'.tr(),
                                style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w800,
                                    color: c.text)),
                            const Spacer(),
                            Text('${(24 * fill).ceil().clamp(2, 24)} / 24',
                                style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w900,
                                    color: gauge)),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: Stack(
                            children: [
                              Container(height: 12.h, color: c.fill),
                              FractionallySizedBox(
                                widthFactor: fill,
                                child: Container(height: 12.h, color: gauge),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 14.h),
                        _pop(
                          _seg(t, 0.8, 1.0),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12.w, vertical: 8.h),
                            decoration: BoxDecoration(
                              color: tint.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(LucideIcons.packagePlus,
                                    size: 16.sp, color: tint),
                                SizedBox(width: 8.w),
                                Text('ob_m_restock'.tr(),
                                    style: TextStyle(
                                        fontSize: 12.5.sp,
                                        fontWeight: FontWeight.w800,
                                        color: tint)),
                              ],
                            ),
                          ),
                          dy: 10,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ------------------------------------------------------------- 4 · et plus

class _MoreArt extends StatelessWidget {
  final bool active;
  final Animation<double> ambient;
  final Color tint;
  const _MoreArt(
      {required this.active, required this.ambient, required this.tint});

  @override
  Widget build(BuildContext context) {
    final c = context.gb;
    Widget row(int k, double t, IconData icon, String title, String sub,
        Color col, double tilt) {
      final p = _seg(t, 0.1 + k * 0.18, 0.55 + k * 0.18, Curves.easeOutBack);
      return Opacity(
        opacity: p.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset((1 - p) * (k.isEven ? -60 : 60), (1 - p) * 30),
          child: Transform.rotate(
            angle: (1 - p) * tilt,
            child: _float(
              ambient,
              k * 0.17,
              3.5,
              Container(
                width: double.infinity,
                margin: EdgeInsets.only(bottom: 14.h),
                padding: EdgeInsets.all(15.w),
                decoration: _glass(context),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(11.w),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [col, Color.lerp(col, Colors.black, 0.25)!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: Icon(icon, size: 21.sp, color: Colors.white),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: TextStyle(
                                  fontSize: 14.5.sp,
                                  fontWeight: FontWeight.w900,
                                  color: c.text)),
                          SizedBox(height: 2.h),
                          Text(sub,
                              style: TextStyle(
                                  fontSize: 11.5.sp, color: c.subtext)),
                        ],
                      ),
                    ),
                    Icon(LucideIcons.chevronRight, size: 18.sp, color: c.subtext),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return _Entrance(
      active: active,
      builder: (context, t) => SizedBox(
        width: 310.w,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            row(0, t, LucideIcons.creditCard, 'ob_m_credit'.tr(),
                'ob_m_credit_sub'.tr(), const Color(0xffD97706), -0.06),
            row(1, t, LucideIcons.fileText, 'ob_m_pdf'.tr(), 'ob_m_pdf_sub'.tr(),
                tint, 0.05),
            row(2, t, LucideIcons.store, 'ob_m_shops'.tr(),
                'ob_m_shops_sub'.tr(), const Color(0xff0EA5A4), -0.05),
          ],
        ),
      ),
    );
  }
}
