import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:foodly/helpers/utils/period.dart';
import 'package:foodly/helpers/utils/report_pdf.dart';
import 'package:foodly/models/daily_report_model.dart';

DailyReport _sample({bool empty = false}) => DailyReport.fromJson({
      'boutique': {
        'nom': 'Boutique Centrale',
        'telephone': '+22670000000',
        'adresse': 'Avenue Kwame Nkrumah',
        'ville': 'Ouagadougou',
      },
      'gestionnaire': {
        'nom': 'Ouédraogo',
        'prenom': 'Issa',
        'telephone': '+22676543210'
      },
      'totaux': {
        'nombreVentes': empty ? 0 : 2,
        'articlesVendus': empty ? 0 : 5,
        'chiffreAffaires': empty ? '0' : '10500',
        'encaisse': empty ? '0' : '4500',
        'creditDu': empty ? '0' : '6000',
      },
      'ventes': empty
          ? []
          : [
              {
                'numeroVente': 'VENTE-000001',
                'date': '2026-11-11T09:30:00.000Z',
                'montantTotal': '4500',
                'statut': 'PAYE',
                'clientNom': null,
                'vendeur': 'Awa Kaboré',
                'lignes': [
                  {
                    'produit': 'Riz 25 kg',
                    'quantite': 1,
                    'prixUnitaire': '4500',
                    'sousTotal': '4500'
                  },
                ],
              },
              {
                'numeroVente': 'VENTE-000002',
                'date': '2026-11-11T14:05:00.000Z',
                'montantTotal': '6000',
                'statut': 'CREDIT',
                'clientNom': 'Boureima Sana',
                'vendeur': 'Awa Kaboré',
                'lignes': [
                  {
                    'produit':
                        'Huile 5 L (très longue désignation pour tester le retour à la ligne)',
                    'quantite': 2,
                    'prixUnitaire': '2500',
                    'sousTotal': '5000'
                  },
                  {
                    'produit': 'Sucre',
                    'quantite': 2,
                    'prixUnitaire': '500',
                    'sousTotal': '1000'
                  },
                ],
              },
            ],
    });

void main() {
  setUpAll(() => initializeDateFormatting('fr_FR'));

  test('le rapport du jour produit un PDF valide', () async {
    final bytes = await buildDailyReportPdf(
        _sample(), Period.day(DateTime(2026, 11, 11)));
    expect(utf8.decode(bytes.sublist(0, 5)), '%PDF-');
    expect(bytes.length, greaterThan(1500));
  });

  test('un jour sans vente produit quand même un PDF', () async {
    final bytes = await buildDailyReportPdf(
        _sample(empty: true), Period.day(DateTime(2026, 11, 11)));
    expect(utf8.decode(bytes.sublist(0, 5)), '%PDF-');
  });

  test('beaucoup de lignes : le tableau passe sur plusieurs pages', () async {
    final big = DailyReport.fromJson({
      'boutique': {'nom': 'B'},
      'gestionnaire': {'nom': 'G', 'prenom': 'P'},
      'totaux': {
        'nombreVentes': 120,
        'articlesVendus': 120,
        'chiffreAffaires': '120000',
        'encaisse': '120000',
        'creditDu': '0'
      },
      'ventes': List.generate(
          120,
          (i) => {
                'numeroVente': 'VENTE-${(i + 1).toString().padLeft(6, '0')}',
                'date': '2026-11-11T10:00:00.000Z',
                'montantTotal': '1000',
                'statut': i % 3 == 0 ? 'CREDIT' : 'PAYE',
                'clientNom': 'Client $i',
                'vendeur': 'Vendeur',
                'lignes': [
                  {
                    'produit': 'Produit $i',
                    'quantite': 1,
                    'prixUnitaire': '1000',
                    'sousTotal': '1000'
                  }
                ],
              }),
    });
    final bytes =
        await buildDailyReportPdf(big, Period.day(DateTime(2026, 11, 11)));
    expect(bytes.length, greaterThan(5000));
    expect(_sample().telephoneAffiche, '+22676543210');
  });
}
