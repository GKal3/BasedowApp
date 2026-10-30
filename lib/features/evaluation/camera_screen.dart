import 'dart:io' show Platform;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';
import '../../models/eye_boxes.dart';
import '../../models/eye_evaluation.dart';
import '../../router/app_routes.dart';
import '../../shared/widgets/wizard_scaffold.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import 'evaluation_controller.dart';
import 'live_face_guide.dart';
import 'eye_detector.dart';

/// Passo 1: scatto della foto del volto con sagoma guida.
class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key, required this.patientId});

  final String patientId;

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen>
    with WidgetsBindingObserver {
  List<CameraDescription> _cameras = const [];
  CameraController? _controller;
  int _cameraIndex = 0;
  bool _starting = true;
  bool _capturing = false;
  String? _error;
  String? _notice; // messaggio non bloccante, es. "Volto non rilevato"

  // Guida in tempo reale (solo Android/iOS: ML Kit non esiste sul web).
  final _guide = ValueNotifier<GuideResult>(LiveFaceGuide.idle);
  LiveFaceGuide? _tracker;
  bool _streaming = false;

  /// true = lo scatto resta bloccato finché il viso non è allineato.
  /// Lascialo false finché non hai tarato la guida sul tuo telefono.
  static const _requireAlignment = true;

  /// La foto scattata con la fotocamera FRONTALE è a specchio (come il selfie)?
  /// Con la posteriore la foto è sempre "vera". Se con la frontale nella
  /// schermata "occhio destro" vedi l'occhio sbagliato, cambia true/false.
  static const _frontPhotoIsMirrored = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (!kIsWeb) _tracker = LiveFaceGuide();
    _setup();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _tracker?.dispose();
    _guide.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameras.isEmpty) return;
    if (state == AppLifecycleState.inactive) {
      _releaseController();
    } else if (state == AppLifecycleState.resumed &&
        _controller == null &&
        (ModalRoute.of(context)?.isCurrent ?? false)) {
      _startCamera();
    }
  }

  Future<void> _setup() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw CameraException('none', 'Nessuna fotocamera trovata');
      }
      // Di default la fotocamera frontale (come nel prototipo).
      final front = _cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
      );
      _cameraIndex = front == -1 ? 0 : front;
      await _startCamera();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _starting = false;
        _error = 'Fotocamera non disponibile';
      });
    }
  }

  Future<void> _startCamera() async {
    await _releaseController();
    if (!mounted) return;
    setState(() {
      _starting = true;
      _error = null;
    });
    final controller = CameraController(
      _cameras[_cameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
      // Formato richiesto da ML Kit per analizzare il flusso.
      imageFormatGroup: kIsWeb
          ? null
          : (Platform.isAndroid
              ? ImageFormatGroup.nv21
              : ImageFormatGroup.bgra8888),
    );
    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _starting = false;
      });
      _startTracking(controller);
    } catch (_) {
      await controller.dispose();
      if (!mounted) return;
      setState(() {
        _starting = false;
        _error = 'Fotocamera non disponibile';
      });
    }
  }

  Future<void> _releaseController() async {
    final c = _controller;
    await _stopTracking(c);
    _controller = null;
    if (mounted) {
      _guide.value = LiveFaceGuide.idle;
      setState(() {});
    }
    await c?.dispose();
  }

  /// Avvia l'analisi dei fotogrammi: aggiorna solo `_guide`, senza
  /// ridisegnare tutta la schermata.
  Future<void> _startTracking(CameraController c) async {
    final tracker = _tracker;
    if (tracker == null || _streaming || !c.value.isInitialized) return;
    _streaming = true;
    final camera = _cameras[_cameraIndex];
    try {
      await c.startImageStream((image) async {
        final result = await tracker.analyze(
          image,
          camera,
          c.value.deviceOrientation,
        );
        if (result != null && mounted) _guide.value = result;
      });
    } catch (_) {
      _streaming = false; // la guida non parte, ma si può scattare lo stesso
    }
  }

  Future<void> _stopTracking(CameraController? c) async {
    if (!_streaming) return;
    _streaming = false;
    try {
      if (c != null && c.value.isStreamingImages) await c.stopImageStream();
    } catch (_) {}
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    await _startCamera();
  }

  Future<void> _capture() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized || _capturing) return;
    setState(() {
      _capturing = true;
      _notice = null;
    });
    try {
      // Fermo l'analisi in tempo reale prima dello scatto.
      await _stopTracking(c);
      final file = await c.takePicture();

      // ML Kit esiste solo su Android/iOS: su Chrome salto il rilevamento.
      EyeBoxes? boxes;
      if (!kIsWeb) {
        final camera = _cameras[_cameraIndex];
        final mirrored = camera.lensDirection == CameraLensDirection.front &&
            _frontPhotoIsMirrored;
        boxes = await ref
            .read(eyeDetectorProvider)
            .detect(file.path, mirrored: mirrored);
        if (!mounted) return;
        if (boxes == null) {
          setState(() => _notice =
              'Volto non rilevato. Riprova inquadrando bene il viso.');
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted && _notice != null) setState(() => _notice = null);
          });
          _startTracking(c);
          return;
        }
      }

      ref.read(evaluationDraftProvider.notifier).setPhoto(file.path, boxes);
      await _goToEyes();
    } on FaceNotFrontalException {
      if (!mounted) return;
      setState(() =>
          _notice = 'Il viso non è frontale. Guarda dritto e riprova.');
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _notice != null) setState(() => _notice = null);
      });
      _startTracking(c);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Impossibile scattare la foto. Riprova.');
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  /// Spegne la camera, apre la valutazione dell'occhio destro e, se
  /// l'utente torna indietro, riaccende la camera per rifare la foto.
  Future<void> _goToEyes() async {
    await _releaseController();
    if (!mounted) return;
    await context.push(AppRoutes.eye(widget.patientId, Eye.od));
    if (mounted && _cameras.isNotEmpty) await _startCamera();
  }

  @override
  Widget build(BuildContext context) {
    final ready = _controller?.value.isInitialized ?? false;

    return WizardScaffold(
      title: 'Scatta la foto',
      step: 1,
      showNext: false,
      onBack: () => context.pop(),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const _InstructionBanner(),
            AspectRatio(
              aspectRatio: 3 / 4,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _Preview(controller: _controller, starting: _starting),
                  const _GuideShade(),
                  const _ThirdsGrid(),
                  // Sagoma ovale: diventa gialla quando il viso è allineato.
                  ValueListenableBuilder<GuideResult>(
                    valueListenable: _guide,
                    builder: (_, g, _) => _FaceMask(aligned: g.aligned),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Center(
                      child: ValueListenableBuilder<GuideResult>(
                        valueListenable: _guide,
                        builder: (_, g, _) => _StatusPill(
                          text: _error ??
                              _notice ??
                              (ready ? g.message : 'Avvio fotocamera…'),
                          ok: _error == null && _notice == null && g.aligned,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              color: AppColors.sky50,
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                20 + MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                children: [
                  Text(
                    _error == null
                        ? "Allinea il viso all'interno dell'ovale, a distanza costante"
                        : "Consenti l'accesso alla fotocamera dalle impostazioni per continuare.",
                    textAlign: TextAlign.center,
                    style: AppText.t(13, c: AppColors.muted),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 46),
                      const SizedBox(width: 28),
                      ValueListenableBuilder<GuideResult>(
                        valueListenable: _guide,
                        builder: (_, g, _) => _ShutterButton(
                          enabled: ready &&
                              !_capturing &&
                              (!_requireAlignment ||
                                  g.aligned ||
                                  _tracker == null),
                          onTap: _capture,
                        ),
                      ),
                      const SizedBox(width: 28),
                      _SwitchCameraButton(onTap: _switchCamera),
                    ],
                  ),
                  // Solo in debug: permette di provare il resto del flusso
                  // su simulatori senza fotocamera.
                  if (kDebugMode && _error != null)
                    TextButton(
                      onPressed: () {
                        ref.read(evaluationDraftProvider.notifier).setPhoto('');
                        context.push(AppRoutes.eye(widget.patientId, Eye.od));
                      },
                      child: Text(
                        'Continua senza foto (solo test)',
                        style: AppText.t(13, w: FontWeight.w800, c: AppColors.orange),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InstructionBanner extends StatelessWidget {
  const _InstructionBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.sky300,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.access_time, size: 20, color: AppColors.navy),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inquadra il volto del paziente',
                  style: AppText.t(14, w: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  'Il volto deve rientrare completamente nella sagoma guida '
                  'al centro dello schermo.',
                  style: AppText.t(
                    12.5,
                    c: const Color(0xCC023047),
                    h: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.controller, required this.starting});

  final CameraController? controller;
  final bool starting;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    if (c == null || !c.value.isInitialized) {
      return ColoredBox(
        color: AppColors.cameraBg,
        child: starting
            ? const Center(child: CircularProgressIndicator(color: AppColors.sky300))
            : null,
      );
    }
    // previewSize è in orizzontale: scambio larghezza/altezza per il ritratto
    // e riempio il riquadro 3:4 ritagliando (come object-fit: cover).
    final size = c.value.previewSize!;
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: size.height,
          height: size.width,
          child: CameraPreview(c),
        ),
      ),
    );
  }
}

/// Ombreggiatura ai bordi che mette in risalto il centro (`.guide-overlay`).
class _GuideShade extends StatelessWidget {
  const _GuideShade();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.12),
            radius: 0.64,
            colors: [Color(0x0002080F), Color(0x8C02080F)],
            stops: [0.52, 1.0],
          ),
        ),
      ),
    );
  }
}

