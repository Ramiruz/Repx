import 'workout_config.dart';

/// Modelo para representar un entrenamiento completo de Pull-Ups
/// Incluye múltiples series y configuración del entrenamiento
class PullUpWorkout {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final WorkoutConfig config;
  final List<PullUpSet> sets;
  final String title;

  PullUpWorkout({
    String? id,
    DateTime? startTime,
    this.endTime,
    required this.config,
    List<PullUpSet>? sets,
    String? title,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        startTime = startTime ?? DateTime.now(),
        sets = sets ?? [],
        title = title ?? 'Entrenamiento Pull-Ups';

  /// Duración total del entrenamiento
  Duration get totalDuration {
    if (endTime != null) {
      return endTime!.difference(startTime);
    }
    return DateTime.now().difference(startTime);
  }

  /// Total de repeticiones realizadas
  int get totalReps {
    return sets.fold(0, (sum, set) => sum + set.completedReps);
  }

  /// Promedio de repeticiones por serie
  double get averageRepsPerSet {
    if (sets.isEmpty) return 0.0;
    return totalReps / sets.length;
  }

  /// Calidad de forma promedio
  double get averageFormQuality {
    if (sets.isEmpty) return 0.0;
    final totalQuality =
        sets.fold(0.0, (sum, set) => sum + set.averageFormQuality);
    return totalQuality / sets.length;
  }

  /// Si el entrenamiento está completado
  bool get isCompleted => sets.length >= config.totalSets;

  /// Copia el entrenamiento con valores modificados
  PullUpWorkout copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    WorkoutConfig? config,
    List<PullUpSet>? sets,
    String? title,
  }) {
    return PullUpWorkout(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      config: config ?? this.config,
      sets: sets ?? this.sets,
      title: title ?? this.title,
    );
  }

  /// Convierte el entrenamiento a un mapa para almacenamiento
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'title': title,
      'config': {
        'repsPerSet': config.repsPerSet,
        'totalSets': config.totalSets,
        'restTimeSeconds': config.restTimeSeconds,
      },
      'sets': sets.map((s) => s.toJson()).toList(),
    };
  }

  /// Crea un entrenamiento desde un mapa
  factory PullUpWorkout.fromJson(Map<String, dynamic> json) {
    final configMap = json['config'] as Map<String, dynamic>;
    return PullUpWorkout(
      id: json['id'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      title: json['title'] as String,
      config: WorkoutConfig(
        repsPerSet: configMap['repsPerSet'] as int,
        totalSets: configMap['totalSets'] as int,
        restTimeSeconds: configMap['restTimeSeconds'] as int,
      ),
      sets:
          (json['sets'] as List?)?.map((s) => PullUpSet.fromJson(s)).toList() ??
              [],
    );
  }

  @override
  String toString() {
    return 'PullUpWorkout(id: $id, sets: ${sets.length}/${config.totalSets}, totalReps: $totalReps)';
  }
}

/// Modelo para representar una serie individual de Pull-Ups
class PullUpSet {
  final int setNumber;
  final DateTime startTime;
  final DateTime? endTime;
  final int completedReps;
  final List<PullUpRepDetail> reps;
  final double averageFormQuality;

  PullUpSet({
    required this.setNumber,
    DateTime? startTime,
    this.endTime,
    required this.completedReps,
    List<PullUpRepDetail>? reps,
    this.averageFormQuality = 0.0,
  })  : startTime = startTime ?? DateTime.now(),
        reps = reps ?? [];

  Duration get duration {
    if (endTime != null) {
      return endTime!.difference(startTime);
    }
    return DateTime.now().difference(startTime);
  }

  Map<String, dynamic> toJson() {
    return {
      'setNumber': setNumber,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'completedReps': completedReps,
      'averageFormQuality': averageFormQuality,
      'reps': reps.map((r) => r.toJson()).toList(),
    };
  }

  factory PullUpSet.fromJson(Map<String, dynamic> json) {
    return PullUpSet(
      setNumber: json['setNumber'] as int,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      completedReps: json['completedReps'] as int,
      averageFormQuality: (json['averageFormQuality'] as num).toDouble(),
      reps: (json['reps'] as List?)
              ?.map((r) => PullUpRepDetail.fromJson(r))
              .toList() ??
          [],
    );
  }
}

/// Detalles de una repetición individual de Pull-Up
class PullUpRepDetail {
  final int repNumber;
  final DateTime timestamp;
  final double formQuality;
  final double headHeight;
  final double rom; // Range of motion
  final bool isValid;

  PullUpRepDetail({
    required this.repNumber,
    DateTime? timestamp,
    required this.formQuality,
    required this.headHeight,
    required this.rom,
    required this.isValid,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'repNumber': repNumber,
      'timestamp': timestamp.toIso8601String(),
      'formQuality': formQuality,
      'headHeight': headHeight,
      'rom': rom,
      'isValid': isValid,
    };
  }

  factory PullUpRepDetail.fromJson(Map<String, dynamic> json) {
    return PullUpRepDetail(
      repNumber: json['repNumber'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      formQuality: (json['formQuality'] as num).toDouble(),
      headHeight: (json['headHeight'] as num).toDouble(),
      rom: (json['rom'] as num).toDouble(),
      isValid: json['isValid'] as bool,
    );
  }
}

