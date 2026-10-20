import 'eye_evaluation.dart';
import 'eye_boxes.dart';

/// Valutazione salvata di un paziente.
class Evaluation {
  const Evaluation({
    required this.id,
    required this.date,
    required this.od,
    required this.os,
    this.photoPath,
    this.eyeBoxes,
    this.doloreRetrobulbare,
    this.doloreMovimentiOculari,
  });

  final String id;
  final DateTime date;

  /// Percorso locale della foto. Con un backend diventerà il path nello storage.
  final String? photoPath;
  final EyeBoxes? eyeBoxes;
  final EyeEvaluation od;
  final EyeEvaluation os;
  final bool? doloreRetrobulbare;
  final bool? doloreMovimentiOculari;

  EyeEvaluation eye(Eye e) => e == Eye.od ? od : os;

  // Mappa per la tabella `evaluations`. `patient_id` lo aggiunge il repository.
  Map<String, dynamic> toMap() => {
        'id': id,
        'date': date.toUtc().toIso8601String(),
        'photo_path': photoPath,
        'od': od.toMap(),
        'os': os.toMap(),
        'dolore_retrobulbare': doloreRetrobulbare,
        'dolore_movimenti_oculari': doloreMovimentiOculari,
      };

  factory Evaluation.fromMap(Map<String, dynamic> m) => Evaluation(
        id: m['id'] as String,
        date: DateTime.parse(m['date'] as String).toLocal(),
        photoPath: m['photo_path'] as String?,
        od: EyeEvaluation.fromMap(m['od'] as Map<String, dynamic>),
        os: EyeEvaluation.fromMap(m['os'] as Map<String, dynamic>),
        doloreRetrobulbare: m['dolore_retrobulbare'] as bool?,
        doloreMovimentiOculari: m['dolore_movimenti_oculari'] as bool?,
      );
}
