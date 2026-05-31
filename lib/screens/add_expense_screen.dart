import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

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
  static const _monthsFr = [
    'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
  ];

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

  String _formatDate(DateTime d) =>
      '${d.day} ${_monthsFr[d.month - 1]} ${d.year}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showError('Veuillez saisir un titre.');
      return;
    }
    final amountText =
        _amountController.text.trim().replaceAll(',', '.');
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      _showError('Veuillez saisir un montant valide.');
      return;
    }
    if (_coupleId == null) {
      _showError('Liez d\'abord votre compte à un partenaire.');
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
      if (mounted) _showError('Erreur lors de l\'enregistrement.');
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: const BackButton(color: AppColors.textDark),
        title: const Text(
          'Nouvelle dépense',
          style: TextStyle(
              color: AppColors.textDark, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Titre',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                  hintText: 'ex. Courses du samedi'),
            ),
            const SizedBox(height: 20),

            Text('Montant ($_currency)',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark)),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true),
              decoration: const InputDecoration(hintText: '0,00'),
            ),
            const SizedBox(height: 20),

            const Text('Catégorie',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark)),
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
                          : AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? Colors.transparent
                            : AppColors.textGrey.withAlpha(100),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(emoji,
                            style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 4),
                        Text(
                          cat,
                          style: TextStyle(
                              fontSize: 13,
                              color: selected
                                  ? Colors.white
                                  : AppColors.textGrey),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            const Text('Date',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.textGrey.withAlpha(76)),
                ),
                child: Row(children: [
                  const Icon(Icons.calendar_today,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(_formatDate(_selectedDate),
                      style: const TextStyle(
                          color: AppColors.textDark, fontSize: 14)),
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
                    : const Text('Enregistrer la dépense',
                        style: TextStyle(
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
