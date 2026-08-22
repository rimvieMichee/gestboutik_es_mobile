import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:foodly/controller/my_controller.dart';
import 'package:foodly/helpers/services/error_handling.dart';
import 'package:foodly/helpers/services/sale_service.dart';
import 'package:foodly/models/sale_model.dart';

class SalesHistoryController extends MyController {
  final RxBool isLoading = true.obs;
  final RxList<SaleModel> sales = <SaleModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadSales();
  }

  Future<void> loadSales() async {
    isLoading.value = true;
    try {
      final result = await SaleService.findAll();
      sales.assignAll(result.data);
    } on DioException catch (e) {
      letMeHandleAllErrors(e);
    } finally {
      isLoading.value = false;
    }
  }
}
