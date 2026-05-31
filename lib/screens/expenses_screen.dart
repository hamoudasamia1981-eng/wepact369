import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'add_expense_screen.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});
  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  static const _monthsFr = [
    'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
  ];
  static const _filters = ["Aujourd'hui", 'Semaine', 'Mois', 'Année'];
  static const _categoryEmojis = <String, String>{
    'Alimentation': '🛒', 'Loyer': '🏠', 'Restaurant': '🍴',
    'Transport': '🚗', 'Enfants': '👶', 'Maison': '🛋️',
    'Loisirs': '🎭', 'Santé': '💊', 'Autre': '💳',
  };
  static const _categoryColors = <String, Color>{
    'Alimentation': Color(0xFFFEF3C7), 'Loyer': Color(0xFFDBEAFE),
    'Restaurant': Color(0xFFFEE2E2), 'Transport': Color(0xFFD1FAE5),
    'Enfants': Color(0xFFFEF9C3), 'Maison': Color(0xFFCCFBF1),
    'Loisirs': Color(0xFFFCE7F3), 'Santé': Color(0xFFEDE9FE),
    'Autre': Color(0xFFF3F4F6),
  };

  String _selectedFilter = 'Mois';
  DateTime _currentPeriod = DateTime.now();
  String? _firstName;
  String? _partnerFirstName;
  String? _coupleId;
  String _currency = '£';
  String? _currentUid;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    _currentUid = user.uid;
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users').doc(user.uid).get();
      if (!mounted) return;
      final data = userDoc.data();
      final partnerId = data?['partnerId'] as String?;
      final firstName = data?['firstName'] as String? ?? '';
      final currency = data?['currency'] as String? ?? '£';
      if (partnerId == null) {
        setState(() {
          _firstName = firstName;
          _currency = currency;
          _isLoading = false;
        });
        return;
      }
      final partnerDoc = await FirebaseFirestore.instance
          .collection('users').doc(partnerId).get();
      if (!mounted) return;
      final ids = [user.uid, partnerId]..sort();
      setState(() {
        _firstName = firstName;
        _currency = currency;
        _coupleId = ids.join('_');
        _partnerFirstName =
            partnerDoc.data()?['firstName'] as String? ?? 'Partenaire';
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  ({DateTime start, DateTime end}) _getDateRange() {
    final d = _currentPeriod;
    switch (_selectedFilter) {
      case "Aujourd'hui":
        return (
          start: DateTime(d.year, d.month, d.day),
          end: DateTime(d.year, d.month, d.day, 23, 59, 59),
        );
      case 'Semaine':
        final mon = d.subtract(Duration(days: d.weekday - 1));
        final sun = mon.add(const Duration(days: 6));
        return (
          start: DateTime(mon.year, mon.month, mon.day),
          end: DateTime(sun.year, sun.month, sun.day, 23, 59, 59),
        );
      case 'Année':
        return (
          start: DateTime(d.year),
          end: DateTime(d.year, 12, 31, 23, 59, 59),
        );
      default:
        return (
          start: DateTime(d.year, d.month),
          end: DateTime(d.year, d.month + 1, 0, 23, 59, 59),
        );
    }
  }

  String get _periodDisplay {
    switch (_selectedFilter) {
      case "Aujourd'hui":
        return '${_currentPeriod.day} ${_monthsFr[_currentPeriod.month - 1]}';
      case 'Semaine':
        final diff = _currentPeriod
            .difference(DateTime(_currentPeriod.year, 1, 1)).inDays;
        return 'Semaine ${(diff / 7).floor() + 1}';
      case 'Année':
        return '${_currentPeriod.year}';
      default:
        return '${_monthsFr[_currentPeriod.month - 1]} ${_currentPeriod.year}';
    }
  }

  void _prev() => setState(() {
        switch (_selectedFilter) {
          case "Aujourd'hui":
            _currentPeriod =
                _currentPeriod.subtract(const Duration(days: 1));
            break;
          case 'Semaine':
            _currentPeriod =
                _currentPeriod.subtract(const Duration(days: 7));
            break;
          case 'Année':
            _currentPeriod = DateTime(_currentPeriod.year - 1);
            break;
          default:
            _currentPeriod =
                DateTime(_currentPeriod.year, _currentPeriod.month - 1);
        }
      });

  void _next() => setState(() {
        switch (_selectedFilter) {
          case "Aujourd'hui":
            _currentPeriod = _currentPeriod.add(const Duration(days: 1));
            break;
          case 'Semaine':
            _currentPeriod = _currentPeriod.add(const Duration(days: 7));
            break;
          case 'Année':
            _currentPeriod = DateTime(_currentPeriod.year + 1);
            break;
          default:
            _currentPeriod =
                DateTime(_currentPeriod.year, _currentPeriod.month + 1);
        }
      });

  String _formatDate(Timestamp ts) {
    final d = ts.toDate();
    return '${d.day} ${_monthsFr[d.month - 1]} ${d.year}';
  }

  Future<void> _confirmDelete(String docId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la dépense'),
        content: const Text('Confirmer la suppression ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await FirebaseFirestore.instance
          .collection('expenses').doc(docId).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    // Single-field query avoids composite index requirement.
    // Date filtering is done client-side in the StreamBuilder builder.
    final stream = _coupleId != null
        ? FirebaseFirestore.instance
            .collection('expenses')
            .where('coupleId', isEqualTo: _coupleId)
            .snapshots()
        : _currentUid != null
            ? FirebaseFirestore.instance
                .collection('expenses')
                .where('createdBy', isEqualTo: _currentUid)
                .snapshots()
            : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('Dépenses',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: AppColors.textDark)),
      ),
      body: Column(
        children: [
          // Period navigation
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _prev),
                Expanded(
                  child: Center(
                    child: Text(_periodDisplay,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.textDark)),
                  ),
                ),
                IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _next),
              ],
            ),
          ),
          // Filter pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: _filters.map((f) {
                final sel = _selectedFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: sel
                      ? ElevatedButton(
                          onPressed: () => setState(() {
                            _selectedFilter = f;
                            _currentPeriod = DateTime.now();
                          }),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(f),
                        )
                      : OutlinedButton(
                          onPressed: () => setState(() {
                            _selectedFilter = f;
                            _currentPeriod = DateTime.now();
                          }),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textGrey,
                            side: const BorderSide(
                                color: AppColors.textGrey),
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(f),
                        ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 4),
          // Content
          Expanded(
            child: stream == null
                ? const Center(
                    child: Text(
                      'Connectez-vous à un partenaire pour voir les dépenses.',
                      style: TextStyle(color: AppColors.textGrey),
                      textAlign: TextAlign.center,
                    ),
                  )
                : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: stream,
                    builder: (ctx, snap) {
                      if (snap.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primary));
                      }
                      // Filter by selected period client-side
                      final range = _getDateRange();
                      final docs = (snap.data?.docs ?? [])
                          .where((doc) {
                            final ts = doc.data()['date'] as Timestamp?;
                            if (ts == null) return false;
                            final d = ts.toDate();
                            return !d.isBefore(range.start) &&
                                !d.isAfter(range.end);
                          })
                          .toList()
                        ..sort((a, b) {
                          final ta = (a.data()['date'] as Timestamp?)
                                  ?.toDate() ??
                              DateTime(0);
                          final tb = (b.data()['date'] as Timestamp?)
                                  ?.toDate() ??
                              DateTime(0);
                          return tb.compareTo(ta);
                        });
                      double myTotal = 0, partnerTotal = 0;
                      for (final d in docs) {
                        final amt =
                            (d['amount'] as num?)?.toDouble() ?? 0;
                        if (d['createdBy'] == _currentUid) {
                          myTotal += amt;
                        } else {
                          partnerTotal += amt;
                        }
                      }
                      final total = myTotal + partnerTotal;
                      final myR = total > 0
                          ? (myTotal / total).clamp(0.0, 1.0)
                          : 0.0;
                      final pR = total > 0
                          ? (partnerTotal / total).clamp(0.0, 1.0)
                          : 0.0;
                      final myI = (_firstName?.isNotEmpty == true)
                          ? _firstName![0].toUpperCase()
                          : '?';
                      final pI =
                          (_partnerFirstName?.isNotEmpty == true)
                              ? _partnerFirstName![0].toUpperCase()
                              : '?';

                      return SingleChildScrollView(
                        child: Column(
                          children: [
                            // Summary card
                            Container(
                              margin: const EdgeInsets.fromLTRB(
                                  16, 8, 16, 8),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF7C3AED),
                                    Color(0xFF6D28D9)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                      color:
                                          AppColors.primary.withAlpha(76),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8))
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.center,
                                children: [
                                  Column(children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor:
                                          Colors.white.withAlpha(76),
                                      child: Text(myI,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight:
                                                  FontWeight.bold)),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(_firstName ?? '',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.white)),
                                    Text(
                                        '$_currency${myTotal.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                            fontSize: 18,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    SizedBox(
                                      width: 70,
                                      child: LinearProgressIndicator(
                                        value: myR,
                                        backgroundColor:
                                            Colors.white.withAlpha(76),
                                        valueColor:
                                            const AlwaysStoppedAnimation(
                                                Colors.white),
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                    ),
                                  ]),
                                  Expanded(
                                    child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Text('TOTAL',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.white70,
                                                  fontWeight:
                                                      FontWeight.bold,
                                                  letterSpacing: 1.2)),
                                          Text(
                                              '$_currency${total.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                  fontSize: 22,
                                                  color: Colors.white,
                                                  fontWeight:
                                                      FontWeight.bold)),
                                          const Text('ensemble',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.white60)),
                                          const SizedBox(height: 8),
                                          const Icon(Icons.bar_chart,
                                              color: Colors.white60,
                                              size: 20),
                                        ]),
                                  ),
                                  Column(children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: AppColors.secondary,
                                      child: Text(pI,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight:
                                                  FontWeight.bold)),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(_partnerFirstName ?? '',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.secondary)),
                                    Text(
                                        '$_currency${partnerTotal.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                            fontSize: 18,
                                            color: AppColors.secondary,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    SizedBox(
                                      width: 70,
                                      child: LinearProgressIndicator(
                                        value: pR,
                                        backgroundColor:
                                            Colors.white.withAlpha(76),
                                        valueColor:
                                            const AlwaysStoppedAnimation(
                                                AppColors.secondary),
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                    ),
                                  ]),
                                ],
                              ),
                            ),
                            // List
                            if (docs.isEmpty)
                              const Padding(
                                padding:
                                    EdgeInsets.symmetric(vertical: 40),
                                child: Column(children: [
                                  Icon(Icons.receipt_long,
                                      color: AppColors.textGrey,
                                      size: 48),
                                  SizedBox(height: 12),
                                  Text(
                                      'Aucune dépense pour cette période',
                                      style: TextStyle(
                                          color: AppColors.textGrey)),
                                ]),
                              )
                            else
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16),
                                child: Column(
                                  children: docs.map((doc) {
                                    final d = doc.data();
                                    final title =
                                        d['title'] as String? ?? '';
                                    final amt =
                                        (d['amount'] as num?)
                                                ?.toDouble() ??
                                            0;
                                    final cat =
                                        d['category'] as String? ??
                                            'Autre';
                                    final cur =
                                        d['currency'] as String? ??
                                            _currency;
                                    final by =
                                        d['createdBy'] as String? ?? '';
                                    final dateTs =
                                        d['date'] as Timestamp?;
                                    final emoji =
                                        _categoryEmojis[cat] ?? '💳';
                                    final bg = _categoryColors[cat] ??
                                        const Color(0xFFF3F4F6);
                                    final owner = by == _currentUid
                                        ? (_firstName ?? 'Moi')
                                        : (_partnerFirstName ??
                                            'Partenaire');
                                    final dateStr = dateTs != null
                                        ? _formatDate(dateTs)
                                        : '';

                                    return Container(
                                      margin: const EdgeInsets.only(
                                          bottom: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.white,
                                        borderRadius:
                                            BorderRadius.circular(12),
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
                                              color: bg,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      10)),
                                          child: Center(
                                              child: Text(emoji,
                                                  style: const TextStyle(
                                                      fontSize: 20))),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(title,
                                                  style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: AppColors
                                                          .textDark)),
                                              Text('$cat • $dateStr',
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color: AppColors
                                                          .textGrey)),
                                              const SizedBox(height: 4),
                                              Row(children: [
                                                CircleAvatar(
                                                  radius: 8,
                                                  backgroundColor:
                                                      AppColors.primary,
                                                  child: Text(
                                                    owner.isNotEmpty
                                                        ? owner[0]
                                                            .toUpperCase()
                                                        : '?',
                                                    style: const TextStyle(
                                                        fontSize: 8,
                                                        color:
                                                            Colors.white),
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(owner,
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        color: AppColors
                                                            .primary)),
                                              ]),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                                '$cur${amt.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    color:
                                                        AppColors.primary)),
                                            if (by == _currentUid)
                                              SizedBox(
                                                width: 32,
                                                height: 32,
                                                child: IconButton(
                                                  icon: const Icon(
                                                      Icons.delete_outline,
                                                      size: 18,
                                                      color: AppColors
                                                          .textGrey),
                                                  padding: EdgeInsets.zero,
                                                  onPressed: () =>
                                                      _confirmDelete(
                                                          doc.id),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ]),
                                    );
                                  }).toList(),
                                ),
                              ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          // Add button
          Padding(
            padding: const EdgeInsets.all(16),
            child: GestureDetector(
              onTap: _coupleId == null
                  ? null
                  : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddExpenseScreen(),
                        ),
                      ),
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: _coupleId == null
                      ? const LinearGradient(
                          colors: [
                            AppColors.textGrey,
                            AppColors.textGrey
                          ],
                        )
                      : const LinearGradient(
                          colors: [
                            Color(0xFF7C3AED),
                            Color(0xFFF59E0B)
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    '+ Ajouter une dépense',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
