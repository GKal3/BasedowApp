import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/patient_repository.dart';
import '../../data/providers.dart';
import '../../models/evaluation.dart';
import '../../models/patient.dart';
import '../../shared/formatters.dart';
import '../auth/auth_controller.dart';

/// Lista pazienti del medico loggato.
class PatientsController extends AsyncNotifier<List<Patient>> {
  @override
  Future<List<Patient>> build() async {
    final user = ref.watch(authProvider);
    if (user == null) return const [];
    return ref.watch(patientRepositoryProvider).list(user.id);
  }

  Future<void> _run(
    Future<void> Function(PatientRepository repo, String ownerId) action,
  ) async {
    final user = ref.read(authProvider);
    if (user == null) return;
    try {
      await action(ref.read(patientRepositoryProvider), user.id);
    } catch (_) {
      ref.invalidateSelf();
      rethrow;
    }
    ref.invalidateSelf();
    await future;
  }

  Future<void> add({
    required String nome,
    required String cognome,
    DateTime? dataNascita,
    String note = '',
  }) {
    final p = Patient(
      id: 'p_${newId()}',
      nome: nome,
      cognome: cognome,
      dataNascita: dataNascita,
      note: note,
    );
    return _run((repo, owner) => repo.upsert(owner, p));
  }

  Future<void> save(Patient patient) =>
      _run((repo, owner) => repo.upsert(owner, patient));

  Future<void> remove(String patientId) =>
      _run((repo, owner) => repo.delete(owner, patientId));

  Future<void> addEvaluation(String patientId, Evaluation evaluation) =>
      _run((repo, owner) => repo.addEvaluation(owner, patientId, evaluation));

    Future<void> removeEvaluation(String patientId, String evaluationId) =>
      _run((repo, owner) => repo.deleteEvaluation(owner, patientId, evaluationId));

  Future<void> replaceEvaluation(
    String patientId,
    Evaluation evaluation,
    String existingEvaluationId,
  ) =>
      _run((repo, owner) async {
        await repo.addEvaluation(owner, patientId, evaluation);
        await repo.deleteEvaluation(
          owner,
          patientId,
          existingEvaluationId,
        );
      });
}

final patientsProvider =
    AsyncNotifierProvider<PatientsController, List<Patient>>(
  PatientsController.new,
);

/// Singolo paziente per id (null se non trovato o lista non ancora caricata).
final patientProvider = Provider.family<Patient?, String>((ref, id) {
  final list = ref.watch(patientsProvider).value;
  if (list == null) return null;
  for (final p in list) {
    if (p.id == id) return p;
  }
  return null;
});

/// Banner "✓ Salvataggio effettuato" mostrato per ~3 secondi.
class SavedBannerController extends Notifier<bool> {
  Timer? _timer;

  @override
  bool build() {
    ref.onDispose(() => _timer?.cancel());
    return false;
  }

  void show() {
    _timer?.cancel();
    state = true;
    _timer = Timer(const Duration(milliseconds: 3200), () => state = false);
  }
}

final savedBannerProvider =
    NotifierProvider<SavedBannerController, bool>(SavedBannerController.new);
