import 'package:flutter/foundation.dart';
import '../models/pose_keypoint.dart';
import 'angle_calculator.dart';

/// Resultado de validación de pose
class PoseValidationResult {
  final bool isValid;
  final List<String> errors; // Lista de errores encontrados
  final Map<String, double> angles; // Ángulos calculados
  final double formQuality; // Calidad de forma (0-100)

  PoseValidationResult({
    required this.isValid,
    List<String>? errors,
    Map<String, double>? angles,
    this.formQuality = 0.0,
  })  : errors = errors ?? [],
        angles = angles ?? {};

  @override
  String toString() {
    return 'PoseValidation(valid: $isValid, quality: ${formQuality.toStringAsFixed(1)}%, errors: $errors)';
  }
}

/// Validador de poses para flexiones de pecho
class PoseValidator {
  // 🚨 CRÍTICO: Validación de presencia de persona (AJUSTADO para casos reales)
  static const int minKeypointsForPerson =
      5; // Ajustado a 5 puntos críticos para ser más permisivo cuando el sujeto está lejos
  static const double minAverageConfidence =
      0.30; // Confianza promedio mínima reducida a 30% para permitir detecciones débiles

  // Umbrales de ángulos para validación (OPTIMIZADOS según datos reales)
  static const double minElbowAngleDown =
      90.0; // Ángulo mínimo en posición baja (flexión ~90° es estándar fitness)
  static const double maxElbowAngleDown =
      140.0; // Ángulo máximo en posición baja (AJUSTADO - permite ROM natural 90-140°)
  static const double minElbowAngleUp =
      140.0; // Ángulo mínimo en posición alta (REDUCIDO de 150° - más permisivo)
  static const double maxElbowAngleUp = 180.0; // Ángulo máximo en posición alta

  static const double minBackAngle = 160.0; // Ángulo mínimo de espalda recta
  static const double maxBackAngle = 180.0; // Ángulo máximo de espalda

  // 📏 LÍNEA IMAGINARIA: Validación de profundidad (eje Y)
  // Muñecas deben bajar mínimo 6% respecto a hombros para contar flexión
  static const double minDepthThreshold =
      0.06; // 6% de la altura (AJUSTADO - más permisivo para ángulos de cámara variados)

