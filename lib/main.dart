import 'dart:async';
import 'dart:developer';
import 'package:foodly/routes.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:provider/provider.dart';
import 'package:url_strategy/url_strategy.dart';
import 'helpers/constant/app_constant.dart';
import 'helpers/localizations/app_localization_delegate.dart';
import 'helpers/localizations/language.dart';
import 'helpers/localizations/translator.dart';
import 'helpers/logger/logger.dart';
import 'helpers/remote/api_service.dart';
import 'helpers/remote/local_notification.dart';
import 'helpers/services/auth_services.dart';
import 'helpers/services/navigation_service.dart';
import 'helpers/storage/local_storage.dart';
import 'helpers/theme/admin_theme.dart';
import 'helpers/theme/app_notifier.dart';
import 'helpers/theme/app_style.dart';
import 'helpers/theme/gb_theme.dart';
import 'helpers/theme/theme_customizer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setPathUrlStrategy();
  await GetStorage.init();
  await LocalStorage.init();
  await GetStorage.init();
  initLogger();
  APIService.initializeAPIService(
      devBaseUrl: AppConstant.baseURl, prodBaseUrl: AppConstant.baseURl);
  AppStyle.init();
  log("GetToken ${LocalStorage.getAuthToken()}");
  log("GetUserID ${LocalStorage.getUserID()}");
  if (LocalStorage.getTheme() == null) {
    await LocalStorage.setThemeMode(ThemeMode.light);
  }
  LocalStorage.setAppLink(false);
  await initializeDateFormatting();
  await ThemeCustomizer.init();
  await Translator.changeLanguage(await Language.getLanguage());
  await SystemChrome.setPreferredOrientations(
    <DeviceOrientation>[
      DeviceOrientation.portraitDown,
      DeviceOrientation.portraitUp,
    ],
  );
  if (!kIsWeb) {
    LocalNotification().initialize();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppNotifier>(
          create: (context) => AppNotifier(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// En mode « Système », suit le passage clair/sombre de l'appareil en direct.
  @override
  void didChangePlatformBrightness() {
    if (LocalStorage.getThemeMode() == ThemeMode.system && mounted) {
      context.read<AppNotifier>().changeTheme();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppNotifier>(
      builder: (_, notifier, ___) {
        AdminTheme.setTheme(context);
        return ScreenUtilInit(
          designSize: kIsWeb ? const Size(1280, 832) : const Size(430, 932),
          child: GetMaterialApp(
            debugShowCheckedModeBanner: false,
            theme: GbTheme.light(),
            darkTheme: GbTheme.dark(),
            defaultTransition: Transition.native,
            navigatorKey: NavigationService.navigatorKey,
            initialRoute: AuthService.isLoggedIn
                ? "/dashboard"
                : LocalStorage.onboardingDone
                    ? "/auth/login"
                    : "/onboarding",
            themeMode: LocalStorage.getThemeMode(),
            getPages: getPageRoute(),
            builder: (_, child) {
              NavigationService.registerContext(_);
              return Directionality(
                textDirection: AppTheme.textDirection,
                child: child ?? Container(),
              );
            },
            localizationsDelegates: [
              AppLocalizationsDelegate(context),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: Language.getLocales(),
          ),
        );
      },
    );
  }
}
