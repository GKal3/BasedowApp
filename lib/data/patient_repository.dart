import '../models/evaluation.dart';
import '../models/patient.dart';

/// Contratto di accesso ai pazienti. Ogni medico vede solo i propri (ownerId).
abstract class PatientRepository {
  Future<List<Patient>> list(String ownerId);
  Future<void> upsert(String ownerId, Patient patient);
  Future<void> delete(String ownerId, String patientId);
  Future<void> addEvaluation(
    String ownerId,
    String patientId,
    Evaluation evaluation,
  );
  Future<void> deleteEvaluation(
    String ownerId,
    String patientId,
    String evaluationId,
  );
}

/// Implementazione in RAM: i dati si perdono alla chiusura dell'app.
/// Non è usata in produzione (vedi `providers.dart`), ma serve per provare
/// l'interfaccia senza rete e per i test.
class InMemoryPatientRepository implements PatientRepository {
  final Map<String, List<Patient>> _byOwner = {};

  List<Patient> _of(String ownerId) =>
      _byOwner.putIfAbsent(ownerId, () => <Patient>[]);

  @override
  Future<List<Patient>> list(String ownerId) async =>
      List.unmodifiable(_of(ownerId));

  @override
  Future<void> upsert(String ownerId, Patient patient) async {
    final list = _of(ownerId);
    final i = list.indexWhere((p) => p.id == patient.id);
    if (i == -1) {
      list.insert(0, patient);
    } else {
      list[i] = patient;
    }
  }

  @override
  Future<void> delete(String ownerId, String patientId) async {
    _of(ownerId).removeWhere((p) => p.id == patientId);
  }

  @override
  Future<void> addEvaluation(
    String ownerId,
    String patientId,
    Evaluation evaluation,
  ) async {
    final list = _of(ownerId);
    final i = list.indexWhere((p) => p.id == patientId);
    if (i == -1) return;
    list[i] = list[i].copyWith(
      evaluations: [...list[i].evaluations, evaluation],
    );
  }

  @override
  Future<void> deleteEvaluation(
    String ownerId,
    String patientId,
    String evaluationId,
  ) async {
    final list = _of(ownerId);
    final i = list.indexWhere((p) => p.id == patientId);
    if (i == -1) return;
    list[i] = list[i].copyWith(
      evaluations:
          list[i].evaluations.where((e) => e.id != evaluationId).toList(),
    );
  }
}