import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/evaluation.dart';
import '../../models/eye_evaluation.dart';
import '../../shared/formatters.dart';

/// Bozza della valutazione in corso: vive per tutta la durata del wizard
/// (foto → occhi → sintomi → riepilogo) e viene azzerata a ogni nuova valutazione.
class EvaluationDraft {
  const EvaluationDraft({
    this.photoPath,
    this.od = const EyeEvaluation(),
    this.os = const EyeEvaluation(),
    this.doloreRetrobulbare,
    this.doloreMovimentiOculari,
  });

  /// null = nessuna foto; '' = "continua senza foto" (solo debug).
  final String? photoPath;
  final EyeEvaluation od;
  final EyeEvaluation os;
  final bool? doloreRetrobulbare;
  final bool? doloreMovimentiOculari;

  EyeEvaluation eye(Eye e) => e == Eye.od ? od : os;

  bool get symptomsComplete =>
      doloreRetrobulbare != null && doloreMovimentiOculari != null;

  EvaluationDraft copyWith({
    String? photoPath,
    EyeEvaluation? od,
    EyeEvaluation? os,
    bool? doloreRetrobulbare,
    bool? doloreMovimentiOculari,
  }) {
    return EvaluationDraft(
      photoPath: photoPath ?? this.photoPath,
      od: od ?? this.od,
      os: os ?? this.os,
      doloreRetrobulbare: doloreRetrobulbare ?? this.doloreRetrobulbare,
      doloreMovimentiOculari:
          doloreMovimentiOculari ?? this.doloreMovimentiOculari,
    );
  }

  Evaluation toEvaluation() => Evaluation(
        id: 'e_${newId()}',
        date: DateTime.now(),
        photoPath: photoPath,
        od: od,
        os: os,
        doloreRetrobulbare: doloreRetrobulbare,
        doloreMovimentiOculari: doloreMovimentiOculari,
      );
}

class EvaluationDraftController extends Notifier<EvaluationDraft> {
  @override
  EvaluationDraft build() => const EvaluationDraft();

  void reset() => state = const EvaluationDraft();

  void setPhoto(String path) => state = state.copyWith(photoPath: path);

  void _setEye(Eye e, EyeEvaluation value) {
    state = e == Eye.od ? state.copyWith(od: value) : state.copyWith(os: value);
  }

  void setGrade(Eye e, GradeField field, int value) =>
      _setEye(e, state.eye(e).withGrade(field, value));

  void setEdemaCaruncola(Eye e, bool value) =>
      _setEye(e, state.eye(e).withEdemaCaruncola(value));

  void setMrd1(Eye e, double? value) =>
      _setEye(e, state.eye(e).withMrd1(value));

  void setMrd2(Eye e, double? value) =>
      _setEye(e, state.eye(e).withMrd2(value));

  void setDoloreRetrobulbare(bool v) =>
      state = state.copyWith(doloreRetrobulbare: v);

  void setDoloreMovimentiOculari(bool v) =>
      state = state.copyWith(doloreMovimentiOculari: v);
}

final evaluationDraftProvider =
    NotifierProvider<EvaluationDraftController, EvaluationDraft>(
  EvaluationDraftController.new,
);
