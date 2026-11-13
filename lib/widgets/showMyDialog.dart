import 'package:flutter/material.dart';
import 'package:foodly/widgets/gesboutik/gb_sheets.dart';

/// Ancienne fenêtre générique du modèle de départ : elle ouvre désormais une
/// bottom sheet (plus aucun dialogue dans l'appli).
void showMyDialog(
  BuildContext context, {
  required Widget content,
  List<Widget>? actions,
  String? title,
  double? borderRadius,
  EdgeInsetsGeometry? contentPadding,
}) {
  showGbSheet<void>(
    context,
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        Padding(padding: contentPadding ?? EdgeInsets.zero, child: content),
        if (actions != null)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.end, children: actions),
          ),
      ],
    ),
  );
}
