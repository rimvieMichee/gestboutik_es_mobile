import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:foodly/controller/my_controller.dart';
import 'package:foodly/helpers/services/realtime_service.dart';
import 'package:foodly/helpers/utils/realtime_listener.dart';
import 'package:foodly/helpers/services/error_handling.dart';
import 'package:foodly/helpers/services/sale_service.dart';
import 'package:foodly/helpers/utils/period.dart';
import 'package:foodly/models/paginated_result.dart';
import 'package:foodly/models/sale_model.dart';

/// Historique des ventes (employé : les siennes ; gestionnaire : toute la
/// boutique), filtrable par crédit et par période, avec chargement progressif.
class SalesHistoryController extends MyController with RealtimeListener {
  static const _pageSize = 20;

  final RxBool isLoading = true.obs;
  final RxBool isLoadingMore = false.obs;
  final RxList<SaleModel> sales = <SaleModel>[].obs;
  final Rx<CreditFilter> credit = CreditFilter.all.obs;
  final Rxn<Period> period = Rxn<Period>();

  int _page = 1;
  bool _hasMore = true;

  @override
  void onInit() {
    super.onInit();
    // Ouverture depuis la carte « Crédits en cours » de l'accueil.
    final args = Get.arguments;
    if (args is Map && args['credit'] == 'unpaid') {
      credit.value = CreditFilter.unpaid;
    }
    loadSales();
    listenRealtime({'sale.created', 'credit.settled'}, (_) {
      debounced('sales', const Duration(milliseconds: 700),
          () => loadSales(silent: true));
    });
  }

  Future<void> loadSales({bool silent = false}) async {
    if (!silent) isLoading.value = true;
    _page = 1;
    _hasMore = true;
    try {
      final result = await _fetch(1);
      sales.assignAll(result.data);
      _hasMore = result.meta.page < result.meta.totalPages;
    } on DioException catch (e) {
      letMeHandleAllErrors(e);
    } finally {
      if (!silent) isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (isLoading.value || isLoadingMore.value || !_hasMore) return;
    isLoadingMore.value = true;
    try {
      final result = await _fetch(_page + 1);
      _page = result.meta.page;
      sales.addAll(result.data);
      _hasMore = result.meta.page < result.meta.totalPages;
    } on DioException catch (e) {
      letMeHandleAllErrors(e);
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<PaginatedResult<SaleModel>> _fetch(int page) => SaleService.findAll(
        page: page,
        limit: _pageSize,
        period: period.value,
        credit: credit.value,
      );

  void setCredit(CreditFilter value) {
    if (credit.value == value) return;
    credit.value = value;
    loadSales();
  }

  void setPeriod(Period? value) {
    period.value = value;
    loadSales();
  }
}
