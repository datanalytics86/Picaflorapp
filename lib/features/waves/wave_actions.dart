import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/privacy/wave_quota.dart';
import '../../services/safety_service_live.dart' deferred as live;
import 'wave_models.dart';

class WaveException implements Exception {
  WaveException(this.message);
  final String message;
}

class WaveActions {
  Future<Wave> send({
    required String fromUid,
    required String toUid,
    String? note,
    required bool plus,
  }) async {
    if (fromUid.isEmpty || toUid.isEmpty || fromUid == toUid) {
      throw WaveException('No se pudo enviar el saludo.');
    }
    if (!WaveQuota.canSend(
      sentToday: memoryWaves.sentToday(fromUid, DateTime.now()),
      plus: plus,
    )) {
      throw WaveException(
        'Llegaste a ${WaveQuota.freeDailyLimit} saludos hoy. Mañana se renuevan.',
      );
    }
    if (note != null && note.trim().isNotEmpty && !plus) {
      throw WaveException('La nota va con Picaflor Plus.');
    }
    if (memoryWaves.pendingBetween(fromUid, toUid) != null) {
      throw WaveException('Ya hay un saludo pendiente.');
    }

    if (!AppConfig.demoMode) {
      await live.loadLibrary();
      await live.sendWave(toUid: toUid, note: note);
    }

    return memoryWaves.add(fromUid: fromUid, toUid: toUid, note: note);
  }
}

final waveActionsProvider = Provider<WaveActions>((ref) => WaveActions());
