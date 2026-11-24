import 'package:foodly/helpers/storage/local_storage.dart';
import 'package:foodly/widgets/gesboutik/gb_sheets.dart';
import 'package:foodly/helpers/extensions/string.dart';
import 'package:flutter/material.dart';
import 'package:foodly/widgets/gesboutik/gb_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart' hide Trans;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:foodly/controller/apps/employees/employees_controller.dart';
import 'package:foodly/helpers/theme/app_theme.dart';
import 'package:foodly/helpers/utils/app_snackbar.dart';
import 'package:foodly/models/employee_model.dart';
import 'package:foodly/widgets/gesboutik/gb_add_button.dart';
import 'package:foodly/widgets/gesboutik/gb_app_bar.dart';
import 'package:foodly/widgets/gesboutik/gb_dispose.dart';
import 'package:foodly/widgets/gesboutik/gb_empty_state.dart';
import 'package:foodly/widgets/gesboutik/gb_search_field.dart';
import 'package:foodly/widgets/gesboutik/gb_skeleton.dart';
import 'package:foodly/widgets/gesboutik/gb_staggered_item.dart';

class EmployeesScreen extends StatelessWidget {
  const EmployeesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(EmployeesController());

    return Scaffold(
      backgroundColor: context.gb.background,
      appBar: gbAppBar(
        title: 'employees'.tr(),
        subtitle:
            LocalStorage.isMultiShop ? LocalStorage.getBoutiqueName() : null,
        showBack: false,
      ),
      floatingActionButton: GbAddButton(
        tooltip: 'new_employee'.tr(),
        onPressed: () => _showCreateSheet(context, controller),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 6.h),
            child: GbSearchField(
              hint: 'search_employee'.tr(),
              onChanged: controller.onSearchChanged,
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return GbSkeleton.employeeList();
              }
              if (controller.employees.isEmpty) {
                return GbEmptyState(
                  icon: LucideIcons.users,
                  title: 'no_employee'.tr(),
                  subtitle: controller.search.value.isNotEmpty
                      ? 'try_other_search'.tr()
                      : 'employees_empty_hint'.tr(),
                );
              }
              return RefreshIndicator(
                onRefresh: controller.loadEmployees,
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 170.h),
                  itemCount: controller.employees.length,
                  separatorBuilder: (_, __) => SizedBox(height: 10.h),
                  itemBuilder: (context, index) {
                    final employee = controller.employees[index];
                    return GbStaggeredItem(
                      index: index,
                      child: _EmployeeTile(
                        employee: employee,
                        onOpen: () => Get.toNamed('/employee-detail',
                            arguments: employee),
                        onResetPassword: () =>
                            showPasswordSheet(context, controller, employee),
                        onToggleStatus: () =>
                            confirmToggle(context, controller, employee),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- création

  void _showCreateSheet(BuildContext context, EmployeesController controller) {
    final formKey = GlobalKey<FormState>();
    final username = TextEditingController();
    final password = TextEditingController();
    final prenom = TextEditingController();
    final nom = TextEditingController();
    final telephone = TextEditingController();

    _showSheet(
      context,
      title: 'new_employee'.tr(),
      subtitle: 'employee_form_hint'.tr(),
      builder: (sheetContext) => Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SheetField(
                controller: prenom,
                label: 'first_name'.tr(),
                icon: LucideIcons.user),
            _SheetField(
                controller: nom,
                label: 'family_name'.tr(),
                icon: LucideIcons.user),
            _SheetField(
              controller: telephone,
              label: 'phone'.tr(),
              icon: LucideIcons.phone,
              keyboard: TextInputType.phone,
            ),
            _SheetField(
              controller: username,
              label: 'login_id_required'.tr(),
              icon: LucideIcons.atSign,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'login_id_error'.tr()
                  : null,
            ),
            _SheetField(
              controller: password,
              label: 'password_min8_required'.tr(),
              icon: LucideIcons.lock,
              password: true,
              validator: (v) =>
                  (v == null || v.length < 8) ? 'min8_chars'.tr() : null,
            ),
            SizedBox(height: 6.h),
            _SubmitButton(
              controller: controller,
              label: 'create_account'.tr(),
              busyLabel: 'creating'.tr(),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final ok = await controller.createEmployee(
                  username: username.text.trim(),
                  password: password.text,
                  nom: nom.text.trim(),
                  prenom: prenom.text.trim(),
                  telephone: telephone.text.trim(),
                );
                if (!ok || !sheetContext.mounted) return;
                final fullName =
                    '${prenom.text.trim()} ${nom.text.trim()}'.trim();
                final label =
                    fullName.isEmpty ? username.text.trim() : fullName;
                // Ferme la feuille puis confirme (pop direct, pas Get.back()).
                Navigator.of(sheetContext).pop();
                appSnackbar(
                  heading: 'employee_added'.tr(),
                  message: 'employee_added_msg'.trp({'name': label}),
                  snackbarState: SnackbarState.success,
                );
              },
            ),
          ],
        ),
      ),
    ).whenComplete(
        () => disposeAfterClose([username, password, prenom, nom, telephone]));
  }

