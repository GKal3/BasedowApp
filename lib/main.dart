/* INIZIO DEL PROGETTO FLUTTER*/

// Librerie di Flutter
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// File locale app.dart, che contiene il widget App
import 'app.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
// async perchè contiene una funzione asincrona: await...
Future<void> main() async {
  // Inizializza il "ponte" tra il framework Flutter e il motore nativo.
  WidgetsFlutterBinding.ensureInitialized();
  // Imposta l'orientamento preferito dell'applicazione su verticale (portrait).
  // L’await aspetta che la piattaforma abbia applicato l’impostazione prima di far partire l’app.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    publishableKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );
  // Avvia l'applicazione Flutter, avvolgendo il widget principale App in un ProviderScope per la gestione dello stato con Riverpod.
  runApp(const ProviderScope(child: App()));
}