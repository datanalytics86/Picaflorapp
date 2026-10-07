import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../services/safety_service_live.dart' deferred as live;

/// Bloqueos y reportes en memoria (demo) o vía callable (prod).
class SafetyController extends ChangeNotifier {
  final _blocked = <String>{};
  final _reports = <Map<String, String>>[];

  Set<String> get blocked => Set.unmodifiable(_blocked);

  bool isBlocked(String uid) => _blocked.contains(uid);

  Future<void> block(String otherUid) async {
    if (otherUid.isEmpty) return;
    _blocked.add(otherUid);
    notifyListeners();
    if (AppConfig.demoMode) return;
    await live.loadLibrary();
    await live.blockUser(otherUid);
  }

  Future<void> report({
    required String otherUid,
    required String reason,
    String? text,
    bool alsoBlock = true,
  }) async {
    _reports.add({
      'otherUid': otherUid,
      'reason': reason,
      if (text != null) 'text': text,
    });
    if (alsoBlock) await block(otherUid);
    if (AppConfig.demoMode) return;
    await live.loadLibrary();
    await live.submitReport(otherUid: otherUid, reason: reason, text: text);
  }

  Future<void> deleteAccount() async {
    if (AppConfig.demoMode) return;
    await live.loadLibrary();
    await live.deleteAccount();
  }

  Future<Map<String, dynamic>> exportMyData() async {
    if (AppConfig.demoMode) {
      return {
        'mode': 'demo',
        'note': 'En demo no hay datos en la nube.',
        'blocked': _blocked.toList(),
      };
    }
    await live.loadLibrary();
    return live.exportMyData();
  }
}

final safetyControllerProvider = ChangeNotifierProvider<SafetyController>((ref) {
  return SafetyController();
});
