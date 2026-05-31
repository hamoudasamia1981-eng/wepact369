import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

enum AuthStatus { idle, loading, success, error }

class AppAuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();

  AuthStatus _status = AuthStatus.idle;
  String? _errorMessage;

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == AuthStatus.loading;
  User? get currentUser => _service.currentUser;
  Stream<User?> get authStateChanges => _service.authStateChanges;

  void clearError() {
    _status = AuthStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    _begin();
    try {
      await _service.signInWithEmail(email, password);
      _succeed();
      return true;
    } on FirebaseAuthException catch (e) {
      _fail(_message(e.code));
      return false;
    }
  }

  Future<bool> signUp(String email, String password, String name) async {
    _begin();
    try {
      await _service.signUpWithEmail(email, password);
      await _service.updateDisplayName(name);
      _succeed();
      return true;
    } on FirebaseAuthException catch (e) {
      _fail(_message(e.code));
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _begin();
    try {
      final result = await _service.signInWithGoogle();
      if (result == null) {
        _status = AuthStatus.idle;
        notifyListeners();
        return false;
      }
      _succeed();
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'popup-closed-by-user' ||
          e.code == 'cancelled-popup-request') {
        _status = AuthStatus.idle;
        notifyListeners();
        return false;
      }
      _fail(_message(e.code));
      return false;
    } catch (_) {
      _fail('Google sign in failed. Please try again.');
      return false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    _begin();
    try {
      await _service.sendPasswordResetEmail(email);
      _succeed();
      return true;
    } on FirebaseAuthException catch (e) {
      _fail(_message(e.code));
      return false;
    }
  }

  Future<void> signOut() async {
    await _service.signOut();
    _status = AuthStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }

  void _begin() {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();
  }

  void _succeed() {
    _status = AuthStatus.success;
    _errorMessage = null;
    notifyListeners();
  }

  void _fail(String message) {
    _status = AuthStatus.error;
    _errorMessage = message;
    notifyListeners();
  }

  String _message(String code) => switch (code) {
        'user-not-found' => 'No account found with this email.',
        'wrong-password' => 'Incorrect password.',
        'invalid-credential' => 'Invalid email or password.',
        'email-already-in-use' => 'An account already exists with this email.',
        'invalid-email' => 'Invalid email address.',
        'weak-password' => 'Password must be at least 6 characters.',
        'too-many-requests' => 'Too many attempts. Please try again later.',
        'network-request-failed' => 'Network error. Check your connection.',
        _ => 'Authentication failed. Please try again.',
      };
}
