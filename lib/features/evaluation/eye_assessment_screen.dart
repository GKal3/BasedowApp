import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/eye_evaluation.dart';
import '../../router/app_routes.dart';
import '../../shared/widgets/wizard_scaffold.dart';
import 'evaluation_controller.dart';
import 'widgets/eye_photo.dart';
import 'widgets/mrd_widgets.dart';
import 'widgets/selectors.dart';

/// Passo 2: valutazione clinica di un occhio. Si usa due volte: prima OD, poi OS.
/// Con [editMode] (arrivo dal riepilogo) "Avanti" torna al riepilogo.
class EyeAssessmentScreen extends ConsumerStatefulWidget {
  const EyeAssessmentScreen({
    super.key,
    required this.patientId,
    required this.eye,
    this.editMode = false,
  });

  final String patientId;
  final Eye eye;
  final bool editMode;

  @override
  ConsumerState<EyeAssessmentScreen> createState() =>
      _EyeAssessmentScreenState();
}

class _EyeAssessmentScreenState extends ConsumerState<EyeAssessmentScreen> {
  late final TextEditingController _mrd1;
  late final TextEditingController _mrd2;

  @override
  void initState() {
    super.initState();
    final data = ref.read(evaluationDraftProvider).eye(widget.eye);
    _mrd1 = TextEditingController(text: data.mrd1?.toString() ?? '');
    _mrd2 = TextEditingController(text: data.mrd2?.toString() ?? '');
  }

  @override
  void dispose() {
    _mrd1.dispose();
    _mrd2.dispose();
    super.dispose();
  }

  void _next() {
    if (widget.editMode) {
      context.pop();
    } else if (widget.eye == Eye.od) {
      context.push(AppRoutes.eye(widget.patientId, Eye.os));
    } else {
      context.push(AppRoutes.symptoms(widget.patientId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final eye = widget.eye;
    final draft = ref.watch(evaluationDraftProvider);
    final data = draft.eye(eye);
    final ctrl = ref.read(evaluationDraftProvider.notifier);
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    Widget grade(String title, GradeField field) => EvalSection(
          title: title,
          child: GradeSelector(
            value: data.grade(field),
            onChanged: (v) => ctrl.setGrade(eye, field, v),
          ),
        );

    return WizardScaffold(
      title: eye == Eye.od
          ? 'Valutazione occhio destro'
          : 'Valutazione occhio sinistro',
      step: 2,
      onBack: () => context.pop(),
      onNext: data.isComplete ? _next : null,
      child: Column(
        children: [
          // Foto fissa in alto: scorrono solo i parametri.
          // Con la tastiera aperta la nascondo per lasciare spazio ai campi MRD.
          if (!keyboardOpen) PhotoFixedHeader(path: draft.photoPath, eye: eye, boxes: draft.eyeBoxes),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionDivider(label: eye.label),
                  grade('Iperemia congiuntivale', GradeField.iperemiaCongiuntivale),
                  grade('Chemosi congiuntivale', GradeField.chemosiCongiuntivale),
                  EvalSection(
                    title: 'Edema caruncola e plica',
                    child: YesNoSelector(
                      value: data.edemaCaruncola,
                      onChanged: (v) => ctrl.setEdemaCaruncola(eye, v),
                    ),
                  ),
                  grade('Iperemia palpebrale', GradeField.iperemiaPalpebrale),
                  grade('Edema palpebrale', GradeField.edemaPalpebrale),
                  EvalSection(
                    title: 'Retrazione palpebrale',
                    child: Column(
                      children: [
                        MrdBlock(
                          label: 'MRD1 — margine superiore',
                          normalTag: 'Valore normale: 4–5 mm',
                          controller: _mrd1,
                          onChanged: (v) => ctrl.setMrd1(eye, v),
                        ),
                        MrdBlock(
                          label: 'MRD2 — margine inferiore',
                          normalTag: 'Valore normale: 5 mm',
                          controller: _mrd2,
                          onChanged: (v) => ctrl.setMrd2(eye, v),
                        ),
                        RimaResult(value: data.rima),
                      ],
                    ),
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
