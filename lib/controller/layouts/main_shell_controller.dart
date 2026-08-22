import 'package:get/get.dart';

/// Contrôleur de la coquille principale (bottom nav) affichée après connexion.
class MainShellController extends GetxController {
  final RxInt currentIndex = 0.obs;

  void changeTab(int index) => currentIndex.value = index;
}
