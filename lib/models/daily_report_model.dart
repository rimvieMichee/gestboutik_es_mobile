double _num(dynamic v) => double.parse(v.toString());

/// Une ligne de vente (un produit vendu).
class ReportLine {
  final String produit;
  final int quantite;
  final double prixUnitaire;
  final double sousTotal;

  ReportLine({
    required this.produit,
    required this.quantite,
    required this.prixUnitaire,
    required this.sousTotal,
  });

  factory ReportLine.fromJson(Map<String, dynamic> j) => ReportLine(
        produit: j['produit'] as String,
        quantite: j['quantite'] as int,
        prixUnitaire: _num(j['prixUnitaire']),
        sousTotal: _num(j['sousTotal']),
      );
}

/// Une vente du rapport : « Crédit » tant que l'emprunteur n'a pas payé, sinon « Payé ».
class ReportSale {
  final String numeroVente;
  final DateTime date;
  final double montantTotal;
  final bool isCredit;
  final String? clientNom;
  final String vendeur;

  /// Boutique de la vente (rapport consolidé).
  final String? boutique;
  final List<ReportLine> lignes;

  ReportSale({
    this.boutique,
    required this.numeroVente,
    required this.date,
    required this.montantTotal,
    required this.isCredit,
    required this.clientNom,
    required this.vendeur,
    required this.lignes,
  });

  String get statutLabel => isCredit ? 'Crédit' : 'Payé';

  factory ReportSale.fromJson(Map<String, dynamic> j) => ReportSale(
        numeroVente: j['numeroVente'] as String,
        date: DateTime.parse(j['date'] as String).toLocal(),
        montantTotal: _num(j['montantTotal']),
        isCredit: j['statut'] == 'CREDIT',
        clientNom: j['clientNom'] as String?,
        vendeur: (j['vendeur'] as String?) ?? '',
        boutique: j['boutique'] as String?,
        lignes: (j['lignes'] as List)
            .map((e) => ReportLine.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Une boutique dans le rapport consolidé.
class ReportShop {
  final String nom;
  final int nombreVentes;
  final double chiffreAffaires;
  final double creditDu;

  const ReportShop({
    required this.nom,
    required this.nombreVentes,
    required this.chiffreAffaires,
    required this.creditDu,
  });

  factory ReportShop.fromJson(Map<String, dynamic> j) => ReportShop(
        nom: j['nom'] as String,
        nombreVentes: j['nombreVentes'] as int,
        chiffreAffaires: _num(j['chiffreAffaires']),
        creditDu: _num(j['creditDu']),
      );
}

/// Rapport complet des ventes d'une période (renvoyé par `GET /sales/report`).
class DailyReport {
  /// Vrai pour le rapport de toutes les boutiques du gestionnaire.
  final bool consolide;
  final List<ReportShop> parBoutique;
  final String boutiqueNom;
  final String? boutiqueTelephone;
  final String? boutiqueAdresse;
  final String gestionnaireNom;
  final String? gestionnaireTelephone;

  final int nombreVentes;
  final int articlesVendus;
  final double chiffreAffaires;
  final double encaisse;
  final double creditDu;
  final List<ReportSale> ventes;

  DailyReport({
    this.consolide = false,
    this.parBoutique = const [],
    required this.boutiqueNom,
    required this.boutiqueTelephone,
    required this.boutiqueAdresse,
    required this.gestionnaireNom,
    required this.gestionnaireTelephone,
    required this.nombreVentes,
    required this.articlesVendus,
    required this.chiffreAffaires,
    required this.encaisse,
    required this.creditDu,
    required this.ventes,
  });

  /// Numéro affiché en en-tête : celui du gestionnaire, à défaut celui de la boutique.
  String? get telephoneAffiche {
    final g = gestionnaireTelephone?.trim();
    if (g != null && g.isNotEmpty) return g;
    final b = boutiqueTelephone?.trim();
    return (b != null && b.isNotEmpty) ? b : null;
  }

  bool get gestionnaireSansNumero =>
      (gestionnaireTelephone ?? '').trim().isEmpty;

  factory DailyReport.fromJson(Map<String, dynamic> j) {
    final boutique = (j['boutique'] as Map?) ?? const {};
    final gest = (j['gestionnaire'] as Map?) ?? const {};
    final totaux = j['totaux'] as Map<String, dynamic>;
    final adresse = [boutique['adresse'], boutique['ville']]
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .join(', ');
    return DailyReport(
      consolide: j['consolide'] == true,
      parBoutique: ((j['parBoutique'] as List?) ?? const [])
          .map((e) => ReportShop.fromJson(e as Map<String, dynamic>))
          .toList(),
      boutiqueNom: (boutique['nom'] as String?) ?? '',
      boutiqueTelephone: boutique['telephone'] as String?,
      boutiqueAdresse: adresse.isEmpty ? null : adresse,
      gestionnaireNom: '${gest['prenom'] ?? ''} ${gest['nom'] ?? ''}'.trim(),
      gestionnaireTelephone: gest['telephone'] as String?,
      nombreVentes: totaux['nombreVentes'] as int,
      articlesVendus: totaux['articlesVendus'] as int,
      chiffreAffaires: _num(totaux['chiffreAffaires']),
      encaisse: _num(totaux['encaisse']),
      creditDu: _num(totaux['creditDu']),
      ventes: (j['ventes'] as List)
          .map((e) => ReportSale.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
