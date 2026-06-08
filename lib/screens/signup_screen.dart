import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_localizations.dart';
import '../providers/language_provider.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  final _prenomController = TextEditingController();
  final _nomController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  String _gender = 'male';
  bool _termsAccepted = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _prenomController.dispose();
    _nomController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _submit() async {
    final l = context.read<LanguageProvider>().l10n;
    if (!_formKey.currentState!.validate()) return;
    if (!_termsAccepted) {
      _showError(l.acceptTermsError);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final cred = await _authService.signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
      final user = cred.user;
      if (user == null) throw Exception('no user');

      await _authService.updateDisplayName(
        '${_prenomController.text.trim()} ${_nomController.text.trim()}',
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'firstName': _prenomController.text.trim(),
        'lastName': _nomController.text.trim(),
        'email': _emailController.text.trim(),
        'gender': _gender,
        'currency': '£',
        'partnerId': null,
        'partnerEmail': null,
        'partnerSince': null,
        'createdAt': FieldValue.serverTimestamp(),
        'photoURL': null,
      });
      AnalyticsService.instance.logSignupCompleted(method: 'email');

      try {
        await FirebaseAuth.instance.currentUser?.sendEmailVerification();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
            'Account created successfully 💜\nPlease check your email and verify your account.'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 5),
        ));
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
            'Account created, but verification email could not be sent. Please try again later.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 5),
        ));
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/invite-partner');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showError(context.read<LanguageProvider>().l10n.authError(e.code));
    } catch (_) {
      if (!mounted) return;
      _showError(context.read<LanguageProvider>().l10n.signupError);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signUpWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final cred = await _authService.signInWithGoogle();
      if (!mounted || cred == null) return;
      final user = cred.user!;
      final docRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      final doc = await docRef.get();
      if (!doc.exists) {
        final parts = (user.displayName ?? '').split(' ');
        await docRef.set({
          'firstName': parts.isNotEmpty ? parts.first : '',
          'lastName': parts.length > 1 ? parts.skip(1).join(' ') : '',
          'email': user.email ?? '',
          'gender': '',
          'currency': '£',
          'partnerId': null,
          'partnerEmail': null,
          'partnerSince': null,
          'createdAt': FieldValue.serverTimestamp(),
          'photoURL': user.photoURL,
        });
        AnalyticsService.instance.logSignupCompleted(method: 'google');
      }
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/invite-partner');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showError(context.read<LanguageProvider>().l10n.authError(e.code));
    } catch (_) {
      if (!mounted) return;
      _showError(context.read<LanguageProvider>().l10n.googleCancelled);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _genderCard({
    required String value,
    required String emoji,
    required String label,
  }) {
    final isMale = value == 'male';
    final isSelected = _gender == value;
    final selectedBorderColor =
        isMale ? AppColors.primary : AppColors.secondary;
    final selectedBgColor =
        isMale ? AppColors.purpleLight : AppColors.orangeLight;
    final selectedTextColor =
        isMale ? AppColors.primary : AppColors.secondary;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gender = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? selectedBgColor : AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? selectedBorderColor
                  : AppColors.textGrey.withAlpha(76),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color:
                      isSelected ? selectedTextColor : AppColors.textGrey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: const BackButton(color: AppColors.textDark),
        title: Text(
          l.signupTitle,
          style: const TextStyle(
              color: AppColors.textDark, fontWeight: FontWeight.w600),
        ),
        actions: const [
          LangToggleButton(dark: false),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _prenomController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w500),
                  cursorColor: AppColors.primary,
                  decoration: InputDecoration(
                    labelText: l.firstNameLabel,
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? l.fieldRequired
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nomController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w500),
                  cursorColor: AppColors.primary,
                  decoration: InputDecoration(
                    labelText: l.lastNameLabel,
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? l.fieldRequired
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w500),
                  cursorColor: AppColors.primary,
                  decoration: InputDecoration(
                    labelText: l.emailLabel,
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return l.fieldRequired;
                    if (!v.contains('@')) return l.invalidEmail;
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Text(l.genderLabel,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _genderCard(
                        value: 'male', emoji: '👨', label: l.maleLabel),
                    const SizedBox(width: 12),
                    _genderCard(
                        value: 'female',
                        emoji: '👩',
                        label: l.femaleLabel),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w500),
                  cursorColor: AppColors.primary,
                  decoration: InputDecoration(
                    labelText: l.passwordLabel,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return l.fieldRequired;
                    if (v.length < 6) return l.passwordMin;
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmController,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w500),
                  cursorColor: AppColors.primary,
                  decoration: InputDecoration(
                    labelText: l.confirmPasswordLabel,
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(
                          () => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return l.fieldRequired;
                    if (v != _passwordController.text) {
                      return l.passwordsMismatch;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _termsAccepted,
                        activeColor: AppColors.primary,
                        onChanged: (v) =>
                            setState(() => _termsAccepted = v ?? false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textGrey),
                          children: [
                            TextSpan(text: l.acceptTermsPrefix),
                            TextSpan(
                              text: l.termsLink,
                              style: const TextStyle(
                                color: AppColors.primary,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            TextSpan(text: l.andThe),
                            TextSpan(
                              text: l.privacyLink,
                              style: const TextStyle(
                                color: AppColors.primary,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Text(l.createAccountButton),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(l.orContinueWith,
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textGrey.withAlpha(180))),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 56,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _signUpWithGoogle,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('G',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFEA4335))),
                        const SizedBox(width: 10),
                        Text(l.continueWithGoogle),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(l.alreadyAccount,
                        style:
                            const TextStyle(color: AppColors.textGrey)),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        l.signInLink,
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
