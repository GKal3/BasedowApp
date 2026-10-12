import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.message, this.icon});

  final String message;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 56, color: AppColors.muted2),
            const SizedBox(height: 14),
          ],
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppText.t(14, c: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
