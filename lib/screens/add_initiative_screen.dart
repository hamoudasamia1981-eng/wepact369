import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AddInitiativeScreen extends StatefulWidget {
  const AddInitiativeScreen({super.key});
  @override
  State<AddInitiativeScreen> createState() => _AddInitiativeScreenState();
}

class _AddInitiativeScreenState extends State<AddInitiativeScreen> {
  static const _categories = <String, String>{
    'Sortie': '❤️',
    'Voyage': '✈️',
    'Restaurant': '🍴',
    'Cinéma': '🎬',
    'Cadeau': '🎁',
    'Autre': '🎊',
  };
  static const _monthsFr = [
    'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
  ];

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();
  String _selectedCategory = 'Sortie';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationController.dispose();
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

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  String _formatDate(DateTime d) =>
      '${d.day} ${_monthsFr[d.month - 1]} ${d.year}';

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

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

      Timestamp? dueTs;
      if (_selectedDate != null) {
        final combined = DateTime(
          _selectedDate!.year, _selectedDate!.month, _selectedDate!.day,
          _selectedTime?.hour ?? 0, _selectedTime?.minute ?? 0,
        );
        dueTs = Timestamp.fromDate(combined);
      }

      await FirebaseFirestore.instance.collection('pacts').add({
        'coupleId': ids.join('_'),
        'createdBy': user.uid,
        'title': title,
        'description': _descController.text.trim(),
        'category': _categories[_selectedCategory] ?? '🎊',
        'type': 'initiative',
        'status': 'pending',
        'dueDate': dueTs,
        'location': _locationController.text.trim(),
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
        title: const Text('Nouvelle initiative',
            style: TextStyle(
                color: AppColors.textDark, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Category chips (orange style)
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
                          color: sel
                              ? AppColors.secondary
                              : AppColors.white,
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

            const Text('Titre de l\'initiative',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration:
                  const InputDecoration(hintText: 'ex. Dîner romantique'),
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
                  hintText: 'Décrivez votre idée...'),
            ),
            const SizedBox(height: 20),

            // Date + Time row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Date',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.textGrey.withAlpha(76)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.calendar_today,
                                color: AppColors.secondary, size: 18),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _selectedDate != null
                                    ? _formatDate(_selectedDate!)
                                    : 'Date',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: _selectedDate != null
                                        ? AppColors.textDark
                                        : AppColors.textGrey),
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Heure',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _pickTime,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.textGrey.withAlpha(76)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.access_time,
                                color: AppColors.secondary, size: 18),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _selectedTime != null
                                    ? _formatTime(_selectedTime!)
                                    : 'Heure',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: _selectedTime != null
                                        ? AppColors.textDark
                                        : AppColors.textGrey),
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            const Text('Lieu (optionnel)',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark)),
            const SizedBox(height: 8),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                hintText: 'ex. Restaurant Le Jardin',
                prefixIcon:
                    Icon(Icons.location_on, color: AppColors.secondary),
              ),
            ),
            const SizedBox(height: 32),

            // Orange gradient button
            GestureDetector(
              onTap: _isLoading ? null : _save,
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: _isLoading
                      ? const LinearGradient(colors: [
                          AppColors.textGrey,
                          AppColors.textGrey
                        ])
                      : const LinearGradient(
                          colors: [
                            Color(0xFFF59E0B),
                            Color(0xFFEF8C0A)
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text(
                          'Proposer l\'initiative',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
