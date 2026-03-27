import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Controller for the Settings screen.
class SettingsController {
  /// Signs the user out of Firebase and returns them to the Login screen.
  static Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, '/');
  }
}
