/// Compte employé d'une boutique, tel que renvoyé par `GET /users`
/// (visible uniquement par le gestionnaire de la boutique).
class EmployeeModel {
  final String id;
  final String nom;
  final String prenom;
  final String username;
  final String? telephone;
  final String? email;
  final String statut;
  final DateTime? createdAt;

  EmployeeModel({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.username,
    required this.statut,
    this.telephone,
    this.email,
    this.createdAt,
  });

  bool get isActive => statut == 'ACTIVE';

  String get nomComplet {
    final full = '$prenom $nom'.trim();
    return full.isEmpty ? username : full;
  }

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['id'] as String,
      nom: (json['nom'] as String?) ?? '',
      prenom: (json['prenom'] as String?) ?? '',
      username: json['username'] as String,
      telephone: json['telephone'] as String?,
      email: json['email'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)?.toLocal()
          : null,
      statut: (json['statut'] as String?) ?? 'ACTIVE',
    );
  }
}

/// Activité d'un employé (ventes et chiffre d'affaires), voir `GET /users/:id/stats`.
class EmployeeStats {
  final int nombreVentes;
  final double chiffreAffaires;
  final int ventesDuJour;
  final double chiffreAffairesDuJour;
  final DateTime? derniereVente;

  EmployeeStats({
    required this.nombreVentes,
    required this.chiffreAffaires,
    required this.ventesDuJour,
    required this.chiffreAffairesDuJour,
    this.derniereVente,
  });

  factory EmployeeStats.fromJson(Map<String, dynamic> json) {
    return EmployeeStats(
      nombreVentes: json['nombreVentes'] as int,
      chiffreAffaires: double.parse(json['chiffreAffaires'].toString()),
      ventesDuJour: json['ventesDuJour'] as int,
      chiffreAffairesDuJour:
          double.parse(json['chiffreAffairesDuJour'].toString()),
      derniereVente: json['derniereVente'] != null
          ? DateTime.tryParse(json['derniereVente'] as String)?.toLocal()
          : null,
    );
  }
}
