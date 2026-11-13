import 'package:flutter/foundation.dart';

/// Libère des contrôleurs de saisie une fois la fenêtre fermée.
///
/// À utiliser à la place de `showXxx(...).whenComplete(controller.dispose)` :
/// le future d'une feuille ou d'une boîte de dialogue se termine dès le début
/// de la fermeture, alors que l'animation de sortie utilise encore les champs
/// (erreur « TextEditingController was used after being disposed »).
void disposeAfterClose(List<ChangeNotifier> controllers) {
  Future<void>.delayed(const Duration(milliseconds: 700), () {
    for (final c in controllers) {
      c.dispose();
    }
  });
}
