import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});
  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  static const _categories = <String, String>{
    'Maison': '🏠',
    'Courses': '🛒',
    'Enfants': '👶',
    'Loisirs': '🎭',
    'Santé': '💊',
    'Autre': '💳',
  };
  static const _monthsFr = [
    'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
  ];

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedCategory = 'Maison';
  DateTime? _selectedDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  String _formatDate(DateTime d) =>
      '${d.day} ${_monthsFr[d.month - 1]} ${d.year}';

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showError('Veuillez saisir un titre.');
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users').doc(user.uid).get();
      final partnerId = userDoc.data()?['partnerId'] as String?;
      if (partnerId == null) {
        _showError('Liez d\'abord votre compte à un partenaire.');
        setState(() => _isLoading = false);
        return;
      }
      final ids = [user.uid, partnerId]..sort();
      await FirebaseFirestore.instance.collection('pacts').add({
        'coupleId': ids.join('_'),
        'createdBy': user.uid,
        'title': title,
        'description': _descController.text.trim(),
        'category': _categories[_selectedCategory] ?? '💳',
        'type': 'task',
        'status': 'pending',
        'dueDate': _selectedDate != null
            ? Timestamp.fromDate(_selectedDate!)
            : null,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: const BackButton(color: AppColors.textDark),
        title: const Text('Nouvelle tâche',
            style: TextStyle(
                color: AppColors.textDark, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Category chips
            const Text('Catégorie',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.entries.map((e) {
                  final sel = _selectedCategory == e.key;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _selectedCategory = e.key),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel ? AppColors.primary : AppColors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: sel
                                ? Colors.transparent
                                : AppColors.textGrey.withAlpha(100),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(e.value,
                                style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 4),
                            Text(e.key,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: sel
                                        ? Colors.white
                                        : AppColors.textGrey)),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            const Text('Titre de la tâche',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration:
                  const InputDecoration(hintText: 'ex. Faire les courses'),
            ),
            const SizedBox(height: 20),

            const Text('Description (optionnel)',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark)),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              maxLines: 4,
              decoration: const InputDecoration(
                  hintText: 'Ajoutez des détails...'),
            ),
            const SizedBox(height: 20),

            const Text('Date limite',
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
                  Text(
                    _selectedDate != null
                        ? _formatDate(_selectedDate!)
                        : 'Choisir une date',
                    style: TextStyle(
                        color: _selectedDate != null
                            ? AppColors.textDark
                            : AppColors.textGrey,
                        fontSize: 14),
                  ),
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
                    : const Text('Proposer la tâche',
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
