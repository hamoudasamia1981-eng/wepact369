import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _monthsFr = [
    'jan', 'fév', 'mar', 'avr', 'mai', 'juin',
    'juil', 'août', 'sep', 'oct', 'nov', 'déc',
  ];

  String? _firstName, _photoURL, _email;
  String? _partnerFirstName, _partnerLastName, _partnerPhotoURL;
  Timestamp? _partnerSince;
  int _proposedCount = 0, _acceptedCount = 0, _totalCount = 0;
  bool _darkMode = false;
  String _language = 'fr';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _darkMode = prefs.getBool('darkMode') ?? false;
      _language = prefs.getString('language') ?? 'fr';
    });
  }

  Future<void> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users').doc(user.uid).get();
      if (!mounted) return;
      final data = userDoc.data();
      final partnerId = data?['partnerId'] as String?;
      setState(() {
        _firstName = data?['firstName'] as String?;
        _email = user.email;
        _photoURL = data?['photoURL'] as String?;
        _partnerSince = data?['partnerSince'] as Timestamp?;
      });
      if (partnerId == null) {
        setState(() => _isLoading = false);
        return;
      }
      final uid = user.uid;
      final ids = [uid, partnerId]..sort();
      final coupleId = ids.join('_');
      // Single-field query only — avoids composite index requirements.
      final results = await Future.wait<dynamic>([
        FirebaseFirestore.instance.collection('users').doc(partnerId).get(),
        FirebaseFirestore.instance
            .collection('pacts')
            .where('coupleId', isEqualTo: coupleId)
            .get(),
      ]);
      if (!mounted) return;
      final pd = (results[0] as DocumentSnapshot<Map<String, dynamic>>).data();
      final allPacts = (results[1] as QuerySnapshot<Map<String, dynamic>>).docs;
      setState(() {
        _partnerFirstName = pd?['firstName'] as String?;
        _partnerLastName = pd?['lastName'] as String?;
        _partnerPhotoURL = pd?['photoURL'] as String?;
        _proposedCount = allPacts.where((d) => d['createdBy'] == uid).length;
        _acceptedCount =
            allPacts.where((d) => d['status'] == 'accepted').length;
        _totalCount = allPacts.length;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', value);
    if (mounted) setState(() => _darkMode = value);
  }

  Future<void> _toggleLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final next = _language == 'fr' ? 'en' : 'fr';
    await prefs.setString('language', next);
    if (mounted) setState(() => _language = next);
  }

  String _formatDate(Timestamp ts) {
    final d = ts.toDate();
    return '${d.day} ${_monthsFr[d.month - 1]} ${d.year}';
  }

  String get _displayName => _firstName ?? 'Mon profil';
  String get _partnerFullName =>
      [_partnerFirstName, _partnerLastName].whereType<String>().join(' ');
  String get _partnerInitial =>
      (_partnerFirstName?.isNotEmpty == true) ? _partnerFirstName![0].toUpperCase() : '?';
  String get _myInitial =>
      (_firstName?.isNotEmpty == true) ? _firstName![0].toUpperCase() : '?';

  Future<void> _signOut() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler',
                  style: TextStyle(color: AppColors.textGrey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await AuthService().signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── PURPLE GRADIENT HEADER ────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                  top: 60, left: 20, right: 20, bottom: 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  // Language toggle
                  Row(
                    children: [
                      const Spacer(),
                      GestureDetector(
                        onTap: _toggleLanguage,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white54),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _language == 'fr' ? '🇫🇷' : '🇬🇧',
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _language == 'fr' ? 'FR' : 'EN',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Avatar
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: AppColors.secondary,
                        backgroundImage: _photoURL != null
                            ? NetworkImage(_photoURL!)
                            : null,
                        child: _photoURL == null
                            ? Text(_myInitial,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 28))
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: const [
                              BoxShadow(
                                  color: AppColors.cardShadow,
                                  blurRadius: 4)
                            ],
                          ),
                          child: const Icon(Icons.camera_alt,
                              color: AppColors.primary, size: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(_displayName,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(_email ?? '',
                      style: const TextStyle(
                          fontSize: 14, color: Colors.white70)),
                  if (_partnerSince != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '❤️ Ensemble depuis le ${_formatDate(_partnerSince!)}',
                      style: const TextStyle(
                          fontSize: 13, color: Colors.white60),
                    ),
                  ],
                  const SizedBox(height: 20),
                  // Stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStat('$_proposedCount', 'Proposés'),
                      Container(width: 1, height: 30,
                          color: Colors.white30),
                      _buildStat('$_acceptedCount', 'Acceptés'),
                      Container(width: 1, height: 30,
                          color: Colors.white30),
                      _buildStat('$_totalCount', 'Total'),
                    ],
                  ),
                ],
              ),
            ),

            // ── PARTENAIRE ────────────────────────────────────────────
            if (_partnerFirstName != null) ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Text('PARTENAIRE',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textGrey,
                        letterSpacing: 1.2)),
              ),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: AppColors.white,
                elevation: 1,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.secondary,
                    backgroundImage: _partnerPhotoURL != null
                        ? NetworkImage(_partnerPhotoURL!)
                        : null,
                    child: _partnerPhotoURL == null
                        ? Text(_partnerInitial,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold))
                        : null,
                  ),
                  title: Text(
                    _partnerFullName.isNotEmpty
                        ? _partnerFullName
                        : (_partnerFirstName ?? ''),
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                  subtitle: Text(
                    '❤️ Connecté avec ${_firstName ?? ''}',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textGrey),
                  ),
                ),
              ),
            ],

            // ── PARAMÈTRES ────────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text('PARAMÈTRES',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textGrey,
                      letterSpacing: 1.2)),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: AppColors.white,
              elevation: 1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  ListTile(
                    leading: _iconBox(
                        AppColors.purpleLight, Icons.settings, AppColors.primary),
                    title: const Text('Paramètres',
                        style: TextStyle(
                            fontSize: 15, color: AppColors.textDark)),
                    trailing: const Icon(Icons.chevron_right,
                        color: AppColors.textGrey),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SettingsScreen())),
                  ),
                  const Divider(height: 1, indent: 16),
                  ListTile(
                    leading: _iconBox(
                        const Color(0xFFFEF3C7),
                        Icons.dark_mode,
                        Color(0xFFF59E0B)),
                    title: const Text('Mode sombre',
                        style: TextStyle(
                            fontSize: 15, color: AppColors.textDark)),
                    trailing: Switch(
                      value: _darkMode,
                      onChanged: _toggleDarkMode,
                      activeThumbColor: AppColors.primary,
                    ),
                  ),
                  const Divider(height: 1, indent: 16),
                  ListTile(
                    leading: _iconBox(AppColors.purpleLight,
                        Icons.notifications_outlined, AppColors.primary),
                    title: const Text('Notifications',
                        style: TextStyle(
                            fontSize: 15, color: AppColors.textDark)),
                    trailing: const Icon(Icons.chevron_right,
                        color: AppColors.textGrey),
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Bientôt disponible'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── SIGN OUT ──────────────────────────────────────────────
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withAlpha(60)),
              ),
              child: ListTile(
                leading: _iconBox(
                    const Color(0xFFFFEBEE), Icons.logout, AppColors.error),
                title: const Text('Se déconnecter',
                    style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                onTap: _signOut,
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              'WePact v1.0.0',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textGrey),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String value, String label) => Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.white70)),
        ],
      );

  Widget _iconBox(Color bg, IconData icon, Color iconColor) => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: iconColor, size: 20),
      );
}
