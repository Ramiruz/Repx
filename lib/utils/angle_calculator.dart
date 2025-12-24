import 'dart:math' as math;
import '../models/pose_keypoint.dart';

/// Utilidad para calcular ángulos entre puntos clave del cuerpo
class AngleCalculator {
  /// Calcula el ángulo entre tres puntos (en grados)
  ///
  /// Parámetros:
  /// - [pointA]: Primer punto (ej: hombro)
  /// - [pointB]: Punto central/vértice (ej: codo)
  /// - [pointC]: Tercer punto (ej: muñeca)
  ///
  /// Retorna el ángulo en grados (0-180)
  static double calculateAngle(
    PoseKeypoint pointA,
    PoseKeypoint pointB,
    PoseKeypoint pointC,
  ) {
    // Vectores desde el punto B (vértice) hacia A y C
    final vectorBA = _Vector2D(pointA.x - pointB.x, pointA.y - pointB.y);
    final vectorBC = _Vector2D(pointC.x - pointB.x, pointC.y - pointB.y);

    // Producto punto de los vectores
    final dotProduct = vectorBA.x * vectorBC.x + vectorBA.y * vectorBC.y;

    // Magnitudes de los vectores
    final magnitudeBA = math.sqrt(
      vectorBA.x * vectorBA.x + vectorBA.y * vectorBA.y,
    );
    final magnitudeBC = math.sqrt(
      vectorBC.x * vectorBC.x + vectorBC.y * vectorBC.y,
    );

    // Evitar división por cero
    if (magnitudeBA == 0 || magnitudeBC == 0) {
      return 0.0;
    }

    // Calcular el ángulo usando el coseno
    final cosineAngle = dotProduct / (magnitudeBA * magnitudeBC);

    // Limitar el valor entre -1 y 1 para evitar errores de acos
    final clampedCosine = cosineAngle.clamp(-1.0, 1.0);

    // Convertir de radianes a grados
    final angleRadians = math.acos(clampedCosine);
    final angleDegrees = angleRadians * (180.0 / math.pi);

    return angleDegrees;
  }

  /// Calcula el ángulo del codo (hombro -> codo -> muñeca)
  static double? calculateElbowAngle(
    PoseDetection pose,
    String side, // 'left' o 'right'
  ) {
    final shoulder = pose.getKeypoint('${side}_shoulder');
    final elbow = pose.getKeypoint('${side}_elbow');
    final wrist = pose.getKeypoint('${side}_wrist');

    // 🔍 DEBUG: Solo logear si falta algún keypoint crítico
    if (shoulder == null || elbow == null || wrist == null) {
      print(
          '⚠️ Keypoints $side faltantes: shoulder=${shoulder != null}, elbow=${elbow != null}, wrist=${wrist != null}');
      return null;
    }

    // AJUSTADO: Umbral más permisivo (0.12 en lugar de 0.15 de isValid)
    const minConfidence = 0.12;
    if (shoulder.confidence < minConfidence ||
        elbow.confidence < minConfidence ||
        wrist.confidence < minConfidence) {
      print(
          '⚠️ Confianza $side baja: shoulder=${(shoulder.confidence * 100).toStringAsFixed(0)}%, '
          'elbow=${(elbow.confidence * 100).toStringAsFixed(0)}%, '
          'wrist=${(wrist.confidence * 100).toStringAsFixed(0)}%');
      return null;
    }

    final angle = calculateAngle(shoulder, elbow, wrist);
    print('✅ Ángulo $side codo calculado: ${angle.toStringAsFixed(1)}°');
    return angle;
  }

  /// Calcula el ángulo de la espalda (hombro -> cadera -> rodilla)
  static double? calculateBackAngle(
    PoseDetection pose,
    String side, // 'left' o 'right'
  ) {
    final shoulder = pose.getKeypoint('${side}_shoulder');
    final hip = pose.getKeypoint('${side}_hip');
    final knee = pose.getKeypoint('${side}_knee');

    if (shoulder == null || hip == null || knee == null) {
      return null;
    }

    if (!shoulder.isValid || !hip.isValid || !knee.isValid) {
      return null;
    }

    return calculateAngle(shoulder, hip, knee);
  }

  /// Calcula el promedio de ángulos de ambos lados
  /// ✅ MODIFICADO: Acepta un solo brazo válido (permite contar con un brazo)
  static double? calculateAverageAngle(double? left, double? right) {
    if (left == null && right == null) return null;
    if (left == null) return right; // Solo derecho válido
    if (right == null) return left; // Solo izquierdo válido
    return (left + right) / 2; // Ambos válidos: promediar
  }

  /// Calcula la distancia euclidiana entre dos puntos
  static double calculateDistance(PoseKeypoint pointA, PoseKeypoint pointB) {
    final dx = pointA.x - pointB.x;
    final dy = pointA.y - pointB.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Verifica si un ángulo está dentro de un rango
  static bool isAngleInRange(double? angle, double min, double max) {
    if (angle == null) return false;
    return angle >= min && angle <= max;
  }

  /// Normaliza un ángulo a un rango 0-180
  static double normalizeAngle(double angle) {
    double normalized = angle % 360;
    if (normalized > 180) {
      normalized = 360 - normalized;
    }
    return normalized.abs();
  }
}

/// Clase auxiliar para representar vectores 2D
class _Vector2D {
  final double x;
  final double y;

  _Vector2D(this.x, this.y);

  double get magnitude => math.sqrt(x * x + y * y);

  _Vector2D normalize() {
    final mag = magnitude;
    if (mag == 0) return _Vector2D(0, 0);
    return _Vector2D(x / mag, y / mag);
  }

  @override
  String toString() => 'Vector2D($x, $y)';
}

