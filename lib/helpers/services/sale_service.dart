import 'package:foodly/helpers/remote/api_service.dart';
import 'package:foodly/models/paginated_result.dart';
import 'package:foodly/models/sale_model.dart';

class SaleItemInput {
  final String productId;
  final int quantite;

  SaleItemInput({required this.productId, required this.quantite});

  Map<String, dynamic> toJson() => {'productId': productId, 'quantite': quantite};
}

class SaleService {
  /// Enregistre une vente. Le backend recalcule les prix/totaux et vérifie
  /// le stock : aucun montant n'est envoyé par le client.
  static Future<SaleModel> create(List<SaleItemInput> items) async {
    final response = await APIService.post(
      path: '/sales',
      mapData: {'items': items.map((e) => e.toJson()).toList()},
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
    );
    return SaleModel.fromJson(response.data!);
  }

  static Future<PaginatedResult<SaleModel>> findAll({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await APIService.get(
      path: '/sales',
      params: {'page': page, 'limit': limit},
    );
    return PaginatedResult.fromJson(response.data!, SaleModel.fromJson);
  }

  static Future<SaleModel> findOne(String id) async {
    final response = await APIService.get(path: '/sales/$id');
    return SaleModel.fromJson(response.data!);
  }
}
