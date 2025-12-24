import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pullup_workout.dart';

/// Servicio para almacenar y recuperar entrenamientos de Pull-Ups
class PullUpWorkoutStorage {
  static const String _keyWorkouts = 'pullup_workouts';
  static PullUpWorkoutStorage? _instance;

  PullUpWorkoutStorage._internal();

  factory PullUpWorkoutStorage() {
    _instance ??= PullUpWorkoutStorage._internal();
    return _instance!;
  }

  /// Recupera todos los entrenamientos de Pull-Ups
  Future<List<PullUpWorkout>> getWorkouts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final workoutsString = prefs.getString(_keyWorkouts);
      
      if (workoutsString == null || workoutsString.isEmpty) {
        print('📂 [PullUp] No hay entrenamientos guardados');
        return [];
      }
      
      final workoutsJson = jsonDecode(workoutsString) as List;
      final workouts = workoutsJson
          .map((json) => PullUpWorkout.fromJson(json as Map<String, dynamic>))
          .toList();
      
      print('📖 [PullUp] Cargados ${workouts.length} entrenamientos');
      return workouts;
    } catch (e) {
      print('❌ [PullUp] Error cargando entrenamientos: $e');
      return [];
    }
  }

  /// Guarda un entrenamiento de Pull-Ups
  Future<bool> saveWorkout(PullUpWorkout workout) async {
    try {
      print('💾 [PullUp] Guardando entrenamiento: ${workout.id}');
      
      final prefs = await SharedPreferences.getInstance();
      final workouts = await getWorkouts();
      
      // Actualizar o agregar entrenamiento
      final existingIndex = workouts.indexWhere((w) => w.id == workout.id);
      if (existingIndex >= 0) {
        workouts[existingIndex] = workout;
        print('📝 [PullUp] Actualizando entrenamiento existente');
      } else {
        workouts.add(workout);
        print('➕ [PullUp] Agregando nuevo entrenamiento');
      }
      
      // Ordenar por fecha (más reciente primero)
      workouts.sort((a, b) => b.startTime.compareTo(a.startTime));
      
      // Limitar a 100 entrenamientos máximo
      if (workouts.length > 100) {
        workouts.removeRange(100, workouts.length);
        print('🗂️ [PullUp] Limitando historial a 100 entrenamientos');
      }
      
      final workoutsJson = workouts.map((w) => w.toJson()).toList();
      final success = await prefs.setString(_keyWorkouts, jsonEncode(workoutsJson));
      
      print('✅ [PullUp] Entrenamiento guardado: $success');
      print('📊 [PullUp] Total entrenamientos: ${workouts.length}');
      
      return success;
    } catch (e) {
      print('❌ [PullUp] Error guardando entrenamiento: $e');
      return false;
    }
  }

  /// Obtiene un entrenamiento específico por ID
  Future<PullUpWorkout?> getWorkout(String id) async {
    try {
      final workouts = await getWorkouts();
      return workouts.firstWhere((w) => w.id == id);
    } catch (e) {
      print('❌ [PullUp] Entrenamiento no encontrado: $id');
      return null;
    }
  }

  /// Elimina un entrenamiento
  Future<bool> deleteWorkout(String id) async {
    try {
      final workouts = await getWorkouts();
      workouts.removeWhere((w) => w.id == id);
      
      final prefs = await SharedPreferences.getInstance();
      final workoutsJson = workouts.map((w) => w.toJson()).toList();
      final success = await prefs.setString(_keyWorkouts, jsonEncode(workoutsJson));
      
      print('🗑️ [PullUp] Entrenamiento eliminado: $id');
      return success;
    } catch (e) {
      print('❌ [PullUp] Error eliminando entrenamiento: $e');
      return false;
    }
  }

  /// Obtiene estadísticas generales
  Future<PullUpWorkoutStats> getStats() async {
    try {
      final workouts = await getWorkouts();
      
      if (workouts.isEmpty) {
        return PullUpWorkoutStats.empty();
      }
      
      final totalWorkouts = workouts.length;
      final totalReps = workouts.fold(0, (sum, w) => sum + w.totalReps);
      final totalDuration = workouts.fold(
        Duration.zero, 
        (sum, w) => sum + w.totalDuration,
      );
      final averageReps = totalReps / totalWorkouts;
      final averageFormQuality = workouts.fold(0.0, (sum, w) => sum + w.averageFormQuality) / totalWorkouts;
      
      // Mejor sesión (más repeticiones)
      final bestWorkout = workouts.reduce((a, b) => a.totalReps > b.totalReps ? a : b);
      
      return PullUpWorkoutStats(
        totalWorkouts: totalWorkouts,
        totalReps: totalReps,
        totalDuration: totalDuration,
        averageReps: averageReps,
        averageFormQuality: averageFormQuality,
        bestWorkoutReps: bestWorkout.totalReps,
        bestWorkoutDate: bestWorkout.startTime,
      );
    } catch (e) {
      print('❌ [PullUp] Error calculando estadísticas: $e');
      return PullUpWorkoutStats.empty();
    }
  }

  /// Limpia todos los entrenamientos (para testing/debug)
  Future<bool> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.remove(_keyWorkouts);
      print('🧹 [PullUp] Historial limpiado: $success');
      return success;
    } catch (e) {
      print('❌ [PullUp] Error limpiando historial: $e');
      return false;
    }
  }
}

/// Estadísticas generales de entrenamientos de Pull-Ups
class PullUpWorkoutStats {
  final int totalWorkouts;
  final int totalReps;
  final Duration totalDuration;
  final double averageReps;
  final double averageFormQuality;
  final int bestWorkoutReps;
  final DateTime? bestWorkoutDate;

  PullUpWorkoutStats({
    required this.totalWorkouts,
    required this.totalReps,
    required this.totalDuration,
    required this.averageReps,
    required this.averageFormQuality,
    required this.bestWorkoutReps,
    this.bestWorkoutDate,
  });

  factory PullUpWorkoutStats.empty() {
    return PullUpWorkoutStats(
      totalWorkouts: 0,
      totalReps: 0,
      totalDuration: Duration.zero,
      averageReps: 0.0,
      averageFormQuality: 0.0,
      bestWorkoutReps: 0,
      bestWorkoutDate: null,
    );
  }
}
