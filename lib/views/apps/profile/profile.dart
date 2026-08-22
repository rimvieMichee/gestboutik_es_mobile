import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:foodly/helpers/storage/local_storage.dart';
import 'package:foodly/helpers/theme/app_theme.dart';
import 'package:foodly/widgets/gesboutik/gb_staggered_item.dart';

/// Fiche d'identité de l'employé connecté : nom, rôle, boutique de
/// rattachement. Purement informatif — la déconnexion vit dans l'onglet
/// Réglages pour éviter de dupliquer l'action à deux endroits.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  String get _fullName => LocalStorage.getUserName() ?? '';

  String get _roleLabel {
    switch (LocalStorage.getUserRole()) {
      case 'SUPER_ADMIN':
        return 'Administrateur';
      case 'EMPLOYEE':
        return 'Employé';
      default:
        return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.theme.colorScheme.primary;
    final boutiqueName = LocalStorage.getBoutiqueName() ?? '';
    final initial = _fullName.isNotEmpty ? _fullName[0].toUpperCase() : '?';

    final infoRows = <_InfoRow>[
      _InfoRow(icon: LucideIcons.userCircle, label: 'Nom complet', value: _fullName.isNotEmpty ? _fullName : '—'),
      _InfoRow(icon: LucideIcons.shieldCheck, label: 'Rôle', value: _roleLabel),
      _InfoRow(icon: LucideIcons.store, label: 'Boutique', value: boutiqueName.isNotEmpty ? boutiqueName : '—'),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 32.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [primary, primary.withOpacity(0.85)],
                ),
              ),
              child: Column(
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) => Transform.scale(scale: value, child: child),
                    child: Container(
                      width: 84.w,
                      height: 84.w,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 16, offset: const Offset(0, 6)),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initial,
                        style: TextStyle(fontSize: 32.sp, fontWeight: FontWeight.bold, color: primary),
                      ),
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Text(
                    _fullName.isNotEmpty ? _fullName : 'Employé',
                    style: TextStyle(color: Colors.white, fontSize: 19.sp, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      _roleLabel,
                      style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.all(16.w),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  'Informations du compte',
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                SizedBox(height: 12.h),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14.r),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < infoRows.length; i++) ...[
                        if (i > 0) Divider(height: 1, indent: 16.w, endIndent: 16.w, color: Colors.grey[100]),
                        GbStaggeredItem(index: i, child: _buildInfoTile(infoRows[i], primary)),
                      ],
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(_InfoRow row, Color primary) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(9.w),
            decoration: BoxDecoration(color: primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10.r)),
            child: Icon(row.icon, size: 18.sp, color: primary),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row.label, style: TextStyle(fontSize: 11.5.sp, color: Colors.grey[600])),
                SizedBox(height: 2.h),
                Text(row.value, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow {
  final IconData icon;
  final String label;
  final String value;

  _InfoRow({required this.icon, required this.label, required this.value});
}
