import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import '../services/pullup_counter.dart';
import '../utils/app_colors.dart';
import '../utils/drawing_utils_pullup.dart';
import '../models/pose_keypoint.dart';

/// Widget de cámara para Pull-Ups con overlay de barra y skeleton
class CameraPreviewWidgetPullUp extends StatelessWidget {
  final CameraController cameraController;

  const CameraPreviewWidgetPullUp({
    super.key,
    required this.cameraController,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<PullUpCounter>(
      builder: (context, counter, _) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // Camera preview
            CameraPreview(cameraController),

            // Overlay con skeleton y barra
            CustomPaint(
              painter: _PullUpOverlayPainter(
                pose: counter.currentPose,
                barHeight: counter.barHeight,
                formQuality: counter.formQuality,
              ),
            ),

            // Feedback eliminado - ahora se maneja en la UI premium principal
          ],
        );
      },
    );
  }
}

/// Painter para dibujar skeleton y barra de referencia
class _PullUpOverlayPainter extends CustomPainter {
  final PoseDetection? pose;
  final double barHeight;
  final double formQuality;

  _PullUpOverlayPainter({
    required this.pose,
    required this.barHeight,
    required this.formQuality,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (pose == null) return;

    // Dibujar barra de referencia
    _drawBarReference(canvas, size);

    // Dibujar skeleton usando DrawingUtilsPullUp
    DrawingUtilsPullUp.drawSkeleton(
      canvas,
      size,
      pose!,
      showCorrectForm: formQuality > 80,
    );
  }

  void _drawBarReference(Canvas canvas, Size size) {
    final barY = size.height * barHeight;

    // Glow exterior MÁS GRANDE
    final outerGlowPaint = Paint()
      ..color = AppColors.primaryCyan.withOpacity(0.2)
      ..strokeWidth = 20
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25)
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(0, barY),
      Offset(size.width, barY),
      outerGlowPaint,
    );

    // Glow medio
    final midGlowPaint = Paint()
      ..color = AppColors.primaryCyan.withOpacity(0.4)
      ..strokeWidth = 12
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(0, barY),
      Offset(size.width, barY),
      midGlowPaint,
    );

    // Línea sólida principal MÁS GRUESA
    final barPaint = Paint()
      ..color = AppColors.primaryCyan
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(0, barY),
      Offset(size.width, barY),
      barPaint,
    );

    // Puntos decorativos MÁS GRANDES
    final dotPaint = Paint()
      ..color = AppColors.primaryCyan
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(30, barY), 8, dotPaint);
    canvas.drawCircle(Offset(size.width - 30, barY), 8, dotPaint);

    // Badge BARRA eliminado para diseño premium más limpio
  }

  @override
  bool shouldRepaint(_PullUpOverlayPainter oldDelegate) {
    return oldDelegate.pose != pose ||
        oldDelegate.barHeight != barHeight ||
        oldDelegate.formQuality != formQuality;
  }
}
