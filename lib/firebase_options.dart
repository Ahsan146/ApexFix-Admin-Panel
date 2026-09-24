import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAXDF1ycT8KWaF_BUJfArOTcct3Ll08BZQ',
    appId: '1:572335403894:web:a434d210ebd3cad805c057',
    messagingSenderId: '572335403894',
    projectId: 'apexfix',
    authDomain: 'apexfix.firebaseapp.com',
    storageBucket: 'apexfix.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDwt_w8PuV7aPijHP_oh-FLyC-aeRiD6M8',
    appId: '1:572335403894:android:2f3b116e053f664705c057',
    messagingSenderId: '572335403894',
    projectId: 'apexfix',
    storageBucket: 'apexfix.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDwt_w8PuV7aPijHP_oh-FLyC-aeRiD6M8',
    appId: '1:572335403894:ios:apexfixcustomerapp',
    messagingSenderId: '572335403894',
    projectId: 'apexfix',
    storageBucket: 'apexfix.firebasestorage.app',
    iosBundleId: 'com.example.apexfixFlutter',
  );
}