  /// Valida si la pose está en posición "arriba" (brazos extendidos)
  static PoseValidationResult validateUpPosition(PoseDetection pose) {
    final errors = <String>[];
    final angles = <String, double>{};
    double qualityScore = 100.0;

    // 🚨 VALIDACIÓN CRÍTICA: Verificar que hay una persona presente
    if (!_isPersonPresent(pose)) {
      return PoseValidationResult(
        isValid: false,
        errors: ['No se detecta persona en el cuadro'],
        formQuality: 0.0,
      );
    }

    // 🏋️ VALIDAR POSTURA HORIZONTAL (plancha)
    if (!isInPlankPosition(pose)) {
      return PoseValidationResult(
        isValid: false,
        errors: ['Colócate en posición de plancha'],
        formQuality: 0.0,
      );
    }

    // 📏 VALIDACIÓN DE LÍNEA IMAGINARIA: Verificar que está arriba (muñecas cerca de hombros)
    // AHORA: Solo advertencia, NO bloqueante
    final validDepth = _validateDepthPosition(pose, isDownPosition: false);
    if (!validDepth) {
      // Solo penalizar calidad, NO invalidar la pose
      errors.add('Intenta extender más los brazos');
      qualityScore -= 10.0; // Penalización REDUCIDA (antes 15)
    }

    // Calcular ángulos de codos
    final leftElbow = AngleCalculator.calculateElbowAngle(pose, 'left');
    final rightElbow = AngleCalculator.calculateElbowAngle(pose, 'right');
    final avgElbow = AngleCalculator.calculateAverageAngle(
      leftElbow,
      rightElbow,
    );

    if (leftElbow != null) angles['left_elbow'] = leftElbow;
    if (rightElbow != null) angles['right_elbow'] = rightElbow;

    // Validar extensión de brazos (PENALTIES SUAVES)
    if (avgElbow == null) {
      errors.add('No se pudieron detectar los codos');
      qualityScore = 0.0; // Sin datos = sin calidad
    } else if (avgElbow < minElbowAngleUp) {
      errors.add('¡Extiende más los brazos!');
      // Penalty progresiva pero MÁS SUAVE: máximo -30 puntos
      final penalty = ((minElbowAngleUp - avgElbow) * 0.3).clamp(0.0, 30.0);
      qualityScore -= penalty;
    }

    // Calcular ángulo de espalda
    final leftBack = AngleCalculator.calculateBackAngle(pose, 'left');
    final rightBack = AngleCalculator.calculateBackAngle(pose, 'right');
    final avgBack = AngleCalculator.calculateAverageAngle(leftBack, rightBack);

    if (leftBack != null) angles['left_back'] = leftBack;
    if (rightBack != null) angles['right_back'] = rightBack;

    // Validar espalda recta (OPCIONAL - puede estar fuera de cuadro)
    if (avgBack == null) {
      // ⚠️ Caderas fuera de cuadro - NO invalidar, penalización muy leve
      // errors.add('No se pudo detectar la postura de la espalda'); // REMOVIDO
      qualityScore -=
          5; // Penalización muy leve (caderas pueden estar fuera de cuadro)
    } else if (avgBack < minBackAngle) {
      errors.add('Mantén la espalda recta');
      // Penalty progresiva: máximo -30 puntos
      final penalty = ((minBackAngle - avgBack) * 0.3).clamp(0.0, 30.0);
      qualityScore -= penalty;
    }

    // CLAMP FINAL - CRÍTICO para evitar valores exagerados
    qualityScore = qualityScore.clamp(0.0, 100.0);

    return PoseValidationResult(
      isValid: avgElbow !=
          null, // ✅ Válido si hay ángulos de codo (espalda OPCIONAL)
      errors: errors,
      angles: angles,
      formQuality: qualityScore,
    );
  }

