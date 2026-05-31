import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'add_expense_screen.dart';
import 'add_initiative_screen.dart';
import 'add_task_screen.dart';
import 'calendar_screen.dart';
import 'expenses_screen.dart';
import 'home_screen.dart';
import 'pacts_screen.dart';
import 'profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(
        onTabChange: (index) => setState(() => _currentIndex = index),
      ),
      const ExpensesScreen(),
      const PactsScreen(),
      const CalendarScreen(),
      const ProfileScreen(),
    ];
  }

  void _showCreationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
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
            const SizedBox(height: 16),
            const Text(
              'Que voulez-vous créer ?',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark),
            ),
            const SizedBox(height: 24),

            // Expense card
            GestureDetector(
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AddExpenseScreen()),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.orangeLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.secondary, width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.credit_card,
                          color: AppColors.secondary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Dépense',
                              style: TextStyle(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                          Text('Ajouter une dépense partagée',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textGrey)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        color: AppColors.secondary),
                  ],
                ),
              ),
            ),

            // Task card
            GestureDetector(
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AddTaskScreen()),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.purpleLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.primary, width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.assignment,
                          color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tâche',
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                          Text('À organiser ou à faire',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textGrey)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        color: AppColors.primary),
                  ],
                ),
              ),
            ),

            // Initiative card
            GestureDetector(
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AddInitiativeScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.orangeLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.secondary, width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.stars,
                          color: AppColors.secondary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Initiative',
                              style: TextStyle(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                          Text('Une idée à partager',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textGrey)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        color: AppColors.secondary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreationSheet,
        backgroundColor: AppColors.primary,
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        color: AppColors.white,
        elevation: 8,
        padding: EdgeInsets.zero,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              _NavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: 'Accueil',
                  index: 0,
                  current: _currentIndex,
                  onTap: (i) => setState(() => _currentIndex = i)),
              _NavItem(
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long,
                  label: 'Dépenses',
                  index: 1,
                  current: _currentIndex,
                  onTap: (i) => setState(() => _currentIndex = i)),
              const SizedBox(width: 60), // FAB gap
              _NavItem(
                  icon: Icons.calendar_today_outlined,
                  activeIcon: Icons.calendar_today,
                  label: 'Calendrier',
                  index: 3,
                  current: _currentIndex,
                  onTap: (i) => setState(() => _currentIndex = i)),
              _NavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Profil',
                  index: 4,
                  current: _currentIndex,
                  onTap: (i) => setState(() => _currentIndex = i)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int current;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = current == index;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? activeIcon : icon,
              color:
                  selected ? AppColors.primary : AppColors.textGrey,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color:
                    selected ? AppColors.primary : AppColors.textGrey,
                fontWeight: selected
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
