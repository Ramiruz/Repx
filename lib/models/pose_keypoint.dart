/// Modelo para representar un punto clave (keypoint) detectado en el cuerpo
/// Usado por YOLOv11 para detección de pose
class PoseKeypoint {
  final String name; // Nombre del keypoint (ej: 'left_shoulder', 'right_elbow')
  final double x; // Coordenada X normalizada (0.0 - 1.0)
  final double y; // Coordenada Y normalizada (0.0 - 1.0)
  final double confidence; // Confianza de la detección (0.0 - 1.0)

  PoseKeypoint({
    required this.name,
    required this.x,
    required this.y,
    required this.confidence,
  });

  /// Verifica si el keypoint es válido (tiene suficiente confianza)
  /// Umbral optimizado: 0.12 para permitir detección en condiciones difíciles (ángulos, luz)
  bool get isValid => confidence > 0.12;

  /// Copia el keypoint con valores modificados
  PoseKeypoint copyWith({
    String? name,
    double? x,
    double? y,
    double? confidence,
  }) {
    return PoseKeypoint(
      name: name ?? this.name,
      x: x ?? this.x,
      y: y ?? this.y,
      confidence: confidence ?? this.confidence,
    );
  }

  /// Convierte el keypoint a un mapa
  Map<String, dynamic> toJson() {
    return {'name': name, 'x': x, 'y': y, 'confidence': confidence};
  }

  /// Crea un keypoint desde un mapa
  factory PoseKeypoint.fromJson(Map<String, dynamic> json) {
    return PoseKeypoint(
      name: json['name'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      confidence: (json['confidence'] as num).toDouble(),
    );
  }

  @override
  String toString() {
    return 'PoseKeypoint($name: x=$x, y=$y, conf=$confidence)';
  }
}

/// Colección completa de keypoints detectados en una pose
class PoseDetection {
  final List<PoseKeypoint> keypoints;
  final double overallConfidence; // Confianza general de la detección
  final DateTime timestamp;

  PoseDetection({
    required this.keypoints,
    required this.overallConfidence,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Obtiene un keypoint específico por nombre
  PoseKeypoint? getKeypoint(String name) {
    try {
      return keypoints.firstWhere((kp) => kp.name == name);
    } catch (e) {
      return null;
    }
  }

  /// Verifica si todos los keypoints críticos están presentes y válidos
  bool get isValid {
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

    return criticalKeypoints.every((name) {
      final kp = getKeypoint(name);
      return kp != null && kp.isValid;
    });
  }

  Map<String, dynamic> toJson() {
    return {
      'keypoints': keypoints.map((kp) => kp.toJson()).toList(),
      'overallConfidence': overallConfidence,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory PoseDetection.fromJson(Map<String, dynamic> json) {
    return PoseDetection(
      keypoints: (json['keypoints'] as List)
          .map((kp) => PoseKeypoint.fromJson(kp))
          .toList(),
      overallConfidence: (json['overallConfidence'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

