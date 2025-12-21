/// Modelo para representar una sesión de ejercicio de flexiones
class PushUpSession {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final int totalReps; // Total de repeticiones válidas
  final int invalidReps; // Repeticiones inválidas (mala forma)
  final double averageFormQuality; // Promedio de calidad de forma (0-100)
  final Duration duration;
  final List<RepDetail> reps; // Detalles de cada repetición

  PushUpSession({
    String? id,
    DateTime? startTime,
    this.endTime,
    this.totalReps = 0,
    this.invalidReps = 0,
    this.averageFormQuality = 0.0,
    Duration? duration,
    List<RepDetail>? reps,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        startTime = startTime ?? DateTime.now(),
        duration = duration ?? Duration.zero,
        reps = reps ?? [];

  /// Duración de la sesión (tiempo real transcurrido)
  Duration get sessionDuration {
    if (endTime != null) {
      return endTime!.difference(startTime);
    }
    // Calcular duración en tiempo real si la sesión está activa
    return DateTime.now().difference(startTime);
  }

  /// Porcentaje de repeticiones válidas
  double get validRepPercentage {
    final total = totalReps + invalidReps;
    if (total == 0) return 0.0;
    return (totalReps / total) * 100;
  }

  /// Copia la sesión con valores modificados
  PushUpSession copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    int? totalReps,
    int? invalidReps,
    double? averageFormQuality,
    Duration? duration,
    List<RepDetail>? reps,
  }) {
    return PushUpSession(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      totalReps: totalReps ?? this.totalReps,
      invalidReps: invalidReps ?? this.invalidReps,
      averageFormQuality: averageFormQuality ?? this.averageFormQuality,
      duration: duration ?? this.duration,
      reps: reps ?? this.reps,
    );
  }

  /// Convierte la sesión a un mapa para almacenamiento
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'totalReps': totalReps,
      'invalidReps': invalidReps,
      'averageFormQuality': averageFormQuality,
      'duration': duration.inSeconds,
      'reps': reps.map((r) => r.toJson()).toList(),
    };
  }

  /// Crea una sesión desde un mapa
  factory PushUpSession.fromJson(Map<String, dynamic> json) {
    return PushUpSession(
      id: json['id'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      totalReps: json['totalReps'] as int,
      invalidReps: json['invalidReps'] as int,
      averageFormQuality: (json['averageFormQuality'] as num).toDouble(),
      duration: Duration(seconds: json['duration'] as int),
      reps:
          (json['reps'] as List?)?.map((r) => RepDetail.fromJson(r)).toList() ??
              [],
    );
  }

  @override
  String toString() {
    return 'PushUpSession(id: $id, reps: $totalReps, quality: ${averageFormQuality.toStringAsFixed(1)}%, duration: ${sessionDuration.inMinutes}m)';
  }
}

/// Detalles de una repetición individual
class RepDetail {
  final int repNumber;
  final DateTime timestamp;
  final double formQuality; // Calidad de forma (0-100)
  final double elbowAngle; // Ángulo mínimo de codo alcanzado
  final double backAngle; // Ángulo de espalda promedio
  final bool isValid; // Si la repetición fue válida

  RepDetail({
    required this.repNumber,
    DateTime? timestamp,
    required this.formQuality,
    required this.elbowAngle,
    required this.backAngle,
    required this.isValid,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'repNumber': repNumber,
      'timestamp': timestamp.toIso8601String(),
      'formQuality': formQuality,
      'elbowAngle': elbowAngle,
      'backAngle': backAngle,
      'isValid': isValid,
    };
  }

  factory RepDetail.fromJson(Map<String, dynamic> json) {
    return RepDetail(
      repNumber: json['repNumber'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      formQuality: (json['formQuality'] as num).toDouble(),
      elbowAngle: (json['elbowAngle'] as num).toDouble(),
      backAngle: (json['backAngle'] as num).toDouble(),
      isValid: json['isValid'] as bool,
    );
  }
}
