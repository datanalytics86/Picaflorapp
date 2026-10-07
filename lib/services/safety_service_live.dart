import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/config/app_config.dart';

FirebaseFunctions get _fns =>
    FirebaseFunctions.instanceFor(region: AppConfig.region);

Future<void> sendWave({
  required String toUid,
  String? note,
}) async {
  await _fns.httpsCallable('sendWave').call({
    'toUid': toUid,
    if (note != null && note.isNotEmpty) 'note': note,
  });
}

Future<String?> respondWave({
  required String waveId,
  required bool accept,
}) async {
  final res = await _fns.httpsCallable('respondWave').call({
    'waveId': waveId,
    'accept': accept,
  });
  final data = res.data;
  if (data is Map && data['chatId'] is String) {
    return data['chatId'] as String;
  }
  return null;
}

Future<void> blockUser(String otherUid) async {
  await _fns.httpsCallable('blockUser').call({'otherUid': otherUid});
}

Future<void> submitReport({
  required String otherUid,
  required String reason,
  String? text,
}) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) {
    throw StateError('Sin sesión');
  }
  await FirebaseFirestore.instance.collection('reports').add({
    'reporterId': uid,
    'otherUid': otherUid,
    'reason': reason,
    'text': text ?? '',
    'createdAt': FieldValue.serverTimestamp(),
  });
}

Future<void> deleteAccount() async {
  await _fns.httpsCallable('deleteAccount').call({'confirm': 'ELIMINAR'});
}

Future<Map<String, dynamic>> exportMyData() async {
  final res = await _fns.httpsCallable('exportMyData').call();
  final data = res.data;
  if (data is Map) {
    return data.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}
