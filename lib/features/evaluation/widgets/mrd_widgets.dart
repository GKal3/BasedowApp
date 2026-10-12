import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/eye_evaluation.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';

/// Blocco di inserimento MRD1 / MRD2 in millimetri (`.mrd-block`).
class MrdBlock extends StatelessWidget {
  const MrdBlock({
    super.key,
    required this.label,
    required this.normalTag,
    required this.controller,
    required this.onChanged,
  });

  final String label;
  final String normalTag;
  final TextEditingController controller;
  final ValueChanged<double?> onChanged;

  OutlineInputBorder _border(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.small),
        borderSide: BorderSide(color: c, width: 1.5),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.cardBorder, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.t(13.5, w: FontWeight.w800)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.sky300,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(normalTag, style: AppText.t(11.5, w: FontWeight.w700)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  style: AppText.t(18, w: FontWeight.w800),
                  onChanged: (text) {
                    final v = double.tryParse(text.replaceAll(',', '.'));
                    onChanged(v);
                  },
                  decoration: InputDecoration(
                    hintText: '0.0',
                    hintStyle: AppText.t(18, w: FontWeight.w800, c: AppColors.muted2),
                    filled: true,
                    fillColor: AppColors.white,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: _border(AppColors.cardBorder),
                    enabledBorder: _border(AppColors.cardBorder),
                    focusedBorder: _border(AppColors.sky300),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('mm', style: AppText.t(14, w: FontWeight.w700, c: AppColors.muted)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Riquadro blu con l'ampiezza della rima palpebrale (MRD1 + MRD2).
class RimaResult extends StatelessWidget {
  const RimaResult({super.key, required this.value});

  final double? value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ampiezza rima palpebrale (MRD1 + MRD2)',
                  style: AppText.t(13, w: FontWeight.w700, c: const Color(0xE6FFFFFF)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Valore normale: 9–10 mm',
                  style: AppText.t(11.5, w: FontWeight.w700, c: AppColors.amber),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            formatMm(value),
            style: AppText.t(26, w: FontWeight.w800, c: AppColors.white),
          ),
        ],
      ),
    );
  }
}
