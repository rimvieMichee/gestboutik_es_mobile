import 'package:foodly/helpers/localizations/language.dart';
import 'package:dio/dio.dart';
import 'package:foodly/helpers/extensions/string.dart';
import 'package:foodly/helpers/services/auth_services.dart';
import 'package:foodly/helpers/services/biometric_service.dart';
import 'package:foodly/helpers/remote/api_service.dart';
import 'package:foodly/helpers/utils/app_snackbar.dart';
import 'package:foodly/helpers/services/setting_service.dart';
import 'package:foodly/helpers/services/realtime_service.dart';
import 'package:foodly/helpers/storage/local_storage.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';

class SettingsController extends GetxController {
  RxBool isLoading = false.obs;

  /// Index de la langue choisie dans [Language.languages].
  final RxInt selectedLanguageIndex = 0.obs;

  /// Biométrie : appareil compatible (sinon la ligne est masquée) et état.
  final RxBool biometricSupported = false.obs;
  final RxBool biometricEnabled = false.obs;
  final RxBool biometricBusy = false.obs;

  @override
  void onInit() {
    super.onInit();
    final code = LocalStorage.getLanguage();
    final index =
        Language.languages.indexWhere((l) => l.locale.languageCode == code);
    selectedLanguageIndex.value = index < 0 ? 0 : index;
    _loadBiometric();
  }

  Future<void> _loadBiometric() async {
    biometricSupported.value =
        await BiometricService.status() != BiometricStatus.notSupported;
    biometricEnabled.value = await BiometricService.isReady();
  }

  /// Vérifie le mot de passe auprès du serveur sans toucher à la session.
  Future<bool> verifyPassword(String password) async {
    final username = LocalStorage.getLastUsername();
    if (username == null) return false;
    try {
      await APIService.postWithoutAth(
        path: '/auth/login',
        mapData: {'username': username, 'password': password},
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      return true;
    } on DioException {
      return false;
    }
  }

  /// Active (après confirmation biométrique) ou désactive la connexion
  /// biométrique. [password] n'est requis que pour l'activation.
  Future<void> setBiometric(bool enable, {String? password}) async {
    if (biometricBusy.value) return;
    biometricBusy.value = true;
    try {
      if (!enable) {
        await BiometricService.disable();
        biometricEnabled.value = false;
        appSnackbar(
            message: 'biometric_deactivated'.tr(),
            snackbarState: SnackbarState.info);
        return;
      }
      final ok = await BiometricService.authenticate(
          'biometric_reason_enable'.tr());
      if (!ok) return;
      await BiometricService.enable(
          LocalStorage.getLastUsername() ?? '', password ?? '');
      biometricEnabled.value = true;
      appSnackbar(
          message: 'biometric_activated'.tr(),
          snackbarState: SnackbarState.success);
    } finally {
      biometricBusy.value = false;
    }
  }

  // Future<void> onLogout() async {
  //   try {
  //     AuthService.isLoggedIn = false;
  //     final isLogout = await SettingService.userSignOut();
  //
  //     if (isLogout) {
  //       await LocalStorage.removeLoggedInUser();
  //       Get.offAndToNamed('/auth/login');
  //     }
  //   } catch (e, st) {
  //     log("Logout error: $e\n$st");
  //   } finally {
  //     isLoading(false);
  //   }
  // }

  Future<void> onLogout() async {
    try {
      // La révocation côté serveur est best-effort : la session locale est
      // nettoyée et l'utilisateur redirigé dans tous les cas.
      await SettingService.userSignOut();
    } finally {
      RealtimeService.instance.disconnect();
      AuthService.isLoggedIn = false;
      BiometricService.skipAutoPrompt = true;
      await LocalStorage.removeLoggedInUser();
      isLoading(false);
      Get.offAllNamed('/auth/login');
    }
  }
}
