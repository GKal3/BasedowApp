import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

/// Pulsante giallo principale (`.btn-primary` / `.btn-save`).
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.fontSize = 16,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    const radius = BorderRadius.all(Radius.circular(AppRadius.small));
    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.amber,
          borderRadius: radius,
          boxShadow: enabled ? AppShadows.button : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 17),
              child: Center(
                child: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: AppColors.navy,
                        ),
                      )
                    : Text(label, style: AppText.t(fontSize, w: FontWeight.w800)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pulsante blu scuro con icona "+" (`.btn-fab`).
class NavyButton extends StatelessWidget {
  const NavyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.add,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(AppRadius.small));
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.navy,
        borderRadius: radius,
        boxShadow: AppShadows.button,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: AppColors.white),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: AppText.t(15, w: FontWeight.w800, c: AppColors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pulsante con bordo (`.btn-outline`), anche in versione "pericolo".
class OutlineActionButton extends StatelessWidget {
  const OutlineActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.danger = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.danger : AppColors.navy;
    const radius = BorderRadius.all(Radius.circular(AppRadius.small));
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: color, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: Text(label, style: AppText.t(13.5, w: FontWeight.w800, c: color)),
          ),
        ),
      ),
    );
  }
}

/// Riga "Non hai un account? Registrati".
class AuthSwitchLine extends StatelessWidget {
  const AuthSwitchLine({
    super.key,
    required this.prefix,
    required this.action,
    required this.onTap,
  });

  final String prefix;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: [
        Text(prefix, style: AppText.t(13.5, c: AppColors.muted)),
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(action, style: AppText.t(13.5, w: FontWeight.w800)),
          ),
        ),
      ],
    );
  }
}
