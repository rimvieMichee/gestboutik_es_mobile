import 'package:foodly/helpers/extensions/string.dart';
import 'package:dio/dio.dart';
import 'package:foodly/helpers/services/auth_services.dart';
import 'package:foodly/helpers/services/realtime_service.dart';
import 'package:foodly/helpers/storage/local_storage.dart';
import 'package:foodly/helpers/utils/app_snackbar.dart';
import 'package:get/get.dart' hide Response, Trans;

/// Extrait le message d'erreur renvoyé par le backend NestJS, qu'il soit une
/// chaîne unique (exceptions métier) ou une liste (erreurs de validation DTO).
String? _serverMessage(DioException e) {
  final data = e.response?.data;
  if (data is Map) {
    final message = data['message'];
    if (message is String) return message;
    if (message is List) return message.join(', ');
  }
  return null;
}

/// To handle all the error app wide
void letMeHandleAllErrors(DioException e) {
  final serverMessage = _serverMessage(e);

  switch (e.response?.statusCode) {
    case 401:
      // Le serveur répond « Unauthorized » quand le jeton a expiré : message
      // clair à la place. On ne garde le texte du serveur que pour un compte
      // ou une boutique désactivés.
      final suspended = (serverMessage ?? '').toLowerCase().contains('désactiv');
      appSnackbar(
        heading: (suspended ? 'error' : 'session_expired_title').tr(),
        message: suspended ? serverMessage! : 'session_expired_msg'.tr(),
        snackbarState: SnackbarState.warning,
      );
      RealtimeService.instance.disconnect();
      AuthService.isLoggedIn = false;
      LocalStorage.removeLoggedInUser();
      Get.offAllNamed("/auth/login");
      break;
    case 403:
      appSnackbar(
        heading: 'error'.tr(),
        message: serverMessage ?? 'access_denied'.tr(),
        snackbarState: SnackbarState.danger,
      );
      break;
    case 429:
      appSnackbar(
        heading: 'error'.tr(),
        message:
            serverMessage ?? 'too_many_attempts'.tr(),
        snackbarState: SnackbarState.warning,
      );
      break;
    case 400:
      appSnackbar(
        heading: 'error'.tr(),
        message: serverMessage ?? 'invalid_request'.tr(),
        snackbarState: SnackbarState.danger,
      );
      break;
    case 404:
      appSnackbar(
        heading: 'error'.tr(),
        message: serverMessage ?? 'not_found'.tr(),
        snackbarState: SnackbarState.danger,
      );
      break;
    case 500:
      appSnackbar(
        heading: 'error'.tr(),
        message: 'server_error'.tr(),
        snackbarState: SnackbarState.danger,
      );
      break;
    default:
      appSnackbar(
        heading: 'error'.tr(),
        message: serverMessage ??
            (e.response == null ? 'network_error' : 'generic_error').tr(),
        snackbarState: SnackbarState.danger,
      );
      break;
  }
}
