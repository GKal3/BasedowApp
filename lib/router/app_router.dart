/* CONFIGURAZIONE DEL ROUTER - NAVIGAZIONE */

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_controller.dart';             // Per authProvider
import '../features/auth/login_screen.dart';                // Per LoginScreen
import '../features/auth/register_screen.dart';             // Per RegisterScreen
import '../features/auth/start_screen.dart';                // Per StartScreen
import '../features/evaluation/camera_screen.dart';         // Per CameraScreen
import '../features/evaluation/eye_assessment_screen.dart'; // Per EyeAssessmentScreen
import '../features/evaluation/summary_screen.dart';        // Per SummaryScreen
import '../features/evaluation/symptoms_screen.dart';       // Per SymptomsScreen
import '../features/patients/dashboard_screen.dart';        // Per DashboardScreen
import '../features/patients/patient_detail_screen.dart';   // Per PatientDetailScreen
import '../features/patients/patient_form_screen.dart';     // Per PatientFormScreen
import '../models/eye_evaluation.dart';                     // Per EyeX
// Da qui prende le rotte che chiama nella configurazione di GoRouter, ad esempio start, login, etc
import 'app_routes.dart';

/// Router dell'app. Reagisce al login/logout e reindirizza da solo:
///  - non loggato  → può vedere solo start / login / registrazione
///  - loggato      → da quelle schermate va direttamente ai pazienti
final routerProvider = Provider<GoRouter>((ref) {
  // Notifica i cambiamenti di stato a chi è in ascolto per aggiornare il router
  final refresh = ValueNotifier<int>(0);
  // Ascolta i cambiamenti di stato dell'autenticazione e incrementa il valore di refresh per notificare il router.
  // I due _ ignorano il valore precedente e quello nuovo, perché interessa solo che qualcosa sia cambiato.
  ref.listen(authProvider, (_, _) => refresh.value++);
  // Quando il provider (refresh) viene eliminato, rimuove l'ascoltatore per evitare perdite di memoria.
  ref.onDispose(refresh.dispose);
  // CONFIGURAZIONE DI GO ROUTER: inizializza il router con la posizione iniziale, le regole di reindirizzamento e le rotte.
  return GoRouter(
    initialLocation: AppRoutes.start,
    // Dice al router di rieseguire redirect ogni volta che refresh notifica.
    // Così, appena l’utente fa login, viene portato via dalla schermata di login senza codice aggiuntivo.
    refreshListenable: refresh,
    redirect: (context, state) {
      // Controlla se l'utente è loggato leggendo il provider authProvider.
      final loggedIn = ref.read(authProvider) != null;
      // Ottiene la posizione corrente della rotta e verifica se è una rotta pubblica (start, login, register).
      final loc = state.matchedLocation;
      // Dichiara quali rotte sono pubbliche.
      final isPublic = loc == AppRoutes.start ||
          loc == AppRoutes.login ||
          loc == AppRoutes.register;
      // Se l'utente non è loggato e sta cercando di accedere a una rotta privata, lo reindirizza alla schermata iniziale.
      if (!loggedIn && !isPublic) return AppRoutes.start;
      // Se l'utente è loggato e sta cercando di accedere a una rotta pubblica, lo reindirizza alla schermata dei pazienti.
      if (loggedIn && isPublic) return AppRoutes.patients;
      // Altrimenti, non fa alcun reindirizzamento.
      return null;
    },
    // Associa le rotte alle schermate corrispondenti. Ogni GoRoute ha un percorso e un builder che restituisce il widget della schermata.
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