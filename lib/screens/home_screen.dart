import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class HomeScreen extends StatefulWidget {
  final ValueChanged<int>? onTabChange;

  const HomeScreen({super.key, this.onTabChange});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _currentUser = FirebaseAuth.instance.currentUser;

  String? _firstName;
  String? _partnerFirstName;
  String? _partnerPhotoURL;
  String? _partnerId;
  String? _coupleId;
  String _currency = '£';

  double _myTotal = 0;
  double _partnerTotal = 0;

  int _proposedCount = 0;
  int _acceptedCount = 0;
  int _pendingForMeCount = 0;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_currentUser == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser.uid)
          .get();
      if (!mounted) return;

      final userData = userDoc.data();
      final partnerId = userData?['partnerId'] as String?;
      final firstName = userData?['firstName'] as String? ?? '';
      final currency = userData?['currency'] as String? ?? '£';

      setState(() {
        _firstName = firstName;
        _partnerId = partnerId;
        _currency = currency;
      });

      if (partnerId == null) {
        setState(() => _isLoading = false);
        return;
      }

      final uid = _currentUser.uid;
      final ids = [uid, partnerId]..sort();
      final coupleId = ids.join('_');

      final now = DateTime.now();
      final firstOfMonthTs =
          Timestamp.fromDate(DateTime(now.year, now.month, 1));

      final results = await Future.wait<dynamic>([
        FirebaseFirestore.instance.collection('users').doc(partnerId).get(),
        FirebaseFirestore.instance
            .collection('expenses')
            .where('coupleId', isEqualTo: coupleId)
            .where('date', isGreaterThanOrEqualTo: firstOfMonthTs)
            .get(),
        FirebaseFirestore.instance
            .collection('pacts')
            .where('coupleId', isEqualTo: coupleId)
            .where('status', isEqualTo: 'pending')
            .where('createdBy', isEqualTo: uid)
            .get(),
        FirebaseFirestore.instance
            .collection('pacts')
            .where('coupleId', isEqualTo: coupleId)
            .where('status', isEqualTo: 'accepted')
            .get(),
        FirebaseFirestore.instance
            .collection('pacts')
            .where('coupleId', isEqualTo: coupleId)
            .where('status', isEqualTo: 'pending')
            .where('createdBy', isEqualTo: partnerId)
            .get(),
      ]);

      if (!mounted) return;

      final partnerData =
          (results[0] as DocumentSnapshot<Map<String, dynamic>>).data();
      final expenseDocs =
          (results[1] as QuerySnapshot<Map<String, dynamic>>).docs;
      final proposedDocs =
          (results[2] as QuerySnapshot<Map<String, dynamic>>).docs;
      final acceptedDocs =
          (results[3] as QuerySnapshot<Map<String, dynamic>>).docs;
      final pendingForMeDocs =
          (results[4] as QuerySnapshot<Map<String, dynamic>>).docs;

      double myTotal = 0;
      double partnerTotal = 0;
      for (final doc in expenseDocs) {
        final amount = (doc.data()['amount'] as num?)?.toDouble() ?? 0;
        if (doc.data()['createdBy'] == uid) {
          myTotal += amount;
        } else {
          partnerTotal += amount;
        }
      }

      setState(() {
        _partnerFirstName =
            partnerData?['firstName'] as String? ?? 'Partenaire';
        _partnerPhotoURL = partnerData?['photoURL'] as String?;
        _coupleId = coupleId;
        _myTotal = myTotal;
        _partnerTotal = partnerTotal;
        _proposedCount = proposedDocs.length;
        _acceptedCount = acceptedDocs.length;
        _pendingForMeCount = pendingForMeDocs.length;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bonjour,';
    if (hour < 18) return 'Bon après-midi,';
    return 'Bonsoir,';
  }

  String get _currentMonthFr {
    const months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
    ];
    return months[DateTime.now().month - 1];
  }

  Widget _buildStatusBadge(String status) {
    switch (status) {
      case 'accepted':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFD1FAE5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check, size: 12, color: AppColors.success),
              SizedBox(width: 4),
              Text(
                'Accepté',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      case 'declined':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.close, size: 12, color: AppColors.error),
              SizedBox(width: 4),
              Text(
                'Refusé',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      default:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.orangeLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.access_time, size: 12, color: AppColors.secondary),
              SizedBox(width: 4),
              Text(
                'En attente',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildStatCard({
    required Color iconBgColor,
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (_partnerId == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Connectez-vous à votre partenaire pour commencer',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: AppColors.textGrey),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/invite-partner'),
                  child: const Text('Inviter mon partenaire'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final totalAmount = _myTotal + _partnerTotal;
    final myProgress =
        totalAmount > 0 ? (_myTotal / totalAmount).clamp(0.0, 1.0) : 0.0;
    final partnerProgress =
        totalAmount > 0 ? (_partnerTotal / totalAmount).clamp(0.0, 1.0) : 0.0;
    final myInitial =
        (_firstName?.isNotEmpty == true) ? _firstName![0].toUpperCase() : '?';
    final partnerInitial = (_partnerFirstName?.isNotEmpty == true)
        ? _partnerFirstName![0].toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── HEADER ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greeting,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textGrey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  _firstName ?? '',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Image.asset(
                                'assets/images/logo.png',
                                width: 22,
                                height: 22,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  _partnerFirstName ?? '',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_pendingForMeCount > 0) ...[
                            const SizedBox(height: 4),
                            const Text(
                              '❤️ Une décision attend votre réponse',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.cardShadow,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.notifications_outlined,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),

              // ── ORANGE BANNER ────────────────────────────────────────
              if (_pendingForMeCount > 0)
                GestureDetector(
                  onTap: () => widget.onTabChange?.call(2),
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.orangeLight,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: AppColors.secondary, width: 1),
                    ),
                    child: Row(
                      children: [
                        const Text('⏳', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$_pendingForMeCount pacte(s) en attente de votre réponse',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: AppColors.secondary,
                        ),
                      ],
                    ),
                  ),
                ),

              // ── PURPLE EXPENSES CARD ─────────────────────────────────
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(76),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // My column
                    Column(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white.withAlpha(76),
                          child: Text(
                            myInitial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _firstName ?? '',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.white),
                        ),
                        Text(
                          '$_currency${_myTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 80,
                          child: LinearProgressIndicator(
                            value: myProgress,
                            backgroundColor: Colors.white.withAlpha(76),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                    // Center total
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                                fontSize: 12, color: Colors.white70),
                          ),
                          Text(
                            '$_currency${totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 22,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Partner column
                    Column(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.secondary,
                          backgroundImage: _partnerPhotoURL != null
                              ? NetworkImage(_partnerPhotoURL!)
                              : null,
                          child: _partnerPhotoURL == null
                              ? Text(
                                  partnerInitial,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _partnerFirstName ?? '',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.secondary),
                        ),
                        Text(
                          '$_currency${_partnerTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            color: AppColors.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 80,
                          child: LinearProgressIndicator(
                            value: partnerProgress,
                            backgroundColor: Colors.white.withAlpha(76),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.secondary),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── 3 MINI STATS CARDS ───────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        iconBgColor: AppColors.orangeLight,
                        icon: Icons.send,
                        iconColor: AppColors.secondary,
                        value: _proposedCount.toString(),
                        label: 'Pacts proposés',
                      ),
                    ),
                    Expanded(
                      child: _buildStatCard(
                        iconBgColor: const Color(0xFFD1FAE5),
                        icon: Icons.check_circle,
                        iconColor: AppColors.success,
                        value: _acceptedCount.toString(),
                        label: 'Pacts acceptés',
                      ),
                    ),
                    Expanded(
                      child: _buildStatCard(
                        iconBgColor: AppColors.purpleLight,
                        icon: Icons.calendar_today,
                        iconColor: AppColors.primary,
                        value: _currentMonthFr,
                        label: 'Ce mois-ci',
                      ),
                    ),
                  ],
                ),
              ),

              // ── RECENT ACTIVITY ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Activité récente',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => widget.onTabChange?.call(2),
                          child: const Text(
                            'Voir tout',
                            style: TextStyle(color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_coupleId != null)
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('pacts')
                            .where('coupleId', isEqualTo: _coupleId)
                            .orderBy('createdAt', descending: true)
                            .limit(5)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(
                                    color: AppColors.primary),
                              ),
                            );
                          }
                          final docs = snapshot.data?.docs ?? [];
                          if (docs.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Text(
                                  'Aucune activité pour le moment',
                                  style:
                                      TextStyle(color: AppColors.textGrey),
                                ),
                              ),
                            );
                          }
                          return Column(
                            children: docs.map((doc) {
                              final data = doc.data();
                              final type =
                                  data['type'] as String? ?? 'task';
                              final category =
                                  data['category'] as String? ?? '📋';
                              final title =
                                  data['title'] as String? ?? 'Sans titre';
                              final status =
                                  data['status'] as String? ?? 'pending';
                              final createdBy =
                                  data['createdBy'] as String? ?? '';
                              final proposerName =
                                  createdBy == _currentUser?.uid
                                      ? 'Vous'
                                      : (_partnerFirstName ?? 'Partenaire');
                              final cardBgColor = type == 'initiative'
                                  ? AppColors.orangeLight
                                  : AppColors.purpleLight;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: AppColors.cardShadow,
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: cardBgColor,
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Text(
                                          category,
                                          style: const TextStyle(
                                              fontSize: 20),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textDark,
                                            ),
                                          ),
                                          Text(
                                            'Proposé par $proposerName',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    _buildStatusBadge(status),
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
