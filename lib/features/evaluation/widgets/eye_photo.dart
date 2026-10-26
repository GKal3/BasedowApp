import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../models/eye_boxes.dart';
import '../../../models/eye_evaluation.dart';
import '../../../shared/widgets/app_photo.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';

/// Punto della foto su cui centrare lo zoom quando NON ci sono i box
/// rilevati (valutazioni vecchie, o su Chrome dove ML Kit non esiste).
Alignment eyeFocus(Eye eye) =>
    eye == Eye.od ? const Alignment(0.36, -0.24) : const Alignment(-0.36, -0.24);

/// Foto ingrandita su un solo occhio, con bordo celeste.
/// Se ci sono i [boxes] rilevati, l'occhio è centrato nel riquadro.
class EyeCropFrame extends StatelessWidget {
  const EyeCropFrame({
    super.key,
    required this.path,
    required this.eye,
    this.boxes,
  });

  final String? path;
  final Eye eye;
  final EyeBoxes? boxes;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = math.min(w / (4 / 3.1), 230.0);
        final b = boxes;
        final hasPhoto = path != null && path!.isNotEmpty;

        final Widget content;
        if (b != null && hasPhoto) {
          // Scala la foto in modo che il box dell'occhio stia tutto nel
          // riquadro, e sposta la foto perché il centro del box coincida
          // con il centro del riquadro.
          final box = b.of(eye == Eye.od);
          final iw = b.imageWidth.toDouble();
          final ih = b.imageHeight.toDouble();
          final scale = math.min(w / (box.width * iw), h / (box.height * ih));
          final cx = (box.left + box.width / 2) * iw;
          final cy = (box.top + box.height / 2) * ih;
          content = Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                left: w / 2 - cx * scale,
                top: h / 2 - cy * scale,
                width: iw * scale,
                height: ih * scale,
                child: AppPhoto(path: path, fit: BoxFit.fill, cacheWidth: 3000),
              ),
            ],
          );
        } else {
          final focus = eyeFocus(eye);
          content = Transform.scale(
            scale: 2.2,
            alignment: focus,
            child: AppPhoto(
              path: path,
              width: double.infinity,
              height: double.infinity,
              alignment: focus,
            ),
          );
        }

        return Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: AppColors.photoPlaceholder,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.sky300, width: 1.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: content,
        );
      },
    );
  }
}

/// Intestazione fissa con "Foto acquisita:" e l'occhio ingrandito.
class PhotoFixedHeader extends StatelessWidget {
  const PhotoFixedHeader({
    super.key,
    required this.path,
    required this.eye,
    this.boxes,
  });

  final String? path;
  final Eye eye;
  final EyeBoxes? boxes;

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
          EyeCropFrame(path: path, eye: eye, boxes: boxes),
        ],
      ),
    );
  }
}