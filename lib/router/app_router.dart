import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_controller.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/auth/start_screen.dart';
import '../features/evaluation/camera_screen.dart';
import '../features/evaluation/eye_assessment_screen.dart';
import '../features/evaluation/summary_screen.dart';
import '../features/evaluation/symptoms_screen.dart';
import '../features/patients/dashboard_screen.dart';
import '../features/patients/patient_detail_screen.dart';
import '../features/patients/patient_form_screen.dart';
import '../models/eye_evaluation.dart';
import 'app_routes.dart';

/// Router dell'app. Reagisce al login/logout e reindirizza da solo:
///  - non loggato  → può vedere solo start / login / registrazione
///  - loggato      → da quelle schermate va direttamente ai pazienti
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: AppRoutes.start,
    refreshListenable: refresh,
    redirect: (context, state) {
      final loggedIn = ref.read(authProvider) != null;
      final loc = state.matchedLocation;
      final isPublic = loc == AppRoutes.start ||
          loc == AppRoutes.login ||
          loc == AppRoutes.register;

      if (!loggedIn && !isPublic) return AppRoutes.start;
      if (loggedIn && isPublic) return AppRoutes.patients;
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.start, builder: (_, _) => const StartScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, _) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.patients,
        builder: (_, _) => const DashboardScreen(),
        routes: [
          // 'new' va dichiarato PRIMA di ':id', altrimenti verrebbe letto come id.
          GoRoute(path: 'new', builder: (_, _) => const PatientFormScreen()),
          GoRoute(
            path: ':id',
            builder: (_, s) =>
                PatientDetailScreen(patientId: s.pathParameters['id']!),
            routes: [
              GoRoute(
                path: 'edit',
                builder: (_, s) =>
                    PatientFormScreen(patientId: s.pathParameters['id']),
              ),
              GoRoute(
                path: 'evaluation/camera',
                builder: (_, s) =>
                    CameraScreen(patientId: s.pathParameters['id']!),
              ),
              GoRoute(
                path: 'evaluation/eye/:eye',
                builder: (_, s) => EyeAssessmentScreen(
                  patientId: s.pathParameters['id']!,
                  eye: EyeX.fromCode(s.pathParameters['eye']!),
                  editMode: s.uri.queryParameters['edit'] == '1',
                ),
              ),
              GoRoute(
                path: 'evaluation/symptoms',
                builder: (_, s) => SymptomsScreen(
                  patientId: s.pathParameters['id']!,
                  editMode: s.uri.queryParameters['edit'] == '1',
                ),
              ),
              GoRoute(
                path: 'evaluation/summary',
                builder: (_, s) =>
                    SummaryScreen(patientId: s.pathParameters['id']!),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
