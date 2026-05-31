import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_localizations.dart';
import '../providers/settings_provider.dart';
import '../theme/app_colors.dart';

class _ActivityItem {
  final String type; // 'pact' or 'expense'
  final String title;
  final String status;
  final String emoji;
  final bool isInitiative;
  final bool createdByMe;
  final String? expenseCurrency;
  final double? expenseAmount;
  final Timestamp? createdAt;

  const _ActivityItem({
    required this.type,
    required this.title,
    required this.status,
    required this.emoji,
    required this.isInitiative,
    required this.createdByMe,
    this.expenseCurrency,
    this.expenseAmount,
    this.createdAt,
  });
}

class HomeScreen extends StatefulWidget {
  final ValueChanged<int>? onTabChange;
  final void Function(int pactsTab)? onNavigateToPacts;
  final void Function(String filter)? onNavigateToExpenses;

  const HomeScreen({
    super.key,
    this.onTabChange,
    this.onNavigateToPacts,
    this.onNavigateToExpenses,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _categoryEmojis = <String, String>{
    'Alimentation': '🛒', 'Loyer': '🏠', 'Restaurant': '🍴',
    'Transport': '🚗', 'Enfants': '👶', 'Maison': '🛋️',
    'Loisirs': '🎭', 'Santé': '💊', 'Autre': '💳',
  };

  final _currentUser = FirebaseAuth.instance.currentUser;
  final _db = FirebaseFirestore.instance;

  String? _firstName;
  String? _partnerFirstName;
  String? _partnerPhotoURL;
  String? _partnerId;
  String _currency = '£';

  double _myTotal = 0;
  double _partnerTotal = 0;
  int _proposedCount = 0;
  int _acceptedCount = 0;
  int _pendingForMeCount = 0;

  bool _isLoading = true;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _pactsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _expensesSub;

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _allPacts = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _allExpenses = [];
  List<_ActivityItem> _recentActivity = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _pactsSub?.cancel();
    _expensesSub?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (_currentUser == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final userDoc =
          await _db.collection('users').doc(_currentUser.uid).get();
      if (!mounted) return;
      final userData = userDoc.data();
      final partnerId = userData?['partnerId'] as String?;
      final firstName = userData?['firstName'] as String? ?? '';
      final currency = userData?['currency'] as String? ?? '£';

      if (partnerId == null) {
        setState(() {
          _firstName = firstName;
          _partnerId = null;
          _currency = currency;
          _isLoading = false;
        });
        context.read<SettingsProvider>().syncCurrency(currency);
        return;
      }

      final partnerDoc =
          await _db.collection('users').doc(partnerId).get();
      if (!mounted) return;
      final uid = _currentUser.uid;
      final ids = [uid, partnerId]..sort();
      final coupleId = ids.join('_');

      setState(() {
        _firstName = firstName;
        _partnerId = partnerId;
        _currency = currency;
        _partnerFirstName =
            partnerDoc.data()?['firstName'] as String? ?? 'Partenaire';
        _partnerPhotoURL = partnerDoc.data()?['photoURL'] as String?;
        _isLoading = false;
      });
      context.read<SettingsProvider>().syncCurrency(currency);

      _pactsSub = _db
          .collection('pacts')
          .where('coupleId', isEqualTo: coupleId)
          .snapshots()
          .listen((snap) {
        if (!mounted) return;
        _allPacts = snap.docs;
        _recompute(uid, partnerId);
      });

      _expensesSub = _db
          .collection('expenses')
          .where('coupleId', isEqualTo: coupleId)
          .snapshots()
          .listen((snap) {
        if (!mounted) return;
        _allExpenses = snap.docs;
        _recompute(uid, partnerId);
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _recompute(String uid, String partnerId) {
    double myTotal = 0, partnerTotal = 0;
    for (final doc in _allExpenses) {
      final amount = (doc.data()['amount'] as num?)?.toDouble() ?? 0;
      if (doc.data()['createdBy'] == uid) {
        myTotal += amount;
      } else {
        partnerTotal += amount;
      }
    }

    final proposedCount = _allPacts
        .where((d) =>
            d.data()['status'] == 'pending' &&
            d.data()['createdBy'] == uid)
        .length;
    final acceptedCount =
        _allPacts.where((d) => d.data()['status'] == 'accepted').length;
    final pendingForMeCount = _allPacts
        .where((d) =>
            d.data()['status'] == 'pending' &&
            d.data()['createdBy'] == partnerId)
        .length;

    final items = <_ActivityItem>[];
    for (final doc in _allPacts) {
      final data = doc.data();
      items.add(_ActivityItem(
        type: 'pact',
        title: data['title'] as String? ?? '',
        status: data['status'] as String? ?? 'pending',
        emoji: data['category'] as String? ?? '📋',
        isInitiative: (data['type'] as String?) == 'initiative',
        createdByMe: (data['createdBy'] as String? ?? '') == uid,
        createdAt: data['createdAt'] as Timestamp?,
      ));
    }
    for (final doc in _allExpenses) {
      final data = doc.data();
      final cat = data['category'] as String? ?? 'Autre';
      final cur = data['currency'] as String? ?? _currency;
      final amount = (data['amount'] as num?)?.toDouble() ?? 0;
      items.add(_ActivityItem(
        type: 'expense',
        title: data['title'] as String? ?? '',
        status: 'expense',
        emoji: _categoryEmojis[cat] ?? '💳',
        isInitiative: false,
        createdByMe: (data['createdBy'] as String? ?? '') == uid,
        expenseCurrency: cur,
        expenseAmount: amount,
        createdAt: data['createdAt'] as Timestamp?,
      ));
    }
    items.sort((a, b) {
      final ta = a.createdAt?.millisecondsSinceEpoch ?? 0;
      final tb = b.createdAt?.millisecondsSinceEpoch ?? 0;
      return tb.compareTo(ta);
    });

    setState(() {
      _myTotal = myTotal;
      _partnerTotal = partnerTotal;
      _proposedCount = proposedCount;
      _acceptedCount = acceptedCount;
      _pendingForMeCount = pendingForMeCount;
      _recentActivity = items.take(5).toList();
    });
  }

  Widget _buildStatusBadge(String status, AppLocalizations l) {
    switch (status) {
      case 'accepted':
        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
              color: const Color(0xFFD1FAE5),
              borderRadius: BorderRadius.circular(20)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.check, size: 12, color: AppColors.success),
            const SizedBox(width: 4),
            Text(l.acceptedBadge,
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.success,
                    fontWeight: FontWeight.bold)),
          ]),
        );
      case 'declined':
        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(20)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.close, size: 12, color: AppColors.error),
            const SizedBox(width: 4),
            Text(l.declinedBadge,
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.error,
                    fontWeight: FontWeight.bold)),
          ]),
        );
      case 'expense':
        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
              color: AppColors.purpleLight,
              borderRadius: BorderRadius.circular(20)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.receipt_long,
                size: 12, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(l.expenseBadge,
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold)),
          ]),
        );
      default:
        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
              color: AppColors.orangeLight,
              borderRadius: BorderRadius.circular(20)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.access_time,
                size: 12, color: AppColors.secondary),
            const SizedBox(width: 4),
            Text(l.pendingBadge,
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.secondary,
                    fontWeight: FontWeight.bold)),
          ]),
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
              offset: Offset(0, 2))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: iconBgColor, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark)),
        ),
        Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
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
                Text(l.connectPartnerMsg,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 16, color: AppColors.textGrey)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/invite-partner'),
                  child: Text(l.invitePartnerButton),
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
    final partnerProgress = totalAmount > 0
        ? (_partnerTotal / totalAmount).clamp(0.0, 1.0)
        : 0.0;
    final myInitial = (_firstName?.isNotEmpty == true)
        ? _firstName![0].toUpperCase()
        : '?';
    final partnerInitial = (_partnerFirstName?.isNotEmpty == true)
        ? _partnerFirstName![0].toUpperCase()
        : '?';
    final currency = context.watch<SettingsProvider>().currency;
    final currentMonth =
        l.monthsFull[DateTime.now().month - 1];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── HEADER ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.greeting(DateTime.now().hour),
                              style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textGrey)),
                          const SizedBox(height: 4),
                          Text(
                            '${_firstName ?? ''} 💜 ${_partnerFirstName ?? ''}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark),
                          ),
                          if (_pendingForMeCount > 0) ...[
                            const SizedBox(height: 4),
                            Text(l.pendingResponseInline,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.primary)),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    LangToggleButton(dark: false),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                              color: AppColors.cardShadow,
                              blurRadius: 8,
                              offset: Offset(0, 2))
                        ],
                      ),
                      child: const Icon(Icons.notifications_outlined,
                          color: AppColors.primary, size: 22),
                    ),
                  ],
                ),
              ),

              // ── ORANGE BANNER ────────────────────────────────
              if (_pendingForMeCount > 0)
                GestureDetector(
                  onTap: () => widget.onTabChange?.call(2),
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.orangeLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.secondary, width: 1),
                    ),
                    child: Row(children: [
                      const Text('⏳', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l.pendingBannerText(_pendingForMeCount),
                          style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.secondary,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          color: AppColors.secondary),
                    ]),
                  ),
                ),

              // ── EXPENSES CARD ────────────────────────────────
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
                        offset: const Offset(0, 8))
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white.withAlpha(76),
                        child: Text(myInitial,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 4),
                      Text(_firstName ?? '',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.white)),
                      Text('$currency${_myTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
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
                    ]),
                    Expanded(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(l.totalLabel,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.white70)),
                            Text(
                                '$currency${totalAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontSize: 22,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ]),
                    ),
                    Column(children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.secondary,
                        backgroundImage: _partnerPhotoURL != null
                            ? NetworkImage(_partnerPhotoURL!)
                            : null,
                        child: _partnerPhotoURL == null
                            ? Text(partnerInitial,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold))
                            : null,
                      ),
                      const SizedBox(height: 4),
                      Text(_partnerFirstName ?? '',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.secondary)),
                      Text(
                          '$currency${_partnerTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 18,
                              color: AppColors.secondary,
                              fontWeight: FontWeight.bold)),
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
                    ]),
                  ],
                ),
              ),

              // ── STAT CARDS ───────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => widget.onNavigateToPacts?.call(1),
                      child: _buildStatCard(
                        iconBgColor: AppColors.orangeLight,
                        icon: Icons.send,
                        iconColor: AppColors.secondary,
                        value: _proposedCount.toString(),
                        label: l.proposedPacts,
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => widget.onNavigateToPacts?.call(0),
                      child: _buildStatCard(
                        iconBgColor: const Color(0xFFD1FAE5),
                        icon: Icons.check_circle,
                        iconColor: AppColors.success,
                        value: _acceptedCount.toString(),
                        label: l.acceptedPacts,
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          widget.onNavigateToExpenses?.call('Mois'),
                      child: _buildStatCard(
                        iconBgColor: AppColors.purpleLight,
                        icon: Icons.calendar_today,
                        iconColor: AppColors.primary,
                        value: currentMonth,
                        label: l.thisMonth,
                      ),
                    ),
                  ),
                ]),
              ),

              // ── RECENT ACTIVITY ──────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(l.recentActivity,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark)),
                      const Spacer(),
                      TextButton(
                        onPressed: () => widget.onTabChange?.call(2),
                        child: Text(l.seeAll,
                            style: const TextStyle(
                                color: AppColors.primary)),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    if (_recentActivity.isEmpty)
                      Center(
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: 24),
                          child: Text(l.noActivity,
                              style: const TextStyle(
                                  color: AppColors.textGrey)),
                        ),
                      )
                    else
                      ...(_recentActivity.map((item) {
                        final cardBgColor = item.isInitiative
                            ? AppColors.orangeLight
                            : AppColors.purpleLight;
                        final subtitle = item.type == 'pact'
                            ? l.proposedBy(item.createdByMe
                                ? l.youLabel
                                : (_partnerFirstName ?? l.partnerLabel))
                            : '${item.createdByMe ? (_firstName ?? '') : (_partnerFirstName ?? '')} • ${item.expenseCurrency ?? currency}${item.expenseAmount?.toStringAsFixed(2) ?? ''}';
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
                                  offset: Offset(0, 2))
                            ],
                          ),
                          child: Row(children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                  color: cardBgColor,
                                  borderRadius:
                                      BorderRadius.circular(10)),
                              child: Center(
                                  child: Text(item.emoji,
                                      style: const TextStyle(
                                          fontSize: 20))),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(item.title,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textDark)),
                                  Text(subtitle,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.primary)),
                                ],
                              ),
                            ),
                            _buildStatusBadge(item.status, l),
                          ]),
                        );
                      })),
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
