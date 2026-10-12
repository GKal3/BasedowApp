import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_routes.dart';
import '../../shared/widgets/app_buttons.dart';
import '../../shared/widgets/gradient_background.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/images/eye_mark.png', width: 190),
                  const SizedBox(height: 28),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: Text(
                      'Orbitopatia basedowiana',
                      textAlign: TextAlign.center,
                      style: AppText.t(23, w: FontWeight.w800, h: 1.32),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: Text(
                      'Acquisisci una fotografia del volto e registra i segni '
                      'clinici oculari in pochi passaggi guidati.',
                      textAlign: TextAlign.center,
                      style: AppText.t(14.5, c: AppColors.muted, h: 1.55),
                    ),
                  ),
                  const SizedBox(height: 36),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 270),
                    child: PrimaryButton(
                      label: 'Accedi',
                      onPressed: () => context.push(AppRoutes.login),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AuthSwitchLine(
                    prefix: 'Non hai un account?',
                    action: 'Registrati',
                    onTap: () => context.push(AppRoutes.register),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
