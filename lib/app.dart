/* CONFIGURAZIONE DELL'APP */

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Importa il router e il tema dell'applicazione
import 'router/app_router.dart';
import 'theme/app_theme.dart';
// Un widget che estende Consumer invece di Stateless per poter leggere i provider di Riverpod.
class App extends ConsumerWidget {
  const App({super.key});
  // Il metodo build (di Consumer) costruisce il widget dell'applicazione.
  // riceve anche ref, che permette di leggere i provider di Riverpod.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // .router è necessario per usare GoRouter, che gestisce la navigazione dell'app.
    return MaterialApp.router(
      title: 'Orbitopatia basedowiana',
      // Nasconde il banner di debug in alto a destra (DEBUG) quando l'app è in modalità debug.
      debugShowCheckedModeBanner: false,
      // Applica il tema chiaro definito in app_theme.dart
      theme: AppTheme.light,
      // Configura il router dell'applicazione, che gestisce la navigazione tra le schermate.
      // Il router è fornito da Riverpod tramite il provider routerProvider.
      routerConfig: ref.watch(routerProvider),
      // Italiano per calendario e dialoghi di sistema.
      locale: const Locale('it', 'IT'),
      supportedLocales: const [Locale('it', 'IT')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    );
  }
}