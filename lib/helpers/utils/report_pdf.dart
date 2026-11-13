import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:foodly/helpers/utils/period.dart';
import 'package:foodly/models/daily_report_model.dart';
import 'package:foodly/widgets/gesboutik/gb_format.dart';

/// Construit le PDF « Rapport des ventes » : en-tête (boutique, gestionnaire,
/// téléphone), totaux, puis la liste complète des produits vendus avec leur
/// statut (Payé ou Crédit). Polices PDF standard : on évite les caractères hors
/// Latin-1 (tirets longs, puces…) qu'elles ne savent pas dessiner.
Future<Uint8List> buildDailyReportPdf(DailyReport report, Period period) async {
  // Les polices PDF standard ne dessinent pas le tiret long (périodes libres).
  final periodLabel = period.label.replaceAll('\u2013', '-');
  const green = PdfColor.fromInt(0xFF43A047);
  const amber = PdfColor.fromInt(0xFFF59E0B);
  const grey = PdfColor.fromInt(0xFF6B7280);
  const lightGrey = PdfColor.fromInt(0xFFF3F4F6);
  const border = PdfColor.fromInt(0xFFE5E7EB);

  final timeFmt = DateFormat('HH:mm');
  final generated = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
  final doc = pw.Document(
    title: 'Rapport des ventes - ${periodLabel}',
    author: report.boutiqueNom,
  );

  pw.Widget stat(String label, String value, {PdfColor color = green}) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        // Bordure gauche colorée : le PDF n'accepte pas de coins arrondis avec
        // une bordure non uniforme.
        decoration: pw.BoxDecoration(
          color: lightGrey,
          border: pw.Border(left: pw.BorderSide(color: color, width: 3)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label,
                style: const pw.TextStyle(fontSize: 8.5, color: grey)),
            pw.SizedBox(height: 3),
            pw.Text(value,
                style:
                    pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  final phone = report.telephoneAffiche;

  // Une ligne de tableau par produit vendu.
  final rows = <List<String>>[];
  final creditRows = <int>{};
  for (final sale in report.ventes) {
    for (final line in sale.lignes) {
      if (sale.isCredit) creditRows.add(rows.length);
      rows.add([
        // VENTE-000007 -> #7 : court, sans retour à la ligne dans la colonne.
        '#${int.tryParse(sale.numeroVente.replaceFirst('VENTE-', '')) ?? sale.numeroVente}',
        timeFmt.format(sale.date),
        line.produit,
        '${line.quantite}',
        formatFcfa(line.prixUnitaire),
        formatFcfa(line.sousTotal),
        sale.statutLabel,
        [
          if (report.consolide && (sale.boutique ?? '').isNotEmpty)
            sale.boutique!,
          sale.isCredit
              ? (sale.clientNom ?? '-')
              : (sale.vendeur.isEmpty ? '-' : sale.vendeur),
        ].join(' · '),
      ]);
    }
  }

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 32),
      header: (ctx) => ctx.pageNumber == 1
          ? pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            report.boutiqueNom.isEmpty
                                ? 'Boutique'
                                : report.boutiqueNom,
                            style: pw.TextStyle(
                                fontSize: 20,
                                fontWeight: pw.FontWeight.bold,
                                color: green),
                          ),
                          if (report.boutiqueAdresse != null)
                            pw.Text(report.boutiqueAdresse!,
                                style: const pw.TextStyle(
                                    fontSize: 9, color: grey)),
                          pw.SizedBox(height: 6),
                          pw.Text(
                            'Gestionnaire : ${report.gestionnaireNom.isEmpty ? '-' : report.gestionnaireNom}',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                          pw.Text(
                            'Tél : ${phone ?? 'non renseigné'}',
                            style: pw.TextStyle(
                                fontSize: 10, fontWeight: pw.FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('RAPPORT DES VENTES',
                            style: pw.TextStyle(
                                fontSize: 13, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 3),
                        pw.Text(periodLabel,
                            style: const pw.TextStyle(fontSize: 11)),
                        pw.SizedBox(height: 3),
                        pw.Text('Généré le $generated',
                            style:
                                const pw.TextStyle(fontSize: 8, color: grey)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Divider(color: green, thickness: 1.5),
                pw.SizedBox(height: 10),
              ],
            )
          : pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(report.boutiqueNom,
                      style: const pw.TextStyle(fontSize: 9, color: grey)),
                  pw.Text('Rapport des ventes - ${periodLabel}',
                      style: const pw.TextStyle(fontSize: 9, color: grey)),
                ],
              ),
            ),
      footer: (ctx) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('GesBoutik',
              style: const pw.TextStyle(fontSize: 8, color: grey)),
          pw.Text('Page ${ctx.pageNumber} / ${ctx.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: grey)),
        ],
      ),
      build: (ctx) => [
        pw.Row(children: [
          stat("Chiffre d'affaires", formatFcfa(report.chiffreAffaires)),
          pw.SizedBox(width: 8),
          stat('Ventes', '${report.nombreVentes}'),
          pw.SizedBox(width: 8),
          stat('Articles vendus', '${report.articlesVendus}'),
        ]),
        pw.SizedBox(height: 8),
        pw.Row(children: [
          stat('Encaissé (payé)', formatFcfa(report.encaisse)),
          pw.SizedBox(width: 8),
          stat('À crédit (non réglé)', formatFcfa(report.creditDu),
              color: amber),
          pw.SizedBox(width: 8),
          pw.Expanded(child: pw.SizedBox()),
        ]),
        if (report.consolide && report.parBoutique.isNotEmpty) ...[
          pw.SizedBox(height: 14),
          pw.Text('Par boutique',
              style:
                  pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: const ['Boutique', 'Ventes', "Chiffre d'affaires", 'À crédit'],
            data: [
              for (final s in report.parBoutique)
                [
                  s.nom,
                  '${s.nombreVentes}',
                  formatFcfa(s.chiffreAffaires),
                  formatFcfa(s.creditDu),
                ],
            ],
            headerStyle: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: green),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellPadding:
                const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
            border: pw.TableBorder(
              horizontalInside: pw.BorderSide(color: border, width: 0.5),
              bottom: pw.BorderSide(color: border, width: 0.5),
            ),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FixedColumnWidth(44),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(2),
            },
            cellAlignments: {
              1: pw.Alignment.centerRight,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
            },
            oddRowDecoration: const pw.BoxDecoration(color: lightGrey),
          ),
        ],
        pw.SizedBox(height: 16),
        pw.Text('Détail des produits vendus',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        if (rows.isEmpty)
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(24),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: border),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Center(
              child: pw.Text('Aucune vente enregistrée sur cette période.',
                  style: const pw.TextStyle(fontSize: 10, color: grey)),
            ),
          )
        else
          pw.TableHelper.fromTextArray(
            headers: const [
              'N°',
              'Heure',
              'Produit',
              'Qté',
              'Prix unit.',
              'Montant',
              'Statut',
              'Client / Vendeur',
            ],
            data: rows,
            headerStyle: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: green),
            cellStyle: const pw.TextStyle(fontSize: 8.5),
            cellPadding:
                const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
            border: pw.TableBorder(
              horizontalInside: pw.BorderSide(color: border, width: 0.5),
              bottom: pw.BorderSide(color: border, width: 0.5),
            ),
            columnWidths: {
              0: const pw.FixedColumnWidth(34),
              1: const pw.FixedColumnWidth(34),
              2: const pw.FlexColumnWidth(3),
              3: const pw.FixedColumnWidth(26),
              4: const pw.FlexColumnWidth(1.6),
              5: const pw.FlexColumnWidth(1.7),
              6: const pw.FixedColumnWidth(42),
              7: const pw.FlexColumnWidth(2),
            },
            cellAlignments: {
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
              5: pw.Alignment.centerRight,
            },
            oddRowDecoration: const pw.BoxDecoration(color: lightGrey),
            // Les lignes à crédit ressortent en orange dans la colonne Statut
            // (rowNum compte l'en-tête comme ligne 0).
            cellDecoration: (index, data, rowNum) => creditRows
                        .contains(rowNum - 1) &&
                    index == 6
                ? const pw.BoxDecoration(color: PdfColor.fromInt(0xFFFEF3C7))
                : const pw.BoxDecoration(),
          ),
        if (rows.isNotEmpty) ...[
          pw.SizedBox(height: 10),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: pw.BoxDecoration(
                color: green,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Text(
                'TOTAL : ${formatFcfa(report.chiffreAffaires)}',
                style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white),
              ),
            ),
          ),
        ],
      ],
    ),
  );

  return doc.save();
}