  /// Valida si la pose está en posición "abajo" (brazos flexionados)
  static PoseValidationResult validateDownPosition(PoseDetection pose) {
    final errors = <String>[];
    final angles = <String, double>{};
    double qualityScore = 100.0;

    // 🚨 VALIDACIÓN CRÍTICA: Verificar que hay una persona presente
    if (!_isPersonPresent(pose)) {
      return PoseValidationResult(
        isValid: false,
        errors: ['No se detecta persona en el cuadro'],
        formQuality: 0.0,
      );
    }

    // 🏋️ VALIDAR POSTURA HORIZONTAL (plancha)
    if (!isInPlankPosition(pose)) {
      return PoseValidationResult(
        isValid: false,
        errors: ['Colócate en posición de plancha'],
        formQuality: 0.0,
      );
    }

    // 📏 VALIDACIÓN DE LÍNEA IMAGINARIA: Verificar que descendió (muñecas abajo de hombros)
    // AHORA: Solo advertencia si no hay datos, NO bloqueante
    final validDepth = _validateDepthPosition(pose, isDownPosition: true);
    if (!validDepth) {
      // Solo penalizar calidad moderadamente, NO invalidar
      errors.add('Intenta bajar un poco más');
      qualityScore -= 12.0; // Penalización REDUCIDA (antes 20)
    }

    // Calcular ángulos de codos
    final leftElbow = AngleCalculator.calculateElbowAngle(pose, 'left');
    final rightElbow = AngleCalculator.calculateElbowAngle(pose, 'right');
    final avgElbow = AngleCalculator.calculateAverageAngle(
      leftElbow,
      rightElbow,
    );

    if (leftElbow != null) angles['left_elbow'] = leftElbow;
    if (rightElbow != null) angles['right_elbow'] = rightElbow;

    // Validar flexión de brazos (PENALTIES SUAVES)
    if (avgElbow == null) {
      errors.add('No se pudieron detectar los codos');
      qualityScore = 0.0; // Sin datos = sin calidad
    } else if (avgElbow > maxElbowAngleDown) {
      errors.add('¡Baja más! Flexiona los codos');
      // Penalty progresiva: máximo -40 puntos
      final penalty = ((avgElbow - maxElbowAngleDown) * 0.5).clamp(0.0, 40.0);
      qualityScore -= penalty;
    } else if (avgElbow < minElbowAngleDown) {
      errors.add('No bajes demasiado');
      // Penalty mínima
      final penalty = ((minElbowAngleDown - avgElbow) * 0.2).clamp(0.0, 20.0);
      qualityScore -= penalty;
    }

    // Calcular ángulo de espalda
    final leftBack = AngleCalculator.calculateBackAngle(pose, 'left');
    final rightBack = AngleCalculator.calculateBackAngle(pose, 'right');
    final avgBack = AngleCalculator.calculateAverageAngle(leftBack, rightBack);

    if (leftBack != null) angles['left_back'] = leftBack;
    if (rightBack != null) angles['right_back'] = rightBack;

    // Validar espalda recta (OPCIONAL)
    if (avgBack == null) {
      // ⚠️ Caderas fuera de cuadro - penalización muy leve
      qualityScore -= 5;
    } else if (avgBack < minBackAngle) {
      errors.add('Mantén la espalda recta');
      // Penalty progresiva: máximo -30 puntos
      final penalty = ((minBackAngle - avgBack) * 0.3).clamp(0.0, 30.0);
      qualityScore -= penalty;
    }
    // Si avgBack es null, no penalizar (puede estar fuera de cuadro)

    // CLAMP FINAL - CRÍTICO para evitar valores exagerados
    qualityScore = qualityScore.clamp(0.0, 100.0);
    qualityScore = qualityScore.clamp(0.0, 100.0);

    return PoseValidationResult(
      isValid: avgElbow != null, // ✅ Válido si hay ángulos de codo
      errors: errors,
      angles: angles,
      formQuality: qualityScore,
    );
  }

  /// Valida la pose general (verifica que todos los keypoints necesarios estén presentes)
  static bool validatePoseDetection(PoseDetection pose) {
    if (!pose.isValid) return false;

    // Verificar que los keypoints críticos estén presentes y sean válidos
    final criticalKeypoints = [
      'left_shoulder',
      'right_shoulder',
      'left_elbow',
      'right_elbow',
      'left_wrist',
      'right_wrist',
      'left_hip',
      'right_hip',
    ];

    for (final keypointName in criticalKeypoints) {
      final kp = pose.getKeypoint(keypointName);
      if (kp == null || !kp.isValid) {
        return false;
      }
    }

    return true;
  }

  /// Obtiene un mensaje de feedback basado en los errores
  static String getFeedbackMessage(List<String> errors) {
    if (errors.isEmpty) return '¡Perfecto! ✓';
    return errors.first; // Retorna el error más importante
  }

