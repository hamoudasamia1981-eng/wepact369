import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_constants.dart';
import '../theme/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedCurrency = AppConstants.defaultCurrency;
  String _selectedLanguage = 'fr';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _selectedLanguage = prefs.getString('language') ?? 'fr');
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users').doc(user.uid).get();
      if (!mounted) return;
      setState(() {
        _selectedCurrency =
            doc.data()?['currency'] as String? ?? AppConstants.defaultCurrency;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _setCurrency(String currency) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _selectedCurrency = currency);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'currency': currency});
    } catch (_) {}
  }

  Future<void> _setLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
    if (mounted) setState(() => _selectedLanguage = lang);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: const BackButton(color: AppColors.textDark),
        title: const Text('Paramètres',
            style: TextStyle(
                color: AppColors.textDark, fontWeight: FontWeight.w600)),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // DEVISE
                  const Text('Devise',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AppConstants.currencies.map((c) {
                      final sel = _selectedCurrency == c;
                      return GestureDetector(
                        onTap: () => _setCurrency(c),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: sel ? AppColors.primary : AppColors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: sel
                                  ? Colors.transparent
                                  : AppColors.textGrey.withAlpha(100),
                            ),
                          ),
                          child: Text(
                            c,
                            style: TextStyle(
                              color: sel ? Colors.white : AppColors.textGrey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),

                  // LANGUE
                  const Text('Langue',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildLangCard('fr', '🇫🇷', 'Français')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildLangCard('en', '🇬🇧', 'English')),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildLangCard(String code, String flag, String label) {
    final sel = _selectedLanguage == code;
    return GestureDetector(
      onTap: () => _setLanguage(code),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: sel ? AppColors.purpleLight : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: sel ? AppColors.primary : AppColors.textGrey.withAlpha(80),
            width: sel ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(flag, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color:
                        sel ? AppColors.primary : AppColors.textGrey)),
          ],
        ),
      ),
    );
  }
}
