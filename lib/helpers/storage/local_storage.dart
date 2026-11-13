import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:foodly/helpers/localizations/language.dart';
import 'package:foodly/helpers/services/auth_services.dart';
import 'package:foodly/helpers/theme/theme_customizer.dart';

class LocalStorage {
  static const String _loggedInUserKey = "user";
  static const String _themeCustomizerKey = "theme_customizer";
  static const String _languageKey = "lang_code";
  static const String _userIDKey = "user_id";
  static const String _userWalletIDKey = "user_wallet_id";
  static const String _userCurrencyIDKey = "user_currency_id";
  static const String _userCurrencyLabel = "user_currency_label";
  static const String _userWalletBalance = "user_wallet_balance";

  static const String _userNameKey = "user_name";
  static const String _authToken = "auth_token";
  static const String _phoneNumber = "phone";
  static const String _email = "email";
  static const String _theme = "theme";
  static const String _setAppLink = "setAppLink";
  static const String _countryID = "countryID";
  static const String _appLinkPoolID = "appLinkID";
  static const String _password = "password";
  static const String _loggedIn = "loggedIn";
  static const String _notification = "notification";
  static const String _firstName = "first_name";
  static const String _lastName = "last_name";
  static const String _refreshToken = "refresh_token";
  static const String _userRole = "user_role";
  static const String _boutiqueId = "boutique_id";
  static const String _boutiqueName = "boutique_name";
  static const String _biometricEnabled = "biometric_login_enabled";
  static const String _lastUsername = "last_username";
  static const String _shopCount = "shop_count";
  static const String _lastDisplayName = "last_display_name";

  static const String _languageIndexKey =
      'app_language_index'; // New key for index

  static SharedPreferences? _preferencesInstance;

  static SharedPreferences get preferences {
    if (_preferencesInstance == null) {
      throw ("Call LocalStorage.init() to initialize local storage");
    }
    return _preferencesInstance!;
  }

  static Future<void> init() async {
    _preferencesInstance = await SharedPreferences.getInstance();
    await initData();
  }

