import 'fitness_level.dart';

/// Resultado completo de una sesión de Fitness Test
class FitnessTestResult {
  /// ID único del resultado
  final String id;

  /// Timestamp de cuando se completó el test
  final DateTime timestamp;

  /// Repeticiones por ejercicio
  final int pushupCount;
  final int squatCount;
  final int abdominalCount;

  /// Calidad promedio por ejercicio (0.0 - 1.0)
  final double pushupQuality;
  final double squatQuality;
  final double abdominalQuality;

  /// Nivel de fitness calculado
  final FitnessLevel level;

  /// Sugerencias personalizadas generadas
  final List<String> suggestions;

  /// Duración total del test en segundos
  final int durationSeconds;

  const FitnessTestResult({
    required this.id,
    required this.timestamp,
    required this.pushupCount,
    required this.squatCount,
    required this.abdominalCount,
    required this.pushupQuality,
    required this.squatQuality,
    required this.abdominalQuality,
    required this.level,
    this.suggestions = const [],
    this.durationSeconds = 180, // 3 minutos por defecto
  });

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

  /// Estado descriptivo para cada ejercicio
  String getExerciseStatus(int count, double quality) {
    if (count >= 25 && quality >= 0.85) return 'Excelente ✅';
    if (count >= 20 && quality >= 0.75) return 'Muy Bien ✅';
    if (count >= 15 && quality >= 0.65) return 'Bien 👍';
    if (count >= 10) return 'Regular 📈';
    return 'Necesita mejora 💪';
  }

  String get pushupStatus => getExerciseStatus(pushupCount, pushupQuality);
  String get squatStatus => getExerciseStatus(squatCount, squatQuality);
  String get abdominalStatus =>
      getExerciseStatus(abdominalCount, abdominalQuality);

  /// Serialización a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'pushupCount': pushupCount,
      'squatCount': squatCount,
      'abdominalCount': abdominalCount,
      'pushupQuality': pushupQuality,
      'squatQuality': squatQuality,
      'abdominalQuality': abdominalQuality,
      'level': level.name,
      'suggestions': suggestions,
      'durationSeconds': durationSeconds,
    };
  }

  /// Deserialización desde JSON
  factory FitnessTestResult.fromJson(Map<String, dynamic> json) {
    return FitnessTestResult(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      pushupCount: json['pushupCount'] as int,
      squatCount: json['squatCount'] as int,
      abdominalCount: json['abdominalCount'] as int,
      pushupQuality: (json['pushupQuality'] as num).toDouble(),
      squatQuality: (json['squatQuality'] as num).toDouble(),
      abdominalQuality: (json['abdominalQuality'] as num).toDouble(),
      level: FitnessLevel.values.firstWhere(
        (l) => l.name == json['level'],
        orElse: () => FitnessLevel.principiante,
      ),
      suggestions: List<String>.from(json['suggestions'] ?? []),
      durationSeconds: json['durationSeconds'] as int? ?? 180,
    );
  }

  @override
  String toString() {
    return 'FitnessTestResult(id: $id, total: $totalReps, level: ${level.displayName})';
  }
}

