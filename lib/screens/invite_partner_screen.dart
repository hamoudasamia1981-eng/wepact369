import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../config/app_localizations.dart';
import '../providers/language_provider.dart';
import '../services/partner_service.dart';
import '../theme/app_colors.dart';
import 'package:provider/provider.dart';

class InvitePartnerScreen extends StatefulWidget {
  const InvitePartnerScreen({super.key});

  @override
  State<InvitePartnerScreen> createState() => _InvitePartnerScreenState();
}

class _InvitePartnerScreenState extends State<InvitePartnerScreen> {
  final _partnerService = PartnerService();
  final _emailController = TextEditingController();
  bool _invitationSent = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendInvitation() async {
    final l = context.read<LanguageProvider>().l10n;
    final toEmail = _emailController.text.trim();
    if (toEmail.isEmpty) {
      _showSnackBar(l.enterPartnerEmail, isError: true);
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _isLoading = true);
    final error = await _partnerService.sendInvitation(user.uid, toEmail);
    if (!mounted) return;
    if (error != null) {
      _showSnackBar(error, isError: true);
    } else {
      setState(() => _invitationSent = true);
      _showSnackBar(
          context.read<LanguageProvider>().l10n.inviteSent,
          isError: false);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _cancelInvitation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _isLoading = true);
    await _partnerService.cancelInvitation(user.uid);
    if (!mounted) return;
    setState(() {
      _invitationSent = false;
      _isLoading = false;
      _emailController.clear();
    });
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: SizedBox(
                    width: 110,
                    height: 64,
                    child: Stack(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                              color: AppColors.secondary,
                              shape: BoxShape.circle),
                        ),
                        Positioned(
                          left: 46,
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  l.inviteTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark),
                ),
                const SizedBox(height: 8),
                Text(
                  l.inviteSubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textGrey),
                ),
                const SizedBox(height: 40),
                Text(
                  l.partnerEmailLabel,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _sendInvitation(),
                  decoration: InputDecoration(
                    hintText: l.partnerEmailLabel,
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _sendInvitation,
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.favorite_border,
                                  color: Colors.white),
                              const SizedBox(width: 8),
                              Text(l.inviteButton,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_invitationSent)
                  TextButton(
                    onPressed: _isLoading ? null : _cancelInvitation,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cancel, color: Colors.red),
                        const SizedBox(width: 6),
                        Text(l.cancelInviteButton,
                            style:
                                const TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/home'),
                  child: Text(
                    l.skipForNow,
                    style: TextStyle(
                        color: AppColors.textGrey.withAlpha(180)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
