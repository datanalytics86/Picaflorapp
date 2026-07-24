/// Relativo en español chileno corto: "ahora", "hace 3 min", "ayer".
abstract final class TimeAgo {
  static String format(DateTime? date, {DateTime? now}) {
    if (date == null) return '';
    final n = now ?? DateTime.now();
    final diff = n.difference(date);

    if (diff.isNegative || diff.inSeconds < 45) return 'ahora';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24 && date.day == n.day) {
      final h = date.hour.toString().padLeft(2, '0');
      final m = date.minute.toString().padLeft(2, '0');
      return '$h:$m';
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

    return '${date.day}/${date.month}';
  }

  static String lastSeen(DateTime? lastSeen, {bool isOnline = false}) {
    if (isOnline) return 'En línea';
    if (lastSeen == null) return 'Desconectado';

    final n = DateTime.now();
    final diff = n.difference(lastSeen);

    if (diff.inMinutes < 2) return 'Activo hace un momento';
    if (diff.inMinutes < 60) return 'Activo hace ${diff.inMinutes} min';
    if (diff.inHours < 24 && lastSeen.day == n.day) {
      final h = lastSeen.hour.toString().padLeft(2, '0');
      final m = lastSeen.minute.toString().padLeft(2, '0');
      return 'Activo hoy a las $h:$m';
    }
    return 'Activo ${format(lastSeen)}';
  }

  static String _weekday(int weekday) {
    const names = {
      1: 'lun',
      2: 'mar',
      3: 'mié',
      4: 'jue',
      5: 'vie',
      6: 'sáb',
      7: 'dom',
    };
    return names[weekday] ?? '';
  }
}
