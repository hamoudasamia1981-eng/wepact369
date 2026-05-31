import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../config/app_localizations.dart';
import '../theme/app_colors.dart';

class PactDetailScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;
  final String? currentUid;
  final String? partnerFirstName;

  const PactDetailScreen({
    super.key,
    required this.docId,
    required this.data,
    required this.currentUid,
    required this.partnerFirstName,
  });

  @override
  State<PactDetailScreen> createState() => _PactDetailScreenState();
}

class _PactDetailScreenState extends State<PactDetailScreen> {
  bool _isUpdating = false;

  Future<void> _updateStatus(String status) async {
    setState(() => _isUpdating = true);
    try {
      await FirebaseFirestore.instance
          .collection('pacts')
          .doc(widget.docId)
          .update({'status': status});
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final data = widget.data;
    final title = data['title'] as String? ?? '';
    final description = data['description'] as String? ?? '';
    final category = data['category'] as String? ?? '📋';
    final type = data['type'] as String? ?? 'task';
    final status = data['status'] as String? ?? 'pending';
    final createdBy = data['createdBy'] as String? ?? '';
    final dueDate = data['dueDate'] as Timestamp?;

    final proposerName = createdBy == widget.currentUid
        ? l.youLabel
        : (widget.partnerFirstName ?? l.partnerLabel);
    final bgColor =
        type == 'initiative' ? AppColors.orangeLight : AppColors.purpleLight;
    final isFromPartner = createdBy != widget.currentUid;

    String dateText = '';
    String timeText = '';
    if (dueDate != null) {
      final d = dueDate.toDate();
      dateText = '${d.day} ${l.monthsShort[d.month - 1]} ${d.year}';
      if (d.hour != 0 || d.minute != 0) {
        timeText =
            '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
      }
    }

    Widget statusBadge;
    switch (status) {
      case 'accepted':
        statusBadge = _badge(
            l.acceptedBadge, AppColors.success, const Color(0xFFD1FAE5));
        break;
      case 'declined':
        statusBadge = _badge(
            l.declinedBadge, AppColors.error, const Color(0xFFFEE2E2));
        break;
      default:
        statusBadge =
            _badge(l.pendingBadge, AppColors.secondary, AppColors.orangeLight);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: const BackButton(color: AppColors.textDark),
        title: Text(
          type == 'initiative' ? l.initiativeType : l.taskType,
          style: const TextStyle(
              color: AppColors.textDark, fontWeight: FontWeight.w600),
        ),
        actions: const [
          LangToggleButton(dark: false),
          SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                      child:
                          Text(category, style: const TextStyle(fontSize: 28))),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark)),
                      const SizedBox(height: 6),
                      statusBadge,
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            _infoRow(Icons.person, l.proposedBy(proposerName), AppColors.primary),

            if (dateText.isNotEmpty) ...[
              const SizedBox(height: 12),
              _infoRow(Icons.calendar_today, dateText, AppColors.textDark),
            ],

            if (timeText.isNotEmpty) ...[
              const SizedBox(height: 12),
              _infoRow(Icons.access_time, timeText, AppColors.textDark),
            ],

            if (description.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(l.descriptionLabel,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppColors.textGrey.withAlpha(76)),
                ),
                child: Text(description,
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.textDark)),
              ),
            ],

            if (status == 'pending' && isFromPartner) ...[
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isUpdating ? null : () => _updateStatus('declined'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(l.declineButton),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          _isUpdating ? null : () => _updateStatus('accepted'),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isUpdating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Text(l.acceptButton),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color textColor, Color bgColor) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 12,
                color: textColor,
                fontWeight: FontWeight.bold)),
      );

  Widget _infoRow(IconData icon, String text, Color color) => Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(fontSize: 14, color: color)),
          ),
        ],
      );
}
