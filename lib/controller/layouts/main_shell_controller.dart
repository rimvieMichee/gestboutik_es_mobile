import 'package:get/get.dart';

/// Contrôleur de la coquille principale (bottom nav) affichée après connexion.
class MainShellController extends GetxController {
  MainShellController({int initialIndex = 0}) : currentIndex = initialIndex.obs;

  final RxInt currentIndex;

  void changeTab(int index) => currentIndex.value = index;
}
