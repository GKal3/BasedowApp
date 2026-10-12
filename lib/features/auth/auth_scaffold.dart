import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/gradient_background.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

/// Struttura comune di login e registrazione: sfondo sfumato, freccia
/// indietro in alto a sinistra, logo sbiadito in alto a destra, contenuto
/// centrato verticalmente (scorre quando compare la tastiera).
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(30, 70, 30, 30),
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppText.t(22, w: FontWeight.w800)),
                        const SizedBox(height: 6),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 320),
                          child: Text(
                            subtitle,
                            style: AppText.t(14, c: AppColors.muted, h: 1.5),
                          ),
                        ),
                        const SizedBox(height: 26),
                        ...children,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 18,
                left: 18,
                child: Material(
                  color: const Color(0x8CFFFFFF),
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => context.pop(),
                    child: const SizedBox(
                      width: 34,
                      height: 34,
                      child: Icon(Icons.chevron_left, size: 24, color: AppColors.navy),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 18,
                right: 18,
                child: Opacity(
                  opacity: 0.45,
                  child: Image.asset('assets/images/eye_mark.png', width: 56),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