class _ThirdsGrid extends StatelessWidget {
  const _ThirdsGrid();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(child: CustomPaint(painter: _ThirdsPainter()));
  }
}

class _ThirdsPainter extends CustomPainter {
  const _ThirdsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x66FFFFFF)
      ..strokeWidth = 1;
    for (final f in [1 / 3, 2 / 3]) {
      canvas.drawLine(Offset(size.width * f, 0), Offset(size.width * f, size.height), paint);
      canvas.drawLine(Offset(0, size.height * f), Offset(size.width, size.height * f), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FaceMask extends StatelessWidget {
  const _FaceMask({required this.aligned});

  final bool aligned;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
        child: CustomPaint(
          painter: _MaskPainter(
            aligned ? AppColors.amber : const Color(0xEBFFFFFF),
          ),
        ),
      ),
    );
  }
}

class _MaskPainter extends CustomPainter {
  const _MaskPainter(this.color);

  final Color color;

  /// Ingrandimento dell'ovale rispetto alla sagoma originale.
  /// I rettangoli degli occhi non cambiano. Valori sensati: 1.10 - 1.25.
  static const ovalScale = 1.15;

  @override
  void paint(Canvas canvas, Size s) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Tutto in multipli della distanza tra gli occhi (iod).
    final iod = LiveFaceGuide.eyeIod * s.width;
    final cx = LiveFaceGuide.eyeMidX * s.width;
    final cy = LiveFaceGuide.eyeMidY * s.height;

    // Rettangoli degli occhi (come nel PNG originale).
    for (final dx in [-iod / 2, iod / 2]) {
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(cx + dx, cy),
          width: iod * 0.571,
          height: iod * 0.348,
        ),
        paint,
      );
    }

    // Ovale: stesse proporzioni dell'originale, ingrandito attorno al
    // proprio centro (che sta un po' sotto la linea degli occhi).
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy + iod * 0.166),
        width: iod * 2.222 * ovalScale,
        height: iod * 2.675 * ovalScale,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_MaskPainter old) => old.color != color;
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.text, required this.ok});

  final String text;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xB3023047),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: ok ? AppColors.amber : AppColors.orange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              text,
              style: AppText.t(13, w: FontWeight.w700, c: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShutterButton extends StatelessWidget {
  const _ShutterButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 74,
        height: 74,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.navy, width: 4),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: enabled ? AppColors.amber : const Color(0xFFCDD8DE),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _SwitchCameraButton extends StatelessWidget {
  const _SwitchCameraButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: const SizedBox(
          width: 46,
          height: 46,
          child: Icon(Icons.cached, size: 22, color: AppColors.navy),
        ),
      ),
    );
  }
}