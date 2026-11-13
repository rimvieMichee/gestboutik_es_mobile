import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:foodly/helpers/storage/local_storage.dart';
import 'package:foodly/widgets/gesboutik/gb_sheets.dart';

Widget _host(Future<void> Function(BuildContext) body) => ScreenUtilInit(
      designSize: const Size(402, 874),
      builder: (_, __) => MaterialApp(
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [Locale('fr'), Locale('en')],
        home: Builder(
          builder: (ctx) => Scaffold(
            body: Center(
              child: ElevatedButton(
                  onPressed: () => body(ctx), child: const Text('ouvrir')),
            ),
          ),
        ),
      ),
    );

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
    await initializeDateFormatting();
  });

  Future<void> open(WidgetTester t) async {
    await t.tap(find.text('ouvrir'));
    await t.pumpAndSettle();
  }

  testWidgets('confirmation : renvoie true / false', (t) async {
    t.view.physicalSize = const Size(1206, 2622);
    t.view.devicePixelRatio = 3;
    bool? result;
    await t.pumpWidget(_host((ctx) async => result = await showGbConfirmSheet(ctx,
        title: 'Archiver ?', message: 'Message', confirmLabel: 'Oui')));
    await open(t);
    expect(find.text('Archiver ?'), findsOneWidget);
    await t.tap(find.text('Oui'));
    await t.pumpAndSettle();
    expect(result, true);
    await open(t);
    await t.tap(find.text('Cancel'));
    await t.pumpAndSettle();
    expect(result, false);
  });

  testWidgets('calendrier d\'un jour : pas de débordement, valide la date',
      (t) async {
    t.view.physicalSize = const Size(1206, 2622);
    t.view.devicePixelRatio = 3;
    DateTime? picked;
    await t.pumpWidget(_host((ctx) async => picked = await showGbDateSheet(ctx,
        title: 'Jour',
        initial: DateTime(2026, 11, 12),
        first: DateTime(2020),
        last: DateTime(2026, 11, 30))));
    await open(t);
    await t.tap(find.text('10'));
    await t.pumpAndSettle();
    await t.tap(find.text('Confirm'));
    await t.pumpAndSettle();
    expect(picked, DateTime(2026, 11, 10));
    expect(t.takeException(), isNull);
  });

  testWidgets('calendrier d\'une période : début puis fin', (t) async {
    t.view.physicalSize = const Size(1206, 2622);
    t.view.devicePixelRatio = 3;
    DateTimeRange? picked;
    await t.pumpWidget(_host((ctx) async => picked = await showGbRangeSheet(ctx,
        title: 'Période',
        first: DateTime(2020),
        last: DateTime(2026, 11, 30),
        initial: DateTimeRange(
            start: DateTime(2026, 11, 12), end: DateTime(2026, 11, 12)))));
    await open(t);
    await t.tap(find.text('3')); // début
    await t.pumpAndSettle();
    await t.tap(find.text('9')); // fin (le sélecteur est passé sur « Au »)
    await t.pumpAndSettle();
    await t.tap(find.text('Confirm'));
    await t.pumpAndSettle();
    expect(picked?.start, DateTime(2026, 11, 3));
    expect(picked?.end, DateTime(2026, 11, 9));
    expect(t.takeException(), isNull);
  });
}
