import 'package:flutter/material.dart';

/// Fait apparaître un élément de liste avec un léger fondu + glissement,
/// décalé selon son index pour un effet d'entrée "en cascade".
class GbStaggeredItem extends StatelessWidget {
  final int index;
  final Widget child;

  const GbStaggeredItem({super.key, required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    final delay = (index * 40).clamp(0, 320);
    return TweenAnimationBuilder<double>(
      key: ValueKey(index),
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 280 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 16),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
