// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Replace the placeholder values below with your Firebase project configuration.
///
/// To generate this file automatically, install the FlutterFire CLI and run:
///   dart pub global activate flutterfire_cli
///   flutterfire configure
///
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return ios;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return android;
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_WEB_API_KEY',
    authDomain: 'YOUR_PROJECT_ID.firebaseapp.com',
    projectId: 'edukasinfirebase',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    appId: 'YOUR_WEB_APP_ID',
    measurementId: 'YOUR_MEASUREMENT_ID',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCHWxz7oMooyzCVMv9p09YJ2gYAJ4JJZGI',
    appId: '1:821026531468:android:35c277a57f23dd6c4273a9',
    messagingSenderId: '821026531468',
    projectId: 'edukasinfirebase',
    storageBucket: 'edukasinfirebase.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'edukasinfirebase',
    storageBucket: 'edukasinfirebase.firebasestorage.app',
    iosBundleId: 'com.example.edukasin',
    iosClientId: 'YOUR_IOS_CLIENT_ID',
    androidClientId: 'YOUR_ANDROID_CLIENT_ID',
  );

  static const FirebaseOptions desktop = FirebaseOptions(
    apiKey: 'AIzaSyCHWxz7oMooyzCVMv9p09YJ2gYAJ4JJZGI',
    appId: '1:821026531468:android:35c277a57f23dd6c4273a9',
    messagingSenderId: '821026531468',
    projectId: 'edukasinfirebase',
    storageBucket: 'edukasinfirebase.firebasestorage.app',
  );
}
