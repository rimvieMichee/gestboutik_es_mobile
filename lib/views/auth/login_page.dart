import 'package:flutter/material.dart';
import 'package:foodly/widgets/gesboutik/gb_colors.dart';
import 'package:foodly/helpers/extensions/string.dart';
import 'package:foodly/helpers/services/biometric_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:foodly/controller/auth/login_controller.dart';
import 'package:foodly/helpers/theme/app_theme.dart';
import 'package:get/get.dart' hide Trans;
import 'package:lucide_icons/lucide_icons.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late final LoginController controller;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    controller = Get.put(LoginController());

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _animationController, curve: Curves.easeOutCubic));

    _animationController.forward();
    // Empreinte / Face ID activés : la demande s'ouvre toute seule.
    WidgetsBinding.instance
        .addPostFrameCallback((_) => controller.autoPromptBiometric());
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.gb.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 22.w),
          child: ConstrainedBox(
            constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.vertical),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 48.h),
                    Center(child: _buildLogo()),
                    SizedBox(height: 28.h),
                    _buildWelcomeText(),
                    SizedBox(height: 32.h),
                    _buildLoginCard(),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    final primary = AppTheme.theme.colorScheme.primary;
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutBack,
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) => Transform.scale(
        scale: value,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26.r),
            boxShadow: [
              BoxShadow(
                color: primary.withOpacity(0.35),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Image.asset('assets/images/logo/login.png',
              width: 88.w, height: 88.w),
        ),
      ),
    );
  }

  Widget _buildWelcomeText() {
    return Obx(() {
      final saved = controller.useSavedAccount;
      final first = (controller.savedDisplayName.value ?? '').split(' ').first;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            saved && first.isNotEmpty ? first : 'login_title'.tr(),
            style: TextStyle(
              fontSize: 30.sp,
              fontWeight: FontWeight.bold,
              color: context.gb.text,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            saved && first.isNotEmpty
                ? '${'login_welcome_back'.tr()}, $first'
                : 'login_welcome'.tr(),
            style: TextStyle(
              fontSize: 15.sp,
              color: context.gb.subtext,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildLoginCard() {
    return Obx(() {
      final saved = controller.useSavedAccount;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (saved) _buildSavedAccount() else _buildUsernameField(),
          SizedBox(height: 20.h),
          _buildPasswordField(),
          SizedBox(height: 28.h),
          _buildGeneralError(),
          _buildLoginButton(),
          if (controller.biometricReady.value) _buildBiometricButton(),
          if (saved) _buildOtherAccount(),
        ],
      );
    });
  }

  /// Compte déjà utilisé sur cet appareil : pastille + identifiant.
  Widget _buildSavedAccount() {
    final primary = AppTheme.theme.colorScheme.primary;
    final name = controller.savedDisplayName.value ?? '';
    return Row(
      children: [
        Container(
          width: 46.w,
          height: 46.w,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: primary.withOpacity(0.14), shape: BoxShape.circle),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: TextStyle(
                fontSize: 20.sp, fontWeight: FontWeight.bold, color: primary),
          ),
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: context.gb.text)),
              Text('@${controller.savedUsername.value}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      TextStyle(fontSize: 12.5.sp, color: context.gb.subtext)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBiometricButton() {
    final primary = AppTheme.theme.colorScheme.primary;
    final isIOS = BiometricService.isIOS;
    return Padding(
      padding: EdgeInsets.only(top: 18.h),
      child: Column(
        children: [
          Row(children: [
            Expanded(child: Divider(color: context.gb.border)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Text('login_or'.tr(),
                  style: TextStyle(fontSize: 12.sp, color: context.gb.subtext)),
            ),
            Expanded(child: Divider(color: context.gb.border)),
          ]),
          SizedBox(height: 14.h),
          InkWell(
            onTap: controller.isLoading.value
                ? null
                : controller.loginWithBiometrics,
            customBorder: const CircleBorder(),
            child: Container(
              width: 64.w,
              height: 64.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primary.withOpacity(0.12),
                border: Border.all(color: primary.withOpacity(0.5), width: 1.4),
              ),
              child: Icon(
                isIOS ? Icons.face_unlock_outlined : Icons.fingerprint,
                size: 34.sp,
                color: primary,
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            (isIOS ? 'biometric_login_cta_face' : 'biometric_login_cta').tr(),
            style: TextStyle(fontSize: 12.sp, color: context.gb.subtext),
          ),
        ],
      ),
    );
  }

  Widget _buildOtherAccount() {
    return Padding(
      padding: EdgeInsets.only(top: 10.h),
      child: Center(
        child: TextButton(
          onPressed: controller.useAnotherAccount,
          child: Text(
            'login_other_account'.tr(),
            style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.theme.colorScheme.primary),
          ),
        ),
      ),
    );
  }

  Widget _buildUsernameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'login_username'.tr(),
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: context.gb.text,
          ),
        ),
        SizedBox(height: 8.h),
        Obx(
          () => Container(
            decoration: BoxDecoration(
              color: context.gb.fill,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: controller.usernameError.value != null
                    ? Colors.red
                    : Colors.transparent,
              ),
            ),
            child: TextField(
              controller: controller.username,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              style: TextStyle(fontSize: 16.sp),
              decoration: InputDecoration(
                hintText: 'your_username'.tr(),
                hintStyle: TextStyle(color: context.gb.subtext),
                prefixIcon: Icon(
                  LucideIcons.user,
                  color: AppTheme.theme.colorScheme.primary,
                  size: 20.sp,
                ),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              ),
            ),
          ),
        ),
        _fieldError(controller.usernameError),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'login_password'.tr(),
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: context.gb.text,
          ),
        ),
        SizedBox(height: 8.h),
        Obx(
          () => Container(
            decoration: BoxDecoration(
              color: context.gb.fill,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: controller.passwordError.value != null
                    ? Colors.red
                    : Colors.transparent,
              ),
            ),
            child: TextField(
              controller: controller.password,
              obscureText: !controller.showPassword.value,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => controller.onLogin(),
              style: TextStyle(fontSize: 16.sp),
              decoration: InputDecoration(
                hintText: '••••••••',
                hintStyle: TextStyle(color: context.gb.subtext),
                prefixIcon: Icon(
                  LucideIcons.lock,
                  color: AppTheme.theme.colorScheme.primary,
                  size: 20.sp,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    controller.showPassword.value
                        ? LucideIcons.eye
                        : LucideIcons.eyeOff,
                    color: context.gb.subtext,
                    size: 20.sp,
                  ),
                  onPressed: controller.toggleShowPassword,
                ),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              ),
            ),
          ),
        ),
        _fieldError(controller.passwordError),
      ],
    );
  }

  /// Message d'erreur sous un champ (rien si pas d'erreur ou message vide).
  Widget _fieldError(RxnString error) {
    return Obx(() {
      final message = error.value;
      if (message == null || message.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: EdgeInsets.only(top: 6.h, left: 4.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(LucideIcons.alertCircle, size: 14.sp, color: Colors.red),
            SizedBox(width: 6.w),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                    fontSize: 12.5.sp, color: Colors.red, height: 1.3),
              ),
            ),
          ],
        ),
      );
    });
  }

  /// Bandeau pour les erreurs qui ne concernent aucun champ (réseau, serveur).
  Widget _buildGeneralError() {
    return Obx(() {
      final message = controller.generalError.value;
      if (message == null) return const SizedBox.shrink();
      return Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 16.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.10),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.red.withOpacity(0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(LucideIcons.wifiOff, size: 18.sp, color: Colors.red),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                    fontSize: 12.5.sp, color: Colors.red, height: 1.35),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildLoginButton() {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        height: 56.h,
        child: ElevatedButton(
          onPressed: controller.isLoading.value ? null : controller.onLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.theme.colorScheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            elevation: 0,
            shadowColor: AppTheme.theme.colorScheme.primary.withOpacity(0.5),
          ),
          child: controller.isLoading.value
              ? SizedBox(
                  width: 24.w,
                  height: 24.h,
                  child: const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'login_button'.tr(),
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
