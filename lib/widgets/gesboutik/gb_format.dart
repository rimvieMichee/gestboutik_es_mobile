import 'package:intl/intl.dart';

final NumberFormat _fcfaFormat = NumberFormat('#,##0', 'fr_FR');

/// 12500 -> « 12 500 FCFA »
String formatFcfa(num value) =>
    '${_fcfaFormat.format(value).replaceAll(' ', ' ').replaceAll(' ', ' ')} FCFA';
