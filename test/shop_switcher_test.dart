import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:foodly/helpers/storage/local_storage.dart';
import 'package:foodly/models/shop_model.dart';
import 'package:foodly/models/user_model.dart';
import 'package:foodly/views/apps/shops/shop_switcher_sheet.dart';
import 'package:foodly/widgets/gesboutik/gb_format.dart';

const _a = ShopModel(
    id: 'a',
    nom: 'Boutique A',
    ville: 'Ouagadougou',
    active: true,
    ventesJour: 9,
    chiffreAffairesJour: 190200,
    creditNombre: 4,
    creditMontant: 286000);
const _b = ShopModel(
    id: 'b',
    nom: 'Boutique B',
    ville: 'Bobo-Dioulasso',
    ventesJour: 2,
    chiffreAffairesJour: 30000);
const _off =
    ShopModel(id: 'c', nom: 'Boutique C', statut: 'INACTIVE', ventesJour: 0);

Widget _host(Future<void> Function(BuildContext) open) => ScreenUtilInit(
      designSize: const Size(402, 874),
      builder: (_, __) => MaterialApp(
        home: Builder(
          builder: (ctx) => Scaffold(
            body: Center(
              child: ElevatedButton(
                  onPressed: () => open(ctx), child: const Text('ouvrir')),
            ),
          ),
        ),
      ),
    );

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorage.init();
  });

  void bigScreen(WidgetTester t) {
    t.view.physicalSize = const Size(1206, 2622);
    t.view.devicePixelRatio = 3;
  }

  test('ShopModel lit la réponse de /boutiques/mine', () {
    final shop = ShopModel.fromJson({
      'id': 'x',
      'nom': 'Boutique X',
      'ville': 'Ouaga',
      'statut': 'ACTIVE',
      'active': true,
      'aujourdhui': {'ventes': 3, 'chiffreAffaires': 12500},
      'creditEnCours': {'nombre': 1, 'montant': '4000'},
    });
    expect(shop.active, true);
    expect(shop.ventesJour, 3);
    expect(shop.chiffreAffairesJour, 12500);
    expect(shop.creditMontant, 4000);
    expect(shop.isOpen, true);
    expect(ShopModel.fromJson({'id': 'y', 'nom': 'Y', 'statut': 'INACTIVE'}).isOpen,
        false);
  });

  test("UserModel lit la liste des boutiques du gestionnaire", () {
    final user = UserModel.fromJson({
      'id': 'u',
      'nom': 'O',
      'prenom': 'I',
      'username': 'issa',
      'role': 'ADMIN',
      'boutiqueId': 'a',
      'boutique': {'id': 'a', 'nom': 'A', 'statut': 'ACTIVE'},
      'boutiques': [
        {'id': 'a', 'nom': 'A', 'statut': 'ACTIVE'},
        {'id': 'b', 'nom': 'B', 'statut': 'ACTIVE'},
      ],
    });
    expect(user.boutiques.map((b) => b.id), ['a', 'b']);
    // Réponse d'un ancien serveur ou d'un employé : pas de liste.
    expect(
        UserModel.fromJson({
          'id': 'u',
          'nom': 'O',
          'prenom': 'I',
          'username': 'x',
          'role': 'EMPLOYEE',
        }).boutiques,
        isEmpty);
  });

  test('le sélecteur ne s\'affiche que pour plusieurs boutiques', () async {
    await LocalStorage.setShopCount(1);
    expect(LocalStorage.isMultiShop, false);
    await LocalStorage.setShopCount(2);
    expect(LocalStorage.isMultiShop, true);
  });

  testWidgets('liste les boutiques, le total du jour, et ouvre l\'autre boutique',
      (t) async {
    bigScreen(t);
    ShopModel? picked;
    await t.pumpWidget(_host((ctx) => showShopSwitcher(ctx,
        loader: () async => [_a, _b, _off], onPick: (s) => picked = s)));
    await t.tap(find.text('ouvrir'));
    await t.pumpAndSettle();

    expect(find.text('Boutique A'), findsOneWidget);
    expect(find.text('Boutique B'), findsOneWidget);
    expect(find.text('Boutique C'), findsOneWidget);
    // Total des deux boutiques ouvertes (la désactivée n'est pas comptée).
    expect(find.text(formatFcfa(220200)), findsOneWidget);
    expect(t.takeException(), isNull);

    await t.tap(find.text('Boutique B'));
    await t.pumpAndSettle();
    expect(picked?.id, 'b');
  });

  testWidgets('la boutique active et la boutique désactivée ne changent rien',
      (t) async {
    bigScreen(t);
    ShopModel? picked;
    await t.pumpWidget(_host((ctx) => showShopSwitcher(ctx,
        loader: () async => [_a, _b, _off], onPick: (s) => picked = s)));
    await t.tap(find.text('ouvrir'));
    await t.pumpAndSettle();

    await t.tap(find.text('Boutique C'));
    await t.pumpAndSettle();
    expect(picked, isNull);
    expect(find.text('Boutique C'), findsOneWidget); // la feuille reste ouverte

    await t.tap(find.text('Boutique A'));
    await t.pumpAndSettle();
    expect(picked, isNull);
    expect(find.text('Boutique B'), findsNothing); // feuille refermée
  });

  testWidgets('une erreur réseau propose de réessayer', (t) async {
    bigScreen(t);
    var calls = 0;
    await t.pumpWidget(_host((ctx) => showShopSwitcher(ctx, loader: () async {
          calls++;
          if (calls == 1) throw Exception('réseau');
          return [_a, _b];
        })));
    await t.tap(find.text('ouvrir'));
    await t.pumpAndSettle();
    expect(find.text('Boutique A'), findsNothing);
    await t.tap(find.byType(OutlinedButton));
    await t.pumpAndSettle();
    expect(find.text('Boutique A'), findsOneWidget);
    expect(calls, 2);
  });
}