  // ------------------------------------------------------------- modification

  static void showEditSheet(
    BuildContext context,
    EmployeesController controller,
    EmployeeModel employee,
  ) {
    final formKey = GlobalKey<FormState>();
    final prenom = TextEditingController(text: employee.prenom);
    final nom = TextEditingController(text: employee.nom);
    final telephone = TextEditingController(text: employee.telephone ?? '');

    _showSheet(
      context,
      title: 'edit_employee'.tr(),
      subtitle: 'account_handle'.trp({'username': employee.username}),
      builder: (sheetContext) => Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SheetField(
                controller: prenom,
                label: 'first_name'.tr(),
                icon: LucideIcons.user),
            _SheetField(
              controller: nom,
              label: 'family_name_required'.tr(),
              icon: LucideIcons.user,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'family_name_error'.tr()
                  : null,
            ),
            _SheetField(
              controller: telephone,
              label: 'phone'.tr(),
              icon: LucideIcons.phone,
              keyboard: TextInputType.phone,
            ),
            SizedBox(height: 6.h),
            _SubmitButton(
              controller: controller,
              label: 'save'.tr(),
              busyLabel: 'saving'.tr(),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final ok = await controller.updateEmployee(
                  employee,
                  nom: nom.text.trim(),
                  prenom: prenom.text.trim(),
                  telephone: telephone.text.trim(),
                );
                if (ok && sheetContext.mounted)
                  Navigator.of(sheetContext).pop();
              },
            ),
          ],
        ),
      ),
    ).whenComplete(() => disposeAfterClose([prenom, nom, telephone]));
  }

  // ------------------------------------------------------- changer mot de passe

  static void showPasswordSheet(
    BuildContext context,
    EmployeesController controller,
    EmployeeModel employee,
  ) {
    final formKey = GlobalKey<FormState>();
    final password = TextEditingController();

    _showSheet(
      context,
      title: 'change_password'.tr(),
      subtitle: 'change_pw_subtitle'.trp({
        'name': employee.nomComplet,
        'username': employee.username,
      }),
      builder: (sheetContext) => Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SheetField(
              controller: password,
              label: 'new_password_min8'.tr(),
              icon: LucideIcons.lock,
              password: true,
              validator: (v) =>
                  (v == null || v.length < 8) ? 'min8_chars'.tr() : null,
            ),
            SizedBox(height: 6.h),
            _SubmitButton(
              controller: controller,
              label: 'save'.tr(),
              busyLabel: 'saving'.tr(),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final ok =
                    await controller.resetPassword(employee, password.text);
                if (ok && sheetContext.mounted)
                  Navigator.of(sheetContext).pop();
              },
            ),
          ],
        ),
      ),
    ).whenComplete(() => disposeAfterClose([password]));
  }

  /// Bottom sheet commun : poignée, titre, sous-titre, contenu, clavier géré.
  static Future<void> _showSheet(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Widget Function(BuildContext) builder,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.gb.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26.r)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          20.w,
          10.h,
          20.w,
          MediaQuery.of(sheetContext).viewInsets.bottom + 20.h,
        ),
        child: SingleChildScrollView(
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
                    color: context.gb.skeleton,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ),
              ),
              Text(title,
                  style:
                      TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 4.h),
              Text(subtitle,
                  style:
                      TextStyle(fontSize: 12.5.sp, color: context.gb.subtext)),
              SizedBox(height: 18.h),
              builder(sheetContext),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------- activation

  static Future<void> confirmToggle(
    BuildContext context,
    EmployeesController controller,
    EmployeeModel employee,
  ) async {
    final off = employee.isActive;
    final ok = await showGbConfirmSheet(
      context,
      title: (off ? 'deactivate_account_q' : 'reactivate_account_q').tr(),
      message: off
          ? 'employee_cannot_login'.trp({'name': employee.nomComplet})
          : 'employee_can_login'.trp({'name': employee.nomComplet}),
      confirmLabel: (off ? 'deactivate' : 'reactivate').tr(),
      destructive: off,
      icon: off ? LucideIcons.userX : LucideIcons.userCheck,
    );
    if (ok == true) controller.toggleStatus(employee);
  }
}

