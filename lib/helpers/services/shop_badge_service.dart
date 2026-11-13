import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:foodly/helpers/services/shop_service.dart';
import 'package:foodly/helpers/storage/local_storage.dart';
import 'package:foodly/models/shop_model.dart';

/// Pastille « nouvelles ventes » des autres boutiques d'un gestionnaire.
///
/// Les ventes du jour de chaque boutique sont relevées toutes les minutes ;
/// ce qui dépasse le dernier chiffre vu (mémorisé par jour) est signalé. La
/// boutique ouverte est toujours considérée comme vue.
class ShopBadgeService {
  ShopBadgeService._();

  static const _key = 'shop_badge_seen';
  static const _interval = Duration(seconds: 60);

  /// Total des nouvelles ventes dans les autres boutiques.
  static final ValueNotifier<int> unseen = ValueNotifier<int>(0);
  static final Map<String, int> _perShop = {};
  static Timer? _timer;

  static int unseenFor(String shopId) => _perShop[shopId] ?? 0;

  static String get _today {
    final d = DateTime.now();
    return '${d.year}-${d.month}-${d.day}';
  }

  static void start() {
    if (!LocalStorage.isMultiShop) return;
    _timer?.cancel();
    refresh();
    _timer = Timer.periodic(_interval, (_) => refresh());
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
  }

  static void reset() {
    stop();
    _perShop.clear();
    unseen.value = 0;
  }

  static Future<void> refresh() async {
    try {
      ingest(await ShopService.mine());
    } catch (_) {
      // Hors ligne : on garde l'état précédent.
    }
  }

  /// Compare les chiffres reçus aux derniers vus (aussi appelé par le sélecteur).
  static void ingest(List<ShopModel> shops) {
    final seen = _loadSeen();
    var changed = false;
    _perShop.clear();
    var total = 0;
    for (final s in shops) {
      final known = seen[s.id];
      if (s.active || known == null || s.ventesJour < known) {
        // Boutique ouverte, première relève du jour, ou nouvelle journée.
        if (known != s.ventesJour) {
          seen[s.id] = s.ventesJour;
          changed = true;
        }
        continue;
      }
      final n = s.ventesJour - known;
      if (n > 0 && s.isOpen) {
        _perShop[s.id] = n;
        total += n;
      }
    }
    if (changed) _saveSeen(seen);
    unseen.value = total;
  }

  /// L'utilisateur ouvre cette boutique : ses ventes sont vues.
  static Future<void> markSeen(ShopModel shop) async {
    final seen = _loadSeen()..[shop.id] = shop.ventesJour;
    _perShop.remove(shop.id);
    unseen.value = _perShop.values.fold(0, (a, b) => a + b);
    await _saveSeen(seen);
  }

  static Map<String, int> _loadSeen() {
    try {
      final raw = LocalStorage.preferences.getString(_key);
      if (raw == null) return {};
      final json = jsonDecode(raw) as Map<String, dynamic>;
      if (json['day'] != _today) return {};
      return (json['seen'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, v as int));
    } catch (_) {
      return {};
    }
  }

  static Future<void> _saveSeen(Map<String, int> seen) async {
    try {
      await LocalStorage.preferences
          .setString(_key, jsonEncode({'day': _today, 'seen': seen}));
    } catch (_) {}
  }
}
