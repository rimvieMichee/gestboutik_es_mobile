import 'dart:async';
import 'package:get/get.dart';
import 'package:foodly/helpers/services/realtime_service.dart';

/// Permet à un contrôleur d'écouter les événements temps réel, avec
/// regroupement (debounce) des rechargements et désabonnement automatique.
mixin RealtimeListener on GetxController {
  StreamSubscription<RealtimeEvent>? _realtimeSub;
  final Map<String, Timer> _debounceTimers = {};

  /// Appelle [onEvent] pour chaque événement dont le type est dans [types].
  /// Les resynchronisations (après une coupure réseau) sont toujours transmises.
  void listenRealtime(Set<String> types, void Function(RealtimeEvent) onEvent) {
    _realtimeSub?.cancel();
    _realtimeSub = RealtimeService.instance.events.listen((event) {
      if (event.type == 'resync' || types.contains(event.type)) {
        onEvent(event);
      }
    });
  }

  /// Exécute [action] après [delay] sans nouvel appel avec la même [key] : une
  /// rafale d'événements ne provoque qu'un seul rechargement.
  void debounced(String key, Duration delay, void Function() action) {
    _debounceTimers[key]?.cancel();
    _debounceTimers[key] = Timer(delay, action);
  }

  @override
  void onClose() {
    _realtimeSub?.cancel();
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    super.onClose();
  }
}
