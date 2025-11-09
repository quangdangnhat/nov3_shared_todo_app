import 'package:intl/intl.dart';

/// Utility class per formattare le date
class DateFormatter {
  /// Formato completo: dd/MM/yyyy HH:mm
  static String formatFull(DateTime? date) {
    return date != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(date)
        : 'Data non impostata';
  }

  /// Formato breve: dd/MM
  static String formatShort(DateTime date) {
    return DateFormat('dd/MM').format(date);
  }

  /// Formato per la data odierna: Lunedì, 09 novembre 2025
  static String formatToday() {
    return DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now());
  }

  /// Calcola i giorni rimanenti fino a una data
  static int daysUntil(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);

    return targetDate.difference(today).inDays;
  }

  /// Calcola la durata in giorni tra due date
  static int daysBetween(DateTime start, DateTime end) {
    final startDate = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);

    return endDate.difference(startDate).inDays;
  }

  /// Verifica se una data è scaduta
  static bool isOverdue(DateTime date) {
    return daysUntil(date) < 0;
  }

  /// Formatta i giorni rimanenti in modo descrittivo
  static String formatDaysRemaining(DateTime dueDate) {
    final days = daysUntil(dueDate);

    if (days < 0) {
      return 'Expired  ${-days} ${(-days) == 1 ? "day ago" : "days ago"}';
    } else if (days == 0) {
      return 'Expire Today';
    } else if (days == 1) {
      return 'Expire tomorrow';
    } else {
      return 'Days Left: $days';
    }
  }
}
