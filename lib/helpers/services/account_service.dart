import 'package:foodly/helpers/remote/api_service.dart';

/// Compte de l'utilisateur connecté (numéro de téléphone).
class AccountService {
  static Future<String?> getPhone() async {
    final response = await APIService.get(path: '/users/me');
    return response.data?['telephone'] as String?;
  }

  /// Enregistre le numéro ; une chaîne vide l'efface.
  static Future<void> updatePhone(String phone) async {
    await APIService.patch(
      path: '/users/me',
      mapData: {'telephone': phone.trim()},
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );
  }
}
