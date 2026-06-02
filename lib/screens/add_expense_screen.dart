import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_localizations.dart';
import '../providers/language_provider.dart';
import '../theme/app_colors.dart';
import '../theme/theme_ext.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  static const _categories = [
    'Alimentation', 'Loyer', 'Restaurant', 'Transport',
    'Enfants', 'Maison', 'Loisirs', 'Santé', 'Autre',
  ];
  static const _categoryEmojis = <String, String>{
    'Alimentation': '🛒', 'Loyer': '🏠', 'Restaurant': '🍴',
    'Transport': '🚗', 'Enfants': '👶', 'Maison': '🛋️',
    'Loisirs': '🎭', 'Santé': '💊', 'Autre': '💳',
  };

  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedCategory = 'Alimentation';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  String _currency = '£';
  String? _coupleId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users').doc(user.uid).get();
      if (!mounted) return;
      final data = doc.data();
      final partnerId = data?['partnerId'] as String?;
      if (partnerId != null) {
        final ids = [user.uid, partnerId]..sort();
        setState(() {
          _currency = data?['currency'] as String? ?? '£';
          _coupleId = ids.join('_');
        });
      } else {
        setState(() => _currency = data?['currency'] as String? ?? '£');
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d, AppLocalizations l) =>
      '${d.day} ${l.monthsShort[d.month - 1]} ${d.year}';

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isAfter(now) ? now : _selectedDate,
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    final l = context.read<LanguageProvider>().l10n;
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showError(l.enterTitle);
      return;
    }
    final amountText =
        _amountController.text.trim().replaceAll(',', '.');
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      _showError(l.validAmount);
      return;
    }
    if (_coupleId == null) {
      _showError(l.linkPartnerFirst);
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('expenses').add({
        'coupleId': _coupleId,
        'createdBy': uid,
        'title': title,
        'amount': amount,
        'category': _selectedCategory,
        'date': Timestamp.fromDate(_selectedDate),
        'currency': _currency,
        'createdAt': Timestamp.now(),
      });
      if (!mounted) return;
      Navigator.pop(context);
    } catch (_) {
      if (mounted) _showError(l.saveError);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: context.colorBackground,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: BackButton(color: context.colorText),
        title: Text(
          l.newExpenseTitle,
          style: TextStyle(
              color: context.colorText, fontWeight: FontWeight.w600),
        ),
        actions: const [
          LangToggleButton(dark: false),
          SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.titleFieldLabel,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: context.colorText)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(
                  color: context.colorText,
                  fontSize: 16,
                  fontWeight: FontWeight.w500),
              cursorColor: AppColors.primary,
              decoration: InputDecoration(hintText: l.titleHint),
            ),
            const SizedBox(height: 20),

            Text('${l.amountLabel} ($_currency)',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: context.colorText)),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(
                  color: context.colorText,
                  fontSize: 16,
                  fontWeight: FontWeight.w500),
              cursorColor: AppColors.primary,
              decoration: const InputDecoration(hintText: '0,00'),
            ),
            const SizedBox(height: 20),

            Text(l.categoryLabel,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: context.colorText)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final selected = _selectedCategory == cat;
                final emoji = _categoryEmojis[cat] ?? '💳';
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedCategory = cat),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary
                          : context.colorCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? Colors.transparent
                            : context.colorTextMuted.withAlpha(100),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(emoji,
                            style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 4),
                        Text(
                          l.expenseCategoryLabel(cat),
                          style: TextStyle(
                              fontSize: 13,
                              color: selected
                                  ? Colors.white
                                  : context.colorTextMuted),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            Text(l.dateLabel,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: context.colorText)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.colorCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: context.colorBorder),
                ),
                child: Row(children: [
                  const Icon(Icons.calendar_today,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(_formatDate(_selectedDate, l),
                      style: TextStyle(
                          color: context.colorText, fontSize: 14)),
                ]),
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(l.saveExpenseButton,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
