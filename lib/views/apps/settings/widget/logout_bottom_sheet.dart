import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:foodly/helpers/extensions/string.dart';
import 'package:foodly/widgets/gesboutik/gb_colors.dart';

/// Confirmation de déconnexion (feuille modale). Renvoie `true` si confirmé.
class LogoutDeleteBottomSheet extends StatelessWidget {
  final String title;
  final String subTitle;

  const LogoutDeleteBottomSheet({
    super.key,
    required this.title,
    required this.subTitle,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.gb;
    return Container(
      padding: EdgeInsets.fromLTRB(
          20.w, 12.h, 20.w, 24.h + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 17.sp, fontWeight: FontWeight.w700, color: c.text),
          ),
          SizedBox(height: 8.h),
          Text(
            subTitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5.sp, color: c.subtext),
          ),
          SizedBox(height: 24.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c.text,
                    side: BorderSide(color: c.border),
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r)),
                  ),
                  child: Text('no'.tr(),
                      style: TextStyle(
                          fontSize: 14.sp, fontWeight: FontWeight.w600)),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r)),
                  ),
                  child: Text('yes'.tr(),
                      style: TextStyle(
                          fontSize: 14.sp, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
