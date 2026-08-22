import 'package:flutter/material.dart';

/// Anime un compteur entier de 0 vers sa valeur finale (effet "odomètre")
/// au lieu de l'afficher brutalement une fois les données chargées.
class GbAnimatedCount extends StatelessWidget {
  final int value;
  final TextStyle? style;

  const GbAnimatedCount({super.key, required this.value, this.style});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, count, child) => Text('$count', style: style),
    );
  }
}
