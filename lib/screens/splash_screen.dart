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
    // currentUser covers the Google redirect case where Firebase Auth has
    // already restored the session before authStateChanges fires.
    final syncUser = FirebaseAuth.instance.currentUser;
    debugPrint('[DEBUG] splash: currentUser (sync) = ${syncUser?.uid ?? 'null'} / ${syncUser?.email ?? 'null'}');

    final user = syncUser ??
        await FirebaseAuth.instance.authStateChanges().first;
    debugPrint('[DEBUG] splash: user after authStateChanges = ${user?.uid ?? 'null'} / ${user?.email ?? 'null'}');
    if (!mounted) return;

    if (user != null) {
      await _partnerService.checkAndShowPendingInvitation(
        context,
        user.uid,
        user.email ?? '',
      );
      if (!mounted) return;

      final docRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      debugPrint('[DEBUG] splash: fetching Firestore doc for uid=${user.uid}');
      final doc = await docRef.get();
      debugPrint('[DEBUG] splash: doc.exists=${doc.exists}');
      if (!mounted) return;

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
        debugPrint('[DEBUG] splash: created Firestore doc → navigating to /invite-partner');
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/invite-partner');
        return;
      }

      final partnerId = doc.data()?['partnerId'];
      final destination = partnerId != null ? '/home' : '/invite-partner';
      debugPrint('[DEBUG] splash: partnerId=$partnerId → navigating to $destination');
      Navigator.pushReplacementNamed(context, destination);
    } else {
      debugPrint('[DEBUG] splash: user is null → navigating to /login');
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
