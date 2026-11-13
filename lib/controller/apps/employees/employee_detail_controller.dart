import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:foodly/controller/my_controller.dart';
import 'package:foodly/helpers/services/employee_service.dart';
import 'package:foodly/helpers/services/realtime_service.dart';
import 'package:foodly/helpers/utils/realtime_listener.dart';
import 'package:foodly/helpers/services/error_handling.dart';
import 'package:foodly/helpers/services/sale_service.dart';
import 'package:foodly/models/employee_model.dart';
import 'package:foodly/models/sale_model.dart';

/// Activité d'un employé : statistiques et dernières ventes.
class EmployeeDetailController extends MyController with RealtimeListener {
  final String employeeId;
  EmployeeDetailController(this.employeeId);

  final RxBool isLoading = true.obs;
  final Rxn<EmployeeStats> stats = Rxn<EmployeeStats>();
  final RxList<SaleModel> recentSales = <SaleModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    load();
    listenRealtime({'sale.created', 'credit.settled'}, (event) {
      // Seules les ventes de cet employé changent sa fiche.
      if (event.type != 'resync' && event.userId != employeeId) return;
      debounced('employee', const Duration(milliseconds: 700),
          () => load(silent: true));
    });
  }

  Future<void> load({bool silent = false}) async {
    if (!silent) isLoading.value = true;
    try {
      final results = await Future.wait([
        EmployeeService.stats(employeeId),
        SaleService.findAll(limit: 5, userId: employeeId),
      ]);
      stats.value = results[0] as EmployeeStats;
      recentSales.assignAll((results[1] as dynamic).data as List<SaleModel>);
    } on DioException catch (e) {
      letMeHandleAllErrors(e);
    } finally {
      if (!silent) isLoading.value = false;
    }
  }
}
