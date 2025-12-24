/// Modelo para representar un nivel de fitness
/// Basado en el total de repeticiones completadas en el test
enum FitnessLevel {
  /// 0-30 repeticiones totales
  principiante,

  /// 31-60 repeticiones totales
  intermedio,

  /// 61-90 repeticiones totales
  avanzado,

  /// 91+ repeticiones totales
  atleta,
}

/// Extensión con propiedades de visualización para FitnessLevel
extension FitnessLevelExtension on FitnessLevel {
  /// Nombre para mostrar en español
  String get displayName {
    switch (this) {
      case FitnessLevel.principiante:
        return 'PRINCIPIANTE';
      case FitnessLevel.intermedio:
        return 'INTERMEDIO';
      case FitnessLevel.avanzado:
        return 'AVANZADO';
      case FitnessLevel.atleta:
        return 'ATLETA';
    }
  }

  /// Emoji representativo del nivel
  String get emoji {
    switch (this) {
      case FitnessLevel.principiante:
        return '🟢';
      case FitnessLevel.intermedio:
        return '🟡';
      case FitnessLevel.avanzado:
        return '🟠';
      case FitnessLevel.atleta:
        return '🔴';
    }
  }

  /// Descripción del nivel
  String get description {
    switch (this) {
      case FitnessLevel.principiante:
        return 'Estás comenzando tu viaje fitness. ¡Sigue así!';
      case FitnessLevel.intermedio:
        return 'Buen progreso. Tu resistencia está mejorando.';
      case FitnessLevel.avanzado:
        return 'Excelente condición física. ¡Impresionante!';
      case FitnessLevel.atleta:
        return 'Nivel de atleta profesional. ¡Extraordinario!';
    }
  }

  /// Rango de repeticiones para este nivel
  String get repsRange {
    switch (this) {
      case FitnessLevel.principiante:
        return '0-30 reps';
      case FitnessLevel.intermedio:
        return '31-60 reps';
      case FitnessLevel.avanzado:
        return '61-90 reps';
      case FitnessLevel.atleta:
        return '91+ reps';
    }
  }

  /// Calcula el nivel fitness basado en repeticiones totales
  static FitnessLevel fromTotalReps(int totalReps) {
    if (totalReps >= 91) return FitnessLevel.atleta;
    if (totalReps >= 61) return FitnessLevel.avanzado;
    if (totalReps >= 31) return FitnessLevel.intermedio;
    return FitnessLevel.principiante;
  }
}

