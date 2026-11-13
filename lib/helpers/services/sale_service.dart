import 'package:foodly/helpers/remote/api_service.dart';
import 'package:foodly/helpers/utils/period.dart';
import 'package:foodly/models/daily_report_model.dart';
import 'package:foodly/models/paginated_result.dart';
import 'package:foodly/models/sale_model.dart';

class SaleItemInput {
  final String productId;
  final int quantite;

  SaleItemInput({required this.productId, required this.quantite});

  Map<String, dynamic> toJson() =>
      {'productId': productId, 'quantite': quantite};
}

/// Filtre des ventes à crédit (voir `credit` côté backend).
enum CreditFilter {
  all(null),
  cash('cash'),
  unpaid('unpaid'),
  paid('paid');

  final String? value;
  const CreditFilter(this.value);
}

class SaleService {
  static const _json = <String, dynamic>{
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Enregistre une vente. Le backend recalcule les prix/totaux et vérifie
  /// le stock : aucun montant n'est envoyé par le client. Pour une vente à
  /// crédit, [clientNom] (l'emprunteur) est obligatoire.
  static Future<SaleModel> create(
    List<SaleItemInput> items, {
    bool estCredit = false,
    String? clientNom,
  }) async {
    final response = await APIService.post(
      path: '/sales',
      mapData: {
        'items': items.map((e) => e.toJson()).toList(),
        if (estCredit) 'estCredit': true,
        if (estCredit) 'clientNom': clientNom?.trim(),
      },
      headers: _json,
    );
    return SaleModel.fromJson(response.data!);
  }

  /// [userId] : filtre par employé (honoré uniquement pour le gestionnaire).
  static Future<PaginatedResult<SaleModel>> findAll({
    int page = 1,
    int limit = 20,
    String? userId,
    Period? period,
    CreditFilter credit = CreditFilter.all,
  }) async {
    final response = await APIService.get(
      path: '/sales',
      params: {
        'page': page,
        'limit': limit,
        if (userId != null) 'userId': userId,
        if (period != null) 'dateFrom': period.fromIso,
        if (period != null) 'dateTo': period.toIso,
        if (credit.value != null) 'credit': credit.value,
      },
    );
    return PaginatedResult.fromJson(response.data!, SaleModel.fromJson);
  }

  static Future<SaleModel> findOne(String id) async {
    final response = await APIService.get(path: '/sales/$id');
    return SaleModel.fromJson(response.data!);
  }

  /// Totaux d'une période (employé : ses ventes ; gestionnaire : la boutique).
  static Future<SalesSummary> summary({Period? period, String? userId}) async {
    final response = await APIService.get(
      path: '/sales/summary',
      params: {
        if (period != null) 'dateFrom': period.fromIso,
        if (period != null) 'dateTo': period.toIso,
        if (userId != null) 'userId': userId,
      },
    );
    return SalesSummary.fromJson(response.data!);
  }

  /// Rapport complet d'une période (gestionnaire) : en-tête, totaux, toutes les ventes.
  static Future<DailyReport> report(Period period, {bool all = false}) async {
    final response = await APIService.get(
      path: '/sales/report',
      params: {
        'dateFrom': period.fromIso,
        'dateTo': period.toIso,
        if (all) 'scope': 'all',
      },
    );
    return DailyReport.fromJson(response.data!);
  }

  /// Le gestionnaire marque un crédit comme réglé.
  static Future<SaleModel> settleCredit(String id) async {
    final response = await APIService.patch(
      path: '/sales/$id/settle',
      mapData: <String, dynamic>{},
      headers: _json,
    );
    return SaleModel.fromJson(response.data!);
  }
}
