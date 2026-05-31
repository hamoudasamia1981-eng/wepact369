import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_localizations.dart';
import '../providers/language_provider.dart';
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

  String _formatDate(DateTime d, AppLocalizations l) =>
      '${d.day} ${l.monthsShort[d.month - 1]} ${d.year}';

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
    final l = context.read<LanguageProvider>().l10n;
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showError(l.enterTitle);
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
        _showError(l.linkPartnerFirst);
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
      if (mounted) _showError(l.saveError);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: const BackButton(color: AppColors.textDark),
        title: Text(l.newInitiativeTitle,
            style: const TextStyle(
                color: AppColors.textDark, fontWeight: FontWeight.w600)),
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
            // Category chips (orange style)
            Text(l.categoryLabel,
                style: const TextStyle(
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
                            Text(l.initiativeCategoryLabel(e.key),
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

            Text(l.initiativeTitleLabel,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w500),
              cursorColor: AppColors.primary,
              decoration: InputDecoration(hintText: l.initiativeHint),
            ),
            const SizedBox(height: 20),

            Text(l.descriptionLabel,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark)),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              maxLines: 4,
              style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w500),
              cursorColor: AppColors.primary,
              decoration:
                  InputDecoration(hintText: l.initiativeDescHint),
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
                      Text(l.dateLabel,
                          style: const TextStyle(
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
                                    ? _formatDate(_selectedDate!, l)
                                    : l.dateLabel,
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
                      Text(l.timeLabel,
                          style: const TextStyle(
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
                                    : l.timeLabel,
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

            Text(l.locationLabel,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark)),
            const SizedBox(height: 8),
            TextField(
              controller: _locationController,
              style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w500),
              cursorColor: AppColors.primary,
              decoration: InputDecoration(
                hintText: l.locationHint,
                prefixIcon: const Icon(Icons.location_on,
                    color: AppColors.secondary),
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
                      : Text(
                          l.proposeInitiativeButton,
                          style: const TextStyle(
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
