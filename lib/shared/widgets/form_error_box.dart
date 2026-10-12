import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

/// Riquadro rosso di errore sopra i form. Non occupa spazio se [message] è null.
class FormErrorBox extends StatelessWidget {
  const FormErrorBox({super.key, required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x1AD9534F),
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(color: const Color(0x4DD9534F), width: 1.5),
      ),
      child: Text(
        message!,
        style: AppText.t(13, w: FontWeight.w700, c: AppColors.danger),
      ),
    );
  }
}
