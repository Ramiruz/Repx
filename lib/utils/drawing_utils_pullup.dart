import 'package:flutter/material.dart';
import '../models/pose_keypoint.dart';
import 'app_colors.dart';

/// Utilidades de dibujado EXCLUSIVAS para ejercicio Pull-Ups (modo PORTRAIT)
class DrawingUtilsPullUp {
  // Colores del tema
  static const Color primaryColor = AppColors.primaryCyan;
  static const Color correctColor = AppColors.successGreen;
  static const Color errorColor = AppColors.errorPink;
  static const Color warningColor = AppColors.warningYellow;

  /// Dibuja el skeleton sobre la imagen en modo PORTRAIT
  static void drawSkeleton(
    Canvas canvas,
    Size size,
    PoseDetection pose, {
    bool showCorrectForm = true,
    Map<String, double>? angles,
  }) {
    // 🔧 PULL-UPS: Usar threshold MÁS BAJO porque en portrait la confianza es menor
    // Filtrar keypoints con confianza > 10% (en lugar de 30%)
    final validKeypoints =
        pose.keypoints.where((k) => k.confidence > 0.10).toList();

    print(
        '🎨 [PullUp] Total keypoints: ${pose.keypoints.length}, Válidos (>10%): ${validKeypoints.length}');

    if (validKeypoints.isEmpty) {
      return; // No hay nada que dibujar
    }

    // 🐛 DEBUG: Imprimir tamaño del canvas y coordenadas transformadas
    print('🎨 [PullUp] Canvas: ${size.width}x${size.height}');
    if (validKeypoints.isNotEmpty) {
      final testPoint = validKeypoints.first;
      final transformed =
          _transformCoordinatePortrait(testPoint, size.width, size.height);
      print(
          '🎨 [PullUp] Test: ${testPoint.name} raw(${testPoint.x}, ${testPoint.y}) → canvas(${transformed.dx}, ${transformed.dy})');
    }

    canvas.save();

    final displayWidth = size.width;
    final displayHeight = size.height;

    // Paint con anti-aliasing
    final paint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Función de transformación para PORTRAIT
    Offset transformPoint(PoseKeypoint point) =>
        _transformCoordinatePortrait(point, displayWidth, displayHeight);

    // Definir conexiones del skeleton completo
    final connections = [
      // CABEZA - Conectar ojos y nariz
      ['left_eye', 'right_eye'],
      ['left_eye', 'nose'],
      ['right_eye', 'nose'],

      // TORSO - Conectar hombros con caderas
      ['left_shoulder', 'right_shoulder'],
      ['left_shoulder', 'left_hip'],
      ['right_shoulder', 'right_hip'],
      ['left_hip', 'right_hip'],

      // BRAZOS - Hombro → Codo → Muñeca
      ['left_shoulder', 'left_elbow'],
      ['left_elbow', 'left_wrist'],
      ['right_shoulder', 'right_elbow'],
      ['right_elbow', 'right_wrist'],

      // PIERNAS - Cadera → Rodilla → Tobillo
      ['left_hip', 'left_knee'],
      ['left_knee', 'left_ankle'],
      ['right_hip', 'right_knee'],
      ['right_knee', 'right_ankle'],
    ];

    // Crear mapa de keypoints por nombre
    final keypointMap = {for (var kp in pose.keypoints) kp.name: kp};

    // Color basado en forma correcta
    final skeletonColor = showCorrectForm ? correctColor : primaryColor;

    // Dibujar conexiones
    for (final connection in connections) {
      final start = keypointMap[connection[0]];
      final end = keypointMap[connection[1]];

      // 🔧 PULL-UPS: Threshold más bajo (>10% en lugar de isValid que usa >30%)
      if (start != null &&
          end != null &&
          start.confidence > 0.10 &&
          end.confidence > 0.10) {
        final p1 = transformPoint(start);
        final p2 = transformPoint(end);

        // Sombra de la línea
        paint.color = Colors.black.withOpacity(0.3);
        paint.strokeWidth = 5.0;
        canvas.drawLine(p1.translate(1.5, 1.5), p2.translate(1.5, 1.5), paint);

        // Línea principal
        paint.color = skeletonColor;
        paint.strokeWidth = 4.0;
        canvas.drawLine(p1, p2, paint);
      }
    }

    // Dibujar keypoints principales
    _drawKeypoints(canvas, size, pose, showCorrectForm, angles);

    // Dibujar cabeza
    _drawHead(canvas, pose, transformPoint);

    canvas.restore();
  }

