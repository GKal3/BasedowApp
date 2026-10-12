import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Area fissa in fondo alla schermata con il pulsante principale.
class BottomAction extends StatelessWidget {
  const BottomAction({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.sky50,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: child,
        ),
      ),
    );
  }
}
