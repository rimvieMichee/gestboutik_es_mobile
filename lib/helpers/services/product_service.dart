import 'package:dio/dio.dart';
import 'package:foodly/helpers/remote/api_service.dart';
import 'package:foodly/models/paginated_result.dart';
import 'package:foodly/models/product_model.dart';

const _json = <String, dynamic>{
  'Content-Type': 'application/json',
  'Accept': 'application/json',
};

class ProductService {
  static Future<PaginatedResult<ProductModel>> findAll({
    String? search,
    int page = 1,
    int limit = 50,

    /// 'ACTIVE' (en vente) ou 'INACTIVE' (archivé) ; absent = tous.
    String? statut,
  }) async {
    final response = await APIService.get(
      path: '/products',
      params: {
        'page': page,
        'limit': limit,
        if (statut != null) 'statut': statut,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    return PaginatedResult.fromJson(response.data!, ProductModel.fromJson);
  }

  // ---- Réservé au gestionnaire (ADMIN) ----

  static Map<String, dynamic> _body({
    required String nom,
    required double prixVente,
    double? prixAchat,
    int? seuilAlerte,
    String? sku,
    String? description,
    String? image,
  }) =>
      {
        'nom': nom,
        'prixVente': prixVente,
        if (prixAchat != null) 'prixAchat': prixAchat,
        if (seuilAlerte != null) 'seuilAlerte': seuilAlerte,
        if (sku != null && sku.isNotEmpty) 'sku': sku,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (image != null && image.isNotEmpty) 'image': image,
      };

  static Future<ProductModel> create({
    required String nom,
    required double prixVente,
    double? prixAchat,
    int quantiteDisponible = 0,
    int? seuilAlerte,
    String? sku,
    String? description,
    String? image,
  }) async {
    final response = await APIService.post(
      path: '/products',
      mapData: {
        ..._body(
          nom: nom,
          prixVente: prixVente,
          prixAchat: prixAchat,
          seuilAlerte: seuilAlerte,
          sku: sku,
          description: description,
          image: image,
        ),
        'quantiteDisponible': quantiteDisponible,
      },
      headers: _json,
    );
    return ProductModel.fromJson(response.data!);
  }

  /// La quantité ne se modifie jamais ici : voir [restock] / [adjust].
  static Future<ProductModel> update(
    String id, {
    required String nom,
    required double prixVente,
    double? prixAchat,
    int? seuilAlerte,
    String? sku,
    String? description,
    String? image,
  }) async {
    final response = await APIService.patch(
      path: '/products/$id',
      mapData: _body(
        nom: nom,
        prixVente: prixVente,
        prixAchat: prixAchat,
        seuilAlerte: seuilAlerte,
        sku: sku,
        description: description,
        image: image,
      ),
      headers: _json,
    );
    return ProductModel.fromJson(response.data!);
  }

  static Future<void> changeStatus(String id, {required bool active}) async {
    await APIService.patch(
      path: '/products/$id/status',
      mapData: {'statut': active ? 'ACTIVE' : 'INACTIVE'},
      headers: _json,
    );
  }

  static Future<void> restock(String productId, int quantite,
      {String? note}) async {
    await APIService.post(
      path: '/stock/restock',
      mapData: {
        'productId': productId,
        'quantite': quantite,
        if (note != null && note.isNotEmpty) 'note': note,
      },
      headers: _json,
    );
  }

  /// [delta] signé (ex. -2 pour une casse), [note] obligatoire.
  static Future<void> adjust(String productId, int delta, String note) async {
    await APIService.post(
      path: '/stock/adjustment',
      mapData: {'productId': productId, 'quantite': delta, 'note': note},
      headers: _json,
    );
  }

  /// Envoie l'image vers Cloudinary (via le backend) et renvoie son URL.
  static Future<String> uploadImage(String filePath) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    final response = await APIService.post(
      path: '/media/product-image',
      data: form,
      headers: {'Accept': 'application/json'},
    );
    return response.data!['url'] as String;
  }
}
