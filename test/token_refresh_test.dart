import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodly/helpers/remote/api_service.dart';
import 'package:foodly/helpers/storage/local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Faux backend : /ping exige le jeton « fresh », /auth/refresh en émet un.
void main() {
  late HttpServer server;
  var refreshCalls = 0;
  var refreshOk = true;

  setUpAll(() async {
    server = await HttpServer.bind('127.0.0.1', 0);
    server.listen((req) async {
      final res = req.response..headers.contentType = ContentType.json;
      if (req.uri.path == '/auth/refresh') {
        refreshCalls++;
        await Future<void>.delayed(const Duration(milliseconds: 100));
        if (!refreshOk) {
          res.statusCode = 401;
          res.write(jsonEncode({'message': 'Refresh token invalide ou expiré.'}));
        } else {
          res.write(jsonEncode(
              {'accessToken': 'fresh', 'refreshToken': 'refresh-2'}));
        }
      } else if (req.headers.value('authorization') == 'Bearer fresh') {
        res.write(jsonEncode({'ok': true}));
      } else {
        res.statusCode = 401;
        res.write(jsonEncode({'message': 'Unauthorized'}));
      }
      await res.close();
    });
    APIService.initializeAPIService(
        devBaseUrl: 'http://127.0.0.1:${server.port}',
        prodBaseUrl: 'http://127.0.0.1:${server.port}');
  });

  tearDownAll(() => server.close(force: true));

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
    await LocalStorage.setAuthToken('expired');
    await LocalStorage.setRefreshToken('refresh-1');
    refreshCalls = 0;
    refreshOk = true;
  });

  test('un 401 renouvelle le jeton et rejoue la requête sans erreur', () async {
    final r = await APIService.get(path: '/ping');
    expect(r.data!['ok'], true);
    expect(LocalStorage.getAuthToken(), 'fresh');
    expect(LocalStorage.getRefreshToken(), 'refresh-2');
    expect(refreshCalls, 1);
  });

  test('plusieurs requêtes simultanées : un seul renouvellement', () async {
    final results = await Future.wait(
        [for (var i = 0; i < 4; i++) APIService.get(path: '/ping')]);
    expect(results.every((r) => r.data!['ok'] == true), true);
    expect(refreshCalls, 1);
  });

  test('refresh refusé : le 401 remonte (retour à la connexion)', () async {
    refreshOk = false;
    await expectLater(
      APIService.get(path: '/ping'),
      throwsA(isA<DioException>()
          .having((e) => e.response?.statusCode, 'status', 401)),
    );
  });
}
