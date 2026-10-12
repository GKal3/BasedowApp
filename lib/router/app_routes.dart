import '../models/eye_evaluation.dart';

/// Tutti i percorsi dell'app in un unico posto.
class AppRoutes {
  AppRoutes._();

  static const start = '/';
  static const login = '/login';
  static const register = '/register';
  static const patients = '/patients';
  static const newPatient = '/patients/new';

  static String patient(String id) => '/patients/$id';
  static String editPatient(String id) => '/patients/$id/edit';

  // Flusso di valutazione
  static String camera(String id) => '/patients/$id/evaluation/camera';

  /// [edit] = true quando si arriva dal riepilogo: "Avanti" torna al riepilogo.
  static String eye(String id, Eye eye, {bool edit = false}) =>
      '/patients/$id/evaluation/eye/${eye.code}${edit ? '?edit=1' : ''}';

  static String symptoms(String id, {bool edit = false}) =>
      '/patients/$id/evaluation/symptoms${edit ? '?edit=1' : ''}';

  static String summary(String id) => '/patients/$id/evaluation/summary';
}
