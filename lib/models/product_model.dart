class ProductModel {
  final String id;
  final String nom;
  final String? description;
  final double prixVente;
  final double? prixAchat;
  final int quantiteDisponible;
  final int seuilAlerte;
  final String? sku;
  final String? image;
  final String statut;
  final String boutiqueId;

  ProductModel({
    required this.id,
    required this.nom,
    this.description,
    required this.prixVente,
    this.prixAchat,
    required this.quantiteDisponible,
    required this.seuilAlerte,
    this.sku,
    this.image,
    required this.statut,
    required this.boutiqueId,
  });

  /// Copie avec une nouvelle quantité (mise à jour en direct du stock).
  ProductModel copyWith({int? quantiteDisponible, String? statut}) {
    return ProductModel(
      id: id,
      nom: nom,
      description: description,
      prixVente: prixVente,
      prixAchat: prixAchat,
      quantiteDisponible: quantiteDisponible ?? this.quantiteDisponible,
      seuilAlerte: seuilAlerte,
      sku: sku,
      image: image,
      statut: statut ?? this.statut,
      boutiqueId: boutiqueId,
    );
  }

  bool get stockBas => quantiteDisponible <= seuilAlerte;
  bool get enRupture => quantiteDisponible <= 0;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      nom: json['nom'] as String,
      description: json['description'] as String?,
      prixVente: double.parse(json['prixVente'].toString()),
      prixAchat: json['prixAchat'] != null
          ? double.parse(json['prixAchat'].toString())
          : null,
      quantiteDisponible: json['quantiteDisponible'] as int,
      seuilAlerte: json['seuilAlerte'] as int,
      sku: json['sku'] as String?,
      image: json['image'] as String?,
      statut: json['statut'] as String,
      boutiqueId: json['boutiqueId'] as String,
    );
  }
}
