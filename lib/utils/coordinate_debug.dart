import 'package:flutter/material.dart';
import '../models/pose_keypoint.dart';
import 'drawing_utils.dart';

/// 🔍 UTILIDAD DE DEBUG: Herramientas para verificar transformaciones de coordenadas
///
/// MODO DE USO:
/// 1. En ExerciseScreen, agregar parámetro debug: true al CameraPreviewWidget
/// 2. Activar showDebugOverlay: true en SettingsService
/// 3. Verás coordenadas raw (rojo) vs transformadas (verde) superpuestas
class CoordinateDebug {
  /// Dibuja overlay de debug mostrando coordenadas raw vs transformadas
  ///
  /// VERDE = Coordenadas transformadas (correcto)
  /// ROJO = Coordenadas raw sin transformar (incorrecto)
  ///
  /// Si ambos círculos coinciden = transformación correcta ✅
  /// Si están separados = problema de transformación ❌
  static void drawDebugOverlay(
    Canvas canvas,
    Size size,
    PoseDetection pose,
  ) {
    final keypoints = pose.keypoints.where((k) => k.isValid).toList();

    if (keypoints.isEmpty) return;

    // Pintura para coordenadas RAW (rojo)
    final rawPaint = Paint()
      ..color = Colors.red.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    // Pintura para coordenadas TRANSFORMADAS (verde)
    final transformedPaint = Paint()
      ..color = Colors.green.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    // Pintura para texto
    const textStyle = TextStyle(
      color: Colors.white,
      fontSize: 10,
      fontWeight: FontWeight.bold,
      shadows: [
        Shadow(blurRadius: 4.0, color: Colors.black),
      ],
    );

    for (final keypoint in keypoints) {
      // 🔴 COORDENADAS RAW (sin transformar - INCORRECTO)
      final rawX = keypoint.x * size.width;
      final rawY = keypoint.y * size.height;
      final rawPos = Offset(rawX, rawY);

      // 🟢 COORDENADAS TRANSFORMADAS (correcto)
      final transformedPos = DrawingUtils.transformCoordinate(
        keypoint,
        size.width,
        size.height,
      );

      // Dibujar círculo rojo (raw)
      canvas.drawCircle(rawPos, 6, rawPaint);

      // Dibujar círculo verde (transformado)
      canvas.drawCircle(transformedPos, 6, transformedPaint);

      // Dibujar línea conectando ambos (si hay desalineación)
      final distance = (transformedPos - rawPos).distance;
      if (distance > 5) {
        // Hay desalineación significativa
        final linePaint = Paint()
          ..color = Colors.yellow
          ..strokeWidth = 2;
        canvas.drawLine(rawPos, transformedPos, linePaint);
      }

      // Etiqueta de texto con coordenadas
      final textPainter = TextPainter(
        text: TextSpan(
          text: keypoint.name.split('_').last.substring(0, 1).toUpperCase(),
          style: textStyle,
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          transformedPos.dx - textPainter.width / 2,
          transformedPos.dy - 20,
        ),
      );
    }

    // Leyenda en esquina superior derecha
    _drawLegend(canvas, size);
  }

  static void _drawLegend(Canvas canvas, Size size) {
    const legendText = '🔴 Raw | 🟢 Transformed';

    final textPainter = TextPainter(
      text: const TextSpan(
        text: legendText,
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(blurRadius: 8.0, color: Colors.black),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // Fondo semi-transparente
    final bgRect = Rect.fromLTWH(
      size.width - textPainter.width - 20,
      10,
      textPainter.width + 10,
      textPainter.height + 10,
    );

    final bgPaint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(8)),
      bgPaint,
    );

    textPainter.paint(
      canvas,
      Offset(size.width - textPainter.width - 15, 15),
    );
  }

  /// Imprime análisis de transformación en consola
  static void logTransformationAnalysis(
    PoseDetection pose,
    Size canvasSize,
  ) {
    print('\n📊 ANÁLISIS DE TRANSFORMACIÓN DE COORDENADAS');
    print('════════════════════════════════════════════');
    print('Canvas: ${canvasSize.width.toInt()}x${canvasSize.height.toInt()}');

    final shoulders = [
      pose.getKeypoint('left_shoulder'),
      pose.getKeypoint('right_shoulder'),
    ];

    for (final keypoint in shoulders) {
      if (keypoint == null || !keypoint.isValid) continue;

      final raw = Offset(
        keypoint.x * canvasSize.width,
        keypoint.y * canvasSize.height,
      );

      final transformed = DrawingUtils.transformCoordinate(
        keypoint,
        canvasSize.width,
        canvasSize.height,
      );

      print('\n${keypoint.name}:');
      print(
          '  MediaPipe (normalized): (${keypoint.x.toStringAsFixed(3)}, ${keypoint.y.toStringAsFixed(3)})');
      print(
          '  Raw (directo):          (${raw.dx.toStringAsFixed(1)}, ${raw.dy.toStringAsFixed(1)})');
      print(
          '  Transformed (rotado):   (${transformed.dx.toStringAsFixed(1)}, ${transformed.dy.toStringAsFixed(1)})');
      print(
          '  Delta: ${(transformed - raw).distance.toStringAsFixed(1)} píxeles');
    }

    print('════════════════════════════════════════════\n');
  }

  /// Verifica si la orientación del sensor es la esperada
  static bool verifySensorOrientation(int sensorOrientation) {
    const expectedOrientation = 270; // Cámara frontal landscape

    if (sensorOrientation != expectedOrientation) {
      print('⚠️ ADVERTENCIA: Orientación del sensor inesperada');
      print('   Esperado: $expectedOrientation°');
      print('   Actual: $sensorOrientation°');
      print('   Esto puede causar desalineación del skeleton.');
      return false;
    }

    return true;
  }

  /// Calcula el error promedio de alineación entre skeleton y keypoints
  static double calculateAlignmentError(
    PoseDetection pose,
    Size canvasSize,
  ) {
    final validKeypoints = pose.keypoints.where((k) => k.isValid).toList();
    if (validKeypoints.isEmpty) return 0.0;

    double totalError = 0.0;

    for (final keypoint in validKeypoints) {
      final raw = Offset(
        keypoint.x * canvasSize.width,
        keypoint.y * canvasSize.height,
      );

      final transformed = DrawingUtils.transformCoordinate(
        keypoint,
        canvasSize.width,
        canvasSize.height,
      );

      totalError += (transformed - raw).distance;
    }

    return totalError / validKeypoints.length;
  }
}
