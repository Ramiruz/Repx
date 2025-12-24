import 'pushup_session.dart';

/// Modelo para estadísticas generales del usuario
class ExerciseStats {
  final int totalSessions; // Total de sesiones completadas
  final int totalReps; // Total de repeticiones válidas
  final int totalInvalidReps; // Total de repeticiones inválidas
  final double averageFormQuality; // Promedio general de calidad de forma
  final int bestStreak; // Mejor racha de repeticiones en una sesión
  final Duration totalExerciseTime; // Tiempo total de ejercicio
  final DateTime? lastSessionDate; // Fecha de la última sesión
  final List<PushUpSession> recentSessions; // Últimas 10 sesiones

  ExerciseStats({
    this.totalSessions = 0,
    this.totalReps = 0,
    this.totalInvalidReps = 0,
    this.averageFormQuality = 0.0,
    this.bestStreak = 0,
    Duration? totalExerciseTime,
    this.lastSessionDate,
    List<PushUpSession>? recentSessions,
  }) : totalExerciseTime = totalExerciseTime ?? Duration.zero,
       recentSessions = recentSessions ?? [];

  /// Promedio de repeticiones por sesión
  double get averageRepsPerSession {
    if (totalSessions == 0) return 0.0;
    return totalReps / totalSessions;
  }

  /// Porcentaje de éxito (repeticiones válidas vs total)
  double get successRate {
    final total = totalReps + totalInvalidReps;
    if (total == 0) return 0.0;
    return (totalReps / total) * 100;
  }

  /// Actualiza las estadísticas con una nueva sesión
  ExerciseStats addSession(PushUpSession session) {
    final updatedSessions = [session, ...recentSessions];
    if (updatedSessions.length > 10) {
      updatedSessions.removeLast();
    }

    return ExerciseStats(
      totalSessions: totalSessions + 1,
      totalReps: totalReps + session.totalReps,
      totalInvalidReps: totalInvalidReps + session.invalidReps,
      averageFormQuality: _calculateNewAverage(
        averageFormQuality,
        session.averageFormQuality,
        totalSessions,
      ),
      bestStreak:
          session.totalReps > bestStreak ? session.totalReps : bestStreak,
      totalExerciseTime: totalExerciseTime + session.sessionDuration,
      lastSessionDate: session.endTime ?? session.startTime,
      recentSessions: updatedSessions,
    );
  }

  /// Calcula el nuevo promedio al agregar una sesión
  double _calculateNewAverage(double current, double newValue, int count) {
    if (count == 0) return newValue;
    return ((current * count) + newValue) / (count + 1);
  }

  /// Copia las estadísticas con valores modificados
  ExerciseStats copyWith({
    int? totalSessions,
    int? totalReps,
    int? totalInvalidReps,
    double? averageFormQuality,
    int? bestStreak,
    Duration? totalExerciseTime,
    DateTime? lastSessionDate,
    List<PushUpSession>? recentSessions,
  }) {
    return ExerciseStats(
      totalSessions: totalSessions ?? this.totalSessions,
      totalReps: totalReps ?? this.totalReps,
      totalInvalidReps: totalInvalidReps ?? this.totalInvalidReps,
      averageFormQuality: averageFormQuality ?? this.averageFormQuality,
      bestStreak: bestStreak ?? this.bestStreak,
      totalExerciseTime: totalExerciseTime ?? this.totalExerciseTime,
      lastSessionDate: lastSessionDate ?? this.lastSessionDate,
      recentSessions: recentSessions ?? this.recentSessions,
    );
  }

  /// Convierte las estadísticas a un mapa
  Map<String, dynamic> toJson() {
    return {
      'totalSessions': totalSessions,
      'totalReps': totalReps,
      'totalInvalidReps': totalInvalidReps,
      'averageFormQuality': averageFormQuality,
      'bestStreak': bestStreak,
      'totalExerciseTime': totalExerciseTime.inSeconds,
      'lastSessionDate': lastSessionDate?.toIso8601String(),
      'recentSessions': recentSessions.map((s) => s.toJson()).toList(),
    };
  }

  /// Crea estadísticas desde un mapa
  factory ExerciseStats.fromJson(Map<String, dynamic> json) {
    return ExerciseStats(
      totalSessions: json['totalSessions'] as int,
      totalReps: json['totalReps'] as int,
      totalInvalidReps: json['totalInvalidReps'] as int,
      averageFormQuality: (json['averageFormQuality'] as num).toDouble(),
      bestStreak: json['bestStreak'] as int,
      totalExerciseTime: Duration(seconds: json['totalExerciseTime'] as int),
      lastSessionDate:
          json['lastSessionDate'] != null
              ? DateTime.parse(json['lastSessionDate'] as String)
              : null,
      recentSessions:
          (json['recentSessions'] as List?)
              ?.map((s) => PushUpSession.fromJson(s))
              .toList() ??
          [],
    );
  }

  @override
  String toString() {
    return 'ExerciseStats(sessions: $totalSessions, reps: $totalReps, avg: ${averageFormQuality.toStringAsFixed(1)}%, best: $bestStreak)';
  }
}

