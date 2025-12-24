/// Configuración de entrenamiento para Pull-Ups
class WorkoutConfig {
  final int repsPerSet;
  final int totalSets;
  final int restTimeSeconds;

  const WorkoutConfig({
    required this.repsPerSet,
    required this.totalSets,
    required this.restTimeSeconds,
  });

  WorkoutConfig copyWith({
    int? repsPerSet,
    int? totalSets,
    int? restTimeSeconds,
  }) {
    return WorkoutConfig(
      repsPerSet: repsPerSet ?? this.repsPerSet,
      totalSets: totalSets ?? this.totalSets,
      restTimeSeconds: restTimeSeconds ?? this.restTimeSeconds,
    );
  }

  /// Configuración por defecto
  static const WorkoutConfig defaultConfig = WorkoutConfig(
    repsPerSet: 10,
    totalSets: 3,
    restTimeSeconds: 60,
  );

  @override
  String toString() {
    return 'WorkoutConfig(reps: $repsPerSet, sets: $totalSets, rest: ${restTimeSeconds}s)';
  }
}

