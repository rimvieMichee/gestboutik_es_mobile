import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:foodly/helpers/extensions/string.dart';
import 'package:foodly/helpers/services/auth_services.dart';
import 'package:foodly/helpers/services/error_handling.dart';
import 'package:foodly/helpers/theme/app_theme.dart';
import 'package:foodly/helpers/utils/app_snackbar.dart';
import 'package:foodly/widgets/gesboutik/gb_colors.dart';

/// Feuille de changement de mot de passe : l'actuel, le nouveau (8 caractères
/// minimum) et sa confirmation. Renvoie `true` si le mot de passe a changé.
Future<bool?> showPasswordSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.gb.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26.r)),
    ),
    builder: (_) => const _PasswordSheet(),
  );
}

class _PasswordSheet extends StatefulWidget {
  const _PasswordSheet();

  @override
  State<_PasswordSheet> createState() => _PasswordSheetState();
}

class _PasswordSheetState extends State<_PasswordSheet> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _showCurrent = false;
  bool _showNext = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _validate() {
    if (_current.text.isEmpty) return 'pw_err_current'.tr();
    if (_next.text.length < 8) return 'pw_err_short'.tr();
    if (_next.text == _current.text) return 'pw_err_same'.tr();
    if (_next.text != _confirm.text) return 'pw_err_match'.tr();
    return null;
  }

  Future<void> _save() async {
    final problem = _validate();
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      await AuthService.changePassword(_current.text, _next.text);
      if (!mounted) return;
      appSnackbar(
        heading: 'pw_changed'.tr(),
        message: 'pw_changed_desc'.tr(),
        snackbarState: SnackbarState.success,
      );
      Navigator.of(context).pop(true);
    } on DioException catch (e) {
      letMeHandleAllErrors(e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(TextEditingController ctl, String label, bool visible,
      VoidCallback? toggle,
      {bool autofocus = false}) {
    final c = context.gb;
    final primary = AppTheme.theme.colorScheme.primary;
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: TextField(
        controller: ctl,
        obscureText: !visible,
        autofocus: autofocus,
        enableSuggestions: false,
        autocorrect: false,
        onChanged: (_) {
          if (_error != null) setState(() => _error = null);
        },
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(LucideIcons.lock, size: 19.sp),
          suffixIcon: toggle == null
              ? null
              : IconButton(
                  onPressed: toggle,
                  icon: Icon(visible ? LucideIcons.eyeOff : LucideIcons.eye,
                      size: 19.sp),
                ),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.gb;
    return SingleChildScrollView(
      child: Padding(
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
                    color: c.skeleton,
                    borderRadius: BorderRadius.circular(4.r)),
              ),
            ),
            Text('change_password'.tr(),
                style:
                    TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 4.h),
            Text('pw_sheet_desc'.tr(),
                style: TextStyle(fontSize: 12.5.sp, color: c.subtext)),
            SizedBox(height: 18.h),
            _field(_current, 'pw_current'.tr(), _showCurrent,
                () => setState(() => _showCurrent = !_showCurrent),
                autofocus: true),
            _field(_next, 'pw_new'.tr(), _showNext,
                () => setState(() => _showNext = !_showNext)),
            _field(_confirm, 'pw_confirm'.tr(), _showNext, null),
            if (_error != null)
              Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: Row(
                  children: [
                    Icon(LucideIcons.alertCircle,
                        size: 16.sp, color: Colors.red.shade400),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(_error!,
                          style: TextStyle(
                              fontSize: 12.5.sp, color: Colors.red.shade400)),
                    ),
                  ],
                ),
              ),
            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'saving'.tr() : 'pw_update'.tr(),
                    style: TextStyle(
                        fontSize: 15.sp, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
