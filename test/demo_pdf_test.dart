import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:foodly/helpers/utils/period.dart';
import 'package:foodly/helpers/utils/report_pdf.dart';
import 'package:foodly/models/daily_report_model.dart';

/// Génère le PDF du rapport journalier à partir d'un JSON réel renvoyé par
/// `GET /sales/report` (REPORT_JSON) ; sert à la vidéo de présentation.
void main() {
  test('PDF du rapport depuis des données réelles', () async {
    final src = Platform.environment['REPORT_JSON'];
    final out = Platform.environment['PDF_OUT'];
    if (src == null || out == null) return;
    await initializeDateFormatting('fr_FR');
    final report = DailyReport.fromJson(
        jsonDecode(File(src).readAsStringSync()) as Map<String, dynamic>);
    final bytes = await buildDailyReportPdf(report, Period.day(DateTime.now()));
    File(out).writeAsBytesSync(bytes);
  });
}
