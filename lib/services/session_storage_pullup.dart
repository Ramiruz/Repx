import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pullup_session.dart';

/// Servicio para persistir sesiones de Pull-Ups
class SessionStoragePullUp {
  static const String _sessionsKey = 'pullup_sessions';
  static const int _maxSessions = 50;

  /// Guarda una sesión completada
  static Future<void> saveSession(PullUpSession session) async {
    try {
      print('💾 [PullUp Storage] Iniciando guardado de sesión...');
      final prefs = await SharedPreferences.getInstance();
      print('💾 [PullUp Storage] SharedPreferences obtenido');

      // Obtener sesiones existentes
      final sessions = await getAllSessions();
      print('💾 [PullUp Storage] Sesiones existentes: ${sessions.length}');

      // Agregar nueva sesión al inicio
      sessions.insert(0, session);
      print(
          '💾 [PullUp Storage] Nueva sesión agregada. Total: ${sessions.length}');

      // Limitar número de sesiones
      if (sessions.length > _maxSessions) {
        sessions.removeRange(_maxSessions, sessions.length);
        print('💾 [PullUp Storage] Sesiones limitadas a $_maxSessions');
      }

      // Convertir a JSON y guardar
      final jsonSessions = sessions.map((s) => s.toJson()).toList();
      print('💾 [PullUp Storage] JSON creado. Guardando...');

      final success =
          await prefs.setString(_sessionsKey, jsonEncode(jsonSessions));
      print('💾 [PullUp Storage] Guardado ${success ? "EXITOSO" : "FALLIDO"}');

      print(
          '✅ [PullUp] Sesión guardada: ${session.totalReps} reps, calidad: ${session.averageFormQuality.toStringAsFixed(1)}%');
    } catch (e, stackTrace) {
      print('❌ [PullUp] Error guardando sesión: $e');
      print('❌ [PullUp] StackTrace: $stackTrace');
    }
  }

  /// Obtiene todas las sesiones guardadas
  static Future<List<PullUpSession>> getAllSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_sessionsKey);

      if (jsonString == null) return [];

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => PullUpSession.fromJson(json)).toList();
    } catch (e) {
      print('❌ [PullUp] Error cargando sesiones: $e');
      return [];
    }
  }

  /// Elimina todas las sesiones
  static Future<void> clearAllSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionsKey);
      print('✅ [PullUp] Historial borrado');
    } catch (e) {
      print('❌ [PullUp] Error borrando historial: $e');
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

    int streak = _calculateStreak(sessions);

    return {
      'totalSessions': sessions.length,
      'totalReps': totalReps,
      'averageQuality':
          sessions.isNotEmpty ? totalQuality / sessions.length : 0.0,
      'currentStreak': streak,
    };
  }

  static int _calculateStreak(List<PullUpSession> sessions) {
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
          break;
        }
      }
    }

    return streak;
  }
}

