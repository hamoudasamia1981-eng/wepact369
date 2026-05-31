import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

enum AuthStatus { idle, loading, success, error }

class AppAuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();

  AuthStatus _status = AuthStatus.idle;
  String? _errorMessage;
  String? _errorCode;

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  String? get errorCode => _errorCode;
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
      _fail('google-sign-in-failed');
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

  void _fail(String code) {
    _status = AuthStatus.error;
    _errorCode = code;
    _errorMessage = code;
    notifyListeners();
  }

  // errorCode is exposed so the UI can translate it via AppLocalizations.
  String _message(String code) => code;
}