  /// Dibuja los keypoints como círculos
  static void _drawKeypoints(
    Canvas canvas,
    Size size,
    PoseDetection pose,
    bool showCorrectForm,
    Map<String, double>? angles,
  ) {
    final paint = Paint()..style = PaintingStyle.fill;

    final displayWidth = size.width;
    final displayHeight = size.height;

    Offset transformPoint(PoseKeypoint point) =>
        _transformCoordinatePortrait(point, displayWidth, displayHeight);

    // Solo dibujar articulaciones principales
    final mainJoints = [
      'left_shoulder',
      'right_shoulder',
      'left_elbow',
      'right_elbow',
      'left_wrist',
      'right_wrist',
      'left_hip',
      'right_hip',
      'left_knee',
      'right_knee',
      'left_ankle',
      'right_ankle',
    ];

    final keypointMap = {for (var kp in pose.keypoints) kp.name: kp};
    final jointColor = showCorrectForm ? correctColor : primaryColor;

    for (final jointName in mainJoints) {
      final keypoint = keypointMap[jointName];
      // 🔧 PULL-UPS: Threshold más bajo (>10% en lugar de isValid)
      if (keypoint != null && keypoint.confidence > 0.10) {
        final center = transformPoint(keypoint);
        final radius = 6.0;

        // Sombra del círculo
        paint.color = Colors.black.withOpacity(0.4);
        canvas.drawCircle(center.translate(1, 1), radius + 1, paint);

        // Círculo principal
        paint.color = jointColor;
        canvas.drawCircle(center, radius, paint);

        // Borde blanco
        paint.color = Colors.white;
        paint.style = PaintingStyle.stroke;
        paint.strokeWidth = 1.5;
        canvas.drawCircle(center, radius, paint);
        paint.style = PaintingStyle.fill;
      }
    }
  }

  /// Dibuja la cabeza como un círculo
  static void _drawHead(
    Canvas canvas,
    PoseDetection pose,
    Offset Function(PoseKeypoint) transformPoint,
  ) {
    final keypointMap = {for (var kp in pose.keypoints) kp.name: kp};

    final leftEye = keypointMap['left_eye'];
    final rightEye = keypointMap['right_eye'];
    final nose = keypointMap['nose'];

    // 🔧 PULL-UPS: Threshold más bajo (>10%)
    if (leftEye != null &&
        rightEye != null &&
        nose != null &&
        leftEye.confidence > 0.10 &&
        rightEye.confidence > 0.10 &&
        nose.confidence > 0.10) {
      final leftEyePos = transformPoint(leftEye);
      final rightEyePos = transformPoint(rightEye);

      // Centro de la cabeza (promedio de ojos)
      final center = Offset(
        (leftEyePos.dx + rightEyePos.dx) / 2,
        (leftEyePos.dy + rightEyePos.dy) / 2,
      );

      // Radio basado en distancia entre ojos
      final eyeDistance = (leftEyePos - rightEyePos).distance;
      final headRadius = eyeDistance * 1.8;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..color = primaryColor;

      // Sombra del círculo
      paint.color = Colors.black.withOpacity(0.4);
      paint.strokeWidth = 4.0;
      canvas.drawCircle(center.translate(1, 1), headRadius, paint);

      // Círculo principal de la cabeza
      paint.color = primaryColor;
      paint.strokeWidth = 3.5;
      canvas.drawCircle(center, headRadius, paint);
    }
  }

  /// Transforma coordenadas MediaPipe a coordenadas de canvas
  /// para modo PORTRAIT (Pull-Ups)
  ///
  /// En portrait con cámara frontal, necesitamos espejo horizontal
  static Offset _transformCoordinatePortrait(
    PoseKeypoint keypoint,
    double canvasWidth,
    double canvasHeight,
  ) {
    // Portrait: espejo horizontal para cámara frontal
    final x = canvasWidth * (1.0 - keypoint.x); // Espejo horizontal
    final y = canvasHeight * keypoint.y; // Vertical directa

    return Offset(x, y);
  }
}
