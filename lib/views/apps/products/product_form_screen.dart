import 'package:foodly/helpers/extensions/string.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:foodly/widgets/gesboutik/gb_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart' hide Trans;
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:foodly/controller/apps/products/products_controller.dart';
import 'package:foodly/helpers/theme/app_theme.dart';
import 'package:foodly/helpers/utils/app_snackbar.dart';
import 'package:foodly/models/product_model.dart';
import 'package:foodly/widgets/gesboutik/gb_app_bar.dart';
import 'package:foodly/widgets/gesboutik/gb_format.dart';

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProductsController _controller = Get.find<ProductsController>();
  final ProductModel? _product = Get.arguments as ProductModel?;

  late final _nom = TextEditingController(text: _product?.nom);
  late final _description = TextEditingController(text: _product?.description);
  late final _prixVente = TextEditingController(
      text: _product == null ? '' : _product.prixVente.toStringAsFixed(0));
  late final _prixAchat = TextEditingController(
      text: _product?.prixAchat == null
          ? ''
          : _product!.prixAchat!.toStringAsFixed(0));
  late final _seuil =
      TextEditingController(text: '${_product?.seuilAlerte ?? 0}');
  final _quantite = TextEditingController(text: '0');

  String? _pickedImagePath;

  bool get _isEdit => _product != null;

  @override
  void dispose() {
    for (final c in [
      _nom,
      _description,
      _prixVente,
      _prixAchat,
      _seuil,
      _quantite
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 80,
    );
    if (file != null) setState(() => _pickedImagePath = file.path);
  }

  void _chooseSource() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(LucideIcons.image),
              title: Text('gallery'.tr()),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.camera),
              title: Text('camera'.tr()),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await _controller.saveProduct(
      id: _product?.id,
      nom: _nom.text.trim(),
      prixVente: double.parse(_prixVente.text.replaceAll(',', '.')),
      prixAchat: _prixAchat.text.trim().isEmpty
          ? null
          : double.parse(_prixAchat.text.replaceAll(',', '.')),
      quantiteInitiale: _isEdit ? 0 : int.tryParse(_quantite.text) ?? 0,
      seuilAlerte: int.tryParse(_seuil.text) ?? 0,
      description: _description.text.trim(),
      existingImage: _product?.image,
      imagePath: _pickedImagePath,
    );
    if (!ok || !mounted) return;
    final nom = _nom.text.trim();
    // pop() direct : Get.back() fermerait d'abord un éventuel snackbar ouvert
    // au lieu de quitter la page.
    Navigator.of(context).pop();
    appSnackbar(
      heading: _isEdit ? 'product_updated'.tr() : 'product_added'.tr(),
      message: (_isEdit ? 'product_updated_ok' : 'product_added_ok')
          .trp({'name': nom}),
      snackbarState: SnackbarState.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.theme.colorScheme.primary;
    return Scaffold(
      backgroundColor: context.gb.background,
      appBar:
          gbAppBar(title: _isEdit ? 'edit_product'.tr() : 'new_product'.tr()),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 0),
                    child: Column(
                      children: [
                        _imagePicker(primary),
                        SizedBox(height: 22.h),
                        _section('information'.tr(), LucideIcons.tag, [
                          _field(_nom, 'product_name_required'.tr(),
                              icon: LucideIcons.package, validator: _required),
                          _field(_description, 'description'.tr(),
                              icon: LucideIcons.alignLeft, lines: 3),
                        ]),
                        _section('pricing'.tr(), LucideIcons.wallet, [
                          _field(_prixVente, 'sell_price_required'.tr(),
                              icon: LucideIcons.banknote,
                              suffix: 'FCFA',
                              number: true,
                              validator: _positiveNumber),
                          _field(_prixAchat, 'buy_price'.tr(),
                              icon: LucideIcons.receipt,
                              suffix: 'FCFA',
                              number: true,
                              validator: _optionalNumber),
                          _margin(),
                        ]),
                        _section('stock'.tr(), LucideIcons.boxes, [
                          if (!_isEdit)
                            _field(_quantite, 'initial_quantity'.tr(),
                                icon: LucideIcons.packagePlus,
                                number: true,
                                validator: _optionalInt)
                          else
                            _stockInfo(primary),
                          _field(_seuil, 'alert_threshold'.tr(),
                              icon: LucideIcons.bellRing,
                              number: true,
                              validator: _optionalInt),
                        ]),
                        SizedBox(height: 24.h),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _saveBar(primary),
          ],
        ),
      ),
    );
  }

  Widget _imagePicker(Color primary) {
    final Widget content;
    if (_pickedImagePath != null) {
      content = Image.file(File(_pickedImagePath!), fit: BoxFit.cover);
    } else if (_product?.image != null && _product!.image!.isNotEmpty) {
      content =
          CachedNetworkImage(imageUrl: _product.image!, fit: BoxFit.cover);
    } else {
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.imagePlus, size: 30.sp, color: primary),
          SizedBox(height: 6.h),
          Text('add_photo'.tr(),
              style: TextStyle(
                  fontSize: 11.sp,
                  color: context.gb.subtext,
                  fontWeight: FontWeight.w500)),
        ],
      );
    }
    final hasImage =
        _pickedImagePath != null || (_product?.image?.isNotEmpty ?? false);
    return GestureDetector(
      onTap: _chooseSource,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 128.w,
            height: 128.w,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(22.r),
              border: Border.all(color: primary.withOpacity(0.25)),
            ),
            child: content,
          ),
          if (hasImage)
            Positioned(
              right: -6.w,
              bottom: -6.w,
              child: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child:
                    Icon(LucideIcons.camera, size: 16.sp, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _section(String title, IconData icon, List<Widget> children) {
    final primary = AppTheme.theme.colorScheme.primary;
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 14.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: context.gb.surface,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: context.gb.shadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(7.w),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(9.r),
                ),
                child: Icon(icon, size: 16.sp, color: primary),
              ),
              SizedBox(width: 10.w),
              Text(title,
                  style: TextStyle(
                      fontSize: 14.5.sp, fontWeight: FontWeight.w700)),
            ],
          ),
          SizedBox(height: 16.h),
          ...children,
        ],
      ),
    );
  }

  /// Marge calculée en direct à partir des deux prix saisis.
  Widget _margin() {
    return ListenableBuilder(
      listenable: Listenable.merge([_prixVente, _prixAchat]),
      builder: (context, _) {
        final vente = double.tryParse(_prixVente.text.replaceAll(',', '.'));
        final achat = double.tryParse(_prixAchat.text.replaceAll(',', '.'));
        if (vente == null || achat == null) return const SizedBox.shrink();
        final margin = vente - achat;
        final color = margin >= 0 ? Colors.green : Colors.red;
        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            children: [
              Icon(
                  margin >= 0
                      ? LucideIcons.trendingUp
                      : LucideIcons.trendingDown,
                  size: 18.sp,
                  color: color),
              SizedBox(width: 8.w),
              Text('margin_per_unit'.tr(),
                  style:
                      TextStyle(fontSize: 12.5.sp, color: context.gb.subtext)),
              Text(formatFcfa(margin),
                  style: TextStyle(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w700,
                      color: color)),
            ],
          ),
        );
      },
    );
  }

  Widget _stockInfo(Color primary) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 14.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.info, size: 18.sp, color: primary),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'stock_current_hint'
                  .trp({'n': '${_product!.quantiteDisponible}'}),
              style: TextStyle(
                  fontSize: 12.sp, color: context.gb.subtext, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _saveBar(Color primary) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16.w, 12.h, 16.w, 12.h + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: context.gb.surface,
        boxShadow: context.gb.shadow,
      ),
      child: Obx(
        () => SizedBox(
          width: double.infinity,
          height: 50.h,
          child: FilledButton(
            onPressed: _controller.isSaving.value ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r)),
            ),
            child: Text(
              _controller.isSaving.value
                  ? 'saving'.tr()
                  : (_isEdit ? 'save_changes'.tr() : 'create_product'.tr()),
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'required_field'.tr() : null;

  String? _positiveNumber(String? v) {
    final n = double.tryParse((v ?? '').replaceAll(',', '.'));
    return (n == null || n <= 0) ? 'invalid_amount'.tr() : null;
  }

  String? _optionalNumber(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final n = double.tryParse(v.replaceAll(',', '.'));
    return (n == null || n < 0) ? 'invalid_amount'.tr() : null;
  }

  String? _optionalInt(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final n = int.tryParse(v);
    return (n == null || n < 0) ? 'invalid_integer'.tr() : null;
  }

  Widget _field(
    TextEditingController c,
    String label, {
    required IconData icon,
    bool number = false,
    int lines = 1,
    String? suffix,
    String? Function(String?)? validator,
  }) {
    final primary = AppTheme.theme.colorScheme.primary;
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: color, width: width),
        );
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: TextFormField(
        controller: c,
        maxLines: lines,
        validator: validator,
        keyboardType: number
            ? const TextInputType.numberWithOptions(decimal: true)
            : null,
        textCapitalization:
            number ? TextCapitalization.none : TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          prefixIcon: Icon(icon, size: 19.sp, color: context.gb.subtext),
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
