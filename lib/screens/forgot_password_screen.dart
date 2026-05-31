import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../theme/app_colors.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AppAuthProvider>();
    final success =
        await auth.forgotPassword(_emailController.text.trim());
    if (!mounted) return;
    if (success) {
      setState(() => _emailSent = true);
    } else if (auth.errorCode != null) {
      final l = context.read<LanguageProvider>().l10n;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l.authError(auth.errorCode!)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isLoading = context.watch<AppAuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: const BackButton(color: AppColors.textDark),
        title: Text(
          l.forgotPasswordTitle,
          style: const TextStyle(
              color: AppColors.textDark, fontWeight: FontWeight.w600),
        ),
        actions: const [LangToggleButton(dark: false), SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _emailSent
              ? _SuccessView(email: _emailController.text.trim())
              : _FormView(
                  formKey: _formKey,
                  emailController: _emailController,
                  isLoading: isLoading,
                  onSubmit: _sendReset,
                ),
        ),
      ),
    );
  }
}

class _FormView extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final bool isLoading;
  final VoidCallback onSubmit;

  const _FormView({
    required this.formKey,
    required this.emailController,
    required this.isLoading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          const Icon(Icons.lock_reset, size: 64, color: AppColors.primary),
          const SizedBox(height: 24),
          Text(
            l.forgotPasswordHeading,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l.forgotPasswordBody,
            style: const TextStyle(color: AppColors.textGrey, fontSize: 15),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => onSubmit(),
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
              if (v == null || v.trim().isEmpty) return l.enterEmail;
              if (!v.contains('@')) return l.invalidEmail;
              return null;
            },
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: isLoading ? null : onSubmit,
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Text(l.sendLink),
          ),
        ],
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  final String email;
  const _SuccessView({required this.email});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.mark_email_read_outlined,
            size: 72, color: AppColors.primary),
        const SizedBox(height: 24),
        Text(
          l.checkInbox,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          '${l.resetSentTo} $email',
          style: const TextStyle(color: AppColors.textGrey, fontSize: 15),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.backToLogin),
        ),
      ],
    );
  }
}
