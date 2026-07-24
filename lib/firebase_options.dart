// Placeholder hasta que corras FlutterFire CLI:
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// [isConfigured] es false mientras haya claves YOUR_* / ceros.
// main.dart solo inicializa Firebase si isConfigured && !demoMode.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        return android;
    }
  }

  /// `false` si aún no se corrió `flutterfire configure`.
  static bool get isConfigured {
    final o = currentPlatform;
    if (o.apiKey.isEmpty ||
        o.apiKey.startsWith('YOUR_') ||
        o.appId.startsWith('YOUR_') ||
        o.appId.contains('000000000000') ||
        o.messagingSenderId == '000000000000' ||
        o.messagingSenderId.startsWith('YOUR_')) {
      return false;
    }
    return true;
  }

  // ⚠️ Reemplaza con los valores de tu proyecto Firebase (flutterfire configure).
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'picaflorapp',
    authDomain: 'picaflorapp.firebaseapp.com',
    storageBucket: 'picaflorapp.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'picaflorapp',
    storageBucket: 'picaflorapp.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'picaflorapp',
    storageBucket: 'picaflorapp.appspot.com',
    iosBundleId: 'com.picaflor.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'picaflorapp',
    storageBucket: 'picaflorapp.appspot.com',
    iosBundleId: 'com.picaflor.app',
  );
}
