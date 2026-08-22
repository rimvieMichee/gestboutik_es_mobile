import 'package:dio/dio.dart';
import 'package:foodly/controller/my_controller.dart';
import 'package:foodly/helpers/services/error_handling.dart';
import 'package:foodly/helpers/services/product_service.dart';
import 'package:foodly/helpers/services/sale_service.dart';
import 'package:foodly/helpers/storage/local_storage.dart';

/// Contrôleur du tableau de bord de l'employé : quelques chiffres clés
/// (produits de la boutique, ventes réalisées) en plus des actions rapides.
class DashboardController extends MyController {
  bool isLoading = false;
  int productCount = 0;
  int salesCount = 0;

  String get employeeName => LocalStorage.getUserName() ?? '';
  String get boutiqueName => LocalStorage.getBoutiqueName() ?? '';

  @override
  void onInit() {
    super.onInit();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    isLoading = true;
    update();

    try {
      final results = await Future.wait([
        ProductService.findAll(limit: 1),
        SaleService.findAll(limit: 1),
      ]);
      productCount = results[0].meta.total;
      salesCount = results[1].meta.total;
    } on DioException catch (e) {
      letMeHandleAllErrors(e);
    } finally {
      isLoading = false;
      update();
    }
  }
}
