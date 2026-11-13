import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:foodly/views/ui/shimmer/shimmer_widget.dart';
import 'package:foodly/widgets/gesboutik/gb_colors.dart';

/// Brique de squelette : un bloc (texte, icône, bouton, image) qui prend la
/// couleur du shimmer qui l'enveloppe.
class GbBone extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  final bool circle;

  const GbBone({super.key, this.width, required this.height, this.radius = 6})
      : circle = false;

  const GbBone.circle(double size, {super.key})
      : width = size,
        height = size,
        radius = 0,
        circle = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width?.w,
      height: height.h,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(radius.r),
      ),
    );
  }
}

/// Carte de squelette : la carte (fond, ombre) reste fixe, seul son contenu brille.
class GbSkeletonCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;

  const GbSkeletonCard({
    super.key,
    required this.child,
    this.padding,
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.gb;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(radius.r),
        border: c.isDark ? Border.all(color: c.border) : null,
        boxShadow: c.shadow,
      ),
      child: ShimmerWidget(
        child: Padding(padding: padding ?? EdgeInsets.all(14.w), child: child),
      ),
    );
  }
}

/// Squelettes qui reproduisent exactement la mise en page de chaque écran.
class GbSkeleton {
  GbSkeleton._();

  static Widget _list(int count, Widget Function() item,
      {EdgeInsets? padding}) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: padding ?? EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
      itemCount: count,
      separatorBuilder: (_, __) => SizedBox(height: 10.h),
      itemBuilder: (_, __) => item(),
    );
  }

  // ---- Produits : carte image + nom + prix + stock -------------------------

  static Widget productCard() {
    return GbSkeletonCard(
      radius: 18,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 6,
            child: Container(width: double.infinity, color: Colors.white),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 10.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const GbBone(height: 13),
                      SizedBox(height: 5.h),
                      const GbBone(width: 70, height: 13),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const GbBone(width: 90, height: 15),
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          const GbBone.circle(7),
                          SizedBox(width: 5.w),
                          const GbBone(width: 60, height: 11),
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
    );
  }

  static Widget productGrid() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 24.h),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14.h,
        crossAxisSpacing: 14.w,
        childAspectRatio: 0.74,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => productCard(),
    );
  }

  // ---- Employés : avatar + 2 lignes + badge + menu ---------------------------

  static Widget employeeList() => _list(
        6,
        () => GbSkeletonCard(
          padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
          child: Row(
            children: [
              const GbBone.circle(44),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const GbBone(width: 150, height: 14),
                    SizedBox(height: 6.h),
                    const GbBone(width: 100, height: 11),
                    SizedBox(height: 8.h),
                    const GbBone(width: 60, height: 18, radius: 10),
                  ],
                ),
              ),
              const GbBone.circle(22),
            ],
          ),
        ),
      );

  // ---- Produits archivés : vignette + 3 lignes + bouton ---------------------

  static Widget archivedList() => _list(
        6,
        () => GbSkeletonCard(
          padding: EdgeInsets.all(12.w),
          child: Row(
            children: [
              const GbBone(width: 56, height: 56, radius: 10),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const GbBone(width: 130, height: 14),
                    SizedBox(height: 6.h),
                    const GbBone(width: 80, height: 12),
                    SizedBox(height: 5.h),
                    const GbBone(width: 60, height: 11),
                  ],
                ),
              ),
              const GbBone(width: 92, height: 38, radius: 12),
            ],
          ),
        ),
      );

  // ---- Ventes : icône + 2 lignes + montant -----------------------------------

  static Widget saleRow() => GbSkeletonCard(
        radius: 18,
        child: Row(
          children: [
            const GbBone(width: 40, height: 40, radius: 11),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const GbBone(width: 110, height: 14),
                  SizedBox(height: 6.h),
                  const GbBone(width: 140, height: 11),
                ],
              ),
            ),
            const GbBone(width: 80, height: 16),
          ],
        ),
      );

  static Widget saleList() => _list(7, saleRow);

  // ---- Nouvelle vente : nom + prix/stock + bouton rond -----------------------

  static Widget sellableProductList() => _list(
        7,
        () => GbSkeletonCard(
          radius: 12,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const GbBone(width: 130, height: 15),
                    SizedBox(height: 6.h),
                    const GbBone(width: 190, height: 12),
                  ],
                ),
              ),
              const GbBone.circle(30),
            ],
          ),
        ),
        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 100.h),
      );

  // ---- Accueil : cartes de chiffres + résumé ---------------------------------

  static Widget dashboardStatRow() {
    Widget card() => Expanded(
          child: GbSkeletonCard(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
            child: Row(
              children: [
                const GbBone(width: 40, height: 40, radius: 11),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const GbBone(width: 60, height: 18),
                      SizedBox(height: 6.h),
                      const GbBone(width: 90, height: 11),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
    return Row(children: [card(), SizedBox(width: 12.w), card()]);
  }

  /// Les trois cartes « Aujourd'hui / Ce mois / Cette année ».
  static Widget dashboardTotalsRow() {
    Widget card() => Expanded(
          child: GbSkeletonCard(
            padding: EdgeInsets.all(12.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const GbBone(width: 70, height: 11),
                SizedBox(height: 12.h),
                const GbBone(width: 80, height: 16),
                SizedBox(height: 6.h),
                const GbBone(width: 55, height: 11),
              ],
            ),
          ),
        );
    return Row(children: [
      card(),
      SizedBox(width: 10.w),
      card(),
      SizedBox(width: 10.w),
      card(),
    ]);
  }

  /// Résultat d'une période : montant, puis deux mini-cartes.
  static Widget periodResult() {
    return ShimmerWidget(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GbBone(width: 110, height: 12),
          SizedBox(height: 8.h),
          const GbBone(width: 190, height: 28),
          SizedBox(height: 14.h),
          Row(
            children: [
              Expanded(child: GbBone(height: 46, radius: 12)),
              SizedBox(width: 10.w),
              Expanded(child: GbBone(height: 46, radius: 12)),
            ],
          ),
        ],
      ),
    );
  }

  static Widget dashboardOverview() {
    Widget tile() => GbSkeletonCard(
          padding: EdgeInsets.all(12.w),
          radius: 12,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const GbBone(width: 70, height: 11),
              SizedBox(height: 6.h),
              const GbBone(width: 100, height: 17),
            ],
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShimmerWidget(child: const GbBone(width: 150, height: 17)),
        SizedBox(height: 12.h),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10.h,
          crossAxisSpacing: 10.w,
          childAspectRatio: 2.1,
          children: List.generate(4, (_) => tile()),
        ),
      ],
    );
  }

  // ---- Fiche employé -----------------------------------------------------------

  static Widget employeeStatTile() => Expanded(
        child: GbSkeletonCard(
          padding: EdgeInsets.all(14.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const GbBone(width: 33, height: 33, radius: 10),
              SizedBox(height: 10.h),
              const GbBone(width: 80, height: 16),
              SizedBox(height: 6.h),
              const GbBone(width: 100, height: 11),
            ],
          ),
        ),
      );
}
