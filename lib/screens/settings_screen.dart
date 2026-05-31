import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_constants.dart';
import '../config/app_localizations.dart';
import '../providers/language_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  bool _isLoading = true;
  bool _savingName = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!mounted) return;
      final data = doc.data();
      final currency =
          data?['currency'] as String? ?? AppConstants.defaultCurrency;
      _firstNameController.text = data?['firstName'] as String? ?? '';
      _lastNameController.text = data?['lastName'] as String? ?? '';
      // Sync loaded currency to provider so all screens update
      if (mounted) {
        context.read<SettingsProvider>().syncCurrency(currency);
      }
      setState(() => _isLoading = false);
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveName() async {
    final l = context.read<LanguageProvider>().l10n;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _savingName = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l.nameUpdated),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.read<LanguageProvider>().l10n.saveError),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _savingName = false);
    }
  }

  Future<void> _setLanguage(String lang) async {
    await context.read<LanguageProvider>().setLanguage(lang);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final langCode = context.watch<LanguageProvider>().code;
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: const BackButton(color: AppColors.textDark),
        title: Text(l.settingsTitle,
            style: const TextStyle(
                color: AppColors.textDark, fontWeight: FontWeight.w600)),
        actions: const [
          LangToggleButton(dark: false),
          SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── NOM ──────────────────────────────────────
                  Text(l.nameSection,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textGrey,
                          letterSpacing: 1.2)),
                  const SizedBox(height: 12),
                  _LabeledField(
                    label: l.firstNameLabel,
                    controller: _firstNameController,
                  ),
                  const SizedBox(height: 12),
                  _LabeledField(
                    label: l.lastNameLabel,
                    controller: _lastNameController,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _savingName ? null : _saveName,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        minimumSize: const Size(0, 48),
                      ),
                      child: _savingName
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Text(l.saveChanges),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── DEVISE ───────────────────────────────────
                  Text(l.currencyLabel,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AppConstants.currencies.map((c) {
                      final sel = settings.currency == c;
                      return GestureDetector(
                        onTap: () =>
                            context.read<SettingsProvider>().setCurrency(c),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color:
                                sel ? AppColors.primary : AppColors.white,
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

                  // ── MODE SOMBRE ──────────────────────────────
                  Text(l.darkModeSection,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textGrey,
                          letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                            color: AppColors.cardShadow,
                            blurRadius: 4,
                            offset: Offset(0, 2))
                      ],
                    ),
                    child: SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      title: Text(l.darkModeLabel,
                          style: const TextStyle(
                              fontSize: 15, color: AppColors.textDark)),
                      value: settings.isDark,
                      onChanged: (v) =>
                          context.read<SettingsProvider>().setDarkMode(v),
                      activeThumbColor: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── LANGUE ───────────────────────────────────
                  Text(l.languageLabel,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: _buildLangCard(
                              'fr', '🇫🇷', 'Français', langCode)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _buildLangCard(
                              'en', '🇬🇧', 'English', langCode)),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildLangCard(
      String code, String flag, String label, String langCode) {
    final sel = langCode == code;
    return GestureDetector(
      onTap: () => _setLanguage(code),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: sel ? AppColors.purpleLight : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: sel
                ? AppColors.primary
                : AppColors.textGrey.withAlpha(80),
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
                    color: sel ? AppColors.primary : AppColors.textGrey)),
          ],
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const _LabeledField({required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.person_outline, size: 20),
      ),
    );
  }
}
