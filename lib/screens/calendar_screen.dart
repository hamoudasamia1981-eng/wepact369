import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  static const _dayHeaders = ['D', 'L', 'M', 'M', 'J', 'V', 'S'];
  static const _monthsFr = [
    'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
  ];
  static const _daysFrFull = [
    'Dimanche', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi',
  ];

  DateTime _focusedMonth = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  String? _coupleId;
  String? _partnerFirstName;
  String? _currentUid;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
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
      final partnerId =
          userDoc.data()?['partnerId'] as String?;
      if (partnerId == null) {
        setState(() => _isLoading = false);
        return;
      }
      final partnerDoc = await FirebaseFirestore.instance
          .collection('users').doc(partnerId).get();
      if (!mounted) return;
      final ids = [user.uid, partnerId]..sort();
      setState(() {
        _coupleId = ids.join('_');
        _partnerFirstName =
            partnerDoc.data()?['firstName'] as String? ?? 'Partenaire';
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _prevMonth() => setState(() {
        _focusedMonth =
            DateTime(_focusedMonth.year, _focusedMonth.month - 1);
      });

  void _nextMonth() => setState(() {
        _focusedMonth =
            DateTime(_focusedMonth.year, _focusedMonth.month + 1);
      });

  List<int?> _buildDays() {
    final first =
        DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final offset = first.weekday % 7; // Sunday=0
    final daysInMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    return [
      ...List<int?>.filled(offset, null),
      ...List.generate(daysInMonth, (i) => i + 1),
    ];
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _buildDayCell(
    int? day,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> pacts,
  ) {
    if (day == null) return const SizedBox(height: 48);

    final date =
        DateTime(_focusedMonth.year, _focusedMonth.month, day);
    final today = DateTime.now();
    final isToday = _isSameDay(date, today);
    final isSelected = _isSameDay(date, _selectedDay);

    final dayPacts = pacts.where((p) {
      final due = p.data()['dueDate'] as Timestamp?;
      if (due == null) return false;
      return _isSameDay(due.toDate(), date);
    }).toList();
    final hasTasks =
        dayPacts.any((p) => p.data()['type'] == 'task');
    final hasInit =
        dayPacts.any((p) => p.data()['type'] == 'initiative');

    return GestureDetector(
      onTap: () => setState(() => _selectedDay = date),
      child: SizedBox(
        height: 48,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color:
                    isToday ? AppColors.primary : Colors.transparent,
                shape: BoxShape.circle,
                border: isSelected && !isToday
                    ? Border.all(
                        color: AppColors.primary, width: 2)
                    : null,
              ),
              child: Center(
                child: Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isToday
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color:
                        isToday ? Colors.white : AppColors.textDark,
                  ),
                ),
              ),
            ),
            if (hasTasks || hasInit)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (hasTasks)
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 2),
                      decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle),
                    ),
                  if (hasInit)
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                          color: AppColors.secondary,
                          shape: BoxShape.circle),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPactCard(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final title = data['title'] as String? ?? '';
    final status = data['status'] as String? ?? 'pending';
    final createdBy = data['createdBy'] as String? ?? '';
    final type = data['type'] as String? ?? 'task';
    final category = data['category'] as String? ?? '📋';
    final bgColor = type == 'initiative'
        ? AppColors.orangeLight
        : AppColors.purpleLight;
    final proposerName = createdBy == _currentUid
        ? 'Vous'
        : (_partnerFirstName ?? 'Partenaire');

    Color badgeColor;
    String badgeText;
    switch (status) {
      case 'accepted':
        badgeColor = AppColors.success;
        badgeText = 'Accepté';
        break;
      case 'declined':
        badgeColor = AppColors.error;
        badgeText = 'Refusé';
        break;
      default:
        badgeColor = AppColors.secondary;
        badgeText = 'En attente';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 6,
              offset: Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: bgColor, borderRadius: BorderRadius.circular(10)),
            child: Center(
                child: Text(category,
                    style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark)),
                Text('Proposé par $proposerName',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.primary)),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: badgeColor.withAlpha(30),
                borderRadius: BorderRadius.circular(20)),
            child: Text(badgeText,
                style: TextStyle(
                    fontSize: 11,
                    color: badgeColor,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
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

    final firstOfMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastOfMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0, 23, 59, 59);
    final selectedDayLabel =
        '${_daysFrFull[_selectedDay.weekday % 7]} ${_selectedDay.day} '
        '${_monthsFr[_selectedDay.month - 1]}';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('Calendrier',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: AppColors.textDark)),
      ),
      body: _coupleId == null
          ? const Center(
              child: Text(
                'Connectez-vous à un partenaire pour voir le calendrier.',
                style: TextStyle(color: AppColors.textGrey),
                textAlign: TextAlign.center,
              ),
            )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('pacts')
                  .where('coupleId', isEqualTo: _coupleId)
                  .where('dueDate',
                      isGreaterThanOrEqualTo:
                          Timestamp.fromDate(firstOfMonth))
                  .where('dueDate',
                      isLessThanOrEqualTo:
                          Timestamp.fromDate(lastOfMonth))
                  .snapshots(),
              builder: (ctx, snap) {
                final allPacts = snap.data?.docs ?? [];
                final days = _buildDays();

                final selectedPacts = allPacts.where((p) {
                  final due =
                      p.data()['dueDate'] as Timestamp?;
                  if (due == null) return false;
                  return _isSameDay(due.toDate(), _selectedDay);
                }).toList();

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Month navigation
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            IconButton(
                                icon: const Icon(
                                    Icons.chevron_left),
                                onPressed: _prevMonth),
                            Expanded(
                              child: Center(
                                child: Text(
                                  '${_monthsFr[_focusedMonth.month - 1]} ${_focusedMonth.year}',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textDark),
                                ),
                              ),
                            ),
                            IconButton(
                                icon: const Icon(
                                    Icons.chevron_right),
                                onPressed: _nextMonth),
                          ],
                        ),
                      ),

                      // Day headers
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16),
                        child: Row(
                          children: _dayHeaders
                              .map((h) => Expanded(
                                    child: Center(
                                      child: Text(h,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight:
                                                  FontWeight.bold,
                                              color: AppColors
                                                  .textGrey)),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Calendar grid
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16),
                        child: Column(
                          children: List.generate(
                            (days.length / 7).ceil(),
                            (rowIdx) {
                              final start = rowIdx * 7;
                              final end = (start + 7)
                                  .clamp(0, days.length);
                              final row = days.sublist(start, end);
                              while (row.length < 7) { row.add(null); }
                              return Row(
                                children: row
                                    .map((d) => Expanded(
                                          child: _buildDayCell(
                                              d, allPacts),
                                        ))
                                    .toList(),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Legend
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Row(children: [
                              Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle)),
                              const SizedBox(width: 4),
                              const Text('Tâche',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textGrey)),
                            ]),
                            const SizedBox(width: 16),
                            Row(children: [
                              Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                      color: AppColors.secondary,
                                      shape: BoxShape.circle)),
                              const SizedBox(width: 4),
                              const Text('Initiative',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textGrey)),
                            ]),
                          ],
                        ),
                      ),

                      const Divider(height: 24),

                      // Selected day section
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  selectedDayLabel,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textDark),
                                ),
                                const Spacer(),
                                Text(
                                  '${selectedPacts.length} pact${selectedPacts.length != 1 ? 's' : ''}',
                                  style: const TextStyle(
                                      color: AppColors.textGrey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (selectedPacts.isEmpty)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                      vertical: 24),
                                  child: Text(
                                    'Aucun pacte ce jour',
                                    style: TextStyle(
                                        color: AppColors.textGrey),
                                  ),
                                ),
                              )
                            else
                              ...selectedPacts
                                  .map(_buildPactCard),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
