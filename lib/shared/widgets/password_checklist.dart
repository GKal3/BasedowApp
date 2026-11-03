import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../password_rules.dart';

/// Elenco dei requisiti che si spuntano man mano che si digita.
class PasswordChecklist extends StatelessWidget {
  const PasswordChecklist({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final r in passwordRules)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                children: [
                  Icon(
                    r.test(password)
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: 15,
                    color: r.test(password) ? AppColors.navy : AppColors.muted2,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      r.label,
                      style: AppText.t(
                        12,
                        w: r.test(password) ? FontWeight.w800 : FontWeight.w600,
                        c: r.test(password) ? AppColors.navy : AppColors.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}