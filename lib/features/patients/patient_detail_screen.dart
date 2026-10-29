import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_routes.dart';
import '../../shared/formatters.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/bottom_action.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/navy_app_bar.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../evaluation/evaluation_controller.dart';
import 'patients_controller.dart';
import 'widgets/eval_card.dart';
import 'widgets/patient_card.dart';
import '../../models/evaluation.dart';

class PatientDetailScreen extends ConsumerWidget {
  const PatientDetailScreen({super.key, required this.patientId});

  final String patientId;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimina paziente'),
        content: const Text(
          'Eliminare questo paziente e tutte le sue valutazioni?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Elimina',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    // Prendo il controller prima di navigare: dopo `go` il widget è smontato.
    final ctrl = ref.read(patientsProvider.notifier);
    if (context.mounted) context.go(AppRoutes.patients);
    await ctrl.remove(patientId);
  }

  Future<void> _confirmDeleteEvaluation(
    BuildContext context,
    WidgetRef ref,
    Evaluation e,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimina valutazione'),
        content: Text(
          'Eliminare la valutazione del ${formatDate(e.date)}? '
          'L’operazione non si può annullare.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Elimina',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref
          .read(patientsProvider.notifier)
          .removeEvaluation(patientId, e.id);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Eliminazione non riuscita. Riprova.')),
        );
      }
    }
  }

  // true se si può procedere con una nuova valutazione.
  // Se oggi esiste già una valutazione chiede conferma; con "No" ritorna false.
  Future<bool> _confirmOverwriteToday(
    BuildContext context,
    bool hasEvaluationToday,
  ) async {
    if (!hasEvaluationToday) return true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Valutazione già presente'),
        content: const Text(
          'Hai già acquisito dati per oggi. '
          'Vuoi sovrascriverli con una nuova valutazione?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sì'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patient = ref.watch(patientProvider(patientId));
    final savedBanner = ref.watch(savedBannerProvider);

    if (patient == null) {
      return Scaffold(
        appBar: NavyAppBar(
          title: 'Scheda paziente',
          onBack: () => context.pop(),
        ),
        body: const Center(child: EmptyState(message: 'Paziente non trovato.')),
      );
    }

    final evals = [...patient.evaluations]
      ..sort((a, b) => b.date.compareTo(a.date));
    final age = patient.age;

    return Scaffold(
      appBar: NavyAppBar(
        title: 'Scheda paziente',
        onBack: () => context.pop(),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.topCenter,
                  child: savedBanner
                      ? Container(
                          width: double.infinity,
                          margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.sky300,
                            borderRadius: BorderRadius.circular(AppRadius.small),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check, size: 18, color: AppColors.navy),
                              const SizedBox(width: 8),
                              Text(
                                'Salvataggio effettuato',
                                style: AppText.t(13.5, w: FontWeight.w800),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox(width: double.infinity),
                ),
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(top: savedBanner ? 14 : 0),
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                  decoration: const BoxDecoration(
                    color: AppColors.card,
                    border: Border(
                      top: BorderSide(color: AppColors.cardBorder, width: 1.5),
                      bottom: BorderSide(color: AppColors.cardBorder, width: 1.5),
                    ),
                  ),
                  child: Column(
                    children: [
                      PatientAvatar(initials: patient.initials, size: 64),
                      const SizedBox(height: 12),
                      Text(
                        patient.fullName,
                        textAlign: TextAlign.center,
                        style: AppText.t(19, w: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        patient.dataNascita == null
                            ? 'Data di nascita non specificata'
                            : 'Nato/a il ${formatDate(patient.dataNascita)}'
                                '${age != null ? ' · $age anni' : ''}',
                        style: AppText.t(13, c: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlineActionButton(
                          label: 'Modifica dati',
                          onPressed: () =>
                              context.push(AppRoutes.editPatient(patientId)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlineActionButton(
                          label: 'Elimina paziente',
                          danger: true,
                          onPressed: () => _confirmDelete(context, ref),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
                  child: Text(
                    'VALUTAZIONI REGISTRATE',
                    style: AppText.t(11.5, w: FontWeight.w800, c: AppColors.muted, ls: 0.6),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: evals.isEmpty
                      ? const EmptyState(
                          message: 'Nessuna valutazione registrata per questo paziente.',
                        )
                      : Column(
                          children: [
                            for (var i = 0; i < evals.length; i++)
                              EvalCard(
                                evaluation: evals[i],
                                number: evals.length - i,
                                onDelete: () => _confirmDeleteEvaluation(context, ref, evals[i]),
                              ),
                          ],
                        ),
                ),
              ],
            ),
          ),
          BottomAction(
            child: NavyButton(
              label: 'Nuova valutazione',
              onPressed: () async {
                final today = DateTime.now();
                final todayEvaluations = patient.evaluations
                    .where((evaluation) => evaluation.isOnDay(today));
                final existingEvaluation =
                    todayEvaluations.isEmpty ? null : todayEvaluations.first;
                if (!await _confirmOverwriteToday(
                  context,
                  existingEvaluation != null,
                )) {
                  return;
                }
                if (!context.mounted) return;
                ref.read(evaluationDraftProvider.notifier).reset(
                      replacingEvaluationId: existingEvaluation?.id,
                    );
                context.push(AppRoutes.camera(patientId));
              },
            ),
          ),
        ],
      ),
    );
  }
}