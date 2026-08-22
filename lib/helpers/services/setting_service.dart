import 'package:dio/dio.dart';
import 'package:foodly/helpers/remote/api_service.dart';
import 'package:foodly/helpers/storage/local_storage.dart';

class SettingService {
  /// Révoque le refresh token courant côté serveur. Best-effort : la
  /// déconnexion locale (côté appelant) ne dépend pas de son résultat.
  static Future<bool> userSignOut() async {
    try {
      final refreshToken = LocalStorage.getRefreshToken();
      if (refreshToken == null) return true;

      final response = await APIService.post(
        path: '/auth/logout',
        mapData: {'refreshToken': refreshToken},
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      );
      return response.statusCode == 200;
    } on DioException {
      return false;
    }
  }
}
