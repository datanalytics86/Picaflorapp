import 'package:flutter_test/flutter_test.dart';
import 'package:picaflorapp/core/config/app_config.dart';
import 'package:picaflorapp/data/demo_store.dart';
import 'package:picaflorapp/services/auth_service.dart';

void main() {
  test('demo login: currentSession is set synchronously after signIn', () async {
    expect(AppConfig.demoMode, isTrue);

    final store = DemoStore.instance;
    await store.signOut();
    expect(store.session, isNull);

    final auth = AuthService(demoMode: true);
    expect(auth.currentSession, isNull);

    await auth.signInAsDemoGuest();

    // Lectura síncrona (como hace SessionNotifier.sync).
    expect(auth.currentSession, isNotNull);
    expect(auth.currentSession!.uid, AppConfig.demoUid);
    expect(auth.isSignedIn, isTrue);

    await auth.signOut();
    expect(auth.currentSession, isNull);
  });
}
