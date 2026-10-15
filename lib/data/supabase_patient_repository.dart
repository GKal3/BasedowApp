import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../models/evaluation.dart';
import '../models/patient.dart';
import 'patient_repository.dart';

class SupabasePatientRepository implements PatientRepository {
  sb.SupabaseClient get _c => sb.Supabase.instance.client;

  @override
  Future<List<Patient>> list(String ownerId) async {
    final rows = await _c
        .from('patients')
        .select('*, evaluations(*)')
        .eq('owner_id', ownerId)
        .order('created_at', ascending: false);
    return rows.map<Patient>(Patient.fromMap).toList();
  }

  @override
  Future<void> upsert(String ownerId, Patient p) async {
    await _c.from('patients').upsert({
      'id': p.id,
      'owner_id': ownerId,
      'nome': p.nome,
      'cognome': p.cognome,
      'data_nascita': p.dataNascita?.toIso8601String().substring(0, 10),
      'note': p.note,
    });
  }

  @override
  Future<void> delete(String ownerId, String patientId) async {
    await _c.from('patients').delete().eq('id', patientId);
  }

  @override
  Future<void> addEvaluation(
    String ownerId,
    String patientId,
    Evaluation e,
  ) async {
    await _c.from('evaluations').insert({
      ...e.toMap(),
      'patient_id': patientId,
    });
  }
}