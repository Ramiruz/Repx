import '../../models/fitness_test/fitness_test_state.dart';

/// Gestor de estado de navegación del Fitness Test
/// 
/// Proporciona helpers para determinar transiciones
/// y propiedades de cada fase.
class ExerciseStateManager {
  /// Obtiene la siguiente fase en el flujo
  static FitnessTestPhase getNextPhase(FitnessTestPhase current) {
    return current.nextPhase;
  }

  /// ¿Es una fase de pausa/receso?
  static bool isPausedPhase(FitnessTestPhase phase) {
    return phase.isRestPhase;
  }

  /// Obtiene el tipo de ejercicio para una fase
  static FitnessTestExerciseType? getExerciseType(FitnessTestPhase phase) {
    return phase.exerciseType;
  }

  /// ¿Debe auto-transicionar cuando termina el timer?
  static bool shouldAutoTransition(FitnessTestPhase phase) {
    // Todas las fases con timer auto-transicionan
    return phase.durationSeconds > 0;
  }

  /// Obtiene la duración del timer para una fase
  static int getPhaseTimer(FitnessTestPhase phase) {
    return phase.durationSeconds;
  }

  /// Obtiene el título de la fase para mostrar en UI
  static String getPhaseTitle(FitnessTestPhase phase) {
    switch (phase) {
      case FitnessTestPhase.intro:
        return 'INSTRUCCIONES';
      case FitnessTestPhase.pushup:
        return 'FLEXIONES';
      case FitnessTestPhase.rest1:
        return 'DESCANSO';
      case FitnessTestPhase.squat:
        return 'SENTADILLAS';
      case FitnessTestPhase.rest2:
        return 'DESCANSO';
      case FitnessTestPhase.abdominal:
        return 'ABDOMINALES';
      case FitnessTestPhase.summary:
        return 'RESULTADOS';
      case FitnessTestPhase.completed:
        return 'COMPLETADO';
    }
  }

  /// Obtiene el índice de progreso (0.0 - 1.0)
  static double getProgressPercentage(FitnessTestPhase phase) {
    return phase.progressIndex / 6.0;
  }

  /// ¿Es la última fase de ejercicio?
  static bool isLastExercise(FitnessTestPhase phase) {
    return phase == FitnessTestPhase.abdominal;
  }

  /// Calcula el color de la fase para UI
  static String getPhaseColorHex(FitnessTestPhase phase) {
    switch (phase) {
      case FitnessTestPhase.intro:
        return '#00F5FF'; // Cyan
      case FitnessTestPhase.pushup:
        return '#FF6B6B'; // Rojo suave
      case FitnessTestPhase.rest1:
      case FitnessTestPhase.rest2:
        return '#06FFA5'; // Verde
      case FitnessTestPhase.squat:
        return '#9D4EDD'; // Púrpura
      case FitnessTestPhase.abdominal:
        return '#FFD60A'; // Amarillo
      case FitnessTestPhase.summary:
      case FitnessTestPhase.completed:
        return '#00F5FF'; // Cyan
    }
  }
}

