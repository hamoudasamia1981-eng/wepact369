import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../config/app_localizations.dart';
import '../services/partner_service.dart';
import '../theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _partnerService = PartnerService();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), _navigate);
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    final user = await FirebaseAuth.instance.authStateChanges().first;
    if (!mounted) return;

    if (user != null) {
      await _partnerService.checkAndShowPendingInvitation(
        context,
        user.uid,
        user.email ?? '',
      );
      if (!mounted) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!mounted) return;

      final partnerId = doc.data()?['partnerId'];
      Navigator.pushReplacementNamed(
        context,
        partnerId != null ? '/home' : '/invite-partner',
      );
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 130,
              height: 130,
            ),
            const SizedBox(height: 20),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppColors.secondary, AppColors.primary],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ).createShader(bounds),
              child: const Text(
                'WePact',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Builder(builder: (ctx) {
              final l = AppLocalizations.of(ctx);
              return Text(
                l.splashTagline,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
