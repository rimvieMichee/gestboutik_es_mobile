import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:foodly/controller/my_controller.dart';
import 'package:foodly/helpers/services/auth_services.dart';
import 'package:foodly/helpers/services/error_handling.dart';
import 'package:foodly/helpers/utils/app_snackbar.dart';

class LoginController extends MyController {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController username = TextEditingController();
  final TextEditingController password = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxBool showPassword = false.obs;

  void toggleShowPassword() => showPassword.value = !showPassword.value;

  @override
  void onClose() {
    username.dispose();
    password.dispose();
    super.onClose();
  }

  Future<void> onLogin() async {
    final usernameValue = username.text.trim();
    final passwordValue = password.text;

    if (usernameValue.isEmpty) {
      appSnackbar(
        heading: "Erreur",
        message: "Veuillez entrer votre identifiant.",
        snackbarState: SnackbarState.danger,
      );
      return;
    }
    if (passwordValue.isEmpty) {
      appSnackbar(
        heading: "Erreur",
        message: "Veuillez entrer votre mot de passe.",
        snackbarState: SnackbarState.danger,
      );
      return;
    }

    isLoading.value = true;
    try {
      final user = await AuthService.login(
        username: usernameValue,
        password: passwordValue,
      );

      // L'application mobile est réservée aux employés : un compte admin
      // doit utiliser l'interface web dédiée.
      if (user.role != 'EMPLOYEE') {
        await AuthService.logout();
        appSnackbar(
          heading: "Accès refusé",
          message:
              "Ce compte n'est pas un compte employé. Utilisez l'interface d'administration.",
          snackbarState: SnackbarState.danger,
        );
        return;
      }

      Get.offAllNamed('/dashboard');
    } on DioException catch (e) {
      letMeHandleAllErrors(e);
    } finally {
      isLoading.value = false;
    }
  }
}
