/// Boutique minimale, telle que renvoyée avec l'utilisateur par `/auth/login`.
class BoutiqueSummary {
  final String id;
  final String nom;
  final String statut;

  BoutiqueSummary({required this.id, required this.nom, required this.statut});

  factory BoutiqueSummary.fromJson(Map<String, dynamic> json) {
    return BoutiqueSummary(
      id: json['id'] as String,
      nom: json['nom'] as String,
      statut: json['statut'] as String,
    );
  }
}

/// Utilisateur connecté (SUPER_ADMIN ou EMPLOYEE), tel que renvoyé par le backend GesBoutik.
class UserModel {
  final String id;
  final String nom;
  final String prenom;
  final String username;
  final String role;
  final String? boutiqueId;
  final BoutiqueSummary? boutique;

  /// Boutiques que ce gestionnaire peut ouvrir (vide pour les autres rôles).
  final List<BoutiqueSummary> boutiques;

  UserModel({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.username,
    required this.role,
    this.boutiqueId,
    this.boutique,
    this.boutiques = const [],
  });

  String get nomComplet => '$prenom $nom';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      nom: json['nom'] as String,
      prenom: json['prenom'] as String,
      username: json['username'] as String,
      role: json['role'] as String,
      boutiqueId: json['boutiqueId'] as String?,
      boutique: json['boutique'] != null
          ? BoutiqueSummary.fromJson(json['boutique'] as Map<String, dynamic>)
          : null,
      boutiques: ((json['boutiques'] as List?) ?? const [])
          .map((e) => BoutiqueSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
