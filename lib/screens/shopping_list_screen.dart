import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_localizations.dart';
import '../providers/language_provider.dart';
import '../services/shopping_service.dart';
import '../theme/app_colors.dart';
import '../theme/theme_ext.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final _db = FirebaseFirestore.instance;
  final _itemController = TextEditingController();
  final _focusNode = FocusNode();

  String? _currentUid;
  String? _coupleId;
  String? _myFirstName;
  String? _partnerFirstName;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _itemController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── Data loading (same pattern as ExpensesScreen / PactsScreen) ─
  Future<void> _loadUserData() async {
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
      final data = userDoc.data() ?? {};
      final partnerId = data['partnerId'] as String?;
      final firstName = data['firstName'] as String? ?? '';

      if (partnerId == null) {
        setState(() {
          _myFirstName = firstName;
          _isLoading = false;
        });
        return;
      }

      final partnerDoc =
          await _db.collection('users').doc(partnerId).get();
      if (!mounted) return;
      final ids = [user.uid, partnerId]..sort();
      setState(() {
        _myFirstName = firstName;
        _partnerFirstName =
            partnerDoc.data()?['firstName'] as String? ?? 'Partenaire';
        _coupleId = ids.join('_');
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Firestore writes ─────────────────────────────────────────
  Future<void> _addItem() async {
    final name = _itemController.text.trim();
    if (name.isEmpty || _coupleId == null || _currentUid == null) return;
    setState(() => _isSaving = true);
    final error = await ShoppingService.addItem(
      name: name,
      createdByRef: _currentUid!,
      coupleRef: _coupleId!,
    );
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).saveError),
          backgroundColor: AppColors.error,
        ),
      );
    } else {
      _itemController.clear();
      _focusNode.requestFocus();
    }
    setState(() => _isSaving = false);
  }

  Future<void> _toggleItem(String docId, bool currentlyCompleted) async {
    if (_currentUid == null) return;
    try {
      await _db.collection('shopping_items').doc(docId).update({
        'isCompleted': !currentlyCompleted,
        'completedByRef': !currentlyCompleted ? _currentUid : null,
        'completedAt':
            !currentlyCompleted ? FieldValue.serverTimestamp() : null,
      });
    } catch (_) {}
  }

  Future<void> _clearPurchased(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> purchased,
    AppLocalizations l,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l.shoppingClearConfirmTitle,
          style: TextStyle(
              color: context.colorText, fontWeight: FontWeight.w700),
        ),
        content: Text(l.shoppingClearConfirmBody,
            style: TextStyle(color: context.colorTextMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel,
                style: TextStyle(color: context.colorTextMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.delete,
                style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final batch = _db.batch();
    for (final doc in purchased) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  String _displayName(String? uid) {
    if (uid == null) return '';
    return uid == _currentUid
        ? (_myFirstName ?? '')
        : (_partnerFirstName ?? '');
  }

  // Orange for current user, blue for partner — applied to "Added by" only.
  Color _addedByColor(String? uid) {
    if (uid == null) return AppColors.textGrey;
    return uid == _currentUid
        ? AppColors.secondary   // orange #FF8C00
        : AppColors.meColor;    // blue  #3B82F6
  }

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    context.watch<LanguageProvider>();

    // Early return while loading — same pattern as ExpensesScreen / PactsScreen
    if (_isLoading) {
      return Scaffold(
        backgroundColor: context.colorBackground,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.colorBackground,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        toolbarHeight: 48,
        centerTitle: false,
        title: Text(
          l.shoppingListTitle,
          style: TextStyle(
            color: context.colorText,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        actions: const [LangToggleButton(dark: false), SizedBox(width: 8)],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildAddBar(l),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          Expanded(child: _buildBody(l)),
        ],
      ),
    );
  }

  // ── Add bar ───────────────────────────────────────────────────
  Widget _buildAddBar(AppLocalizations l) {
    final canAdd = _coupleId != null && !_isSaving;

    // Desktop/web: stronger contrast so elements don't vanish on white page.
    // Mobile: keep current values unchanged.
    final containerBg = context.isDark
        ? context.colorCard
        : (kIsWeb ? const Color(0xFFF0F2F5) : AppColors.white);
    final inputFill = context.isDark
        ? context.colorInput
        : (kIsWeb ? const Color(0xFFE8EAED) : const Color(0xFFF3F4F6));
    final enabledBorderColor = context.isDark
        ? Colors.white24
        : (kIsWeb ? const Color(0xFF9CA3AF) : const Color(0xFFD1D5DB));
    final buttonElevation = kIsWeb ? 1.0 : 0.0;

    return Container(
      color: containerBg,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _itemController,
              focusNode: _focusNode,
              enabled: _coupleId != null,
              style: TextStyle(
                  color: context.colorText, fontSize: 15),
              decoration: InputDecoration(
                hintText: l.shoppingItemHint,
                hintStyle: TextStyle(
                    color: context.colorTextMuted, fontSize: 14),
                filled: true,
                fillColor: inputFill,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                      color: enabledBorderColor, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                      color: enabledBorderColor, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                      color: AppColors.primary, width: 2),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                      color: Color(0xFFE5E7EB), width: 1),
                ),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _addItem(),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: canAdd ? _addItem : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor:
                  AppColors.primary.withAlpha(100),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              minimumSize: const Size(76, 46),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              elevation: buttonElevation,
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    l.shoppingAddButton,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Body (list area) ──────────────────────────────────────────
  Widget _buildBody(AppLocalizations l) {
    if (_coupleId == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shopping_cart_outlined,
                  size: 56, color: context.colorTextMuted),
              const SizedBox(height: 16),
              Text(
                l.shoppingNoPartner,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: context.colorTextMuted, fontSize: 15),
              ),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db
          .collection('shopping_items')
          .where('coupleRef', isEqualTo: _coupleId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        final active = docs
            .where((d) => (d.data()['isCompleted'] as bool?) != true)
            .toList()
          ..sort((a, b) {
            final ta =
                (a.data()['createdAt'] as Timestamp?)?.toDate() ??
                    DateTime(0);
            final tb =
                (b.data()['createdAt'] as Timestamp?)?.toDate() ??
                    DateTime(0);
            return ta.compareTo(tb);
          });

        final purchased = docs
            .where((d) => (d.data()['isCompleted'] as bool?) == true)
            .toList()
          ..sort((a, b) {
            final ta =
                (a.data()['completedAt'] as Timestamp?)?.toDate() ??
                    DateTime(0);
            final tb =
                (b.data()['completedAt'] as Timestamp?)?.toDate() ??
                    DateTime(0);
            return tb.compareTo(ta);
          });

        if (active.isEmpty && purchased.isEmpty) {
          return Center(
            child: Text(
              l.shoppingListEmpty,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: context.colorTextMuted, fontSize: 15),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.only(
              left: 16, right: 16, top: 8, bottom: 100),
          children: [
            if (active.isNotEmpty) ...[
              _sectionHeader(l.shoppingActiveSection),
              ...active.map((doc) => _itemTile(doc, l)),
            ],
            if (purchased.isNotEmpty) ...[
              const SizedBox(height: 8),
              _purchasedHeader(purchased, l),
              ...purchased.map((doc) => _itemTile(doc, l)),
            ],
          ],
        );
      },
    );
  }

  // ── Section headers ───────────────────────────────────────────
  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: context.colorTextMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _purchasedHeader(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> purchased,
    AppLocalizations l,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l.shoppingPurchasedSection.toUpperCase(),
            style: TextStyle(
              color: context.colorTextMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          GestureDetector(
            onTap: () => _clearPurchased(purchased, l),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.delete_sweep_outlined,
                    size: 15, color: AppColors.error),
                const SizedBox(width: 4),
                Text(
                  l.shoppingClearPurchased,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Item tile ─────────────────────────────────────────────────
  Widget _itemTile(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    AppLocalizations l,
  ) {
    final data = doc.data();
    final name = (data['name'] as String?) ?? '';
    final isCompleted = (data['isCompleted'] as bool?) == true;
    final createdBy = data['createdByRef'] as String?;
    final completedBy = data['completedByRef'] as String?;

    final subtitleUid = isCompleted ? completedBy : createdBy;
    final subtitlePrefix =
        isCompleted ? l.shoppingBoughtBy : l.shoppingAddedBy;
    final subtitleName = _displayName(subtitleUid);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isCompleted
            ? (context.isDark ? const Color(0xFF181830) : const Color(0xFFF9FAFB))
            : context.colorCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colorBorder),
        boxShadow: isCompleted
            ? null
            : const [
                BoxShadow(
                  color: AppColors.cardShadow,
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Checkbox(
          value: isCompleted,
          onChanged: (_) => _toggleItem(doc.id, isCompleted),
          activeColor: AppColors.success,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4)),
          side:
              BorderSide(color: context.colorTextMuted, width: 1.5),
        ),
        title: Text(
          name,
          style: TextStyle(
            color: isCompleted
                ? context.colorTextMuted
                : context.colorText,
            fontSize: 15,
            fontWeight:
                isCompleted ? FontWeight.w400 : FontWeight.w500,
            decoration:
                isCompleted ? TextDecoration.lineThrough : null,
            decorationColor: context.colorTextMuted,
          ),
        ),
        subtitle: subtitleName.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '$subtitlePrefix $subtitleName',
                  style: TextStyle(
                    color: isCompleted
                        ? context.colorTextMuted
                        : _addedByColor(createdBy),
                    fontSize: 11,
                    fontWeight: isCompleted
                        ? FontWeight.w400
                        : FontWeight.w500,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
