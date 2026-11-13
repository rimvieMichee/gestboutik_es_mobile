import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:foodly/helpers/constant/app_constant.dart';
import 'package:foodly/helpers/storage/local_storage.dart';

/// Événement diffusé par le serveur en temps réel.
class RealtimeEvent {
  /// `stock.updated`, `product.changed`, `sale.created`, `credit.settled`.
  final String type;
  final Map<String, dynamic> data;

  RealtimeEvent(this.type, this.data);

  String? get productId => data['productId'] as String?;
  String? get userId => data['userId'] as String?;
}

/// Connexion temps réel (Socket.IO) au backend : stock, ventes, crédits.
///
/// Le serveur n'envoie que ce que le compte a le droit de voir (un employé ne
/// reçoit pas les ventes de ses collègues). La connexion est ouverte à la
/// connexion de l'utilisateur et fermée à sa déconnexion ; en cas de coupure
/// réseau elle se rétablit seule, et les écrans se resynchronisent.
class RealtimeService {
  RealtimeService._();
  static final RealtimeService instance = RealtimeService._();

  static const _events = [
    'stock.updated',
    'product.changed',
    'sale.created',
    'credit.settled',
  ];

  /// Adresse du serveur (modifiable pour les tests d'intégration).
  static String baseUrl = AppConstant.baseAPI;

  io.Socket? _socket;
  Timer? _retryTimer;
  int _authRetries = 0;
  bool _hadConnection = false;
  final StreamController<RealtimeEvent> _controller =
      StreamController<RealtimeEvent>.broadcast();

  /// Vrai quand le flux en direct est actif (pour l'indicateur « En direct »).
  final RxBool connected = false.obs;

  Stream<RealtimeEvent> get events => _controller.stream;

  void connect() {
    if (_socket != null || LocalStorage.getAuthToken() == null) return;
    _retryTimer?.cancel();

    final socket = io.io(
      baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          // Jeton relu à chaque (re)connexion, pas figé à la création.
          .setAuthFn(
              (callback) => callback({'token': LocalStorage.getAuthToken()}))
          .enableReconnection()
          .setReconnectionDelay(2000)
          .setReconnectionDelayMax(15000)
          .disableAutoConnect()
          .build(),
    );
    _socket = socket;

    socket.onConnect((_) {
      connected.value = true;
      _authRetries = 0;
      // Après une coupure, des événements ont pu être manqués : on demande aux
      // écrans de se resynchroniser.
      if (_hadConnection) {
        _controller.add(RealtimeEvent('resync', const {}));
      }
      _hadConnection = true;
    });
    socket.onDisconnect((_) => connected.value = false);
    socket.onConnectError((error) => connected.value = false);

    // Jeton refusé (expiré ou compte désactivé) : on coupe, puis on réessaie
    // quelques fois seulement, au cas où le jeton aurait été renouvelé.
    socket.on('unauthorized', (_) {
      _closeSocket();
      if (_authRetries < 3 && LocalStorage.getAuthToken() != null) {
        _authRetries++;
        _retryTimer = Timer(const Duration(seconds: 30), connect);
      }
    });

    for (final type in _events) {
      socket.on(type, (data) {
        if (data is Map) {
          _controller.add(RealtimeEvent(type, Map<String, dynamic>.from(data)));
        }
      });
    }

    socket.connect();
  }

  void _closeSocket() {
    _socket?.dispose();
    _socket = null;
    connected.value = false;
  }

  /// À appeler à la déconnexion de l'utilisateur.
  void disconnect() {
    _retryTimer?.cancel();
    _authRetries = 0;
    _hadConnection = false;
    _closeSocket();
  }

  @visibleForTesting
  void emitForTest(RealtimeEvent event) => _controller.add(event);
}
