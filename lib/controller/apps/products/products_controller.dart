import 'package:foodly/helpers/extensions/string.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Trans;
import 'package:foodly/controller/my_controller.dart';
import 'package:foodly/helpers/services/realtime_service.dart';
import 'package:foodly/helpers/utils/realtime_listener.dart';
import 'package:foodly/helpers/services/error_handling.dart';
import 'package:foodly/helpers/services/product_service.dart';
import 'package:foodly/helpers/storage/local_storage.dart';
import 'package:foodly/helpers/utils/app_snackbar.dart';
import 'package:foodly/models/product_model.dart';

class ProductsController extends MyController with RealtimeListener {
  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;
  final RxList<ProductModel> products = <ProductModel>[].obs;
  final RxString search = ''.obs;

  /// Filtre d'affichage : all | low (stock bas) | out (rupture).
  final RxString filter = 'all'.obs;
  Timer? _debounce;

  List<ProductModel> get filtered {
    switch (filter.value) {
      case 'low':
        return products.where((p) => !p.enRupture && p.stockBas).toList();
      case 'out':
        return products.where((p) => p.enRupture).toList();
      default:
        return products.toList();
    }
  }

  /// Le gestionnaire (ADMIN) gère le catalogue ; l'employé le consulte seulement.
  bool get isManager => LocalStorage.getUserRole() == 'ADMIN';

  @override
  void onInit() {
    super.onInit();
    loadProducts();
    listenRealtime({'stock.updated', 'product.changed'}, (event) {
      if (event.type == 'stock.updated') {
        // Stock modifié par une vente ou un réapprovisionnement : appliqué
        // directement sur la carte du produit.
        final id = event.productId;
        final quantite = event.data['quantiteDisponible'] as int?;
        final statut = event.data['statut'] as String?;
        final index = products.indexWhere((p) => p.id == id);
        if (index < 0 || quantite == null) return;
        if (statut != null && statut != 'ACTIVE') {
          products.removeAt(index); // archivé depuis un autre appareil
        } else {
          products[index] =
              products[index].copyWith(quantiteDisponible: quantite);
        }
      } else {
        debounced('products', const Duration(milliseconds: 600),
            () => loadProducts(silent: true));
      }
    });
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

  /// [silent] : recharge en arrière-plan, sans réafficher le squelette.
  Future<void> loadProducts({bool silent = false}) async {
    if (!silent) isLoading.value = true;
    try {
      final result = await ProductService.findAll(
        search: search.value,
        statut: 'ACTIVE', // les produits archivés sont dans Paramètres
      );
      products.assignAll(result.data);
    } on DioException catch (e) {
      letMeHandleAllErrors(e);
    } finally {
      if (!silent) isLoading.value = false;
    }
  }

  /// Crée ou modifie un produit (si [id] est fourni). Si [imagePath] est
  /// renseigné, l'image est d'abord envoyée sur Cloudinary.
  Future<bool> saveProduct({
    String? id,
    required String nom,
    required double prixVente,
    double? prixAchat,
    int quantiteInitiale = 0,
    int? seuilAlerte,
    String? sku,
    String? description,
    String? existingImage,
    String? imagePath,
  }) async {
    isSaving.value = true;
    try {
      var image = existingImage;
      if (imagePath != null) {
        image = await ProductService.uploadImage(imagePath);
      }
      if (id == null) {
        await ProductService.create(
          nom: nom,
          prixVente: prixVente,
          prixAchat: prixAchat,
          quantiteDisponible: quantiteInitiale,
          seuilAlerte: seuilAlerte,
          sku: sku,
          description: description,
          image: image,
        );
      } else {
        await ProductService.update(
          id,
          nom: nom,
          prixVente: prixVente,
          prixAchat: prixAchat,
          seuilAlerte: seuilAlerte,
          sku: sku,
          description: description,
          image: image,
        );
      }
      unawaited(
          loadProducts(silent: true)); // la liste se met à jour sans bloquer
      return true;
    } on DioException catch (e) {
      letMeHandleAllErrors(e);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  /// Met un produit de côté : il disparaît de la liste et de la vente, et se
  /// retrouve dans Paramètres > Produits archivés, d'où on peut le restaurer.
  Future<void> archive(ProductModel product) async {
    try {
      await ProductService.changeStatus(product.id, active: false);
      products.removeWhere((p) => p.id == product.id);
      appSnackbar(
        heading: 'product_archived'.tr(),
        message: 'product_archived_where'.trp({'name': product.nom}),
        snackbarState: SnackbarState.success,
      );
    } on DioException catch (e) {
      letMeHandleAllErrors(e);
    }
  }

  Future<void> toggleStatus(ProductModel product) async {
    try {
      await ProductService.changeStatus(product.id,
          active: product.statut != 'ACTIVE');
      unawaited(loadProducts(silent: true));
    } on DioException catch (e) {
      letMeHandleAllErrors(e);
    }
  }

  /// Réapprovisionnement (quantité > 0) ou ajustement signé avec motif.
  Future<bool> changeStock(
    ProductModel product, {
    required int quantite,
    required bool adjustment,
    String? note,
  }) async {
    isSaving.value = true;
    try {
      if (adjustment) {
        await ProductService.adjust(product.id, quantite, note ?? '');
      } else {
        await ProductService.restock(product.id, quantite, note: note);
      }
      appSnackbar(
        heading: 'stock_updated'.tr(),
        message: product.nom,
        snackbarState: SnackbarState.success,
      );
      unawaited(
          loadProducts(silent: true)); // la liste se met à jour sans bloquer
      return true;
    } on DioException catch (e) {
      letMeHandleAllErrors(e);
      return false;
    } finally {
      isSaving.value = false;
    }
  }
}
