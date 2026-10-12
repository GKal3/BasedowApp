import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../models/eye_evaluation.dart';
import '../../../shared/widgets/app_photo.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';

/// Punto della foto su cui centrare lo zoom per ciascun occhio
/// (68% / 32% orizzontale, 38% verticale, come nel prototipo).
///
/// ATTENZIONE: valido se la foto è "a specchio" come nel selfie. Se sul
/// dispositivo reale OD e OS risultano scambiati, inverti questi due valori.
Alignment eyeFocus(Eye eye) =>
    eye == Eye.od ? const Alignment(0.36, -0.24) : const Alignment(-0.36, -0.24);

/// Foto ingrandita su un solo occhio, con bordo celeste.
class EyeCropFrame extends StatelessWidget {
  const EyeCropFrame({super.key, required this.path, required this.eye});

  final String? path;
  final Eye eye;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final h = math.min(c.maxWidth / (4 / 3.1), 230.0);
        final focus = eyeFocus(eye);
        return Container(
          width: c.maxWidth,
          height: h,
          decoration: BoxDecoration(
            color: AppColors.photoPlaceholder,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.sky300, width: 1.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: Transform.scale(
            scale: 2.2,
            alignment: focus,
            child: AppPhoto(
              path: path,
              width: double.infinity,
              height: double.infinity,
              alignment: focus,
            ),
          ),
        );
      },
    );
  }
}

/// Intestazione fissa con "Foto acquisita:" e l'occhio ingrandito.
class PhotoFixedHeader extends StatelessWidget {
  const PhotoFixedHeader({super.key, required this.path, required this.eye});

  final String? path;
  final Eye eye;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.sky50,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      child: Column(
        children: [
          Text(
            'Foto acquisita:',
            style: AppText.t(13, w: FontWeight.w700, c: AppColors.muted),
          ),
          const SizedBox(height: 8),
          EyeCropFrame(path: path, eye: eye),
        ],
      ),
    );
  }
}
