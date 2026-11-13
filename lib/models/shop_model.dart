double _num(dynamic v) => double.parse((v ?? 0).toString());

/// Une boutique d'un gestionnaire, avec ses chiffres du jour (`GET /boutiques/mine`).
class ShopModel {
  final String id;
  final String nom;
  final String? ville;
  final String statut;

  /// Boutique actuellement ouverte dans l'appli.
  final bool active;
  final int ventesJour;
  final double chiffreAffairesJour;
  final int creditNombre;
  final double creditMontant;

  const ShopModel({
    required this.id,
    required this.nom,
    this.ville,
    this.statut = 'ACTIVE',
    this.active = false,
    this.ventesJour = 0,
    this.chiffreAffairesJour = 0,
    this.creditNombre = 0,
    this.creditMontant = 0,
  });

  bool get isOpen => statut == 'ACTIVE';

  factory ShopModel.fromJson(Map<String, dynamic> j) {
    final today = (j['aujourdhui'] as Map?) ?? const {};
    final credit = (j['creditEnCours'] as Map?) ?? const {};
    return ShopModel(
      id: j['id'] as String,
      nom: j['nom'] as String,
      ville: j['ville'] as String?,
      statut: (j['statut'] as String?) ?? 'ACTIVE',
      active: j['active'] == true,
      ventesJour: (today['ventes'] as int?) ?? 0,
      chiffreAffairesJour: _num(today['chiffreAffaires']),
      creditNombre: (credit['nombre'] as int?) ?? 0,
      creditMontant: _num(credit['montant']),
    );
  }
}
