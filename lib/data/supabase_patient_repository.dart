import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../models/evaluation.dart';
import '../models/patient.dart';
import 'patient_repository.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class SupabasePatientRepository implements PatientRepository {
  sb.SupabaseClient get _c => sb.Supabase.instance.client;

  @override
  Future<List<Patient>> list(String ownerId) async {
    final data = await _c
        .from('patients')
        .select('*, evaluations(*)')
        .eq('owner_id', ownerId)
        .order('created_at', ascending: false);

    // Copie modificabili delle righe.
    final rows = data
        .map<Map<String, dynamic>>((r) => {
              ...r,
              'evaluations': ((r['evaluations'] as List?) ?? const [])
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .toList(),
            })
        .toList();

    // Percorsi del bucket (non locali, non già URL).
    final paths = <String>{};
    for (final r in rows) {
      for (final e in r['evaluations'] as List) {
        final p = (e as Map)['photo_path'] as String?;
        if (p != null && p.isNotEmpty && !p.startsWith('/') && !p.startsWith('http')) {
          paths.add(p);
        }
      }
    }

    // URL firmati validi 6 ore, uno per foto, in parallelo.
    final urls = <String, String>{};
    await Future.wait(paths.map((p) async {
      try {
        urls[p] = await _c.storage.from('photos').createSignedUrl(p, 6 * 3600);
      } catch (_) {
        // File mancante o errore: la foto resta con il segnaposto.
      }
    }));

    for (final r in rows) {
      for (final e in r['evaluations'] as List) {
        final m = e as Map<String, dynamic>;
        final p = m['photo_path'] as String?;
        if (p != null && urls.containsKey(p)) m['photo_path'] = urls[p];
      }
    }

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
    final storage = _c.storage.from('photos');
    final folder = '$ownerId/$patientId';

    // 1. Elenca e cancella i file del paziente (foto e json).
    final files = await storage.list(
      path: folder,
      searchOptions: const sb.SearchOptions(limit: 1000),
    );
    if (files.isNotEmpty) {
      await storage.remove(files.map((f) => '$folder/${f.name}').toList());
    }

    // 2. Cancella il paziente; le valutazioni vanno via con on delete cascade.
    await _c.from('patients').delete().eq('id', patientId);
  }

  @override
  Future<void> addEvaluation(
    String ownerId,
    String patientId,
    Evaluation e,
  ) async {
    final base = '$ownerId/$patientId/${e.id}';
    final storage = _c.storage.from('photos');

    // 1. Foto
    String? photoStoragePath;
    final local = e.photoPath;
    if (local != null && local.isNotEmpty) {
      photoStoragePath = '$base.jpg';
      await storage.upload(
        photoStoragePath,
        File(local),
        fileOptions: const sb.FileOptions(
          contentType: 'image/jpeg',
          upsert: true,
        ),
      );
    }

    // 2. File JSON con i bounding box
    String? boxesStoragePath;
    final boxes = e.eyeBoxes;
    if (boxes != null) {
      boxesStoragePath = '$base.json';
      final bytes = Uint8List.fromList(utf8.encode(jsonEncode(boxes.toMap())));
      await storage.uploadBinary(
        boxesStoragePath,
        bytes,
        fileOptions: const sb.FileOptions(
          contentType: 'application/json',
          upsert: true,
        ),
      );
    }

    // 3. Riga nel database: path nel bucket, non quelli locali
    await _c.from('evaluations').insert({
      ...e.toMap(), // include eye_boxes (jsonb) se hai aggiornato Evaluation
      'photo_path': photoStoragePath,
      'eye_boxes_path': boxesStoragePath,
      'patient_id': patientId,
    });
  }
}