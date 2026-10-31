import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

/// Struttura comune delle schermate della valutazione: barra celeste con
/// indietro / titolo / "Avanti" e barra di avanzamento arancione.
class WizardScaffold extends StatelessWidget {
  const WizardScaffold({
    super.key,
    required this.title,
    required this.step,
    required this.onBack,
    required this.child,
    this.onNext,
    this.showNext = true,
    this.totalSteps = 4,
  });

  final String title;

  /// Passo corrente (1..totalSteps): 1 foto, 2 occhi, 3 sintomi, 4 riepilogo.
  final int step;
  final int totalSteps;
  final VoidCallback onBack;

  /// Se null il pulsante "Avanti" è disabilitato (opacità ridotta).
  final VoidCallback? onNext;
  final bool showNext;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.sky50,
        body: Column(
          children: [
            Container(
              color: AppColors.sky300,
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  height: 53,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: onBack,
                          icon: const Icon(
                            Icons.chevron_left,
                            size: 28,
                            color: AppColors.navy,
                          ),
                          tooltip: 'Indietro',
                        ),
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              title,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              style: AppText.t(16, w: FontWeight.w800),
                            ),
                          ),
                        ),
                        Visibility(
                          visible: showNext,
                          maintainSize: true,
                          maintainAnimation: true,
                          maintainState: true,
                          child: _NextButton(onTap: onNext),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _ProgressBar(value: step / totalSteps),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _NextButton extends StatelessWidget {
  const _NextButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.32 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 6, 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Avanti', style: AppText.t(15, w: FontWeight.w800)),
              const SizedBox(width: 2),
              const Icon(Icons.chevron_right, size: 20, color: AppColors.navy),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 3,
      child: Stack(
        children: [
          Container(color: AppColors.track),
          FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            child: Container(color: AppColors.orange),
          ),
        ],
      ),
    );
  }
}