/// Champ de formulaire des bottom sheets ; `password: true` ajoute l'icône œil.
class _SheetField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool password;
  final TextInputType? keyboard;
  final String? Function(String?)? validator;

  const _SheetField({
    required this.controller,
    required this.label,
    required this.icon,
    this.password = false,
    this.keyboard,
    this.validator,
  });

  @override
  State<_SheetField> createState() => _SheetFieldState();
}

class _SheetFieldState extends State<_SheetField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.theme.colorScheme.primary;
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: c, width: w),
        );
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: TextFormField(
        controller: widget.controller,
        obscureText: widget.password && _hidden,
        keyboardType: widget.keyboard,
        validator: widget.validator,
        autocorrect: false,
        enableSuggestions: !widget.password,
        decoration: InputDecoration(
          labelText: widget.label,
          prefixIcon: Icon(widget.icon, size: 19.sp, color: context.gb.subtext),
          suffixIcon: widget.password
              ? IconButton(
                  icon: Icon(_hidden ? LucideIcons.eye : LucideIcons.eyeOff,
                      size: 19.sp, color: context.gb.subtext),
                  onPressed: () => setState(() => _hidden = !_hidden),
                )
              : null,
          filled: true,
          fillColor: context.gb.fill,
          border: border(Colors.transparent),
          enabledBorder: border(Colors.transparent),
          focusedBorder: border(primary, 1.6),
          errorBorder: border(Colors.red.shade300),
          focusedErrorBorder: border(Colors.red, 1.6),
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final EmployeesController controller;
  final String label;
  final String busyLabel;
  final VoidCallback onPressed;

  const _SubmitButton({
    required this.controller,
    required this.label,
    required this.busyLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        height: 50.h,
        child: FilledButton(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r)),
          ),
          onPressed: controller.isSaving.value ? null : onPressed,
          child: Text(
            controller.isSaving.value ? busyLabel : label,
            style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class _EmployeeTile extends StatelessWidget {
  final EmployeeModel employee;
  final VoidCallback onOpen;
  final VoidCallback onResetPassword;
  final VoidCallback onToggleStatus;

  const _EmployeeTile({
    required this.employee,
    required this.onOpen,
    required this.onResetPassword,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.theme.colorScheme.primary;
    final statusColor = employee.isActive ? Colors.green : Colors.red;
    return Container(
      decoration: BoxDecoration(
        color: context.gb.surface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: context.gb.shadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: Padding(
            padding: EdgeInsets.fromLTRB(14.w, 12.h, 4.w, 12.h),
            child: Row(
              children: [
                Container(
                  width: 44.w,
                  height: 44.w,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: primary.withOpacity(0.12), shape: BoxShape.circle),
                  child: Text(
                    employee.nomComplet.characters.first.toUpperCase(),
                    style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: primary),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        employee.nomComplet,
                        style: TextStyle(
                            fontSize: 15.sp, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        '@${employee.username}',
                        style: TextStyle(
                            fontSize: 12.sp, color: context.gb.subtext),
                      ),
                      SizedBox(height: 6.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(
                          employee.isActive ? 'active'.tr() : 'disabled'.tr(),
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r)),
                  onSelected: (value) {
                    if (value == 'password') onResetPassword();
                    if (value == 'status') onToggleStatus();
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'password',
                      child: Row(children: [
                        Icon(LucideIcons.keyRound, size: 18),
                        SizedBox(width: 10),
                        Text('change_password'.tr()),
                      ]),
                    ),
                    PopupMenuItem(
                      value: 'status',
                      child: Row(children: [
                        Icon(
                            employee.isActive
                                ? LucideIcons.userX
                                : LucideIcons.userCheck,
                            size: 18),
                        const SizedBox(width: 10),
                        Text(employee.isActive
                            ? 'deactivate'.tr()
                            : 'reactivate'.tr()),
                      ]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
