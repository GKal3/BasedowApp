import 'package:flutter/material.dart';

import '../../../models/eye_evaluation.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';

/// Titolo di sezione + contenuto (`.eval-section`).
class EvalSection extends StatelessWidget {
  const EvalSection({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.t(17, w: FontWeight.w700)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// Divisore con testo al centro (`.section-divider`).
class SectionDivider extends StatelessWidget {
  const SectionDivider({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    const line = Expanded(
      child: Divider(height: 1.5, thickness: 1.5, color: AppColors.divider),
    );
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 22),
      child: Row(
        children: [
          line,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppText.t(13.5, w: FontWeight.w700, c: AppColors.muted),
            ),
          ),
          line,
        ],
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.selected,
    required this.onTap,
    required this.padding,
    required this.child,
  });

  final bool selected;
  final VoidCallback onTap;
  final EdgeInsets padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: selected ? AppColors.sky300 : AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: selected ? AppColors.sky300 : AppColors.cardBorder,
            width: 1.5,
          ),
        ),
        child: child,
      ),
    );
  }
}

/// Griglia 2×2 con i gradi 0–3 (Assente / Lieve / Moderata / Severa).
class GradeSelector extends StatelessWidget {
  const GradeSelector({super.key, required this.value, required this.onChanged});

  final int? value;
  final ValueChanged<int> onChanged;

  Widget _card(int i) {
    final selected = value == i;
    return Expanded(
      child: _ChoiceCard(
        selected: selected,
        onTap: () => onChanged(i),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
        child: Column(
          children: [
            Text('$i', style: AppText.t(27, w: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
              gradeLabels[i],
              style: AppText.t(
                12.5,
                w: FontWeight.w700,
                c: selected ? AppColors.navy : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(children: [_card(0), const SizedBox(width: 12), _card(1)]),
        const SizedBox(height: 12),
        Row(children: [_card(2), const SizedBox(width: 12), _card(3)]),
      ],
    );
  }
}

/// Due schede grandi "Sì" / "No".
class YesNoSelector extends StatelessWidget {
  const YesNoSelector({super.key, required this.value, required this.onChanged});

  final bool? value;
  final ValueChanged<bool> onChanged;

  Widget _card(String label, bool v) {
    return Expanded(
      child: _ChoiceCard(
        selected: value == v,
        onTap: () => onChanged(v),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        child: Center(child: Text(label, style: AppText.t(22, w: FontWeight.w800))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [_card('Sì', true), const SizedBox(width: 12), _card('No', false)],
    );
  }
}
