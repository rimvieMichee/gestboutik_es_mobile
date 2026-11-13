import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:foodly/controller/my_controller.dart';
import 'package:foodly/helpers/extensions/string.dart';
import 'package:foodly/widgets/gesboutik/gb_dispose.dart';
import 'package:foodly/helpers/services/auth_services.dart';
import 'package:foodly/helpers/services/biometric_service.dart';
import 'package:foodly/helpers/storage/local_storage.dart';

/// Connexion. Les erreurs sont affichées sous le champ concerné :
/// identifiant (champ vide, compte ou boutique désactivés, accès refusé),
/// mot de passe (champ vide, identifiants incorrects) ; les problèmes
/// réseau ou serveur, qui ne concernent aucun champ, vont dans un bandeau.
class LoginController extends MyController {
  final TextEditingController username = TextEditingController();
  final TextEditingController password = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxBool showPassword = false.obs;

  /// `null` = pas d'erreur. Chaîne vide = champ en rouge sans message
  /// (identifiants incorrects : le message est sous le mot de passe).
  final RxnString usernameError = RxnString();
  final RxnString passwordError = RxnString();
  final RxnString generalError = RxnString();

  /// Compte déjà utilisé sur cet appareil : on n'affiche alors que le mot de
  /// passe (et la biométrie), avec « Se connecter avec un autre compte ».
  final RxnString savedUsername = RxnString();
  final RxnString savedDisplayName = RxnString();
  final RxBool biometricReady = false.obs;

  bool get useSavedAccount => savedUsername.value != null;

  void toggleShowPassword() => showPassword.value = !showPassword.value;

  @override
  void onInit() {
    super.onInit();
    final last = LocalStorage.getLastUsername();
    if (last != null && last.isNotEmpty) {
      savedUsername.value = last;
      savedDisplayName.value = LocalStorage.getLastDisplayName();
    }
    _loadBiometric();
    // Dès que l'utilisateur corrige un champ, son erreur disparaît.
    username.addListener(() {
      if (usernameError.value != null || generalError.value != null) {
        usernameError.value = null;
        generalError.value = null;
      }
    });
    password.addListener(() {
      if (passwordError.value != null || generalError.value != null) {
        passwordError.value = null;
        generalError.value = null;
        if (usernameError.value == '') usernameError.value = null;
      }
    });
  }

  @override
  void onClose() {
    // Pas tout de suite : la page de connexion reste affichée le temps de la
    // transition vers l'accueil et reconstruit encore ses champs.
    disposeAfterClose([username, password]);
    super.onClose();
  }

  Future<void> _loadBiometric() async {
    biometricReady.value = await BiometricService.isReady() &&
        await BiometricService.status() == BiometricStatus.available;
  }

  /// Ouvre la demande biométrique à l'arrivée sur la page (sauf juste après
  /// une déconnexion volontaire).
  Future<void> autoPromptBiometric() async {
    if (BiometricService.skipAutoPrompt) {
      BiometricService.skipAutoPrompt = false;
      return;
    }
    await _loadBiometric();
    if (biometricReady.value) await loginWithBiometrics();
  }

  void useAnotherAccount() {
    savedUsername.value = null;
    savedDisplayName.value = null;
    biometricReady.value = false;
    username.clear();
    password.clear();
    _clearErrors();
  }

  Future<void> loginWithBiometrics() async {
    if (isLoading.value) return;
    _clearErrors();
    final ok = await BiometricService.authenticate('biometric_reason_login'.tr());
    if (!ok) return;
    final creds = await BiometricService.credentials();
    if (creds == null) {
      await BiometricService.disable();
      biometricReady.value = false;
      return;
    }
    final result = await _login(creds.username, creds.password);
    if (result == _LoginResult.badCredentials) {
      // Mot de passe changé depuis l'activation : le coffre est périmé.
      await BiometricService.disable();
      biometricReady.value = false;
      passwordError.value = 'biometric_credentials_invalid'.tr();
    }
  }

  void _clearErrors() {
    usernameError.value = null;
    passwordError.value = null;
    generalError.value = null;
  }

  Future<void> onLogin() async {
    final usernameValue =
        useSavedAccount ? savedUsername.value! : username.text.trim();
    final passwordValue = password.text;

    _clearErrors();
    if (usernameValue.isEmpty) {
      usernameError.value = 'login_enter_username'.tr();
    }
    if (passwordValue.isEmpty) {
      passwordError.value = 'login_enter_password'.tr();
    }
    if (usernameError.value != null || passwordError.value != null) return;

    final result = await _login(usernameValue, passwordValue);
    if (result == _LoginResult.ok) {
      await BiometricService.refreshPassword(usernameValue, passwordValue);
    }
  }

  Future<_LoginResult> _login(String usernameValue, String passwordValue) async {
    isLoading.value = true;
    try {
      final user = await AuthService.login(
        username: usernameValue,
        password: passwordValue,
      );

      // L'application mobile est réservée aux gestionnaires de boutique
      // (ADMIN) et à leurs employés : le compte technicien (SUPER_ADMIN)
      // utilise l'interface web d'administration.
      if (user.role != 'EMPLOYEE' && user.role != 'ADMIN') {
        await AuthService.logout();
        usernameError.value =
            "Ce compte n'a pas accès à l'application mobile. Utilisez l'interface web.";
        return _LoginResult.failed;
      }

      await LocalStorage.setLastAccount(user.username, user.nomComplet);
      Get.offAllNamed('/dashboard');
      return _LoginResult.ok;
    } on DioException catch (e) {
      final bad = e.response?.statusCode == 401 &&
          !(_serverMessage(e) ?? '').toLowerCase().contains('désactiv');
      _showError(e);
      return bad ? _LoginResult.badCredentials : _LoginResult.failed;
    } catch (_) {
      generalError.value = 'Une erreur inattendue est survenue. Réessayez.';
      return _LoginResult.failed;
    } finally {
      isLoading.value = false;
    }
  }

  void _showError(DioException e) {
    final status = e.response?.statusCode;
    final message = _serverMessage(e);

    if (status == 401) {
      final lower = (message ?? '').toLowerCase();
      if (lower.contains('désactiv')) {
        // Compte ou boutique désactivés : le problème vient de l'identifiant.
        usernameError.value = message;
      } else {
        usernameError.value = '';
        passwordError.value = 'login_wrong_credentials'.tr();
      }
      return;
    }
    if (status == 429) {
      generalError.value =
          'Trop de tentatives de connexion. Patientez une minute puis réessayez.';
      return;
    }
    if (status != null && status >= 500) {
      generalError.value =
          'Le serveur rencontre un problème. Réessayez dans un instant.';
      return;
    }
    if (status != null) {
      generalError.value =
          message ?? 'Connexion impossible. Vérifiez vos informations.';
      return;
    }
    // Aucune réponse : pas de réseau, ou serveur en cours de démarrage.
    generalError.value =
        'Impossible de joindre le serveur. Vérifiez votre connexion internet ; '
        "si elle est bonne, le serveur démarre peut-être : réessayez dans quelques secondes.";
  }

  String? _serverMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final message = data['message'];
      if (message is String) return message;
      if (message is List) return message.join(', ');
    }
    return null;
  }
}

enum _LoginResult { ok, badCredentials, failed }
