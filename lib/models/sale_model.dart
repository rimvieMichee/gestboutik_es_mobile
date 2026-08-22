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

  SaleModel({
    required this.id,
    required this.numeroVente,
    required this.date,
    required this.montantTotal,
    required this.statut,
    required this.items,
  });

  factory SaleModel.fromJson(Map<String, dynamic> json) {
    return SaleModel(
      id: json['id'] as String,
      numeroVente: json['numeroVente'] as String,
      date: (json['createdAt'] ?? json['date']) as String,
      montantTotal: double.parse(json['montantTotal'].toString()),
      statut: json['statut'] as String,
      items: (json['items'] as List? ?? [])
          .map((e) => SaleItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
