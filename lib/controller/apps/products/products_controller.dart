import 'dart:async';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:foodly/controller/my_controller.dart';
import 'package:foodly/helpers/services/error_handling.dart';
import 'package:foodly/helpers/services/product_service.dart';
import 'package:foodly/models/product_model.dart';

class ProductsController extends MyController {
  final RxBool isLoading = true.obs;
  final RxList<ProductModel> products = <ProductModel>[].obs;
  final RxString search = ''.obs;
  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    loadProducts();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }

  void onSearchChanged(String value) {
    search.value = value;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), loadProducts);
  }

  Future<void> loadProducts() async {
    isLoading.value = true;
    try {
      final result = await ProductService.findAll(search: search.value);
      products.assignAll(result.data);
    } on DioException catch (e) {
      letMeHandleAllErrors(e);
    } finally {
      isLoading.value = false;
    }
  }
}
