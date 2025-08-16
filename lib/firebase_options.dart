// File: lib/firebase_options.dart
// GENERATED CODE - DO NOT MODIFY BY HAND

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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyEXAMPLE_KEY",
    authDomain: "your-project.firebaseapp.com",
    projectId: "your-project-id",
    storageBucket: "your-project.appspot.com",
    messagingSenderId: "1234567890",
    appId: "1:1234567890:web:abcdef123456",
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyEXAMPLE_KEY",
    appId: "1:1234567890:android:abcdef123456",
    messagingSenderId: "1234567890",
    projectId: "your-project-id",
    storageBucket: "your-project.appspot.com",
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: "AIzaSyEXAMPLE_KEY",
    appId: "1:1234567890:ios:abcdef123456",
    messagingSenderId: "1234567890",
    projectId: "your-project-id",
    storageBucket: "your-project.appspot.com",
    iosClientId: "1234567890-abc123.apps.googleusercontent.com",
    iosBundleId: "com.example.app",
  );
}
