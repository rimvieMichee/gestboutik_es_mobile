import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:foodly/helpers/storage/local_storage.dart';

/// Résultat d'un contrôle de disponibilité de la biométrie sur l'appareil.
enum BiometricStatus { available, notSupported, notEnrolled }

/// Connexion par empreinte digitale / Face ID.
///
/// Le mot de passe n'est jamais gardé dans les préférences : il vit dans le
/// stockage sécurisé de l'appareil (Keychain iOS, Keystore Android) et n'est
/// relu qu'après une authentification biométrique réussie.
class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.unlocked_this_device),
  );
  static const _kUser = 'bio_username';
  static const _kPass = 'bio_password';

  /// Posé à la déconnexion volontaire : la page de connexion ne relance pas
  /// alors la demande biométrique toute seule.
  static bool skipAutoPrompt = false;

  static bool get isIOS => Platform.isIOS;

  static Future<BiometricStatus> status() async {
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      if (!supported || !canCheck) return BiometricStatus.notSupported;
      final types = await _auth.getAvailableBiometrics();
      if (types.isEmpty) return BiometricStatus.notEnrolled;
      return BiometricStatus.available;
    } on PlatformException {
      return BiometricStatus.notSupported;
    }
  }

  /// Demande l'empreinte / le visage. `false` si refusé, annulé ou en erreur.
  static Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
            biometricOnly: true, stickyAuth: true),
      );
    } on PlatformException {
      return false;
    }
  }

  /// Activée dans les paramètres ET identifiants présents dans le coffre.
  static Future<bool> isReady() async {
    if (!LocalStorage.getBiometricEnabled()) return false;
    return (await _storage.read(key: _kPass)) != null;
  }

  static Future<void> enable(String username, String password) async {
    await _storage.write(key: _kUser, value: username);
    await _storage.write(key: _kPass, value: password);
    await LocalStorage.setBiometricEnabled(true);
  }

  /// Garde le coffre à jour quand le mot de passe est ressaisi à la main.
  static Future<void> refreshPassword(String username, String password) async {
    if (!LocalStorage.getBiometricEnabled()) return;
    await _storage.write(key: _kUser, value: username);
    await _storage.write(key: _kPass, value: password);
  }

  /// Après un changement de mot de passe dans l'appli : même identifiant, nouveau secret.
  static Future<void> updateStoredPassword(String password) async {
    if (!LocalStorage.getBiometricEnabled()) return;
    if ((await _storage.read(key: _kUser)) == null) return;
    await _storage.write(key: _kPass, value: password);
  }

  static Future<void> disable() async {
    await _storage.delete(key: _kUser);
    await _storage.delete(key: _kPass);
    await LocalStorage.setBiometricEnabled(false);
  }

  static Future<({String username, String password})?> credentials() async {
    final u = await _storage.read(key: _kUser);
    final p = await _storage.read(key: _kPass);
    if (u == null || p == null) return null;
    return (username: u, password: p);
  }
}
