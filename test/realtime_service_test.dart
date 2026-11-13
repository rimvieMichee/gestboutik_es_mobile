import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:foodly/helpers/services/realtime_service.dart';
import 'package:foodly/helpers/storage/local_storage.dart';

/// Test d'intégration du flux temps réel contre un backend de TEST.
///
/// Désactivé par défaut. Pour l'exécuter, lancer un backend local sur une base
/// de test (jamais la production), puis :
///   REALTIME_TEST_URL=http://localhost:3999 flutter test test/realtime_service_test.dart
final _url = Platform.environment['REALTIME_TEST_URL'];

Future<Map<String, dynamic>> _api(String method, String path,
    {String? token, Object? body}) async {
  final client = HttpClient();
  final request = await client.openUrl(method, Uri.parse('$_url/api$path'));
  request.headers.contentType = ContentType.json;
  if (token != null) request.headers.set('Authorization', 'Bearer $token');
  if (body != null) request.write(jsonEncode(body));
  final response = await request.close();
  final text = await response.transform(utf8.decoder).join();
  client.close();
  return text.isEmpty ? {} : jsonDecode(text) as Map<String, dynamic>;
}

Future<String> _login(String user, String password) async => (await _api(
    'POST', '/auth/login',
    body: {'username': user, 'password': password}))['accessToken'] as String;

void main() {
  test('un gestionnaire reçoit en direct le stock et les ventes', () async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
    RealtimeService.baseUrl = _url!;

    final manager = await _login('gestionnaire1', 'Gestion123!');
    final employee = await _login('employe1b', 'Employee123!');
    await LocalStorage.setAuthToken(manager);

    final service = RealtimeService.instance;
    final received = <RealtimeEvent>[];
    final sub = service.events.listen(received.add);

    service.connect();
    // Attente de la connexion (« ready » côté serveur => connected côté client).
    for (var i = 0; i < 50 && !service.connected.value; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    expect(service.connected.value, isTrue,
        reason: 'la connexion temps réel doit s\'établir');

    final products =
        (await _api('GET', '/products?limit=20', token: employee))['data']
            as List;
    final product = products.firstWhere((p) => p['nom'] == 'Produit A') as Map;
    final before = product['quantiteDisponible'] as int;

    await _api('POST', '/sales', token: employee, body: {
      'items': [
        {'productId': product['id'], 'quantite': 3}
      ],
    });
    await Future<void>.delayed(const Duration(milliseconds: 800));

    final stock = received.firstWhere((e) => e.type == 'stock.updated');
    expect(stock.productId, product['id']);
    expect(stock.data['quantiteDisponible'], before - 3);
    final sale = received.firstWhere((e) => e.type == 'sale.created');
    expect(sale.data['montantTotal'], greaterThan(0));

    service.disconnect();
    expect(service.connected.value, isFalse);
    await sub.cancel();
  },
      skip: _url == null
          ? 'définir REALTIME_TEST_URL pour lancer ce test'
          : false);
}
