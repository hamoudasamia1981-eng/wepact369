import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_localizations.dart';
import '../providers/language_provider.dart';
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

  final _pactsKey = GlobalKey<PactsScreenState>();
  final _expensesKey = GlobalKey<ExpensesScreenState>();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(
        onTabChange: (index) => setState(() => _currentIndex = index),
        onNavigateToPacts: _goToPactsTab,
        onNavigateToExpenses: _goToExpensesWithFilter,
      ),
      ExpensesScreen(key: _expensesKey),
      PactsScreen(key: _pactsKey),
      const CalendarScreen(),
      const ProfileScreen(),
    ];
  }

  void _goToPactsTab(int tabIndex) {
    setState(() => _currentIndex = 2);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pactsKey.currentState?.jumpToTab(tabIndex);
    });
  }

  void _goToExpensesWithFilter(String filter) {
    setState(() => _currentIndex = 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _expensesKey.currentState?.jumpToFilter(filter);
    });
  }

  void _showCreationSheet(BuildContext context) {
    final l = context.read<LanguageProvider>().l10n;
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
            Text(
              l.createWhat,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark),
            ),
            const SizedBox(height: 24),
            _SheetCard(
              color: AppColors.orangeLight,
              borderColor: AppColors.secondary,
              icon: Icons.credit_card,
              iconColor: AppColors.secondary,
              title: l.createExpenseLabel,
              subtitle: l.createExpenseSubtitle,
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AddExpenseScreen()));
              },
            ),
            const SizedBox(height: 12),
            _SheetCard(
              color: AppColors.purpleLight,
              borderColor: AppColors.primary,
              icon: Icons.assignment,
              iconColor: AppColors.primary,
              title: l.createTaskLabel,
              subtitle: l.createTaskSubtitle,
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AddTaskScreen()));
              },
            ),
            const SizedBox(height: 12),
            _SheetCard(
              color: AppColors.orangeLight,
              borderColor: AppColors.secondary,
              icon: Icons.stars,
              iconColor: AppColors.secondary,
              title: l.createInitiativeLabel,
              subtitle: l.createInitiativeSubtitle,
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const AddInitiativeScreen()));
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    final navItems = [
      BottomNavigationBarItem(
        icon: const Icon(Icons.home_outlined),
        activeIcon: const Icon(Icons.home),
        label: l.navHome,
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.receipt_long_outlined),
        activeIcon: const Icon(Icons.receipt_long),
        label: l.navExpenses,
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.handshake_outlined),
        activeIcon: const Icon(Icons.handshake),
        label: l.navPacts,
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.calendar_today_outlined),
        activeIcon: const Icon(Icons.calendar_today),
        label: l.navCalendar,
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.person_outline),
        activeIcon: const Icon(Icons.person),
        label: l.navProfile,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      floatingActionButton: Transform.translate(
        offset: const Offset(0, 6),
        child: SizedBox(
          width: 48,
          height: 48,
          child: FloatingActionButton(
            onPressed: () => _showCreationSheet(context),
            backgroundColor: AppColors.primary,
            elevation: 4,
            child: const Icon(Icons.add, color: Colors.white, size: 20),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textGrey,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.white,
        elevation: 8,
        iconSize: 24,
        selectedFontSize: 11,
        unselectedFontSize: 10,
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w400,
        ),
        items: navItems,
      ),
    );
  }
}

class _SheetCard extends StatelessWidget {
  final Color color;
  final Color borderColor;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SheetCard({
    required this.color,
    required this.borderColor,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: iconColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textGrey)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: iconColor),
          ],
        ),
      ),
    );
  }
}
