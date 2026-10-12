import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_routes.dart';
import '../../shared/widgets/wizard_scaffold.dart';
import 'evaluation_controller.dart';
import 'widgets/selectors.dart';

/// Passo 3: sintomi riferiti dal paziente.
class SymptomsScreen extends ConsumerWidget {
  const SymptomsScreen({
    super.key,
    required this.patientId,
    this.editMode = false,
  });

  final String patientId;
  final bool editMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(evaluationDraftProvider);
    final ctrl = ref.read(evaluationDraftProvider.notifier);

    return WizardScaffold(
      title: 'Sintomi',
      step: 3,
      onBack: () => context.pop(),
      onNext: draft.symptomsComplete
          ? () {
              if (editMode) {
                context.pop();
              } else {
                context.push(AppRoutes.summary(patientId));
              }
            }
          : null,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EvalSection(
              title: 'Il paziente prova dolore retrobulbare spontaneo?',
              child: YesNoSelector(
                value: draft.doloreRetrobulbare,
                onChanged: ctrl.setDoloreRetrobulbare,
              ),
            ),
            EvalSection(
              title: 'Il paziente prova dolore nei movimenti oculari?',
              child: YesNoSelector(
                value: draft.doloreMovimentiOculari,
                onChanged: ctrl.setDoloreMovimentiOculari,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
