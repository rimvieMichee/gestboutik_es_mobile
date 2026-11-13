import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:foodly/helpers/extensions/string.dart';
import 'package:foodly/helpers/storage/local_storage.dart';
import 'package:foodly/helpers/theme/app_theme.dart';
import 'package:foodly/widgets/gesboutik/gb_colors.dart';

/// Toute fenêtre contextuelle de l'appli est une bottom sheet : même fond,
/// mêmes coins arrondis, même poignée, et le contenu remonte avec le clavier.
Future<T?> showGbSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool dismissible = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: dismissible,
    backgroundColor: context.gb.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26.r)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 16.h),
                  decoration: BoxDecoration(
                      color: ctx.gb.skeleton,
                      borderRadius: BorderRadius.circular(4.r)),
                ),
              ),
              builder(ctx),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Confirmation (remplace les AlertDialog). `true` si l'utilisateur confirme.
Future<bool?> showGbConfirmSheet(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String? cancelLabel,
  bool destructive = false,
  IconData icon = LucideIcons.helpCircle,
}) {
  return showGbSheet<bool>(
    context,
    builder: (ctx) {
      final c = ctx.gb;
      final primary = AppTheme.theme.colorScheme.primary;
      final tone = destructive ? Colors.red : primary;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
                color: tone.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, size: 26.sp, color: tone),
          ),
          SizedBox(height: 14.h),
          Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 18.sp, fontWeight: FontWeight.bold, color: c.text)),
          SizedBox(height: 8.h),
          Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5.sp, color: c.subtext, height: 1.4)),
          SizedBox(height: 22.h),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50.h,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text((cancelLabel ?? 'cancel'.tr()),
                        style: TextStyle(
                            fontSize: 15.sp, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: SizedBox(
                  height: 50.h,
                  child: FilledButton(
                    style: destructive
                        ? FilledButton.styleFrom(backgroundColor: Colors.red)
                        : null,
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text(confirmLabel,
                        style: TextStyle(
                            fontSize: 15.sp, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}

Locale get _calendarLocale =>
    Locale(LocalStorage.dateLocale.startsWith('en') ? 'en' : 'fr');

Widget _sheetTitle(BuildContext ctx, String title) => Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Text(title,
          style: TextStyle(
              fontSize: 18.sp, fontWeight: FontWeight.bold, color: ctx.gb.text)),
    );

Widget _actions(BuildContext ctx, VoidCallback onConfirm) => Padding(
      padding: EdgeInsets.only(top: 8.h),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 50.h,
              child: OutlinedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('cancel'.tr(),
                    style:
                        TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: SizedBox(
              height: 50.h,
              child: FilledButton(
                onPressed: onConfirm,
                child: Text('confirm'.tr(),
                    style:
                        TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );

/// Choix d'un jour (remplace showDatePicker).
Future<DateTime?> showGbDateSheet(
  BuildContext context, {
  required String title,
  required DateTime initial,
  required DateTime first,
  required DateTime last,
}) {
  var selected = initial;
  return showGbSheet<DateTime>(
    context,
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sheetTitle(ctx, title),
        Localizations.override(
          context: ctx,
          locale: _calendarLocale,
          child: SizedBox(
            height: 372,
            child: CalendarDatePicker(
              initialDate: initial,
              firstDate: first,
              lastDate: last,
              onDateChanged: (d) => selected = d,
            ),
          ),
        ),
        _actions(ctx, () => Navigator.of(ctx).pop(selected)),
      ],
    ),
  );
}

/// Choix d'une période (remplace showDateRangePicker) : on choisit le premier
/// jour puis le dernier, avec le même calendrier.
Future<DateTimeRange?> showGbRangeSheet(
  BuildContext context, {
  required String title,
  required DateTime first,
  required DateTime last,
  DateTimeRange? initial,
}) {
  var start = initial?.start ?? last;
  var end = initial?.end ?? last;
  var editingEnd = false;
  final df = DateFormat('d MMM yyyy', LocalStorage.dateLocale);
  return showGbSheet<DateTimeRange>(
    context,
    builder: (ctx) => StatefulBuilder(
      builder: (_, setState) {
        final c = ctx.gb;
        final primary = AppTheme.theme.colorScheme.primary;
        Widget tab(String label, DateTime value, bool endTab) {
          final on = editingEnd == endTab;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => editingEnd = endTab),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 12.w),
                decoration: BoxDecoration(
                  color: on ? primary.withOpacity(0.12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                      color: on ? primary : c.border, width: on ? 1.6 : 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(fontSize: 11.5.sp, color: c.subtext)),
                    SizedBox(height: 2.h),
                    Text(df.format(value),
                        style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: on ? primary : c.text)),
                  ],
                ),
              ),
            ),
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sheetTitle(ctx, title),
            SizedBox(height: 8.h),
            Row(children: [
              tab('range_from'.tr(), start, false),
              SizedBox(width: 10.w),
              tab('range_to'.tr(), end, true),
            ]),
            SizedBox(height: 6.h),
            Localizations.override(
              context: ctx,
              locale: _calendarLocale,
              child: SizedBox(
                height: 372,
                child: CalendarDatePicker(
                  key: ValueKey(editingEnd),
                  initialDate: editingEnd ? end : start,
                  firstDate: editingEnd ? start : first,
                  lastDate: last,
                  onDateChanged: (d) => setState(() {
                    if (editingEnd) {
                      end = d;
                    } else {
                      start = d;
                      if (end.isBefore(start)) end = start;
                      editingEnd = true;
                    }
                  }),
                ),
              ),
            ),
            _actions(ctx,
                () => Navigator.of(ctx).pop(DateTimeRange(start: start, end: end))),
          ],
        );
      },
    ),
  );
}
