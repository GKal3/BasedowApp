import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_repository.dart';
import 'patient_repository.dart';
import 'supabase_auth_repository.dart';
import 'supabase_patient_repository.dart';
import '../features/evaluation/eye_detector.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => SupabaseAuthRepository(),
);

final patientRepositoryProvider = Provider<PatientRepository>(
  (ref) => SupabasePatientRepository(),
);

final eyeDetectorProvider = Provider<EyeDetector>((ref) {
  final d = MlKitEyeDetector();
  ref.onDispose(d.dispose);
  return d;
});