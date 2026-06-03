import 'dart:async';
import '../utils/formatters.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_localizations.dart';
import '../providers/settings_provider.dart';
import '../theme/app_colors.dart';
import '../theme/theme_ext.dart';

class _ActivityItem {
  final String type; // 'pact', 'expense', or 'shopping'
  final String title;
  final String status;
  final String emoji;
  final bool isInitiative;
  final bool createdByMe;
  final String? expenseCurrency;
  final double? expenseAmount;
  final Timestamp? createdAt;
  final int shoppingCount; // 0 = individual; >1 = grouped

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
    this.shoppingCount = 0,
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
  String? _partnerId;
  String _currency = '£';

  double _myMonthTotal = 0;
  double _partnerMonthTotal = 0;
  int _proposedCount = 0;
  int _acceptedCount = 0;
  int _pendingForMeCount = 0;
  int _activeShoppingCount = 0;

  bool _isLoading = true;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _pactsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _expensesSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _shoppingSub;

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _allPacts = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _allExpenses = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _allShoppingItems = [];
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
    _shoppingSub?.cancel();
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
      final rawFirst = userData?['firstName'] as String? ?? '';
      final firstName = rawFirst.isNotEmpty
          ? rawFirst[0].toUpperCase() + rawFirst.substring(1)
          : rawFirst;
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

