import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_repository.dart';
import 'patient_repository.dart';
import 'supabase_auth_repository.dart';
import 'supabase_patient_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => SupabaseAuthRepository(),
);

final patientRepositoryProvider = Provider<PatientRepository>(
  (ref) => SupabasePatientRepository(),
);