import 'package:foodly/helpers/remote/api_service.dart';
import 'package:foodly/helpers/storage/local_storage.dart';
import 'package:foodly/models/user_model.dart';

const _jsonHeaders = <String, dynamic>{
  'Content-Type': 'application/json',
  'Accept': 'application/json',
};

/// Authentification auprès du backend GesBoutik (JWT access + refresh token).
class AuthService {
  static bool isLoggedIn = false;

  /// Se connecte avec `username`/`password` et persiste la session localement.
  /// Lève une [DioException] en cas d'échec (identifiants invalides, boutique
  /// désactivée, etc.) : à charge de l'appelant de l'intercepter et d'afficher
  /// le message renvoyé par le backend.
  static Future<UserModel> login({
    required String username,
    required String password,
  }) async {
    final response = await APIService.postWithoutAth(
      path: '/auth/login',
      mapData: {'username': username, 'password': password},
      headers: _jsonHeaders,
    );

    final data = response.data!;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);

    await LocalStorage.setAuthToken(data['accessToken'] as String);
    await LocalStorage.setRefreshToken(data['refreshToken'] as String);
    await LocalStorage.setUserID(user.id);
    await LocalStorage.setFirstName(user.prenom);
    await LocalStorage.setLastName(user.nom);
    await LocalStorage.setUserName(user.nomComplet);
    await LocalStorage.setUserRole(user.role);
    if (user.boutiqueId != null) {
      await LocalStorage.setBoutiqueId(user.boutiqueId!);
    }
    if (user.boutique != null) {
      await LocalStorage.setBoutiqueName(user.boutique!.nom);
    }

    isLoggedIn = true;
    return user;
  }

  /// Révoque la session côté serveur (best-effort) puis nettoie l'état local.
  /// Ne lève jamais d'exception : un échec réseau ne doit pas empêcher la
  /// déconnexion locale de l'utilisateur.
  static Future<void> logout() async {
    final refreshToken = LocalStorage.getRefreshToken();
    if (refreshToken != null) {
      try {
        await APIService.post(
          path: '/auth/logout',
          mapData: {'refreshToken': refreshToken},
          headers: _jsonHeaders,
        );
      } catch (_) {
        // Best-effort : la session locale est nettoyée dans tous les cas.
      }
    }
    isLoggedIn = false;
    await LocalStorage.removeLoggedInUser();
  }
}
