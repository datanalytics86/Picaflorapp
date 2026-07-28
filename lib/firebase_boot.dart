import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options.dart';

/// Inicialización de Firebase aislada — se carga con `deferred as` desde main.
/// En DEMO_MODE main **nunca** llama a [loadLibrary] de este archivo.
Future<void> initFirebase() async {
  if (!DefaultFirebaseOptions.isConfigured) {
    debugPrint(
      '⚠️ firebase_options.dart es placeholder. Corre: flutterfire configure',
    );
    return;
  }
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}
