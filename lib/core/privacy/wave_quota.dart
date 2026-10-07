/// Límites de saludos. La fuente de verdad en producción es la Cloud Function.
abstract final class WaveQuota {
  static const int freeDailyLimit = 20;
  static const int freeRadiusMeters = 5000;
  static const int plusRadiusMeters = 10000;

  static bool canSend({required int sentToday, required bool plus}) {
    if (plus) return true;
    return sentToday < freeDailyLimit;
  }

  static int radiusCap({required bool plus}) =>
      plus ? plusRadiusMeters : freeRadiusMeters;
}

abstract final class ClpFormat {
  /// `$4.990` con punto de miles. No incluye "IVA incluido".
  static String pesos(int amount) {
    final negative = amount < 0;
    final digits = amount.abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write('.');
      buf.write(digits[i]);
    }
    return '${negative ? '-' : ''}\$$buf';
  }
}
