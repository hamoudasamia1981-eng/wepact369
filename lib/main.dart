import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/invite_partner_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation.dart';
import 'screens/signup_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppAuthProvider(),
      child: const WePact369App(),
    ),
  );
}

class WePact369App extends StatelessWidget {
  const WePact369App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WePact',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignupScreen(),
        '/forgot-password': (_) => const ForgotPasswordScreen(),
        '/invite-partner': (_) => const InvitePartnerScreen(),
        '/home': (_) => const MainNavigation(),
      },
    );
  }
}
