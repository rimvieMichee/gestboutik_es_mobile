import 'package:foodly/helpers/remote/api_service.dart';

class PeriodStats {
  final int nombreVentes;
  final double chiffreAffaires;
  PeriodStats(this.nombreVentes, this.chiffreAffaires);

  factory PeriodStats.fromJson(Map<String, dynamic> j) => PeriodStats(
        j['nombreVentes'] as int,
        double.parse(j['chiffreAffaires'].toString()),
      );
}

class ManagerOverview {
  final int totalEmployees;
  final int totalProducts;
  final int totalSales;
  final double chiffreAffaires;
  final PeriodStats jour;
  final PeriodStats semaine;
  final PeriodStats mois;

  ManagerOverview({
    required this.totalEmployees,
    required this.totalProducts,
    required this.totalSales,
    required this.chiffreAffaires,
    required this.jour,
    required this.semaine,
    required this.mois,
  });

  factory ManagerOverview.fromJson(Map<String, dynamic> j) => ManagerOverview(
        totalEmployees: j['totalEmployees'] as int,
        totalProducts: j['totalProducts'] as int,
        totalSales: j['totalSales'] as int,
        chiffreAffaires: double.parse(j['chiffreAffaires'].toString()),
        jour: PeriodStats.fromJson(j['ventesDuJour'] as Map<String, dynamic>),
        semaine:
            PeriodStats.fromJson(j['ventesSemaine'] as Map<String, dynamic>),
        mois: PeriodStats.fromJson(j['ventesMois'] as Map<String, dynamic>),
      );
}

/// Tableau de bord du gestionnaire (rôle ADMIN) pour SA boutique.
class DashboardService {
  static Future<ManagerOverview> overview() async {
    final r = await APIService.get(path: '/dashboard/overview');
    return ManagerOverview.fromJson(r.data!);
  }
}
