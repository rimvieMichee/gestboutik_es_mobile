import 'package:dio/dio.dart';
import 'package:foodly/helpers/services/auth_services.dart';
import 'package:foodly/helpers/storage/local_storage.dart';
import 'package:foodly/helpers/utils/app_snackbar.dart';
import 'package:get/get.dart' hide Response;

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
      appSnackbar(
        heading: "Erreur",
        message: serverMessage ?? "Session expirée, veuillez vous reconnecter.",
        snackbarState: SnackbarState.danger,
      );
      AuthService.isLoggedIn = false;
      LocalStorage.removeLoggedInUser();
      Get.offAllNamed("/auth/login");
      break;
    case 403:
      appSnackbar(
        heading: "Erreur",
        message: serverMessage ?? "Accès refusé.",
        snackbarState: SnackbarState.danger,
      );
      break;
    case 429:
      appSnackbar(
        heading: "Erreur",
        message: serverMessage ?? "Trop de tentatives, réessayez dans un instant.",
        snackbarState: SnackbarState.warning,
      );
      break;
    case 400:
      appSnackbar(
        heading: "Erreur",
        message: serverMessage ?? "Requête invalide.",
        snackbarState: SnackbarState.danger,
      );
      break;
    case 404:
      appSnackbar(
        heading: "Erreur",
        message: serverMessage ?? "Ressource introuvable.",
        snackbarState: SnackbarState.danger,
      );
      break;
    case 500:
      appSnackbar(
        heading: "Erreur",
        message: "Erreur serveur, réessayez plus tard.",
        snackbarState: SnackbarState.danger,
      );
      break;
    default:
      appSnackbar(
        heading: "Erreur",
        message: serverMessage ?? "Une erreur est survenue. Vérifiez votre connexion.",
        snackbarState: SnackbarState.danger,
      );
      break;
  }
}