  static Future<void> initData() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    // La session est considérée active tant qu'un access token est stocké
    // (plus fiable qu'un simple flag booléen, qui n'était d'ailleurs jamais persisté).
    AuthService.isLoggedIn =
        (preferences.getString(_authToken) ?? '').isNotEmpty;
    ThemeCustomizer.fromJSON(preferences.getString(_themeCustomizerKey));
  }

  // Method to save the selected language's index
  static Future<void> setLanguageIndex(int index) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_languageIndexKey, index);
  }

  // Method to get the saved language's index
  static Future<int?> getLanguageIndex() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_languageIndexKey);
  }

  static Future<bool> setLoggedInUser(bool loggedIn) async {
    return preferences.setBool(_loggedInUserKey, loggedIn);
  }

  static Future<bool> setCustomizer(ThemeCustomizer themeCustomizer) {
    return preferences.setString(_themeCustomizerKey, themeCustomizer.toJSON());
  }

  static Future<bool> setLanguage(Language language) {
    return preferences.setString(_languageKey, language.locale.languageCode);
  }

  /// Locale `intl` (noms de mois, jours…) alignée sur la langue de l'appli.
  static String get dateLocale =>
      _preferencesInstance?.getString(_languageKey) == 'en' ? 'en_US' : 'fr_FR';

  static String? getLanguage() {
    return preferences.getString(_languageKey);
  }

  static Future<bool> setUserID(String userID) {
    return preferences.setString(_userIDKey, userID);
  }

  static String? getUserID() {
    return preferences.getString(_userIDKey);
  }

  static Future<bool> setUserWalletID(String userID) {
    return preferences.setString(_userWalletIDKey, userID);
  }

  static Future<bool> setUserWalletBalance(String balance) {
    return preferences.setString(_userWalletBalance, balance);
  }

  static String? getUserWalletID() {
    return preferences.getString(_userWalletIDKey);
  }

  static String? getUserWalletBalance() {
    return preferences.getString(_userWalletBalance);
  }

  static Future<bool> setUserCurrencyID(String currencyId) {
    return preferences.setString(_userCurrencyIDKey, currencyId);
  }

  static String? getUserCurrencyID() {
    return preferences.getString(_userCurrencyIDKey);
  }

  static Future<bool> setUserCurrencyLabel(String currencyLabel) {
    return preferences.setString(_userCurrencyIDKey, currencyLabel);
  }

  static String? getUserCurrencyLabel() {
    return preferences.getString(_userCurrencyLabel);
  }

  static Future<bool> setUserName(String userID) {
    return preferences.setString(_userNameKey, userID);
  }

  static String? getUserName() {
    return preferences.getString(_userNameKey);
  }

  static Future<bool> setEmail(String email) {
    return preferences.setString(_email, email);
  }

  static String? getEmail() {
    return preferences.getString(_email);
  }

  static Future<bool> setAuthToken(String token) {
    return preferences.setString(_authToken, token);
  }

  static String? getAuthToken() {
    return preferences.getString(_authToken);
  }

  static Future<bool> setPhoneNumber(String phone) {
    return preferences.setString(_phoneNumber, phone);
  }

  static String? getPhoneNumber() {
    return preferences.getString(_phoneNumber);
  }

  static ValueNotifier<String> themeNotifier = ValueNotifier("Light");

  static Future<bool> setTheme(String theme) {
    return preferences.setString(_theme, theme);
  }

  static String? getTheme() {
    return preferences.getString(_theme);
  }

  /// Choix d'apparence de l'utilisateur : Système / Clair / Sombre.
  /// Par défaut « Clair » tant qu'aucun choix n'a été fait.
  static ThemeMode getThemeMode() {
    switch (getTheme()) {
      case 'Dark':
        return ThemeMode.dark;
      case 'System':
        return ThemeMode.system;
      default:
        return ThemeMode.light;
    }
  }

  static Future<bool> setThemeMode(ThemeMode mode) {
    final value = switch (mode) {
      ThemeMode.dark => 'Dark',
      ThemeMode.system => 'System',
      ThemeMode.light => 'Light',
    };
    return setTheme(value);
  }

  /// `true` si l'interface est actuellement sombre (en mode Système, selon l'appareil).
  static bool get isDarkMode {
    switch (getThemeMode()) {
      case ThemeMode.dark:
        return true;
      case ThemeMode.light:
        return false;
      case ThemeMode.system:
        return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark;
    }
  }

  static Future<bool> setAppLink(bool setValue) {
    return preferences.setBool(_setAppLink, setValue);
  }

  static bool isAppLink() {
    return preferences.getBool(_setAppLink) ?? false;
  }

  static Future<bool> setAppLinkStationID(String id) {
    return preferences.setString(_appLinkPoolID, id);
  }

  static String? getAppLinkStationID() {
    return preferences.getString(_appLinkPoolID);
  }

  static Future<bool> setCountryID(String id) {
    return preferences.setString(_countryID, id);
  }

  static String? getCountryID() {
    return preferences.getString(_countryID);
  }

  static Future<bool> setPassword(String password) {
    return preferences.setString(_password, password);
  }

  static String? getPassword() {
    return preferences.getString(_password);
  }

  static Future<bool> setAlwaysLoggedIn(bool value) {
    return preferences.setBool(_loggedIn, value);
  }

  static bool getAlwaysLoggedIn() {
    return preferences.getBool(_loggedIn) ?? false;
  }

  static Future<bool> setNotification(List<String> notification) {
    return preferences.setStringList(_notification, notification);
  }

  static List<String>? getNotification() {
    return preferences.getStringList(_notification);
  }

  static Future<bool> setRefreshToken(String token) {
    return preferences.setString(_refreshToken, token);
  }

  static String? getRefreshToken() {
    return preferences.getString(_refreshToken);
  }

  static Future<bool> setUserRole(String role) {
    return preferences.setString(_userRole, role);
  }

  static String? getUserRole() {
    return preferences.getString(_userRole);
  }

  /// Nombre de boutiques que le gestionnaire connecté peut ouvrir.
  static Future<bool> setShopCount(int count) {
    return preferences.setInt(_shopCount, count);
  }

  static int getShopCount() => preferences.getInt(_shopCount) ?? 0;

  /// Vrai si le gestionnaire gère plusieurs boutiques (sélecteur affiché).
  static bool get isMultiShop => getShopCount() > 1;

  static Future<bool> setBoutiqueId(String boutiqueId) {
    return preferences.setString(_boutiqueId, boutiqueId);
  }

  static String? getBoutiqueId() {
    return preferences.getString(_boutiqueId);
  }

  static Future<bool> setBoutiqueName(String boutiqueName) {
    return preferences.setString(_boutiqueName, boutiqueName);
  }

  static String? getBoutiqueName() {
    return preferences.getString(_boutiqueName);
  }

  static Future<bool> setFirstName(String firstName) {
    return preferences.setString(_firstName, firstName);
  }

  static String? getFirstName() {
    return preferences.getString(_firstName);
  }

  static Future<bool> setLastName(String lastName) {
    return preferences.setString(_lastName, lastName);
  }

  static String? getLastName() {
    return preferences.getString(_lastName);
  }

  /// Connexion par empreinte / Face ID activée dans les paramètres. Les
  /// identifiants eux-mêmes sont dans le stockage sécurisé (BiometricService).
  static Future<bool> setBiometricEnabled(bool value) {
    return preferences.setBool(_biometricEnabled, value);
  }

  static bool getBiometricEnabled() {
    return preferences.getBool(_biometricEnabled) ?? false;
  }

  /// Dernier compte connecté : conservé après la déconnexion pour proposer
  /// « Bon retour, … » sur la page de connexion. Jamais le mot de passe.
  static Future<void> setLastAccount(String username, String displayName) async {
    await preferences.setString(_lastUsername, username);
    await preferences.setString(_lastDisplayName, displayName);
  }

  static String? getLastUsername() => preferences.getString(_lastUsername);
  static String? getLastDisplayName() => preferences.getString(_lastDisplayName);

  static Future<void> clearLastAccount() async {
    await preferences.remove(_lastUsername);
    await preferences.remove(_lastDisplayName);
  }

  static Future<void> removeLoggedInUser() async {
    preferences.remove(_loggedInUserKey);
    preferences.remove(_userIDKey);
    preferences.remove(_authToken);
    preferences.remove(_refreshToken);
    preferences.remove(_userRole);
    preferences.remove(_boutiqueId);
    preferences.remove(_boutiqueName);
    preferences.remove(_shopCount);
    preferences.remove(_userNameKey);
    preferences.remove(_firstName);
    preferences.remove(_lastName);
    preferences.remove(_password);
  }

  static Future<bool> removeAllUserData() async {
    return preferences.clear();
  }
}
