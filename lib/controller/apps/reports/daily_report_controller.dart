import 'package:foodly/helpers/extensions/string.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Trans;
import 'package:foodly/views/apps/reports/pdf_preview_screen.dart';
import 'package:foodly/controller/my_controller.dart';
import 'package:foodly/helpers/services/realtime_service.dart';
import 'package:foodly/helpers/utils/realtime_listener.dart';
import 'package:foodly/helpers/services/error_handling.dart';
import 'package:foodly/helpers/services/sale_service.dart';
import 'package:foodly/helpers/utils/app_snackbar.dart';
import 'package:foodly/helpers/utils/period.dart';
import 'package:foodly/helpers/utils/report_pdf.dart';
import 'package:foodly/models/daily_report_model.dart';

/// Rapport journalier du gestionnaire : résumé complet des ventes d'un jour
/// choisi, et export PDF.
class DailyReportController extends MyController with RealtimeListener {
  final Rx<Period> period = Period.day(DateTime.now()).obs;
  final Rxn<DailyReport> report = Rxn<DailyReport>();
  final RxBool isLoading = true.obs;

  /// Rapport de toutes les boutiques du gestionnaire (au lieu de la boutique ouverte).
  final RxBool allShops = false.obs;
  final RxBool isExporting = false.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    allShops.value = args is Map && args['all'] == true;
    load();
    listenRealtime({'sale.created', 'credit.settled'}, (_) {
      // Seul le rapport du jour en cours bouge quand une vente est enregistrée.
      final now = DateTime.now();
      final p = period.value;
      if (now.isBefore(p.start) || now.isAfter(p.end)) return;
      debounced('report', const Duration(milliseconds: 700),
          () => load(silent: true));
    });
  }

  Future<void> load({bool silent = false}) async {
    if (!silent) isLoading.value = true;
    try {
      report.value = await SaleService.report(period.value, all: allShops.value);
    } on DioException catch (e) {
      letMeHandleAllErrors(e);
    } finally {
      if (!silent) isLoading.value = false;
    }
  }

  Future<void> setAll(bool value) {
    if (allShops.value == value) return Future.value();
    allShops.value = value;
    return load();
  }

  Future<void> setDay(DateTime day) {
    period.value = Period.day(day);
    return load();
  }

  Future<void> setPeriod(Period p) {
    period.value = p;
    return load();
  }

  /// Passe à un autre type de période (jour, semaine, mois, année) en gardant
  /// la date de référence ; la plage libre est choisie par l'écran.
  Future<void> setKind(PeriodKind kind) =>
      setPeriod(Period.of(kind, period.value.start));

  Future<void> shift(int delta) {
    period.value = period.value.shift(delta);
    return load();
  }

  /// Génère le PDF et l'ouvre en aperçu ; l'envoi (WhatsApp, e-mail,
  /// fichiers...) et l'impression se décident depuis l'aperçu.
  Future<void> exportPdf() async {
    final data = report.value;
    if (data == null || isExporting.value) return;
    isExporting.value = true;
    try {
      final bytes = await buildDailyReportPdf(data, period.value);
      final p = period.value;
      String ymd(DateTime d) =>
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final scope = allShops.value ? 'rapport-toutes-boutiques' : 'rapport-ventes';
      final suffix = switch (p.kind) {
        PeriodKind.day => ymd(p.start),
        PeriodKind.week => 'semaine-${ymd(p.start)}',
        PeriodKind.month =>
          'mois-${p.start.year}-${p.start.month.toString().padLeft(2, '0')}',
        PeriodKind.year => 'annee-${p.start.year}',
        PeriodKind.custom => '${ymd(p.start)}_au_${ymd(p.end)}',
      };
      final name = '$scope-$suffix.pdf';
      await Get.to(() => PdfPreviewScreen(bytes: bytes, filename: name));
    } catch (_) {
      appSnackbar(
        heading: 'PDF',
        message: 'pdf_error'.tr(),
        snackbarState: SnackbarState.danger,
      );
    } finally {
      isExporting.value = false;
    }
  }
}
