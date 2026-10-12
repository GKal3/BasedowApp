import 'eye_evaluation.dart';

/// Valutazione salvata di un paziente.
class Evaluation {
  const Evaluation({
    required this.id,
    required this.date,
    required this.od,
    required this.os,
    this.photoPath,
    this.doloreRetrobulbare,
    this.doloreMovimentiOculari,
  });

  final String id;
  final DateTime date;

  /// Percorso locale della foto. Con un backend diventerà il path nello storage.
  final String? photoPath;
  final EyeEvaluation od;
  final EyeEvaluation os;
  final bool? doloreRetrobulbare;
  final bool? doloreMovimentiOculari;

  EyeEvaluation eye(Eye e) => e == Eye.od ? od : os;
}
