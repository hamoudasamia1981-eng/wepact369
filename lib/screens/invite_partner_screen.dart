import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_localizations.dart';
import '../providers/language_provider.dart';
import '../services/partner_service.dart';
import '../theme/app_colors.dart';

Future<void> _signOutAndGoToLogin(BuildContext context) async {
  await FirebaseAuth.instance.signOut();
  if (context.mounted) {
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }
}

class InvitePartnerScreen extends StatefulWidget {
  const InvitePartnerScreen({super.key});

  @override
  State<InvitePartnerScreen> createState() => _InvitePartnerScreenState();
}

class _InvitePartnerScreenState extends State<InvitePartnerScreen> {
  final _partnerService = PartnerService();
  final _emailController = TextEditingController();
  final _db = FirebaseFirestore.instance;

  bool _invitationSent = false;
  bool _isLoading = false;
  bool _initializing = true;
  String? _invitedEmail;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSub;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _userSub?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _initializing = false);
      return;
    }

    // Detect existing pending invitation sent by this user
    final invQuery = await _db
        .collection('invitations')
        .where('fromUid', isEqualTo: user.uid)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (!mounted) return;

    if (invQuery.docs.isNotEmpty) {
      final toEmail = invQuery.docs.first.data()['toEmail'] as String?;
      setState(() {
        _invitationSent = true;
        _invitedEmail = toEmail;
        _initializing = false;
      });
    } else {
      setState(() => _initializing = false);
    }

    // Real-time listener: navigate to /home as soon as partnerId is set
    _userSub = _db
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      if ((snap.data()?['partnerId'] as String?) != null) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    });
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
      setState(() {
        _invitationSent = true;
        _invitedEmail = toEmail;
      });
      _showSnackBar(l.inviteSent, isError: false);
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
      _invitedEmail = null;
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
    context.watch<LanguageProvider>();

    if (_initializing) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: _invitationSent
                ? _buildPendingState(l)
                : _buildInviteForm(l),
          ),
        ),
      ),
    );
  }

  // ── Pending state (invitation sent, waiting for partner) ──────
  Widget _buildPendingState(AppLocalizations l) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(
          child: SizedBox(
            width: 72,
            height: 72,
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(
          l.invitePendingTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l.invitePendingSubtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: AppColors.textGrey),
        ),
        if (_invitedEmail != null) ...[
          const SizedBox(height: 20),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.purpleLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _invitedEmail!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
        const SizedBox(height: 32),
        TextButton.icon(
          onPressed: _isLoading ? null : _cancelInvitation,
          icon: const Icon(Icons.cancel_outlined, color: AppColors.error),
          label: Text(
            l.cancelInviteButton,
            style: const TextStyle(color: AppColors.error),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => _signOutAndGoToLogin(context),
          child: Text(
            l.signOutLabel,
            style: TextStyle(color: AppColors.textGrey.withAlpha(180)),
          ),
        ),
      ],
    );
  }

  // ── Invite form ───────────────────────────────────────────────
  Widget _buildInviteForm(AppLocalizations l) {
    return Column(
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
                    shape: BoxShape.circle,
                  ),
                ),
                Positioned(
                  left: 46,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
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
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l.inviteSubtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: AppColors.textGrey),
        ),
        const SizedBox(height: 40),
        Text(
          l.partnerEmailLabel,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _sendInvitation(),
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          cursorColor: AppColors.primary,
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
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.favorite_border,
                          color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        l.inviteButton,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        // "Passer pour l'instant" removed — partner connection is required.
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => _signOutAndGoToLogin(context),
          child: Text(
            l.signOutLabel,
            style: TextStyle(color: AppColors.textGrey.withAlpha(180)),
          ),
        ),
      ],
    );
  }
}
