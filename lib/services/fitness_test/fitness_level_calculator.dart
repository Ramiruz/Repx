import '../../models/fitness_test/fitness_level.dart';

/// Calculadora de nivel de fitness y generador de sugerencias
class FitnessLevelCalculator {
  /// Calcula el nivel de fitness basado en repeticiones totales
  static FitnessLevel calculateLevel(int totalReps) {
    return FitnessLevelExtension.fromTotalReps(totalReps);
  }

  /// Genera sugerencias personalizadas basadas en el rendimiento
  static List<String> generateSuggestions({
    required int pushupCount,
    required int squatCount,
    required int abdominalCount,
    required double pushupQuality,
    required double squatQuality,
    required double abdominalQuality,
  }) {
    final List<String> suggestions = [];

    // Analizar cantidad de repeticiones
    final counts = {
      'flexiones': pushupCount,
      'sentadillas': squatCount,
      'abdominales': abdominalCount,
    };

    // Encontrar ejercicio con menos reps
    final minExercise = counts.entries.reduce(
      (a, b) => a.value < b.value ? a : b,
    );

    // Encontrar ejercicio con más reps
    final maxExercise = counts.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );

    // Sugerencia 1: Mejorar ejercicio más débil
    if (minExercise.value < 15) {
      suggestions.add(
        'Enfócate en mejorar ${minExercise.key}: solo ${minExercise.value} reps. '
        'Intenta llegar a 20+.',
      );
    } else if (minExercise.value < 20) {
      suggestions.add(
        'Tus ${minExercise.key} están bien (${minExercise.value}), '
        'pero puedes llegar a 25+.',
      );
    }

    // Sugerencia 2: Calidad baja
    final qualities = {
      'flexiones': pushupQuality,
      'sentadillas': squatQuality,
      'abdominales': abdominalQuality,
    };

    for (var entry in qualities.entries) {
      if (entry.value > 0 && entry.value < 0.75) {
        suggestions.add(
          'Mejora tu técnica en ${entry.key}: calidad ${(entry.value * 100).toStringAsFixed(0)}%. '
          'Presta atención a la forma correcta.',
        );
        break; // Solo una sugerencia de calidad
      }
    }

    // Sugerencia 3: Desequilibrio
    final diff = maxExercise.value - minExercise.value;
    if (diff > 10 && minExercise.value > 0) {
      suggestions.add(
        'Hay desequilibrio entre ejercicios: ${maxExercise.value} ${maxExercise.key} '
        'vs ${minExercise.value} ${minExercise.key}. Trabaja en equilibrar.',
      );
    }

    // Sugerencia 4: Específica por ejercicio
    if (pushupQuality >= 0.85 && pushupCount >= 20) {
      suggestions.add('¡Excelente forma en flexiones! Sigue así.');
    }

    if (squatCount >= 20 && squatQuality >= 0.80) {
      suggestions.add('Buen trabajo en sentadillas. Intenta más profundidad.');
    }

    if (abdominalCount >= 25) {
      suggestions.add('Gran resistencia abdominal. Prueba variaciones más difíciles.');
    }

    // Sugerencia 5: General según nivel
    final totalReps = pushupCount + squatCount + abdominalCount;
    final level = calculateLevel(totalReps);

    switch (level) {
      case FitnessLevel.principiante:
        suggestions.add(
          'Nivel principiante: Enfócate en consistencia. '
          'Practica 3-4 veces por semana.',
        );
        break;
      case FitnessLevel.intermedio:
        suggestions.add(
          'Nivel intermedio: Buen progreso. '
          'Aumenta gradualmente el número de reps.',
        );
        break;
      case FitnessLevel.avanzado:
        suggestions.add(
          'Nivel avanzado: ¡Impresionante! '
          'Considera añadir peso o variaciones.',
        );
        break;
      case FitnessLevel.atleta:
        suggestions.add(
          '¡Nivel de atleta! Mantén tu rutina y '
          'desafíate con ejercicios más complejos.',
        );
        break;
    }

    // Limitar a 4 sugerencias máximo
    if (suggestions.length > 4) {
      return suggestions.sublist(0, 4);
    }

    return suggestions;
  }

  /// Obtiene estado descriptivo para un ejercicio
  static String getExerciseStatus(int count, double quality) {
    if (count >= 25 && quality >= 0.85) return 'Excelente ✅';
    if (count >= 20 && quality >= 0.75) return 'Muy Bien ✅';
    if (count >= 15 && quality >= 0.65) return 'Bien 👍';
    if (count >= 10) return 'Regular 📈';
    return 'Necesita mejora 💪';
  }

  /// Calcula puntuación total (0-100)
  static int calculateScore({
    required int pushupCount,
    required int squatCount,
    required int abdominalCount,
    required double pushupQuality,
    required double squatQuality,
    required double abdominalQuality,
  }) {
    final totalReps = pushupCount + squatCount + abdominalCount;

    // Puntuación base por reps (0-70 puntos)
    double repsScore = (totalReps / 90) * 70;
    repsScore = repsScore.clamp(0, 70);

    // Puntuación por calidad promedio (0-30 puntos)
    int qualityCount = 0;
    double qualitySum = 0;

    if (pushupCount > 0) {
      qualitySum += pushupQuality;
      qualityCount++;
    }
    if (squatCount > 0) {
      qualitySum += squatQuality;
      qualityCount++;
    }
    if (abdominalCount > 0) {
      qualitySum += abdominalQuality;
      qualityCount++;
    }

    final avgQuality = qualityCount > 0 ? qualitySum / qualityCount : 0;
    final qualityScore = avgQuality * 30;

    return (repsScore + qualityScore).round().clamp(0, 100);
  }
}

