import 'package:foodly/helpers/remote/api_service.dart';
import 'package:foodly/models/employee_model.dart';
import 'package:foodly/models/paginated_result.dart';

const _json = <String, dynamic>{
  'Content-Type': 'application/json',
  'Accept': 'application/json',
};

/// Gestion des comptes employés par le gestionnaire (rôle ADMIN) de la boutique.
/// Le backend déduit le rôle (EMPLOYEE) et la boutique du compte connecté.
class EmployeeService {
  static Future<PaginatedResult<EmployeeModel>> findAll({
    String? search,
    int page = 1,
    int limit = 50,
  }) async {
    final response = await APIService.get(
      path: '/users',
      params: {
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    return PaginatedResult.fromJson(response.data!, EmployeeModel.fromJson);
  }

  static Future<EmployeeStats> stats(String id) async {
    final response = await APIService.get(path: '/users/$id/stats');
    return EmployeeStats.fromJson(response.data!);
  }

  static Future<EmployeeModel> create({
    required String username,
    required String password,
    String? nom,
    String? prenom,
    String? telephone,
  }) async {
    final response = await APIService.post(
      path: '/users',
      mapData: {
        'username': username,
        'password': password,
        if (nom != null && nom.isNotEmpty) 'nom': nom,
        if (prenom != null && prenom.isNotEmpty) 'prenom': prenom,
        if (telephone != null && telephone.isNotEmpty) 'telephone': telephone,
      },
      headers: _json,
    );
    return EmployeeModel.fromJson(response.data!);
  }

  static Future<EmployeeModel> update(
    String id, {
    required String nom,
    required String prenom,
    String? telephone,
  }) async {
    final response = await APIService.patch(
      path: '/users/$id',
      mapData: {
        'nom': nom,
        'prenom': prenom,
        if (telephone != null && telephone.isNotEmpty) 'telephone': telephone,
      },
      headers: _json,
    );
    return EmployeeModel.fromJson(response.data!);
  }

  static Future<void> changeStatus(String id, {required bool active}) async {
    await APIService.patch(
      path: '/users/$id/status',
      mapData: {'statut': active ? 'ACTIVE' : 'INACTIVE'},
      headers: _json,
    );
  }

  static Future<void> resetPassword(String id, String password) async {
    await APIService.patch(
      path: '/users/$id/password',
      mapData: {'password': password},
      headers: _json,
    );
  }
}
