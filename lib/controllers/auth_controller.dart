import 'package:firebase_auth/firebase_auth.dart';

/// Handles all authentication-related business logic.
/// Returns `null` on success or a user-friendly error string on failure.
class AuthController {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Attempts to sign in with [email] and [password].
  ///
  /// Returns `null` if sign-in succeeds, or a descriptive error message
  /// string if it fails.
  static Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return null; // success
    } on FirebaseAuthException catch (e) {
      return _mapErrorCode(e.code);
    } catch (_) {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Maps Firebase Auth error codes to user-friendly messages.
  static String _mapErrorCode(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found for this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'invalid-credential':
        return 'Invalid credentials. Please check your email and password.';
      default:
        return 'Login failed. Please try again.';
    }
  }
}
