import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_localizations.dart';

class LanguageProvider extends ChangeNotifier {
  String _code;

  LanguageProvider(this._code);

  String get code => _code;
  AppLocalizations get l10n => AppLocalizations(_code);

  Future<void> setLanguage(String code) async {
    if (_code == code) return;
    _code = code;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', code);
  }
}
