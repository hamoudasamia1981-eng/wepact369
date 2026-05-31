import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class PactsScreen extends StatelessWidget {
  const PactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pacts')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.handshake, size: 64, color: AppColors.textGrey),
            SizedBox(height: 16),
            Text(
              'Pacts coming soon',
              style: TextStyle(color: AppColors.textGrey, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
