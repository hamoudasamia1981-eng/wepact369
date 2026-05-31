import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 64, color: AppColors.textGrey),
            SizedBox(height: 16),
            Text(
              'Calendar coming soon',
              style: TextStyle(color: AppColors.textGrey, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