  /// 🚨 Valida que hay una persona presente en el cuadro
  /// Previene falsas alarmas cuando no hay nadie (teléfono en el techo, etc.)
  static bool _isPersonPresent(PoseDetection pose) {
    // Contar keypoints válidos (confianza > umbral moderado)
    int validKeypointsCount = 0;
    double totalConfidence = 0.0;
    int totalKeypoints = 0;

    for (final keypoint in pose.keypoints) {
      // Contar puntos con confianza moderada (>=0.20) para ser tolerantes a distancia
      if (keypoint.confidence > 0.20) {
        validKeypointsCount++;
        totalConfidence += keypoint.confidence;
        totalKeypoints++;
      }
    }

    // Calcular confianza promedio
    final avgConfidence =
        totalKeypoints > 0 ? totalConfidence / totalKeypoints : 0.0;

    // AJUSTADO: Requiere mínimo 6 puntos críticos Y confianza promedio > 35%
    // Adicionalmente, verificar que al menos tengamos hombros O codos
    final hasCriticalPoints = pose.keypoints.any((kp) =>
        (kp.name.contains('shoulder') || kp.name.contains('elbow')) &&
        kp.confidence > 0.3);

    // Si la detección es débil pero tenemos al menos hombros/codos, consideramos presente
    final isPresent = (validKeypointsCount >= minKeypointsForPerson &&
            avgConfidence >= minAverageConfidence &&
            hasCriticalPoints) ||
        (validKeypointsCount >= 4 &&
            hasCriticalPoints &&
            avgConfidence >= 0.22);

    if (!isPresent) {
      print(
          '⚠️ Persona NO detectada: $validKeypointsCount keypoints (min $minKeypointsForPerson), '
          'confianza: ${(avgConfidence * 100).toStringAsFixed(1)}% (min ${(minAverageConfidence * 100).toStringAsFixed(0)}%)');
    }

    return isPresent;
  }

  /// 📏 Valida profundidad usando línea imaginaria (eje Y)
  /// Verifica si muñecas están por debajo/arriba de hombros según posición
  static bool _validateDepthPosition(PoseDetection pose,
      {required bool isDownPosition}) {
    // Obtener puntos críticos con AL MENOS UN LADO válido
    final leftShoulder = pose.getKeypoint('left_shoulder');
    final rightShoulder = pose.getKeypoint('right_shoulder');
    final leftWrist = pose.getKeypoint('left_wrist');
    final rightWrist = pose.getKeypoint('right_wrist');

    // Necesitamos al menos un hombro y una muñeca válidos
    final hasValidLeft = leftShoulder != null &&
        leftShoulder.isValid &&
        leftWrist != null &&
        leftWrist.isValid;
    final hasValidRight = rightShoulder != null &&
        rightShoulder.isValid &&
        rightWrist != null &&
        rightWrist.isValid;

    if (!hasValidLeft && !hasValidRight) {
      return false; // No hay datos suficientes
    }

    // Calcular profundidad con el lado válido (o promedio si ambos válidos)
    double depthDiff = 0.0;
    int validCount = 0;

    if (hasValidLeft) {
      depthDiff += (leftWrist.y - leftShoulder.y); // Positivo = muñeca abajo
      validCount++;
    }
    if (hasValidRight) {
      depthDiff += (rightWrist.y - rightShoulder.y);
      validCount++;
    }

    final avgDepth = depthDiff / validCount;

    if (isDownPosition) {
      // ABAJO: Muñecas deben estar MÁS ABAJO que hombros (Y mayor)
      return avgDepth > minDepthThreshold; // Descendió suficiente
    } else {
      // ARRIBA: Muñecas cerca del nivel de hombros (diferencia pequeña)
      return avgDepth.abs() < minDepthThreshold; // Está extendido
    }
  }

