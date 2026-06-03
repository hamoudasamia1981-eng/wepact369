import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/language_provider.dart';
import 'providers/settings_provider.dart';
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
  if (kIsWeb) {
    try {
      debugPrint('[DEBUG] main: calling getRedirectResult()');
      final result = await FirebaseAuth.instance.getRedirectResult();
      debugPrint('[DEBUG] main: getRedirectResult() user=${result.user?.uid ?? 'null'} email=${result.user?.email ?? 'null'}');
    } catch (e) {
      debugPrint('[DEBUG] main: getRedirectResult() threw: $e');
    }
    debugPrint('[DEBUG] main: currentUser after getRedirectResult = ${FirebaseAuth.instance.currentUser?.uid ?? 'null'} / ${FirebaseAuth.instance.currentUser?.email ?? 'null'}');
  }
  final prefs = await SharedPreferences.getInstance();
  final savedLang = prefs.getString('language') ?? 'fr';
  final savedDark = prefs.getBool('darkMode') ?? false;
  final savedCurrency = prefs.getString('currency') ?? '£';
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppAuthProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider(savedLang)),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(
            isDark: savedDark,
            currency: savedCurrency,
          ),
        ),
      ],
      child: const WePact369App(),
    ),
  );
}

class WePact369App extends StatelessWidget {
  const WePact369App({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<SettingsProvider>().themeMode;
    return MaterialApp(
      title: 'WePact',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
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
