import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/eye_evaluation.dart';
import '../../router/app_routes.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/app_photo.dart';
import '../../shared/widgets/wizard_scaffold.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../patients/patients_controller.dart';
import 'evaluation_controller.dart';

/// Passo 4: riepilogo e salvataggio.
class SummaryScreen extends ConsumerStatefulWidget {
  const SummaryScreen({super.key, required this.patientId});

  final String patientId;

  @override
  ConsumerState<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends ConsumerState<SummaryScreen> {
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    final draft = ref.read(evaluationDraftProvider);
    await ref
        .read(patientsProvider.notifier)
        .addEvaluation(widget.patientId, draft.toEvaluation());
    if (!mounted) return;
    ref.read(savedBannerProvider.notifier).show();
    // `go` ricostruisce lo stack [dashboard, scheda paziente] e chiude il wizard.
    context.go(AppRoutes.patient(widget.patientId));
    ref.read(evaluationDraftProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(evaluationDraftProvider);
    final id = widget.patientId;

    return WizardScaffold(
      title: 'Riepilogo',
      step: 4,
      showNext: false,
      onBack: () => context.pop(),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            decoration: const BoxDecoration(
              color: AppColors.sky50,
              border: Border(bottom: BorderSide(color: Color(0x0F023047))),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 220),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.sky300, width: 1.5),
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: AppPhoto(
                  path: draft.photoPath,
                  width: double.infinity,
                  height: 220,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 16, bottom: 28),
              children: [
                for (final eye in Eye.values)
                  _SummarySection(
                    title: eye.label,
                    onEdit: () =>
                        context.push(AppRoutes.eye(id, eye, edit: true)),
                    rows: _eyeRows(draft.eye(eye)),
                  ),
                _SummarySection(
                  title: 'Sintomi',
                  onEdit: () => context.push(AppRoutes.symptoms(id, edit: true)),
                  rows: [
                    ('Dolore retrobulbare spontaneo', formatYesNo(draft.doloreRetrobulbare)),
                    ('Dolore nei movimenti oculari', formatYesNo(draft.doloreMovimentiOculari)),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: PrimaryButton(
                    label: 'Salva valutazione',
                    fontSize: 15.5,
                    onPressed: _save,
                    loading: _saving,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<(String, String)> _eyeRows(EyeEvaluation e) => [
        ('Iperemia congiuntivale', formatGrade(e.iperemiaCongiuntivale)),
        ('Chemosi congiuntivale', formatGrade(e.chemosiCongiuntivale)),
        ('Edema caruncola/plica', formatYesNo(e.edemaCaruncola)),
        ('Iperemia palpebrale', formatGrade(e.iperemiaPalpebrale)),
        ('Edema palpebrale', formatGrade(e.edemaPalpebrale)),
        ('MRD1', formatMm(e.mrd1)),
        ('MRD2', formatMm(e.mrd2)),
        ('Ampiezza rima palpebrale', formatMm(e.rima)),
      ];
}

/// Riquadro giallo chiaro con barra gialla a sinistra (`.section-retraction`).
class _SummarySection extends StatelessWidget {
  const _SummarySection({
    required this.title,
    required this.onEdit,
    required this.rows,
  });

  final String title;
  final VoidCallback onEdit;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.warningBorder, width: 1.5),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: AppColors.amber),
            Expanded(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: AppText.t(13, w: FontWeight.w800, c: const Color(0xB3023047)),
                        ),
                        GestureDetector(
                          onTap: onEdit,
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                            child: Text(
                              'Modifica',
                              style: AppText.t(12, w: FontWeight.w800, c: AppColors.orange),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  for (var i = 0; i < rows.length; i++)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      decoration: BoxDecoration(
                        border: i == rows.length - 1
                            ? null
                            : const Border(
                                bottom: BorderSide(color: Color(0x14023047)),
                              ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              rows[i].$1,
                              style: AppText.t(13.5, w: FontWeight.w700, c: AppColors.muted),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            rows[i].$2,
                            textAlign: TextAlign.right,
                            style: AppText.t(14.5, w: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
