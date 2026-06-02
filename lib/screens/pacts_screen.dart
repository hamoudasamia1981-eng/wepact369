import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../config/app_localizations.dart';
import '../theme/app_colors.dart';
import 'add_initiative_screen.dart';
import 'add_task_screen.dart';

class PactsScreen extends StatefulWidget {
  const PactsScreen({super.key});
  @override
  PactsScreenState createState() => PactsScreenState();
}

class PactsScreenState extends State<PactsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _db = FirebaseFirestore.instance;

  String? _currentUid;
  String? _partnerFirstName;
  String? _coupleId;
  bool _isLoading = true;

  int _aFaireCount = 0;
  int _enAttenteCount = 0;
  int _refuseCount = 0;
  bool _pactsReady = false;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _allPacts = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _countSub;

  void jumpToTab(int index) {
    if (index >= 0 && index < 3) _tabController.animateTo(index);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _countSub?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    _currentUid = user.uid;
    try {
      final userDoc =
          await _db.collection('users').doc(user.uid).get();
      if (!mounted) return;
      final partnerId =
          userDoc.data()?['partnerId'] as String?;
      if (partnerId == null) {
        setState(() => _isLoading = false);
        return;
      }
      final partnerDoc =
          await _db.collection('users').doc(partnerId).get();
      if (!mounted) return;
      final ids = [user.uid, partnerId]..sort();
      final coupleId = ids.join('_');

      setState(() {
        _partnerFirstName =
            partnerDoc.data()?['firstName'] as String? ?? 'Partenaire';
        _coupleId = coupleId;
        _isLoading = false;
      });

      // Single-field query — no composite index needed.
      // Status filtering and sorting happen client-side.
      _countSub = _db
          .collection('pacts')
          .where('coupleId', isEqualTo: coupleId)
          .snapshots()
          .listen((snap) {
        if (!mounted) return;
        setState(() {
          _allPacts = snap.docs;
          _aFaireCount =
              snap.docs.where((d) => d['status'] == 'accepted').length;
          _enAttenteCount =
              snap.docs.where((d) => d['status'] == 'pending').length;
          _refuseCount =
              snap.docs.where((d) => d['status'] == 'declined').length;
          _pactsReady = true;
        });
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(Timestamp ts, AppLocalizations l) {
    final d = ts.toDate();
    return '${d.day} ${l.monthsShort[d.month - 1]}';
  }

  Widget _buildStatusBadge(String status, AppLocalizations l) {
    switch (status) {
      case 'accepted':
        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              color: const Color(0xFFD1FAE5),
              borderRadius: BorderRadius.circular(20)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.check, size: 11, color: AppColors.success),
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
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(20)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.close, size: 11, color: AppColors.error),
            const SizedBox(width: 4),
            Text(l.declinedBadge,
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.error,
                    fontWeight: FontWeight.bold)),
          ]),
        );
      default:
        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              color: AppColors.orangeLight,
              borderRadius: BorderRadius.circular(20)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.access_time,
                size: 11, color: AppColors.secondary),
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

  void _showAddPactSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Text('📋',
                  style: TextStyle(fontSize: 28)),
              title: const Text('Tâche',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AddTaskScreen()),
                );
              },
            ),
            ListTile(
              leading: const Text('🌟',
                  style: TextStyle(fontSize: 28)),
              title: const Text('Initiative',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AddInitiativeScreen()),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(String docId, String status) async {
    await _db
        .collection('pacts')
        .doc(docId)
        .update({'status': status});
  }

  Widget _buildPactCard(
      QueryDocumentSnapshot<Map<String, dynamic>> doc,
      AppLocalizations l) {
    final data = doc.data();
    final title = data['title'] as String? ?? '';
    final status = data['status'] as String? ?? 'pending';
    final createdBy = data['createdBy'] as String? ?? '';
    final type = data['type'] as String? ?? 'task';
    final category = data['category'] as String? ?? '📋';
    final description = data['description'] as String? ?? '';
    final dueDate = data['dueDate'] as Timestamp?;
    final createdAt = data['createdAt'] as Timestamp?;

    final proposerName = createdBy == _currentUid
        ? l.youLabel
        : (_partnerFirstName ?? l.partnerLabel);
    final bgColor = type == 'initiative'
        ? AppColors.orangeLight
        : AppColors.purpleLight;
    final isFromPartner = createdBy != _currentUid;
    final displayDate = dueDate ?? createdAt;

    return Card(
      color: AppColors.white,
      elevation: 1,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12)),
                  child: Center(
                      child: Text(category,
                          style: const TextStyle(fontSize: 22))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark)),
                      Text(l.proposedBy(proposerName),
                          style: TextStyle(
                              fontSize: 13,
                              color: createdBy == _currentUid
                                  ? AppColors.meColor
                                  : AppColors.partnerColor)),
                      if (description.isNotEmpty)
                        Text(description,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textGrey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildStatusBadge(status, l),
                    const SizedBox(height: 4),
                    if (displayDate != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 12, color: AppColors.textGrey),
                          const SizedBox(width: 4),
                          Text(_formatDate(displayDate, l),
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textGrey)),
                        ],
                      ),
                    const Icon(Icons.chevron_right,
                        color: AppColors.textGrey),
                  ],
                ),
              ],
            ),
            if (status == 'pending' && isFromPartner)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            _updateStatus(doc.id, 'declined'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(
                              color: AppColors.error),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(8)),
                        ),
                        child: Text(l.declineButton),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            _updateStatus(doc.id, 'accepted'),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(8)),
                        ),
                        child: Text(l.acceptButton),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String status, AppLocalizations l) {
    if (_coupleId == null || !_pactsReady) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    final filtered = _allPacts
        .where((d) => d.data()['status'] == status)
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

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.handshake,
                size: 48, color: AppColors.textGrey),
            const SizedBox(height: 12),
            Text(
              status == 'accepted'
                  ? l.noAcceptedPacts
                  : status == 'pending'
                      ? l.noPendingPacts
                      : l.noDeclinedPacts,
              style: const TextStyle(color: AppColors.textGrey),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 148),
      itemCount: filtered.length,
      itemBuilder: (_, i) => _buildPactCard(filtered[i], l),
    );
  }

  Widget _tabLabel(String text, int count, Color badgeColor) => Tab(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text),
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
            child:
                CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(l.pactsTitle,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: AppColors.textDark)),
        actions: const [
          LangToggleButton(dark: false),
          SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textGrey,
          tabs: [
            _tabLabel(l.toDoTab, _aFaireCount, AppColors.primary),
            _tabLabel(l.pendingTab, _enAttenteCount, AppColors.secondary),
            _tabLabel(l.declinedTab, _refuseCount, AppColors.error),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildTab('accepted', l),
              _buildTab('pending', l),
              _buildTab('declined', l),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 68,
            child: Center(
              child: FractionallySizedBox(
                widthFactor: 0.93,
                child: GestureDetector(
                  onTap: () => _showAddPactSheet(context),
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFFFF8C00)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        l.addPactButton,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                    ),
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
