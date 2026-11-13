import 'package:foodly/helpers/remote/api_service.dart';
import 'package:foodly/models/shop_model.dart';

class ShopService {
  /// Les boutiques du gestionnaire, avec leurs chiffres du jour.
  static Future<List<ShopModel>> mine() async {
    final response = await APIService.get(path: '/boutiques/mine');
    final list = response.data?['data'] as List?;
    return (list ?? const [])
        .map((e) => ShopModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
