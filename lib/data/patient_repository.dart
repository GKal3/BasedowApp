import '../models/evaluation.dart';
import '../models/eye_evaluation.dart';
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
}

/// SOLO PER SVILUPPO UI: i dati si perdono al riavvio dell'app.
class InMemoryPatientRepository implements PatientRepository {
  final Map<String, List<Patient>> _byOwner = {
    // Dati demo per vedere le schermate popolate. Da rimuovere.
    'demo': [
      Patient(
        id: 'demo_p1',
        nome: 'Giulia',
        cognome: 'Bianchi',
        dataNascita: DateTime(1984, 3, 12),
        note: 'In terapia con metimazolo.',
        evaluations: [
          Evaluation(
            id: 'demo_e1',
            date: DateTime.now().subtract(const Duration(days: 30)),
            od: const EyeEvaluation(
              iperemiaCongiuntivale: 1,
              chemosiCongiuntivale: 0,
              edemaCaruncola: false,
              iperemiaPalpebrale: 2,
              edemaPalpebrale: 1,
              mrd1: 4.5,
              mrd2: 5.0,
            ),
            os: const EyeEvaluation(
              iperemiaCongiuntivale: 2,
              chemosiCongiuntivale: 1,
              edemaCaruncola: true,
              iperemiaPalpebrale: 2,
              edemaPalpebrale: 2,
              mrd1: 5.5,
              mrd2: 5.0,
            ),
            doloreRetrobulbare: true,
            doloreMovimentiOculari: false,
          ),
        ],
      ),
      Patient(
        id: 'demo_p2',
        nome: 'Marco',
        cognome: 'Verdi',
        dataNascita: DateTime(1971, 9, 3),
      ),
    ],
  };

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
}
