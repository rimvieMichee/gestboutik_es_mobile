import 'package:foodly/helpers/remote/api_service.dart';
import 'package:foodly/models/paginated_result.dart';
import 'package:foodly/models/product_model.dart';

class ProductService {
  static Future<PaginatedResult<ProductModel>> findAll({
    String? search,
    int page = 1,
    int limit = 50,
  }) async {
    final response = await APIService.get(
      path: '/products',
      params: {
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    return PaginatedResult.fromJson(response.data!, ProductModel.fromJson);
  }
}
