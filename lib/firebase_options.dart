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
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD0gl7sbK0ZiSQzLRXvRwVFbsHYc-kpzro',
    appId: '1:1052479560086:web:6a0c8f1c18782f185565b7',
    messagingSenderId: '1052479560086',
    projectId: 'srsapp-38f24',
    authDomain: 'srsapp-38f24.firebaseapp.com',
    storageBucket: 'srsapp-38f24.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD0gl7sbK0ZiSQzLRXvRwVFbsHYc-kpzro',
    appId: '1:1052479560086:android:6a0c8f1c18782f185565b7',
    messagingSenderId: '1052479560086',
    projectId: 'srsapp-38f24',
    storageBucket: 'srsapp-38f24.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD0gl7sbK0ZiSQzLRXvRwVFbsHYc-kpzro',
    appId: '1:1052479560086:ios:6a0c8f1c18782f185565b7',
    messagingSenderId: '1052479560086',
    projectId: 'srsapp-38f24',
    storageBucket: 'srsapp-38f24.firebasestorage.app',
    iosBundleId: 'com.shrfamily.shr',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyD0gl7sbK0ZiSQzLRXvRwVFbsHYc-kpzro',
    appId: '1:1052479560086:ios:6a0c8f1c18782f185565b7',
    messagingSenderId: '1052479560086',
    projectId: 'srsapp-38f24',
    storageBucket: 'srsapp-38f24.firebasestorage.app',
    iosBundleId: 'com.shrfamily.shr',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyD0gl7sbK0ZiSQzLRXvRwVFbsHYc-kpzro',
    appId: '1:1052479560086:web:6a0c8f1c18782f185565b7',
    messagingSenderId: '1052479560086',
    projectId: 'srsapp-38f24',
    authDomain: 'srsapp-38f24.firebaseapp.com',
    storageBucket: 'srsapp-38f24.firebasestorage.app',
  );
}
