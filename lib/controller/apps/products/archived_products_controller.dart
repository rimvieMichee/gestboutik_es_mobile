import 'package:foodly/helpers/extensions/string.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Trans;
import 'package:foodly/controller/my_controller.dart';
import 'package:foodly/helpers/services/realtime_service.dart';
import 'package:foodly/helpers/utils/realtime_listener.dart';
import 'package:foodly/helpers/services/error_handling.dart';
import 'package:foodly/helpers/services/product_service.dart';
import 'package:foodly/helpers/utils/app_snackbar.dart';
import 'package:foodly/models/product_model.dart';

/// Produits mis de côté (archivés) : consultables et restaurables.
class ArchivedProductsController extends MyController with RealtimeListener {
  final RxBool isLoading = true.obs;
  final RxList<ProductModel> products = <ProductModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    load();
    listenRealtime({'product.changed'}, (_) {
      debounced('archived', const Duration(milliseconds: 600),
          () => load(silent: true));
    });
  }

  Future<void> load({bool silent = false}) async {
    if (!silent) isLoading.value = true;
    try {
      final result =
          await ProductService.findAll(statut: 'INACTIVE', limit: 100);
      products.assignAll(result.data);
    } on DioException catch (e) {
      letMeHandleAllErrors(e);
    } finally {
      if (!silent) isLoading.value = false;
    }
  }

  /// Remet le produit en vente : il revient dans la liste des produits.
  Future<void> restore(ProductModel product) async {
    try {
      await ProductService.changeStatus(product.id, active: true);
      products.removeWhere((p) => p.id == product.id);
      appSnackbar(
        heading: 'product_restored'.tr(),
        message: 'product_back_on_sale'.trp({'name': product.nom}),
        snackbarState: SnackbarState.success,
      );
    } on DioException catch (e) {
      letMeHandleAllErrors(e);
    }
  }
}
