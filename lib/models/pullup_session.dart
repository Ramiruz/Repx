/// Modelo para una sesión de Pull-Ups
class PullUpSession {
  final DateTime startTime;
  final DateTime? endTime;
  final int totalReps;
  final int invalidReps;
  final double averageFormQuality;
  final List<RepDetail> reps;
  final double? barHeight; // Altura de la barra calibrada (0-1)

  PullUpSession({
    required this.startTime,
    this.endTime,
    this.totalReps = 0,
    this.invalidReps = 0,
    this.averageFormQuality = 0.0,
    this.reps = const [],
    this.barHeight,
  });

  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  PullUpSession copyWith({
    DateTime? startTime,
    DateTime? endTime,
    int? totalReps,
    int? invalidReps,
    double? averageFormQuality,
    List<RepDetail>? reps,
    double? barHeight,
  }) {
    return PullUpSession(
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      totalReps: totalReps ?? this.totalReps,
      invalidReps: invalidReps ?? this.invalidReps,
      averageFormQuality: averageFormQuality ?? this.averageFormQuality,
      reps: reps ?? this.reps,
      barHeight: barHeight ?? this.barHeight,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'totalReps': totalReps,
      'invalidReps': invalidReps,
      'averageFormQuality': averageFormQuality,
      'reps': reps.map((r) => r.toJson()).toList(),
      'barHeight': barHeight,
    };
  }

  factory PullUpSession.fromJson(Map<String, dynamic> json) {
    return PullUpSession(
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      totalReps: json['totalReps'] as int? ?? 0,
      invalidReps: json['invalidReps'] as int? ?? 0,
      averageFormQuality:
          (json['averageFormQuality'] as num?)?.toDouble() ?? 0.0,
      reps: (json['reps'] as List?)
              ?.map((r) => RepDetail.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
      barHeight: (json['barHeight'] as num?)?.toDouble(),
    );
  }
}

/// Detalle de una repetición individual
class RepDetail {
  final DateTime timestamp;
  final double formQuality;
  final double maxHeight; // Altura máxima alcanzada (0-1)
  final double minHeight; // Altura mínima alcanzada (0-1)
  final bool isValid;

  RepDetail({
    required this.timestamp,
    required this.formQuality,
    required this.maxHeight,
    required this.minHeight,
    this.isValid = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'formQuality': formQuality,
      'maxHeight': maxHeight,
      'minHeight': minHeight,
      'isValid': isValid,
    };
  }

  factory RepDetail.fromJson(Map<String, dynamic> json) {
    return RepDetail(
      timestamp: DateTime.parse(json['timestamp'] as String),
      formQuality: (json['formQuality'] as num?)?.toDouble() ?? 0.0,
      maxHeight: (json['maxHeight'] as num?)?.toDouble() ?? 0.0,
      minHeight: (json['minHeight'] as num?)?.toDouble() ?? 0.0,
      isValid: json['isValid'] as bool? ?? true,
    );
  }
}

