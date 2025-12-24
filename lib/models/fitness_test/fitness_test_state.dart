/// Tipos de ejercicio disponibles en el Fitness Test
enum FitnessTestExerciseType {
  /// Flexiones de pecho (Push-ups)
  pushup,

  /// Sentadillas (Squats)
  squat,

  /// Abdominales (Crunches)
  abdominal,
}

/// Extensión con propiedades de visualización
extension FitnessTestExerciseTypeExtension on FitnessTestExerciseType {
  /// Nombre para mostrar en español
  String get displayName {
    switch (this) {
      case FitnessTestExerciseType.pushup:
        return 'FLEXIONES';
      case FitnessTestExerciseType.squat:
        return 'SENTADILLAS';
      case FitnessTestExerciseType.abdominal:
        return 'ABDOMINALES';
    }
  }

  /// Emoji representativo
  String get emoji {
    switch (this) {
      case FitnessTestExerciseType.pushup:
        return '💪';
      case FitnessTestExerciseType.squat:
        return '🦵';
      case FitnessTestExerciseType.abdominal:
        return '🏃';
    }
  }

  /// Instrucciones de técnica
  String get technique {
    switch (this) {
      case FitnessTestExerciseType.pushup:
        return 'Cuerpo recto, brazos flexionados 90°';
      case FitnessTestExerciseType.squat:
        return 'Cadera hacia atrás, rodillas paralelas';
      case FitnessTestExerciseType.abdominal:
        return 'Levanta hombros hacia caderas, cuello recto';
    }
  }

  /// Mensaje de descanso post-ejercicio
  String get restMessage {
    switch (this) {
      case FitnessTestExerciseType.pushup:
        return 'Descansa, estira tus brazos';
      case FitnessTestExerciseType.squat:
        return 'Descansa, estira tus piernas';
      case FitnessTestExerciseType.abdominal:
        return '¡Test completado!';
    }
  }
}

/// Fases del Fitness Test (navegación)
enum FitnessTestPhase {
  /// Pantalla de instrucciones
  intro,

  /// Ejercicio: Flexiones (60s)
  pushup,

  /// Receso 1 (30s)
  rest1,

  /// Ejercicio: Sentadillas (60s)
  squat,

  /// Receso 2 (30s)
  rest2,

  /// Ejercicio: Abdominales (60s)
  abdominal,

  /// Pantalla de resumen/resultados
  summary,

  /// Test completado (estado final)
  completed,
}

/// Extensión con helpers de navegación
extension FitnessTestPhaseExtension on FitnessTestPhase {
  /// ¿Es una fase de ejercicio?
  bool get isExercisePhase {
    return this == FitnessTestPhase.pushup ||
        this == FitnessTestPhase.squat ||
        this == FitnessTestPhase.abdominal;
  }

  /// ¿Es una fase de descanso?
  bool get isRestPhase {
    return this == FitnessTestPhase.rest1 || this == FitnessTestPhase.rest2;
  }

  /// Duración de la fase en segundos
  int get durationSeconds {
    switch (this) {
      case FitnessTestPhase.intro:
      case FitnessTestPhase.summary:
      case FitnessTestPhase.completed:
        return 0; // Sin timer
      case FitnessTestPhase.pushup:
      case FitnessTestPhase.squat:
      case FitnessTestPhase.abdominal:
        return 60;
      case FitnessTestPhase.rest1:
      case FitnessTestPhase.rest2:
        return 30;
    }
  }

  /// Obtiene el tipo de ejercicio para fases de ejercicio
  FitnessTestExerciseType? get exerciseType {
    switch (this) {
      case FitnessTestPhase.pushup:
        return FitnessTestExerciseType.pushup;
      case FitnessTestPhase.squat:
        return FitnessTestExerciseType.squat;
      case FitnessTestPhase.abdominal:
        return FitnessTestExerciseType.abdominal;
      default:
        return null;
    }
  }

  /// Siguiente fase en el flujo
  FitnessTestPhase get nextPhase {
    switch (this) {
      case FitnessTestPhase.intro:
        return FitnessTestPhase.pushup;
      case FitnessTestPhase.pushup:
        return FitnessTestPhase.rest1;
      case FitnessTestPhase.rest1:
        return FitnessTestPhase.squat;
      case FitnessTestPhase.squat:
        return FitnessTestPhase.rest2;
      case FitnessTestPhase.rest2:
        return FitnessTestPhase.abdominal;
      case FitnessTestPhase.abdominal:
        return FitnessTestPhase.summary;
      case FitnessTestPhase.summary:
      case FitnessTestPhase.completed:
        return FitnessTestPhase.completed;
    }
  }

