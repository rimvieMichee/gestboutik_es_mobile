import 'package:foodly/helpers/storage/local_storage.dart';
import 'package:intl/intl.dart';

enum PeriodKind { day, month, year, custom }

/// Période de consultation des ventes, dans le fuseau horaire de l'appareil.
/// `start` et `end` sont inclus (fin = 23:59:59.999 du dernier jour).
class Period {
  final PeriodKind kind;
  final DateTime start;
  final DateTime end;

  const Period._(this.kind, this.start, this.end);

  static DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
  static DateTime _endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

  factory Period.day(DateTime d) =>
      Period._(PeriodKind.day, _startOfDay(d), _endOfDay(d));

  factory Period.month(DateTime d) => Period._(
        PeriodKind.month,
        DateTime(d.year, d.month, 1),
        // Jour 0 du mois suivant = dernier jour du mois courant.
        _endOfDay(DateTime(d.year, d.month + 1, 0)),
      );

  factory Period.year(DateTime d) => Period._(
        PeriodKind.year,
        DateTime(d.year, 1, 1),
        _endOfDay(DateTime(d.year, 12, 31)),
      );

  factory Period.custom(DateTime a, DateTime b) {
    final from = a.isBefore(b) ? a : b;
    final to = a.isBefore(b) ? b : a;
    return Period._(PeriodKind.custom, _startOfDay(from), _endOfDay(to));
  }

  /// Semaine du lundi au dimanche contenant [d].
  factory Period.week(DateTime d) {
    final monday = DateTime(d.year, d.month, d.day - (d.weekday - 1));
    return Period._(PeriodKind.custom, _startOfDay(monday),
        _endOfDay(DateTime(monday.year, monday.month, monday.day + 6)));
  }

  factory Period.of(PeriodKind kind, [DateTime? reference]) {
    final ref = reference ?? DateTime.now();
    switch (kind) {
      case PeriodKind.day:
        return Period.day(ref);
      case PeriodKind.month:
        return Period.month(ref);
      case PeriodKind.year:
        return Period.year(ref);
      case PeriodKind.custom:
        return Period.custom(ref, ref);
    }
  }

  /// Période précédente (-1) ou suivante (+1) de même nature.
  Period shift(int delta) {
    switch (kind) {
      case PeriodKind.day:
        return Period.day(DateTime(start.year, start.month, start.day + delta));
      case PeriodKind.month:
        return Period.month(DateTime(start.year, start.month + delta, 1));
      case PeriodKind.year:
        return Period.year(DateTime(start.year + delta, 1, 1));
      case PeriodKind.custom:
        final days = end.difference(start).inDays + 1;
        return Period.custom(
          DateTime(start.year, start.month, start.day + delta * days),
          DateTime(end.year, end.month, end.day + delta * days),
        );
    }
  }

  /// On ne navigue pas vers le futur : rien n'a pu être vendu.
  bool get canGoNext => !shift(1).start.isAfter(DateTime.now());

  /// Bornes envoyées au serveur (UTC), calculées dans le fuseau de l'appareil.
  String get fromIso => start.toUtc().toIso8601String();
  String get toIso => end.toUtc().toIso8601String();

  String get label {
    String cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
    switch (kind) {
      case PeriodKind.day:
        return DateFormat('d MMMM yyyy', LocalStorage.dateLocale).format(start);
      case PeriodKind.month:
        return cap(DateFormat('MMMM yyyy', LocalStorage.dateLocale).format(start));
      case PeriodKind.year:
        return '${start.year}';
      case PeriodKind.custom:
        final f = DateFormat('d MMM yyyy', LocalStorage.dateLocale);
        return start.year == end.year &&
                start.month == end.month &&
                start.day == end.day
            ? f.format(start)
            : '${f.format(start)} – ${f.format(end)}';
    }
  }
}
