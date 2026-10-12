import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_repository.dart';
import 'patient_repository.dart';

// Per passare a un backend vero basta cambiare le due implementazioni qui sotto.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => InMemoryAuthRepository(),
);

final patientRepositoryProvider = Provider<PatientRepository>(
  (ref) => InMemoryPatientRepository(),
);
