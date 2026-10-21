import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static const apiKey = String.fromEnvironment('MILLION_FIREBASE_API_KEY');
  static const projectId = String.fromEnvironment('MILLION_FIREBASE_PROJECT_ID');
  static const messagingSenderId = String.fromEnvironment('MILLION_FIREBASE_SENDER_ID');

  static const webAppId = String.fromEnvironment('MILLION_FIREBASE_WEB_APP_ID');
  static const webAuthDomain = String.fromEnvironment('MILLION_FIREBASE_AUTH_DOMAIN');
  static const androidAppId = String.fromEnvironment('MILLION_FIREBASE_ANDROID_APP_ID');
  static const iosAppId = String.fromEnvironment('MILLION_FIREBASE_IOS_APP_ID');
  static const iosBundleId = String.fromEnvironment('MILLION_IOS_BUNDLE_ID');

  static bool get isConfigured {
    if (apiKey.isEmpty || projectId.isEmpty || messagingSenderId.isEmpty) return false;
    if (kIsWeb) return webAppId.isNotEmpty && webAuthDomain.isNotEmpty;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => androidAppId.isNotEmpty,
      TargetPlatform.iOS => iosAppId.isNotEmpty && iosBundleId.isNotEmpty,
      _ => false,
    };
  }

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return const FirebaseOptions(
        apiKey: apiKey,
        appId: webAppId,
        messagingSenderId: messagingSenderId,
        projectId: projectId,
        authDomain: webAuthDomain,
      );
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => const FirebaseOptions(
          apiKey: apiKey,
          appId: androidAppId,
          messagingSenderId: messagingSenderId,
          projectId: projectId,
        ),
      TargetPlatform.iOS => FirebaseOptions(
          apiKey: apiKey,
          appId: iosAppId,
          messagingSenderId: messagingSenderId,
          projectId: projectId,
          iosBundleId: iosBundleId,
        ),
      _ => throw UnsupportedError('MILLION Firebase is configured for web, Android, and iOS only.'),
    };
  }
}
