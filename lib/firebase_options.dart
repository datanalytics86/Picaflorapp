// Archivo placeholder. Reemplázalo con el generado por FlutterFire CLI:
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// Mientras tanto, main.dart intenta inicializar Firebase y continúa
// en modo degradado si no hay configuración válida.

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

  // ⚠️ Reemplaza estos valores con los de tu proyecto Firebase.
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
