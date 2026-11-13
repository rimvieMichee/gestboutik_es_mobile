import 'package:foodly/helpers/extensions/string.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Trans;
import 'package:foodly/controller/my_controller.dart';
import 'package:foodly/helpers/services/employee_service.dart';
import 'package:foodly/helpers/services/error_handling.dart';
import 'package:foodly/helpers/utils/app_snackbar.dart';
import 'package:foodly/models/employee_model.dart';

/// Gestion des comptes employés par le gestionnaire de la boutique.
class EmployeesController extends MyController {
  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;
  final RxList<EmployeeModel> employees = <EmployeeModel>[].obs;
  final RxString search = ''.obs;
  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    loadEmployees();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }

  void onSearchChanged(String value) {
    search.value = value;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), loadEmployees);
  }

  /// [silent] : recharge en arrière-plan, sans réafficher le squelette.
  Future<void> loadEmployees({bool silent = false}) async {
    if (!silent) isLoading.value = true;
    try {
      final result = await EmployeeService.findAll(search: search.value);
      employees.assignAll(result.data);
    } on DioException catch (e) {
      letMeHandleAllErrors(e);
    } finally {
      if (!silent) isLoading.value = false;
    }
  }

  /// Retourne `true` si le compte a bien été créé (pour fermer le formulaire).
  Future<bool> createEmployee({
    required String username,
    required String password,
    String? nom,
    String? prenom,
    String? telephone,
  }) async {
    isSaving.value = true;
    try {
      await EmployeeService.create(
        username: username,
        password: password,
        nom: nom,
        prenom: prenom,
        telephone: telephone,
      );
      unawaited(
          loadEmployees(silent: true)); // la liste se met à jour sans bloquer
      return true;
    } on DioException catch (e) {
      letMeHandleAllErrors(e);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<bool> updateEmployee(
    EmployeeModel employee, {
    required String nom,
    required String prenom,
    String? telephone,
  }) async {
    isSaving.value = true;
    try {
      await EmployeeService.update(employee.id,
          nom: nom, prenom: prenom, telephone: telephone);
      appSnackbar(
        heading: 'employee_edited'.tr(),
        message: 'info_saved'.tr(),
        snackbarState: SnackbarState.success,
      );
      unawaited(
          loadEmployees(silent: true)); // la liste se met à jour sans bloquer
      return true;
    } on DioException catch (e) {
      letMeHandleAllErrors(e);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> toggleStatus(EmployeeModel employee) async {
    try {
      await EmployeeService.changeStatus(employee.id,
          active: !employee.isActive);
      appSnackbar(
        heading: 'account_updated'.tr(),
        message: employee.isActive
            ? 'employee_cannot_login_now'.trp({'name': employee.nomComplet})
            : 'employee_can_login_now'.trp({'name': employee.nomComplet}),
        snackbarState: SnackbarState.success,
      );
      unawaited(loadEmployees(silent: true));
    } on DioException catch (e) {
      letMeHandleAllErrors(e);
    }
  }

  Future<bool> resetPassword(EmployeeModel employee, String password) async {
    isSaving.value = true;
    try {
      await EmployeeService.resetPassword(employee.id, password);
      appSnackbar(
        heading: 'password_changed'.tr(),
        message: 'password_saved_for'.trp({'name': employee.nomComplet}),
        snackbarState: SnackbarState.success,
      );
      return true;
    } on DioException catch (e) {
      letMeHandleAllErrors(e);
      return false;
    } finally {
      isSaving.value = false;
    }
  }
}
