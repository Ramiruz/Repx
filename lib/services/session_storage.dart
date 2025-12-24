import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pushup_session.dart';

/// Servicio para persistir sesiones de ejercicio
class SessionStorage {
  static const String _sessionsKey = 'pushup_sessions';
  static const int _maxSessions = 50; // Máximo de sesiones guardadas

  /// Guarda una sesión completada
  static Future<void> saveSession(PushUpSession session) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Obtener sesiones existentes
      final sessions = await getAllSessions();

      // Agregar nueva sesión al inicio
      sessions.insert(0, session);

      // Limitar número de sesiones
      if (sessions.length > _maxSessions) {
        sessions.removeRange(_maxSessions, sessions.length);
      }

      // Convertir a JSON y guardar
      final jsonSessions = sessions.map((s) => s.toJson()).toList();
      await prefs.setString(_sessionsKey, jsonEncode(jsonSessions));

      print('✅ Sesión guardada: ${session.totalReps} reps');
    } catch (e) {
      print('❌ Error guardando sesión: $e');
    }
  }

  /// Obtiene todas las sesiones guardadas
  static Future<List<PushUpSession>> getAllSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_sessionsKey);

      if (jsonString == null) return [];

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => PushUpSession.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error cargando sesiones: $e');
      return [];
    }
  }

  /// Elimina todas las sesiones
  static Future<void> clearAllSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionsKey);
      print('✅ Historial borrado');
    } catch (e) {
      print('❌ Error borrando historial: $e');
    }
  }

  /// Obtiene estadísticas globales
  static Future<Map<String, dynamic>> getGlobalStats() async {
    final sessions = await getAllSessions();

    if (sessions.isEmpty) {
      return {
        'totalSessions': 0,
        'totalReps': 0,
        'averageQuality': 0.0,
        'currentStreak': 0,
      };
    }

    int totalReps = 0;
    double totalQuality = 0.0;

    for (final session in sessions) {
      totalReps += session.totalReps;
      totalQuality += session.averageFormQuality;
    }

    // Calcular racha (días consecutivos)
    int streak = _calculateStreak(sessions);

    return {
      'totalSessions': sessions.length,
      'totalReps': totalReps,
      'averageQuality':
          sessions.isNotEmpty ? totalQuality / sessions.length : 0.0,
      'currentStreak': streak,
    };
  }

  /// Calcula racha de días consecutivos
  static int _calculateStreak(List<PushUpSession> sessions) {
    if (sessions.isEmpty) return 0;

    int streak = 0;
    DateTime? lastDate;

    for (final session in sessions) {
      final sessionDate = DateTime(
        session.startTime.year,
        session.startTime.month,
        session.startTime.day,
      );

      if (lastDate == null) {
        streak = 1;
        lastDate = sessionDate;
      } else {
        final diff = lastDate.difference(sessionDate).inDays;
        if (diff == 1) {
          streak++;
          lastDate = sessionDate;
        } else if (diff > 1) {
          break; // Racha rota
        }
      }
    }

    return streak;
  }
}

