import 'package:flutter/material.dart';

import '../../../models/evaluation.dart';
import '../../../models/eye_evaluation.dart';
import '../../../shared/formatters.dart';
import '../../../shared/widgets/app_photo.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';

/// Card di una valutazione salvata nella scheda paziente (`.eval-card`).
class EvalCard extends StatelessWidget {
  const EvalCard({
    super.key,
    required this.evaluation,
    required this.number,
    this.onDelete,
  });

  final Evaluation evaluation;

  /// Numero progressivo mostrato nel badge ("Valutazione 2").
  final int number;

  /// Se presente, mostra il pulsante di eliminazione.
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final e = evaluation;
    final hasSymptoms =
        e.doloreRetrobulbare != null || e.doloreMovimentiOculari != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.evalCardTop, AppColors.evalCardBottom],
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: const Color(0x14022638), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F023047),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  formatDate(e.date),
                  style: AppText.t(13.5, w: FontWeight.w800),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xB3FFFFFF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Valutazione $number',
                  style: AppText.t(11, w: FontWeight.w800),
                ),
              ),
              if (onDelete != null) ...[
                const SizedBox(width: 6),
                InkWell(
                  onTap: onDelete,
                  customBorder: const CircleBorder(),
                  child: const Padding(
                    padding: EdgeInsets.all(5),
                    child: Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: AppColors.danger,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.small),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0x1F023047), width: 1.5),
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: AppPhoto(
                path: e.photoPath,
                width: double.infinity,
                height: 140,
              ),
            ),
          ),
          const SizedBox(height: 10),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _EyeBlock(label: 'OD', eye: e.od)),
                const SizedBox(width: 10),
                Expanded(child: _EyeBlock(label: 'OS', eye: e.os)),
              ],
            ),
          ),
          if (hasSymptoms) ...[
            const SizedBox(height: 10),
            _InfoBox(
              label: 'SINTOMI',
              lines: [
                if (e.doloreRetrobulbare != null)
                  ('Dolore retrobulbare', formatYesNo(e.doloreRetrobulbare)),
                if (e.doloreMovimentiOculari != null)
                  ('Dolore nei movimenti', formatYesNo(e.doloreMovimentiOculari)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _EyeBlock extends StatelessWidget {
  const _EyeBlock({required this.label, required this.eye});

  final String label;
  final EyeEvaluation eye;

  @override
  Widget build(BuildContext context) {
    return _InfoBox(
      label: label,
      lines: [
        ('Iperemia', formatGrade(eye.iperemiaCongiuntivale)),
        ('Chemosi', formatGrade(eye.chemosiCongiuntivale)),
        ('Edema caruncola', formatYesNo(eye.edemaCaruncola)),
        ('Iperemia palp.', formatGrade(eye.iperemiaPalpebrale)),
        ('Edema palp.', formatGrade(eye.edemaPalpebrale)),
        ('MRD1', formatMm(eye.mrd1)),
        ('MRD2', formatMm(eye.mrd2)),
        ('Rima', formatMm(eye.rima)),
      ],
    );
  }
}

/// Riquadro semitrasparente con etichetta e righe "chiave: valore".
class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.label, required this.lines});

  final String label;
  final List<(String, String)> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x6BFFFFFF),
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(color: const Color(0x14023047), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppText.t(
              11.5,
              w: FontWeight.w800,
              c: const Color(0xB8023047),
              ls: 0.4,
            ),
          ),
          const SizedBox(height: 6),
          for (final (key, value) in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text.rich(
                TextSpan(
                  style: AppText.t(11.5, w: FontWeight.w700, c: AppColors.muted, h: 1.35),
                  children: [
                    TextSpan(text: '$key: '),
                    TextSpan(
                      text: value,
                      style: AppText.t(11.5, w: FontWeight.w800, h: 1.35),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}