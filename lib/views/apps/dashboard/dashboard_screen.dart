import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:foodly/controller/apps/dashboard/dashboard_controller.dart';
import 'package:foodly/helpers/theme/app_theme.dart';
import 'package:foodly/widgets/gesboutik/gb_animated_count.dart';
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
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bonjour';
    if (hour < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.theme.colorScheme.surface,
      body: GetBuilder<DashboardController>(
        builder: (controller) {
          return RefreshIndicator(
            onRefresh: controller.loadDashboard,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _buildHeader(controller),
                SliverToBoxAdapter(child: SizedBox(height: 24.h)),
                _buildQuickActions(),
                SliverToBoxAdapter(child: SizedBox(height: 110.h)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(DashboardController controller) {
    return SliverToBoxAdapter(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 28.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.theme.colorScheme.primary,
              AppTheme.theme.colorScheme.primary.withOpacity(0.85),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$_greeting,',
                        style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        controller.employeeName.isNotEmpty
                            ? controller.employeeName
                            : 'Employé',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (controller.boutiqueName.isNotEmpty) ...[
                        SizedBox(height: 2.h),
                        Text(
                          controller.boutiqueName,
                          style: TextStyle(color: Colors.white70, fontSize: 13.sp),
                        ),
                      ],
                    ],
                  ),
                ),
                _buildAvatar(controller.employeeName),
              ],
            ),
            SizedBox(height: 18.h),
            controller.isLoading
                ? _buildStatChipsSkeleton()
                : Row(
                    children: [
                      _buildStatChip(
                        icon: LucideIcons.shoppingBag,
                        label: 'Produits',
                        value: controller.productCount,
                      ),
                      SizedBox(width: 12.w),
                      _buildStatChip(
                        icon: LucideIcons.receipt,
                        label: 'Mes ventes',
                        value: controller.salesCount,
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 44.w,
      height: 44.w,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.4)),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStatChipsSkeleton() {
    return Row(
      children: [
        Expanded(child: _skeletonChip()),
        SizedBox(width: 12.w),
        Expanded(child: _skeletonChip()),
      ],
    );
  }

  Widget _skeletonChip() {
    return Container(
      height: 54.h,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12.r),
      ),
    );
  }

  Widget _buildStatChip({required IconData icon, required String label, required int value}) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18.sp),
            SizedBox(width: 8.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                GbAnimatedCount(
                  value: value,
                  style: TextStyle(
                      color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold),
                ),
                Text(label, style: TextStyle(color: Colors.white70, fontSize: 11.sp)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      _QuickAction(
        icon: LucideIcons.shoppingBag,
        label: 'Produits',
        subtitle: 'Consulter le catalogue et le stock',
        onTap: () => Get.toNamed('/products'),
      ),
      _QuickAction(
        icon: LucideIcons.plusCircle,
        label: 'Nouvelle vente',
        subtitle: 'Encaisser un client',
        onTap: () => Get.toNamed('/new-sale'),
      ),
      _QuickAction(
        icon: LucideIcons.history,
        label: 'Historique des ventes',
        subtitle: 'Retrouver une vente passée',
        onTap: () => Get.toNamed('/sales-history'),
      ),
    ];

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions rapides',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
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
                  child: Icon(action.icon, color: AppTheme.theme.colorScheme.primary),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        action.label,
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        action.subtitle,
                        style: TextStyle(fontSize: 11.5.sp, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
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
