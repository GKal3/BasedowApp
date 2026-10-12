import 'package:flutter/material.dart';

import '../../../models/patient.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';

class PatientAvatar extends StatelessWidget {
  const PatientAvatar({super.key, required this.initials, this.size = 46});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.sky300,
        shape: BoxShape.circle,
      ),
      child: Text(
        initials,
        style: AppText.t(size >= 60 ? 22 : 16, w: FontWeight.w800),
      ),
    );
  }
}

/// Riga della lista pazienti (`.patient-card`).
class PatientCard extends StatelessWidget {
  const PatientCard({super.key, required this.patient, required this.onTap});

  final Patient patient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final n = patient.evaluations.length;
    final age = patient.age;
    final meta =
        '${age != null ? '$age anni · ' : ''}$n valutazion${n == 1 ? 'e' : 'i'}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.cardBorder, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                PatientAvatar(initials: patient.initials),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patient.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.t(15, w: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(meta, style: AppText.t(12.5, c: AppColors.muted)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, size: 24, color: AppColors.muted2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
