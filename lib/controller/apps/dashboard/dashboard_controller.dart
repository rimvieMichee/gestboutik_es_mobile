import 'package:dio/dio.dart';
import 'package:foodly/controller/my_controller.dart';
import 'package:foodly/helpers/services/dashboard_service.dart';
import 'package:foodly/helpers/services/realtime_service.dart';
import 'package:foodly/helpers/utils/realtime_listener.dart';
import 'package:foodly/helpers/services/error_handling.dart';
import 'package:foodly/helpers/services/sale_service.dart';
import 'package:foodly/helpers/storage/local_storage.dart';
import 'package:foodly/helpers/utils/period.dart';
import 'package:foodly/models/sale_model.dart';

/// Accueil : totaux des ventes (aujourd'hui, ce mois, cette année), crédits en
/// cours, et consultation d'une période au choix (jour, mois, année, ou
/// intervalle libre). L'employé voit ses ventes, le gestionnaire celles de
/// toute la boutique.
class DashboardController extends MyController with RealtimeListener {
  bool isLoading = false;
  bool isPeriodLoading = false;
  bool hasLoaded = false;

  SalesSummary today = const SalesSummary();
  SalesSummary month = const SalesSummary();
  SalesSummary year = const SalesSummary();

  /// Semaine en cours (lundi à dimanche) et la précédente, pour la comparaison.
  SalesSummary week = const SalesSummary();
  SalesSummary lastWeek = const SalesSummary();

  /// Période consultée et ses totaux.
  Period period = Period.day(DateTime.now());
  SalesSummary periodSummary = const SalesSummary();

  /// Effectifs de la boutique (gestionnaire uniquement).
  int employeeCount = 0;
  int productCount = 0;

  String get employeeName => LocalStorage.getUserName() ?? '';
  bool get isManager => LocalStorage.getUserRole() == 'ADMIN';
  String get boutiqueName => LocalStorage.getBoutiqueName() ?? '';

  /// Crédits encore dus (indépendant de la période consultée).
  double get creditDu => today.creditEnCoursMontant;
  int get creditDuNombre => today.creditEnCoursNombre;

  @override
  void onInit() {
    super.onInit();
    loadDashboard();
    // Chiffres en direct : une vente ou un règlement de crédit les recalcule.
    listenRealtime({'sale.created', 'credit.settled'}, (_) {
      debounced('dashboard', const Duration(milliseconds: 700),
          () => loadDashboard(silent: true));
    });
  }

  /// [silent] : rafraîchit les chiffres sans remettre les squelettes.
  Future<void> loadDashboard({bool silent = false}) async {
    if (!silent) {
      isLoading = true;
      update();
    }

    final now = DateTime.now();
    try {
      // Une seule requête pour tous les totaux (au lieu de sept) : c'est elle
      // qui rend l'accueil rapide, surtout sur un réseau mobile.
      final r = await SaleService.summaries({
        'today': Period.day(now),
        'month': Period.month(now),
        'year': Period.year(now),
        'period': period,
        'week': Period.week(now),
        'lastWeek': Period.week(now).shift(-1),
      });
      today = r.summaries['today']!;
      month = r.summaries['month']!;
      year = r.summaries['year']!;
      periodSummary = r.summaries['period']!;
      week = r.summaries['week']!;
      lastWeek = r.summaries['lastWeek']!;
      if (isManager) {
        employeeCount = r.employees;
        productCount = r.products;
      }
      hasLoaded = true;
    } on DioException catch (e) {
      letMeHandleAllErrors(e);
    } finally {
      isLoading = false;
      update();
    }
  }

  /// Change la période consultée et recharge ses totaux.
  Future<void> setPeriod(Period next) async {
    period = next;
    isPeriodLoading = true;
    update();
    try {
      periodSummary = await SaleService.summary(period: next);
    } on DioException catch (e) {
      letMeHandleAllErrors(e);
    } finally {
      isPeriodLoading = false;
      update();
    }
  }

  /// Passe à un autre type de période en gardant la date de référence.
  Future<void> selectKind(PeriodKind kind) =>
      setPeriod(Period.of(kind, period.start));

  Future<void> shift(int delta) => setPeriod(period.shift(delta));
}