      _shoppingSub = _db
          .collection('shopping_items')
          .where('coupleRef', isEqualTo: coupleId)
          .snapshots()
          .listen((snap) {
        if (!mounted) return;
        _allShoppingItems = snap.docs;
        _recompute(uid, partnerId);
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _recompute(String uid, String partnerId) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    double myMonthTotal = 0, partnerMonthTotal = 0;
    for (final doc in _allExpenses) {
      final data = doc.data();
      final amount = (data['amount'] as num?)?.toDouble() ?? 0;
      final ts = data['date'] as Timestamp?;
      final inMonth = ts != null &&
          !ts.toDate().isBefore(monthStart) &&
          !ts.toDate().isAfter(monthEnd);
      if (data['createdBy'] == uid) {
        if (inMonth) myMonthTotal += amount;
      } else {
        if (inMonth) partnerMonthTotal += amount;
      }
    }

    final proposedCount = _allPacts
        .where((d) => d.data()['status'] == 'pending')
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
    // Group shopping items: at most 1 card for active, 1 card for bought
    final addedDocs = _allShoppingItems
        .where((d) => (d.data()['isCompleted'] as bool?) != true)
        .toList()
      ..sort((a, b) {
        final ta = (a.data()['createdAt'] as Timestamp?)
                ?.millisecondsSinceEpoch ??
            0;
        final tb = (b.data()['createdAt'] as Timestamp?)
                ?.millisecondsSinceEpoch ??
            0;
        return tb.compareTo(ta);
      });
    if (addedDocs.isNotEmpty) {
      final ld = addedDocs.first.data();
      items.add(_ActivityItem(
        type: 'shopping',
        title: addedDocs.length == 1 ? ((ld['name'] as String?) ?? '') : '',
        status: 'shopping_added',
        emoji: '🛒',
        isInitiative: false,
        createdByMe: (ld['createdByRef'] as String?) == uid,
        createdAt: ld['createdAt'] as Timestamp?,
        shoppingCount: addedDocs.length,
      ));
    }

    final boughtDocs = _allShoppingItems
        .where((d) => (d.data()['isCompleted'] as bool?) == true)
        .toList()
      ..sort((a, b) {
        final ta = (a.data()['completedAt'] as Timestamp?)
                ?.millisecondsSinceEpoch ??
            0;
        final tb = (b.data()['completedAt'] as Timestamp?)
                ?.millisecondsSinceEpoch ??
            0;
        return tb.compareTo(ta);
      });
    if (boughtDocs.isNotEmpty) {
      final ld = boughtDocs.first.data();
      items.add(_ActivityItem(
        type: 'shopping',
        title: boughtDocs.length == 1 ? ((ld['name'] as String?) ?? '') : '',
        status: 'shopping_bought',
        emoji: '🛒',
        isInitiative: false,
        createdByMe: (ld['completedByRef'] as String?) == uid,
        createdAt: ld['completedAt'] as Timestamp?,
        shoppingCount: boughtDocs.length,
      ));
    }

    items.sort((a, b) {
      final ta = a.createdAt?.millisecondsSinceEpoch ?? 0;
      final tb = b.createdAt?.millisecondsSinceEpoch ?? 0;
      return tb.compareTo(ta);
    });

    final activeShoppingCount = _allShoppingItems
        .where((d) => (d.data()['isCompleted'] as bool?) != true)
        .length;

    setState(() {
      _myMonthTotal = myMonthTotal;
      _partnerMonthTotal = partnerMonthTotal;
      _proposedCount = proposedCount;
      _acceptedCount = acceptedCount;
      _pendingForMeCount = pendingForMeCount;
      _activeShoppingCount = activeShoppingCount;
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
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colorCard,
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
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
              color: iconBgColor, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.colorText)),
        ),
        const SizedBox(height: 2),
        Text(label,
            maxLines: 2,
            style: TextStyle(fontSize: 10, color: context.colorTextMuted)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: context.colorBackground,
        body: const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_partnerId == null) {
      return Scaffold(
        backgroundColor: context.colorBackground,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(l.connectPartnerMsg,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 16, color: context.colorTextMuted)),
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

    final totalAmount = _myMonthTotal + _partnerMonthTotal;
    final currency = context.watch<SettingsProvider>().currency;
    final myInitial = (_firstName?.isNotEmpty == true)
        ? _firstName![0].toUpperCase()
        : '?';
    final partnerInitial = (_partnerFirstName?.isNotEmpty == true)
        ? _partnerFirstName![0].toUpperCase()
        : '?';

    return Scaffold(
      backgroundColor: context.colorBackground,
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
                              style: TextStyle(
                                  fontSize: 14,
                                  color: context.colorTextMuted)),
                          const SizedBox(height: 4),
                          Text(
                            '${_firstName ?? ''} 💜 ${_partnerFirstName ?? ''}',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: context.colorText),
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
                        color: context.colorCard,
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

              // ── ORANGE BANNER / MOTIVATING MESSAGE ──────────
              if (_pendingForMeCount > 0)
                GestureDetector(
                  onTap: () => widget.onNavigateToPacts?.call(1),
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.orangeLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.secondary.withAlpha(100),
                          width: 1),
                    ),
                    child: Row(children: [
                      const Text('⏳', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l.pendingBannerText(_pendingForMeCount),
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          color: AppColors.secondary, size: 20),
                    ]),
                  ),
                )
              else
                Center(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(0, 12, 0, 0),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F3FF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.primary.withAlpha(51),
                          width: 1),
                    ),
                    child: Text(
                      l.togetherBanner,
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ),

              // ── SHOPPING BANNER ─────────────────────────────
              if (_activeShoppingCount > 0)
                GestureDetector(
                  onTap: () => widget.onTabChange?.call(4),
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.success.withAlpha(120),
                          width: 1),
                    ),
                    child: Row(children: [
                      const Text('🛒', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l.shoppingBannerText(_activeShoppingCount),
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.success,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          color: AppColors.success, size: 20),
                    ]),
                  ),
                ),

              // ── EXPENSES CARD ────────────────────────────────
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
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
                      // LEFT – me
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: AppColors.meColor,
                              child: Text(myInitial,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _firstName ?? '',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withAlpha(217)),
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '$currency${formatAmount(_myMonthTotal)}',
                                style: const TextStyle(
                                    fontSize: 17,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Divider left
                      Container(
                        width: 1,
                        height: 80,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        color: Colors.white.withAlpha(46),
                      ),
                      // CENTER – total
                      Expanded(
                        flex: 2,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(l.totalLabel,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white.withAlpha(217))),
                            const SizedBox(height: 6),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '$currency${formatAmount(totalAmount)}',
                                style: const TextStyle(
                                    fontSize: 28,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(l.isFr ? 'Ce mois-ci' : 'This month',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white.withAlpha(217))),
                          ],
                        ),
                      ),
                      // Divider right
                      Container(
                        width: 1,
                        height: 80,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        color: Colors.white.withAlpha(46),
                      ),
                      // RIGHT – partner
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: AppColors.secondary,
                              child: Text(partnerInitial,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _partnerFirstName ?? '',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withAlpha(217)),
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '$currency${formatAmount(_partnerMonthTotal)}',
                                style: TextStyle(
                                    fontSize: 17,
                                    color: Colors.white.withAlpha(217),
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ),

              // ── STAT CARDS ───────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
                          widget.onNavigateToExpenses?.call('Année'),
                      child: _buildStatCard(
                        iconBgColor: AppColors.purpleLight,
                        icon: Icons.calendar_today,
                        iconColor: AppColors.primary,
                        value: DateTime.now().year.toString(),
                        label: l.isFr ? 'Cette année' : 'This year',
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
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: context.colorText)),
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
                              style: TextStyle(
                                  color: context.colorTextMuted)),
                        ),
                      )
                    else
                      ...(_recentActivity.map((item) {
                        final emojiBgColor = item.type == 'expense'
                            ? const Color(0xFFF3F4F6)
                            : item.type == 'shopping'
                                ? const Color(0xFFD1FAE5)
                                : (item.isInitiative
                                    ? AppColors.orangeLight
                                    : AppColors.purpleLight);
                        final displayTitle = item.type == 'shopping'
                            ? (item.shoppingCount > 1
                                ? (item.status == 'shopping_bought'
                                    ? l.shoppingGroupBought(item.shoppingCount)
                                    : l.shoppingGroupAdded(item.shoppingCount))
                                : '${item.status == 'shopping_bought' ? l.shoppingActivityBought : l.shoppingActivityAdded} : ${item.title}')
                            : item.title;
                        final subtitle = item.type == 'pact'
                            ? l.proposedBy(item.createdByMe
                                ? l.youLabel
                                : (_partnerFirstName ?? l.partnerLabel))
                            : item.type == 'shopping'
                                ? (item.createdByMe
                                    ? (_firstName ?? l.youLabel)
                                    : (_partnerFirstName ?? l.partnerLabel))
                                : '${item.createdByMe ? (_firstName ?? '') : (_partnerFirstName ?? '')} • ${item.expenseCurrency ?? currency}${item.expenseAmount != null ? formatAmount(item.expenseAmount!) : ''}';
                        final subtitleColor = item.type == 'pact'
                            ? (item.createdByMe
                                ? AppColors.meColor
                                : AppColors.partnerColor)
                            : item.type == 'shopping'
                                ? (item.createdByMe
                                    ? AppColors.secondary
                                    : AppColors.meColor)
                                : AppColors.primary;
                        return GestureDetector(
                          onTap: item.type == 'pact'
                              ? () => item.status == 'pending'
                                  ? widget.onNavigateToPacts?.call(1)
                                  : widget.onTabChange?.call(2)
                              : item.type == 'shopping'
                                  ? () => widget.onTabChange?.call(4)
                                  : null,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: context.colorCard,
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
                                    color: emojiBgColor,
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
                                    Text(displayTitle,
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: context.colorText)),
                                    Text(subtitle,
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: subtitleColor)),
                                  ],
                                ),
                              ),
                              _buildStatusBadge(item.status, l),
                            ]),
                          ),
                        );
                      })),
                    const SizedBox(height: 80),
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
