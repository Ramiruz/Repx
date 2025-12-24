import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/fitness_test/fitness_test_result.dart';
import '../../models/fitness_test/fitness_level.dart';

/// Almacenamiento de resultados del Fitness Test
class FitnessTestStorage {
  static const String _resultsKey = 'fitness_test_results';
  static const int _maxResults = 50;

  /// Guarda un resultado de test
  static Future<void> saveResult(FitnessTestResult result) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Obtener resultados existentes
      final results = await getAllResults();

      // Agregar nuevo resultado al inicio
      results.insert(0, result);

      // Limitar cantidad de resultados
      if (results.length > _maxResults) {
        results.removeRange(_maxResults, results.length);
      }

      // Guardar en JSON
      final jsonResults = results.map((r) => r.toJson()).toList();
      await prefs.setString(_resultsKey, jsonEncode(jsonResults));

      if (kDebugMode) {
        print('✅ Resultado guardado: ${result.totalReps} reps, ${result.level.displayName}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error guardando resultado: $e');
      }
    }
  }

  /// Obtiene todos los resultados guardados
  static Future<List<FitnessTestResult>> getAllResults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_resultsKey);

      if (jsonString == null) return [];

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => FitnessTestResult.fromJson(json))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error cargando resultados: $e');
      }
      return [];
    }
  }

  /// Obtiene el último resultado
  static Future<FitnessTestResult?> getLastResult() async {
    final results = await getAllResults();
    return results.isNotEmpty ? results.first : null;
  }

  /// Obtiene estadísticas globales
  static Future<Map<String, dynamic>> getGlobalStats() async {
    final results = await getAllResults();

    if (results.isEmpty) {
      return {
        'totalTests': 0,
        'totalReps': 0,
        'averageScore': 0.0,
        'bestScore': 0,
        'averageQuality': 0.0,
      };
    }

    int totalReps = 0;
    int bestScore = 0;
    double totalQuality = 0.0;

    for (final result in results) {
      totalReps += result.totalReps;
      if (result.totalReps > bestScore) {
        bestScore = result.totalReps;
      }
      totalQuality += result.averageQuality;
    }

    return {
      'totalTests': results.length,
      'totalReps': totalReps,
      'averageScore': totalReps / results.length,
      'bestScore': bestScore,
      'averageQuality': totalQuality / results.length,
    };
  }

  /// Obtiene historial de la última semana
  static Future<List<FitnessTestResult>> getWeeklyResults() async {
    final results = await getAllResults();
    final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));

    return results
        .where((r) => r.timestamp.isAfter(oneWeekAgo))
        .toList();
  }

  /// Elimina todos los resultados
  static Future<void> clearAllResults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_resultsKey);

      if (kDebugMode) {
        print('✅ Historial de Fitness Test borrado');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error borrando historial: $e');
      }
    }
  }
}

