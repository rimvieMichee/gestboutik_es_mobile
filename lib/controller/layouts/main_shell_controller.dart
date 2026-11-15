import 'package:get/get.dart';
import 'package:foodly/helpers/storage/local_storage.dart';

/// Contrôleur de la coquille principale (bottom nav) affichée après connexion.
class MainShellController extends GetxController {
  MainShellController({int initialIndex = 0}) : currentIndex = initialIndex.obs;

  final RxInt currentIndex;

  /// Onglet Vente : au milieu pour le gestionnaire (2), deuxième pour l'employé (1).
  static int get saleTab => LocalStorage.getUserRole() == 'ADMIN' ? 2 : 1;

  void changeTab(int index) => currentIndex.value = index;
}
