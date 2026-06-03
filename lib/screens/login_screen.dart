import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_localizations.dart';
import '../providers/language_provider.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    debugPrint('[DEBUG] LoginScreen: mounted (currentUser=${FirebaseAuth.instance.currentUser?.uid ?? 'null'})');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _navigateAfterLogin(String uid) async {
    final docRef =
        FirebaseFirestore.instance.collection('users').doc(uid);
    final doc = await docRef.get();
    if (!mounted) return;

    if (!doc.exists) {
      final user = FirebaseAuth.instance.currentUser;
      final parts = (user?.displayName ?? '').split(' ');
      await docRef.set({
        'firstName': parts.isNotEmpty ? parts.first : '',
        'lastName': parts.length > 1 ? parts.skip(1).join(' ') : '',
        'email': user?.email ?? '',
        'gender': '',
        'currency': '£',
        'partnerId': null,
        'partnerEmail': null,
        'partnerSince': null,
        'createdAt': FieldValue.serverTimestamp(),
        'photoURL': user?.photoURL,
      });
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/invite-partner');
      return;
    }

    final partnerId = doc.data()?['partnerId'];
    Navigator.pushReplacementNamed(
      context,
      partnerId != null ? '/home' : '/invite-partner',
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _signIn() async {
    final l = context.read<LanguageProvider>().l10n;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      _showError(l.fillAllFields);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final cred = await _authService.signInWithEmail(email, password);
      if (!mounted) return;
      await _navigateAfterLogin(cred.user!.uid);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showError(context.read<LanguageProvider>().l10n.authError(e.code));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    debugPrint('[DEBUG] login: _signInWithGoogle() called');
    setState(() => _isLoading = true);
    try {
      final cred = await _authService.signInWithGoogle();
      debugPrint('[DEBUG] login: signInWithGoogle() returned cred=${cred?.user?.uid ?? 'null'}');
      if (!mounted) return;
      if (cred == null) return;
      await _navigateAfterLogin(cred.user!.uid);
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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),
                  Center(
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 80,
                      height: 80,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l.loginTitle,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l.loginSubtitle,
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.textGrey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  TextField(
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
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _signIn(),
                    style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w500),
                    cursorColor: AppColors.primary,
                    decoration: InputDecoration(
                      labelText: l.passwordLabel,
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(
                            context, '/forgot-password'),
                        child: Text(
                          l.forgotPasswordQ,
                          style: const TextStyle(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signIn,
                      child: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : Text(l.signInButton),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          l.orContinueWith,
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textGrey.withAlpha(180)),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 56,
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _signInWithGoogle,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'G',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFEA4335),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(l.continueWithGoogle),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(l.noAccountYet,
                          style:
                              const TextStyle(color: AppColors.textGrey)),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/signup'),
                        child: Text(
                          l.signUpLink,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Language toggle — top right
            const Positioned(
              top: 8,
              right: 16,
              child: LangToggleButton(dark: false),
            ),
          ],
        ),
      ),
    );
  }
}
