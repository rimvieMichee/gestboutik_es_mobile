import 'package:foodly/helpers/extensions/string.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:foodly/helpers/services/account_service.dart';
import 'package:foodly/helpers/services/error_handling.dart';
import 'package:foodly/helpers/theme/app_theme.dart';
import 'package:foodly/helpers/utils/app_snackbar.dart';
import 'package:foodly/widgets/gesboutik/gb_colors.dart';

/// Feuille de saisie du numéro de téléphone du gestionnaire (en-tête des PDF).
/// Renvoie `true` si le numéro a été enregistré.
Future<bool?> showPhoneSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.gb.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26.r)),
    ),
    builder: (_) => const _PhoneSheet(),
  );
}

class _PhoneSheet extends StatefulWidget {
  const _PhoneSheet();

  @override
  State<_PhoneSheet> createState() => _PhoneSheetState();
}

class _PhoneSheetState extends State<_PhoneSheet> {
  final _controller = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final phone = await AccountService.getPhone();
      if (mounted) _controller.text = phone ?? '';
    } on DioException catch (e) {
      letMeHandleAllErrors(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await AccountService.updatePhone(_controller.text);
      if (!mounted) return;
      appSnackbar(
        heading: 'phone_saved'.tr(),
        message: 'phone_saved_desc'.tr(),
        snackbarState: SnackbarState.success,
      );
      Navigator.of(context).pop(true);
    } on DioException catch (e) {
      letMeHandleAllErrors(e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.gb;
    final primary = AppTheme.theme.colorScheme.primary;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20.w, 10.h, 20.w, MediaQuery.of(context).viewInsets.bottom + 20.h),
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
                  color: c.skeleton, borderRadius: BorderRadius.circular(4.r)),
            ),
          ),
          Text('my_phone'.tr(),
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 4.h),
          Text(
            'phone_sheet_desc'.tr(),
            style: TextStyle(fontSize: 12.5.sp, color: c.subtext),
          ),
          SizedBox(height: 18.h),
          TextField(
            controller: _controller,
            enabled: !_loading,
            keyboardType: TextInputType.phone,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'phone'.tr(),
              prefixIcon: Icon(LucideIcons.phone, size: 19.sp),
              filled: true,
              fillColor: c.fill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: primary, width: 1.6),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            height: 50.h,
            child: FilledButton(
              onPressed: _loading || _saving ? null : _save,
              child: Text(_saving ? 'saving'.tr() : 'save'.tr(),
                  style:
                      TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
