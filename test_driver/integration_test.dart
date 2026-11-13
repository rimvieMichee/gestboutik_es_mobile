import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

/// Écrit chaque capture dans le dossier donné par SHOTS_DIR.
Future<void> main() async {
  final dir = Directory(Platform.environment['SHOTS_DIR'] ?? 'shots')
    ..createSync(recursive: true);
  await integrationDriver(
    onScreenshot: (String name, List<int> bytes, [Map<String, Object?>? args]) async {
      File('${dir.path}/$name.png').writeAsBytesSync(bytes);
      return true;
    },
  );
}
