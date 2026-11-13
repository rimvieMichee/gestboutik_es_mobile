import 'package:flutter/material.dart';

/// Palette des écrans GesBoutik, claire ou sombre selon le thème actif.
/// Toujours lue via le `context` (`context.gb`) pour que les écrans se
/// reconstruisent quand l'utilisateur change d'apparence.
class GbColors {
  final bool isDark;

  /// Fond des pages.
  final Color background;

  /// Cartes, barres, feuilles modales.
  final Color surface;

  /// Contour et séparateurs.
  final Color border;

  /// Fond des champs de saisie et blocs discrets.
  final Color fill;

  /// Squelettes de chargement.
  final Color skeleton;

  /// Texte principal et secondaire.
  final Color text;
  final Color subtext;

  const GbColors._({
    required this.isDark,
    required this.background,
    required this.surface,
    required this.border,
    required this.fill,
    required this.skeleton,
    required this.text,
    required this.subtext,
  });

  static const _dark = GbColors._(
    isDark: true,
    background: Color(0xff121315),
    surface: Color(0xff1D1E21),
    border: Color(0xff2B2D31),
    fill: Color(0xff26282C),
    skeleton: Color(0xff2B2D31),
    text: Color(0xffECECEC),
    subtext: Color(0xff9AA0A6),
  );

  static final _light = GbColors._(
    isDark: false,
    background: const Color(0xffFAFAFA),
    surface: Colors.white,
    border: Colors.grey.shade200,
    fill: const Color(0xffF3F4F6),
    skeleton: Colors.grey.shade300,
    text: Colors.black87,
    subtext: Colors.grey.shade600,
  );

  static GbColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _dark : _light;

  /// Ombre douce des cartes (absente en sombre, où le contraste suffit).
  List<BoxShadow> get shadow => isDark
      ? const []
      : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ];
}

extension GbThemeContext on BuildContext {
  GbColors get gb => GbColors.of(this);
}
