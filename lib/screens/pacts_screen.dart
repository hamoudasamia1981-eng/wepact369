import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class PactsScreen extends StatefulWidget {
  const PactsScreen({super.key});
  @override
  State<PactsScreen> createState() => _PactsScreenState();
}

class _PactsScreenState extends State<PactsScreen>
    with SingleTickerProviderStateMixin {
  static const _monthsFr = [
    'jan', 'fév', 'mar', 'avr', 'mai', 'juin',
    'juil', 'août', 'sep', 'oct', 'nov', 'déc',
  ];

  late final TabController _tabController;
  final _db = FirebaseFirestore.instance;

  String? _currentUid;
  String? _partnerFirstName;
  String? _coupleId;
  bool _isLoading = true;

  int _aFaireCount = 0;
  int _enAttenteCount = 0;
  int _refuseCount = 0;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _countSub;

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

      _countSub = _db
          .collection('pacts')
          .where('coupleId', isEqualTo: coupleId)
          .snapshots()
          .listen((snap) {
        if (!mounted) return;
        setState(() {
          _aFaireCount = snap.docs
              .where((d) => d['status'] == 'accepted').length;
          _enAttenteCount = snap.docs
              .where((d) => d['status'] == 'pending').length;
          _refuseCount = snap.docs
              .where((d) => d['status'] == 'declined').length;
        });
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(Timestamp ts) {
    final d = ts.toDate();
    return '${d.day} ${_monthsFr[d.month - 1]}';
  }

  Widget _buildStatusBadge(String status) {
    switch (status) {
      case 'accepted':
        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              color: const Color(0xFFD1FAE5),
              borderRadius: BorderRadius.circular(20)),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.check, size: 11, color: AppColors.success),
            SizedBox(width: 4),
            Text('Accepté',
                style: TextStyle(
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
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.close, size: 11, color: AppColors.error),
            SizedBox(width: 4),
            Text('Refusé',
                style: TextStyle(
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
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.access_time,
                size: 11, color: AppColors.secondary),
            SizedBox(width: 4),
            Text('En attente',
                style: TextStyle(
                    fontSize: 11,
                    color: AppColors.secondary,
                    fontWeight: FontWeight.bold)),
          ]),
        );
    }
  }

  Future<void> _updateStatus(String docId, String status) async {
    await _db
        .collection('pacts')
        .doc(docId)
        .update({'status': status});
  }

  Widget _buildPactCard(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
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
        ? 'Vous'
        : (_partnerFirstName ?? 'Partenaire');
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
                      Text('Proposé par $proposerName',
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.primary)),
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
                    _buildStatusBadge(status),
                    const SizedBox(height: 4),
                    if (displayDate != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 12, color: AppColors.textGrey),
                          const SizedBox(width: 4),
                          Text(_formatDate(displayDate),
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
                        child: const Text('Refuser'),
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
                        child: const Text('Accepter'),
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

  Widget _buildTab(String status) {
    if (_coupleId == null) {
      return const Center(
          child: Text('Chargement...',
              style: TextStyle(color: AppColors.textGrey)));
    }
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db
          .collection('pacts')
          .where('coupleId', isEqualTo: _coupleId)
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child:
                  CircularProgressIndicator(color: AppColors.primary));
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.handshake,
                    size: 48, color: AppColors.textGrey),
                const SizedBox(height: 12),
                Text(
                  status == 'accepted'
                      ? 'Aucun pact accepté'
                      : status == 'pending'
                          ? 'Aucune proposition en attente'
                          : 'Aucun pact refusé',
                  style:
                      const TextStyle(color: AppColors.textGrey),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: docs.length,
          itemBuilder: (_, i) => _buildPactCard(docs[i]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text('Pactes',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: AppColors.textDark)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textGrey,
          tabs: [
            Tab(text: 'À faire ($_aFaireCount)'),
            Tab(text: 'En attente ($_enAttenteCount)'),
            Tab(text: 'Refusé ($_refuseCount)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTab('accepted'),
          _buildTab('pending'),
          _buildTab('declined'),
        ],
      ),
    );
  }
}
