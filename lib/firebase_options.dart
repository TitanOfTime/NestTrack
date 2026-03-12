import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      apiKey: 'AIzaSyCo8nJaoPIqs971kTDW_twLJL1kH9pv5WU',
      appId: '1:1021354177769:web:e00e6d2e727da5365e2c78',
      messagingSenderId: '1021354177769',
      projectId: 'nesttrack-935ef',
      storageBucket: 'nesttrack-935ef.firebasestorage.app',
    );
  }
}