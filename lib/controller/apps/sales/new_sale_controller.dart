import 'dart:async';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:foodly/controller/my_controller.dart';
import 'package:foodly/helpers/services/error_handling.dart';
import 'package:foodly/helpers/services/product_service.dart';
import 'package:foodly/helpers/services/sale_service.dart';
import 'package:foodly/helpers/utils/app_snackbar.dart';
import 'package:foodly/models/product_model.dart';
import 'package:foodly/models/sale_model.dart';

class CartLine {
  final ProductModel product;
  final int quantite;

  CartLine({required this.product, required this.quantite});

  double get sousTotal => product.prixVente * quantite;
}

class NewSaleController extends MyController {
  final RxBool isLoadingProducts = true.obs;
  final RxBool isSubmitting = false.obs;
  final RxList<ProductModel> products = <ProductModel>[].obs;
  final RxString search = ''.obs;

  /// productId -> quantité choisie
  final RxMap<String, int> cart = <String, int>{}.obs;

  /// Conserve les produits déjà vus (au-delà de la liste filtrée courante),
  /// pour que le panier reste valide même si une recherche masque un produit.
  final Map<String, ProductModel> _productCache = {};

  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    loadProducts();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }

  void onSearchChanged(String value) {
    search.value = value;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), loadProducts);
  }

  Future<void> loadProducts() async {
    isLoadingProducts.value = true;
    try {
      final result = await ProductService.findAll(search: search.value);
      products.assignAll(result.data);
      for (final product in result.data) {
        _productCache[product.id] = product;
      }
    } on DioException catch (e) {
      letMeHandleAllErrors(e);
    } finally {
      isLoadingProducts.value = false;
    }
  }

  int quantityOf(String productId) => cart[productId] ?? 0;

  void addToCart(ProductModel product) {
    _productCache[product.id] = product;
    final current = cart[product.id] ?? 0;
    if (current + 1 > product.quantiteDisponible) {
      appSnackbar(
        heading: "Stock insuffisant",
        message: "Il ne reste que ${product.quantiteDisponible} en stock pour \"${product.nom}\".",
        snackbarState: SnackbarState.warning,
      );
      return;
    }
    cart[product.id] = current + 1;
  }

  void decrementFromCart(ProductModel product) {
    final current = cart[product.id] ?? 0;
    if (current <= 1) {
      cart.remove(product.id);
    } else {
      cart[product.id] = current - 1;
    }
  }

  void removeFromCart(String productId) => cart.remove(productId);

  List<CartLine> get cartLines {
    return cart.entries
        .where((entry) => _productCache.containsKey(entry.key))
        .map((entry) => CartLine(product: _productCache[entry.key]!, quantite: entry.value))
        .toList();
  }

  int get totalItems => cart.values.fold(0, (sum, qty) => sum + qty);

  double get totalAmount =>
      cartLines.fold(0, (sum, line) => sum + line.sousTotal);

  void clearCart() => cart.clear();

  Future<SaleModel?> submitSale() async {
    if (cart.isEmpty) return null;

    isSubmitting.value = true;
    try {
      final items = cart.entries
          .map((e) => SaleItemInput(productId: e.key, quantite: e.value))
          .toList();
      final sale = await SaleService.create(items);
      clearCart();
      return sale;
    } on DioException catch (e) {
      letMeHandleAllErrors(e);
      return null;
    } finally {
      isSubmitting.value = false;
    }
  }
}
