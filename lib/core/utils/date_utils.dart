import 'package:intl/intl.dart';

/// Formateo de fechas en español chileno natural.
abstract final class PicaflorDateUtils {
  static final DateFormat _time = DateFormat('HH:mm', 'es');
  static final DateFormat _dayMonth = DateFormat("d 'de' MMM", 'es');
  static final DateFormat _full = DateFormat("d 'de' MMMM, yyyy", 'es');

  /// Para listas de chat: "ahora", "hace 5 min", "ayer", "14:30", "3 de mar".
  static String relative(DateTime? date, {DateTime? now}) {
    if (date == null) return '';
    final n = now ?? DateTime.now();
    final diff = n.difference(date);

    if (diff.inSeconds < 45) return 'ahora';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24 && date.day == n.day) {
      return _time.format(date);
    }

    final yesterday = n.subtract(const Duration(days: 1));
    if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'ayer';
    }

    if (diff.inDays < 7) {
      return _weekday(date.weekday);
    }

    if (date.year == n.year) {
      return _dayMonth.format(date);
    }

    return _full.format(date);
  }

  /// Solo hora (burbujas de chat).
  static String timeOnly(DateTime? date) {
    if (date == null) return '';
    return _time.format(date);
  }

  /// Separador de día en el hilo del chat.
  static String daySeparator(DateTime date, {DateTime? now}) {
    final n = now ?? DateTime.now();
    if (date.year == n.year && date.month == n.month && date.day == n.day) {
      return 'Hoy';
    }
    final yesterday = n.subtract(const Duration(days: 1));
    if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'Ayer';
    }
    return _dayMonth.format(date);
  }

  /// "En línea", "hace 3 min", "ayer a las 18:20".
  static String lastSeenLabel(DateTime? lastSeen, {bool isOnline = false}) {
    if (isOnline) return 'En línea';
    if (lastSeen == null) return 'Desconectado';

    final n = DateTime.now();
    final diff = n.difference(lastSeen);

    if (diff.inMinutes < 2) return 'Activo hace un momento';
    if (diff.inMinutes < 60) return 'Activo hace ${diff.inMinutes} min';
    if (diff.inHours < 24 && lastSeen.day == n.day) {
      return 'Activo hoy a las ${_time.format(lastSeen)}';
    }
    final yesterday = n.subtract(const Duration(days: 1));
    if (lastSeen.year == yesterday.year &&
        lastSeen.month == yesterday.month &&
        lastSeen.day == yesterday.day) {
      return 'Activo ayer a las ${_time.format(lastSeen)}';
    }
    return 'Activo el ${_dayMonth.format(lastSeen)}';
  }

  static String _weekday(int weekday) {
    const names = {
      1: 'lunes',
      2: 'martes',
      3: 'miércoles',
      4: 'jueves',
      5: 'viernes',
      6: 'sábado',
      7: 'domingo',
    };
    return names[weekday] ?? '';
  }
}
