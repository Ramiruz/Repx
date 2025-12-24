import '../models/pose_keypoint.dart';

/// Validador de forma para Pull-Ups
class PullUpValidator {
  /// Verifica si la persona está en posición colgando de la barra (más permisivo)
  static bool isHangingPosition(PoseDetection pose) {
    // Obtener keypoints clave (solo requerimos hombros para simplificar)
    final leftShoulder = pose.getKeypoint('left_shoulder');
    final rightShoulder = pose.getKeypoint('right_shoulder');
    final leftHip = pose.getKeypoint('left_hip');
    final rightHip = pose.getKeypoint('right_hip');

    // Validar que existan al menos los hombros
    if (leftShoulder == null || rightShoulder == null) {
      return false;
    }

    // Validar confianza mínima (solo hombros)
    if (!leftShoulder.isValid || !rightShoulder.isValid) {
      return false;
    }

    // Condición principal: los hombros deben estar ARRIBA de las caderas (cuerpo vertical)
    // Es más permisivo - solo verifica que el torso esté en orientación vertical
    if (leftHip != null &&
        rightHip != null &&
        leftHip.isValid &&
        rightHip.isValid) {
      final shouldersAboveHips =
          (leftShoulder.y < leftHip.y) && (rightShoulder.y < rightHip.y);
      return shouldersAboveHips;
    }

    // Si no hay caderas detectadas, asumimos que está colgando si hay hombros válidos
    return true;
  }

  /// Calcula la altura promedio de la cabeza (normalizada 0-1)
  /// Valores menores = más arriba en pantalla
  static double? getHeadHeight(PoseDetection pose) {
    final nose = pose.getKeypoint('nose');
    final leftEye = pose.getKeypoint('left_eye');
    final rightEye = pose.getKeypoint('right_eye');

    final validPoints =
        [nose, leftEye, rightEye].where((p) => p != null && p.isValid).toList();

    if (validPoints.isEmpty) return null;

    // Promedio de posiciones Y (0 = top, 1 = bottom)
    final avgY = validPoints.map((p) => p!.y).reduce((a, b) => a + b) /
        validPoints.length;

    return avgY;
  }

  /// Calcula la altura promedio del torso (hombros + caderas)
  static double? getTorsoHeight(PoseDetection pose) {
    final leftShoulder = pose.getKeypoint('left_shoulder');
    final rightShoulder = pose.getKeypoint('right_shoulder');
    final leftHip = pose.getKeypoint('left_hip');
    final rightHip = pose.getKeypoint('right_hip');

    final validPoints = [leftShoulder, rightShoulder, leftHip, rightHip]
        .where((p) => p != null && p.isValid)
        .toList();

    if (validPoints.isEmpty) return null;

    final avgY = validPoints.map((p) => p!.y).reduce((a, b) => a + b) /
        validPoints.length;

    return avgY;
  }

  /// Valida si el cuerpo está alineado (sin balanceo excesivo)
  static bool isBodyAligned(PoseDetection pose) {
    final leftShoulder = pose.getKeypoint('left_shoulder');
    final rightShoulder = pose.getKeypoint('right_shoulder');
    final leftHip = pose.getKeypoint('left_hip');
    final rightHip = pose.getKeypoint('right_hip');

    if (leftShoulder == null ||
        rightShoulder == null ||
        leftHip == null ||
        rightHip == null) {
      return false;
    }

    if (!leftShoulder.isValid ||
        !rightShoulder.isValid ||
        !leftHip.isValid ||
        !rightHip.isValid) {
      return false;
    }

    // Calcular centro de hombros y caderas
    final shoulderCenterX = (leftShoulder.x + rightShoulder.x) / 2;
    final hipCenterX = (leftHip.x + rightHip.x) / 2;

    // El desplazamiento horizontal debe ser mínimo (< 15% del ancho del cuerpo)
    final bodyWidth = (leftShoulder.x - rightShoulder.x).abs();
    final horizontalOffset = (shoulderCenterX - hipCenterX).abs();

    return horizontalOffset < bodyWidth * 0.15;
  }

  /// Calcula la calidad de la forma (0-100)
  static double calculateFormQuality(PoseDetection pose, double barHeight) {
    double quality = 100.0;

    // Penalización si no está en posición colgando
    if (!isHangingPosition(pose)) {
      quality -= 30;
    }

    // Penalización si el cuerpo no está alineado
    if (!isBodyAligned(pose)) {
      quality -= 20;
    }

    // Penalización por keypoints faltantes
    final totalKeypoints = pose.keypoints.length;
    final validKeypoints = pose.keypoints.where((k) => k.isValid).length;
    final keypointRatio = validKeypoints / totalKeypoints;
    quality *= keypointRatio;

    return quality.clamp(0.0, 100.0);
  }
}

