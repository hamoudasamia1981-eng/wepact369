import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  bool _isDark;
  String _currency;

  SettingsProvider({required bool isDark, required String currency})
      : _isDark = isDark, _currency = currency;

  bool get isDark => _isDark;
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;
  String get currency => _currency;

  Future<void> setDarkMode(bool value) async {
    if (_isDark == value) return;
    _isDark = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', value);
  }

  Future<void> setCurrency(String value) async {
    if (_currency == value) return;
    _currency = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', value);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update({'currency': value});
      } catch (_) {}
    }
  }

  /// Called by screens after loading currency from Firestore so the
  /// provider stays in sync without triggering a redundant Firestore write.
  void syncCurrency(String value) {
    if (_currency == value) return;
    _currency = value;
    notifyListeners();
  }
}
