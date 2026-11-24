import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:printing/printing.dart';
import 'package:foodly/helpers/extensions/string.dart';
import 'package:foodly/helpers/theme/app_theme.dart';
import 'package:foodly/widgets/gesboutik/gb_app_bar.dart';
import 'package:foodly/widgets/gesboutik/gb_colors.dart';

/// Aperçu du rapport PDF avant de l'envoyer (WhatsApp, e-mail, fichiers...)
/// ou de l'imprimer. Les pages se feuillettent et se zooment.
class PdfPreviewScreen extends StatelessWidget {
  final Uint8List bytes;
  final String filename;
  const PdfPreviewScreen({super.key, required this.bytes, required this.filename});

  @override
  Widget build(BuildContext context) {
    final c = context.gb;
    final primary = AppTheme.theme.colorScheme.primary;
    return Scaffold(
      backgroundColor: c.background,
      appBar: gbAppBar(title: 'pdf_preview'.tr(), subtitle: filename),
      body: PdfPreview(
        build: (_) async => bytes,
        pdfFileName: filename,
        useActions: false,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        scrollViewDecoration: BoxDecoration(color: c.background),
        pdfPreviewPageDecoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.14),
                blurRadius: 14,
                offset: const Offset(0, 5)),
          ],
        ),
        loadingWidget: const CircularProgressIndicator(),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
            16.w, 12.h, 16.w, 12.h + MediaQuery.of(context).padding.bottom),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(top: BorderSide(color: c.border)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: SizedBox(
                height: 50.h,
                child: OutlinedButton(
                  onPressed: () => Printing.layoutPdf(
                      onLayout: (_) async => bytes, name: filename),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('print'.tr(),
                        maxLines: 1,
                        style: TextStyle(
                            fontSize: 14.sp, fontWeight: FontWeight.w700)),
                  ),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: primary,
                      side: BorderSide(color: primary.withOpacity(0.5))),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              flex: 6,
              child: SizedBox(
                height: 50.h,
                child: FilledButton(
                  onPressed: () =>
                      Printing.sharePdf(bytes: bytes, filename: filename),
                  child: Text('send_pdf'.tr(),
                      style: TextStyle(
                          fontSize: 15.sp, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