  /// Nombre del próximo ejercicio (para pantallas de receso)
  String? get nextExerciseName {
    switch (this) {
      case FitnessTestPhase.rest1:
        return 'SENTADILLAS';
      case FitnessTestPhase.rest2:
        return 'ABDOMINALES';
      default:
        return null;
    }
  }

  /// Índice de progreso (0-6)
  int get progressIndex {
    switch (this) {
      case FitnessTestPhase.intro:
        return 0;
      case FitnessTestPhase.pushup:
        return 1;
      case FitnessTestPhase.rest1:
        return 2;
      case FitnessTestPhase.squat:
        return 3;
      case FitnessTestPhase.rest2:
        return 4;
      case FitnessTestPhase.abdominal:
        return 5;
      case FitnessTestPhase.summary:
      case FitnessTestPhase.completed:
        return 6;
    }
  }
}

/// Estado inmutable del Fitness Test
class FitnessTestState {
  /// Fase actual del test
  final FitnessTestPhase currentPhase;

  /// Contadores de repeticiones
  final int pushupCount;
  final int squatCount;
  final int abdominalCount;

  /// Calidades promedio (0.0 - 1.0)
  final double pushupQuality;
  final double squatQuality;
  final double abdominalQuality;

  /// Tiempo restante en la fase actual (segundos)
  final int remainingSeconds;

  /// Hora de inicio del test
  final DateTime startTime;

  /// ¿Está pausado?
  final bool isPaused;

  FitnessTestState({
    this.currentPhase = FitnessTestPhase.intro,
    this.pushupCount = 0,
    this.squatCount = 0,
    this.abdominalCount = 0,
    this.pushupQuality = 0.0,
    this.squatQuality = 0.0,
    this.abdominalQuality = 0.0,
    this.remainingSeconds = 0,
    DateTime? startTime,
    this.isPaused = false,
  }) : startTime = startTime ?? DateTime.now();

  /// Estado inicial
  factory FitnessTestState.initial() {
    return FitnessTestState(
      startTime: DateTime.now(),
      remainingSeconds: FitnessTestPhase.intro.durationSeconds,
    );
  }

  /// Total de repeticiones
  int get totalReps => pushupCount + squatCount + abdominalCount;

  /// Calidad promedio general
  double get averageQuality {
    int count = 0;
    double sum = 0.0;

    if (pushupCount > 0) {
      sum += pushupQuality;
      count++;
    }
    if (squatCount > 0) {
      sum += squatQuality;
      count++;
    }
    if (abdominalCount > 0) {
      sum += abdominalQuality;
      count++;
    }

    return count > 0 ? sum / count : 0.0;
  }

  /// Contador actual según la fase
  int get currentCount {
    switch (currentPhase) {
      case FitnessTestPhase.pushup:
        return pushupCount;
      case FitnessTestPhase.squat:
        return squatCount;
      case FitnessTestPhase.abdominal:
        return abdominalCount;
      default:
        return 0;
    }
  }

  /// Calidad actual según la fase
  double get currentQuality {
    switch (currentPhase) {
      case FitnessTestPhase.pushup:
        return pushupQuality;
      case FitnessTestPhase.squat:
        return squatQuality;
      case FitnessTestPhase.abdominal:
        return abdominalQuality;
      default:
        return 0.0;
    }
  }

  /// Copia con valores modificados
  FitnessTestState copyWith({
    FitnessTestPhase? currentPhase,
    int? pushupCount,
    int? squatCount,
    int? abdominalCount,
    double? pushupQuality,
    double? squatQuality,
    double? abdominalQuality,
    int? remainingSeconds,
    DateTime? startTime,
    bool? isPaused,
  }) {
    return FitnessTestState(
      currentPhase: currentPhase ?? this.currentPhase,
      pushupCount: pushupCount ?? this.pushupCount,
      squatCount: squatCount ?? this.squatCount,
      abdominalCount: abdominalCount ?? this.abdominalCount,
      pushupQuality: pushupQuality ?? this.pushupQuality,
      squatQuality: squatQuality ?? this.squatQuality,
      abdominalQuality: abdominalQuality ?? this.abdominalQuality,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      startTime: startTime ?? this.startTime,
      isPaused: isPaused ?? this.isPaused,
    );
  }

  @override
  String toString() {
    return 'FitnessTestState(phase: $currentPhase, pushup: $pushupCount, squat: $squatCount, abs: $abdominalCount)';
  }
}

