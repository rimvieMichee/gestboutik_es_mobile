import 'package:flutter/material.dart';
import 'package:foodly/helpers/theme/app_style.dart' as legacy;

/// Thème Material de GesBoutik, clair et sombre : même vert de marque, mêmes
/// boutons, champs, puces, boîtes de dialogue et feuilles modales dans les deux
/// modes. Se superpose aux thèmes hérités du modèle de départ (couleur primaire
/// bleue) pour que les composants Material par défaut aient la bonne apparence.
class GbTheme {
  GbTheme._();

  static final Color brand = Colors.green.shade600;

  static ThemeData light() => _build(legacy.AppTheme.lightTheme, dark: false);
  static ThemeData dark() => _build(legacy.AppTheme.darkTheme, dark: true);

  static ThemeData _build(ThemeData base, {required bool dark}) {
    final background = dark ? const Color(0xff121315) : const Color(0xffFAFAFA);
    final surface = dark ? const Color(0xff1D1E21) : Colors.white;
    final border = dark ? const Color(0xff2B2D31) : Colors.grey.shade200;
    final fill = dark ? const Color(0xff26282C) : const Color(0xffF3F4F6);
    final text = dark ? const Color(0xffECECEC) : Colors.black87;
    final subtext = dark ? const Color(0xff9AA0A6) : Colors.grey.shade600;
    final disabled = dark ? const Color(0xff3A3D42) : Colors.grey.shade300;

    final scheme = base.colorScheme.copyWith(
      primary: brand,
      onPrimary: Colors.white,
      secondary: brand,
      onSecondary: Colors.white,
      surface: surface,
      onSurface: text,
      surfaceTint: Colors.transparent,
      outline: border,
    );

    final shape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
    const buttonText = TextStyle(fontWeight: FontWeight.w700, fontSize: 15);

    return base.copyWith(
      colorScheme: scheme,
      primaryColor: brand,
      scaffoldBackgroundColor: background,
      dividerColor: border,
      dividerTheme: DividerThemeData(color: border, thickness: 1),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: brand,
        selectionColor: brand.withOpacity(0.3),
        selectionHandleColor: brand,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brand,
          foregroundColor: Colors.white,
          disabledBackgroundColor: disabled,
          disabledForegroundColor: subtext,
          shape: shape,
          textStyle: buttonText,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brand,
          foregroundColor: Colors.white,
          disabledBackgroundColor: disabled,
          disabledForegroundColor: subtext,
          shape: shape,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          side: BorderSide(color: border),
          shape: shape,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brand,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: brand,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: subtext),
        labelStyle: TextStyle(color: subtext),
        floatingLabelStyle: TextStyle(color: brand),
        prefixIconColor: subtext,
        suffixIconColor: subtext,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: surface,
        selectedColor: brand,
        side: BorderSide(color: border),
        labelStyle: TextStyle(color: text),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        textStyle: TextStyle(color: text, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: surface,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: brand),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? brand : null,
        ),
      ),
      radioTheme: RadioThemeData(fillColor: WidgetStatePropertyAll(brand)),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? brand : null,
        ),
        checkColor: const WidgetStatePropertyAll(Colors.white),
      ),
    );
  }
}
