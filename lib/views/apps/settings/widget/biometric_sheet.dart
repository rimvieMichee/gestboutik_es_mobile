import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:foodly/helpers/extensions/string.dart';
import 'package:foodly/helpers/services/biometric_service.dart';
import 'package:foodly/helpers/theme/app_theme.dart';
import 'package:foodly/widgets/gesboutik/gb_colors.dart';

/// Demande le mot de passe avant d'activer la connexion biométrique : il est
/// vérifié auprès du serveur ([verify]) puis rangé dans le stockage sécurisé.
/// Renvoie le mot de passe validé, ou `null` si l'utilisateur annule.
Future<String?> showBiometricPasswordSheet(
  BuildContext context, {
  required Future<bool> Function(String password) verify,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.gb.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26.r)),
    ),
    builder: (_) => _BiometricSheet(verify: verify),
  );
}

class _BiometricSheet extends StatefulWidget {
  final Future<bool> Function(String) verify;
  const _BiometricSheet({required this.verify});

  @override
  State<_BiometricSheet> createState() => _BiometricSheetState();
}

class _BiometricSheetState extends State<_BiometricSheet> {
  final _controller = TextEditingController();
  bool _show = false;
  bool _busy = false;
  String? _error;

  Future<void> _submit() async {
    final value = _controller.text;
    if (value.isEmpty) {
      setState(() => _error = 'login_enter_password'.tr());
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await widget.verify(value);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(value);
    } else {
      setState(() {
        _busy = false;
        _error = 'login_wrong_credentials'.tr();
      });
    }
  }

  @override
  void dispose() {
    // Le champ peut encore être reconstruit pendant l'animation de fermeture.
    Future.delayed(const Duration(milliseconds: 700), _controller.dispose);
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
          Row(children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                  color: primary.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(
                  BiometricService.isIOS
                      ? Icons.face_unlock_outlined
                      : Icons.fingerprint,
                  color: primary,
                  size: 24.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text('biometric_confirm_password'.tr(),
                  style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: c.text)),
            ),
          ]),
          SizedBox(height: 8.h),
          Text('biometric_confirm_password_desc'.tr(),
              style: TextStyle(fontSize: 12.5.sp, color: c.subtext)),
          SizedBox(height: 18.h),
          TextField(
            controller: _controller,
            obscureText: !_show,
            autofocus: true,
            enabled: !_busy,
            onSubmitted: (_) => _submit(),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            decoration: InputDecoration(
              labelText: 'login_password'.tr(),
              errorText: _error,
              prefixIcon: Icon(LucideIcons.lock, size: 19.sp),
              suffixIcon: IconButton(
                icon: Icon(_show ? LucideIcons.eye : LucideIcons.eyeOff,
                    size: 19.sp),
                onPressed: () => setState(() => _show = !_show),
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
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            height: 50.h,
            child: FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? SizedBox(
                      width: 22.w,
                      height: 22.w,
                      child: const CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text('biometric_enable_action'.tr(),
                      style: TextStyle(
                          fontSize: 15.sp, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