  /// 🏋️ Valida que la persona esté en posición de plancha (horizontal)
  /// Evita contar flexiones cuando la persona está sentada o de pie
  ///
  /// AHORA PÚBLICO para usar en filtro preventivo de PushUpCounter
  static bool isInPlankPosition(PoseDetection pose) {
    // 🚨 VALIDACIÓN CRÍTICA: Detectar si el dispositivo está boca arriba (mirando al techo)
    // Si la nariz está muy abajo en Y (cerca de 0), el celular está horizontal mirando arriba
    final nose = pose.getKeypoint('nose');
    // Nota: el chequeo original asumía que nariz muy cerca del top (y<0.15)
    // indica que el dispositivo está boca-arriba. Esto puede fallar cuando
    // el usuario está MUY CERCA de la cámara (nariz cerca del top). Ahora
    // solo consideraremos "boca arriba" si la nariz está extremadamente
    // cerca del borde superior AND no hay hombros válidos detectados.
    if (nose != null && nose.isValid) {
      final leftShoulder = pose.getKeypoint('left_shoulder');
      final rightShoulder = pose.getKeypoint('right_shoulder');
      final hasShoulders = (leftShoulder != null && leftShoulder.isValid) ||
          (rightShoulder != null && rightShoulder.isValid);

      // Umbral estricto para considerar dispositivo boca-arriba
      if (nose.y < 0.05 && !hasShoulders) {
        if (kDebugMode) {
          // ignore: avoid_print
          print(
              '⚠️ Dispositivo boca arriba detectado (nariz Y=${(nose.y * 100).toStringAsFixed(0)}%) y sin hombros válidos');
        }
        return false; // Celular mirando al techo
      }
    }

    // Obtener puntos clave: hombros, caderas y rodillas
    final leftShoulder = pose.getKeypoint('left_shoulder');
    final rightShoulder = pose.getKeypoint('right_shoulder');
    final leftHip = pose.getKeypoint('left_hip');
    final rightHip = pose.getKeypoint('right_hip');
    final leftKnee = pose.getKeypoint('left_knee');
    final rightKnee = pose.getKeypoint('right_knee');

    // Necesitamos al menos hombros y caderas válidos
    final hasValidShoulders = (leftShoulder != null && leftShoulder.isValid) ||
        (rightShoulder != null && rightShoulder.isValid);
    final hasValidHips = (leftHip != null && leftHip.isValid) ||
        (rightHip != null && rightHip.isValid);

    if (!hasValidShoulders || !hasValidHips) {
      return false; // No hay datos suficientes
    }

    // Calcular altura promedio de hombros y caderas
    double shoulderY = 0.0;
    int shoulderCount = 0;
    if (leftShoulder != null && leftShoulder.isValid) {
      shoulderY += leftShoulder.y;
      shoulderCount++;
    }
    if (rightShoulder != null && rightShoulder.isValid) {
      shoulderY += rightShoulder.y;
      shoulderCount++;
    }
    shoulderY /= shoulderCount;

    double hipY = 0.0;
    int hipCount = 0;
    if (leftHip != null && leftHip.isValid) {
      hipY += leftHip.y;
      hipCount++;
    }
    if (rightHip != null && rightHip.isValid) {
      hipY += rightHip.y;
      hipCount++;
    }
    hipY /= hipCount;

    // Validación 1: Hombros y caderas deben estar aproximadamente alineados (plancha)
    // En posición horizontal, la diferencia Y debe ser pequeña (< 50% de altura)
    final bodyAlignment = (hipY - shoulderY).abs();
    if (bodyAlignment > 0.50) {
      // Si caderas están mucho más abajo que hombros = persona sentada o agachada
      print(
          '⚠️ NO es plancha: diferencia hombro-cadera ${(bodyAlignment * 100).toStringAsFixed(0)}% (max 50%)');
      return false;
    }

    // Validación 2: Rodillas NO deben estar al nivel de las caderas (rodillas extendidas)
    // Si rodillas están muy cerca de caderas en Y = persona sentada
    if (leftKnee != null && leftKnee.isValid) {
      final kneeHipDiff = (leftKnee.y - hipY).abs();
      if (kneeHipDiff < 0.10) {
        print('⚠️ NO es plancha: rodilla izquierda muy cerca de cadera');
        return false;
      }
    }

    if (rightKnee != null && rightKnee.isValid) {
      final kneeHipDiff = (rightKnee.y - hipY).abs();
      if (kneeHipDiff < 0.10) {
        print('⚠️ NO es plancha: rodilla derecha muy cerca de cadera');
        return false;
      }
    }

    return true; // Posición válida de plancha
  }
}

