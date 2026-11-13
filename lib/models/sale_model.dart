import 'package:foodly/models/product_model.dart';

class SaleItemModel {
  final String id;
  final int quantite;
  final double prixUnitaire;
  final double sousTotal;
  final ProductModel product;

  SaleItemModel({
    required this.id,
    required this.quantite,
    required this.prixUnitaire,
    required this.sousTotal,
    required this.product,
  });

  factory SaleItemModel.fromJson(Map<String, dynamic> json) {
    return SaleItemModel(
      id: json['id'] as String,
      quantite: json['quantite'] as int,
      prixUnitaire: double.parse(json['prixUnitaire'].toString()),
      sousTotal: double.parse(json['sousTotal'].toString()),
      product: ProductModel.fromJson(json['product'] as Map<String, dynamic>),
    );
  }
}

class SaleModel {
  final String id;
  final String numeroVente;
  final String date;
  final double montantTotal;
  final String statut;
  final List<SaleItemModel> items;

  /// Vente à crédit : [clientNom] est l'emprunteur ; tant que
  /// [creditRegleAt] est vide, la somme est encore due.
  final bool isCredit;
  final String? clientNom;
  final DateTime? creditRegleAt;

  /// Employé qui a réalisé la vente (renvoyé pour le gestionnaire).
  final String? vendeur;

  SaleModel({
    required this.id,
    required this.numeroVente,
    required this.date,
    required this.montantTotal,
    required this.statut,
    required this.items,
    this.isCredit = false,
    this.clientNom,
    this.creditRegleAt,
    this.vendeur,
  });

  bool get creditEnCours => isCredit && creditRegleAt == null;

  factory SaleModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    String? vendeur;
    if (user is Map) {
      final full = '${user['prenom'] ?? ''} ${user['nom'] ?? ''}'.trim();
      vendeur = full.isEmpty ? null : full;
    }
    return SaleModel(
      id: json['id'] as String,
      numeroVente: json['numeroVente'] as String,
      date: (json['createdAt'] ?? json['date']) as String,
      montantTotal: double.parse(json['montantTotal'].toString()),
      statut: json['statut'] as String,
      items: (json['items'] as List? ?? [])
          .map((e) => SaleItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      isCredit: json['isCredit'] == true,
      clientNom: json['clientNom'] as String?,
      creditRegleAt: json['creditRegleAt'] != null
          ? DateTime.tryParse(json['creditRegleAt'] as String)?.toLocal()
          : null,
      vendeur: vendeur,
    );
  }
}

/// Totaux d'une période, renvoyés par `GET /sales/summary`.
class SalesSummary {
  final int nombreVentes;
  final double chiffreAffaires;

  /// Part vendue à crédit sur la période.
  final int nombreCredits;
  final double creditMontant;

  /// Tout ce qui reste dû à ce jour (indépendant de la période).
  final int creditEnCoursNombre;
  final double creditEnCoursMontant;

  const SalesSummary({
    this.nombreVentes = 0,
    this.chiffreAffaires = 0,
    this.nombreCredits = 0,
    this.creditMontant = 0,
    this.creditEnCoursNombre = 0,
    this.creditEnCoursMontant = 0,
  });

  factory SalesSummary.fromJson(Map<String, dynamic> j) => SalesSummary(
        nombreVentes: j['nombreVentes'] as int,
        chiffreAffaires: double.parse(j['chiffreAffaires'].toString()),
        nombreCredits: j['nombreCredits'] as int,
        creditMontant: double.parse(j['creditMontant'].toString()),
        creditEnCoursNombre: j['creditEnCoursNombre'] as int,
        creditEnCoursMontant:
            double.parse(j['creditEnCoursMontant'].toString()),
      );
}
