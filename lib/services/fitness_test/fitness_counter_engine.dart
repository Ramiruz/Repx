import 'package:flutter/foundation.dart';
import '../../models/pose_keypoint.dart';
import '../../models/fitness_test/fitness_test_state.dart';
import '../pushup_counter.dart';
import 'squat_counter.dart';
import 'abdominal_counter.dart';

/// Motor unificado de conteo para el Fitness Test
/// 
/// Delega a los contadores específicos según el tipo de ejercicio
/// y proporciona una interfaz unificada para el controlador.
class FitnessCounterEngine extends ChangeNotifier {
  /// Tipo de ejercicio actual
  FitnessTestExerciseType? _currentExerciseType;
  FitnessTestExerciseType? get currentExerciseType => _currentExerciseType;

  /// Contadores específicos
  final PushUpCounter _pushupCounter = PushUpCounter();
  final SquatCounter _squatCounter = SquatCounter();
  final AbdominalCounter _abdominalCounter = AbdominalCounter();

  /// Estado de actividad
  bool _isActive = false;
  bool get isActive => _isActive;

  // === Getters unificados ===

  /// Cuenta actual del ejercicio activo
  int get currentCount {
    switch (_currentExerciseType) {
      case FitnessTestExerciseType.pushup:
        return _pushupCounter.count;
      case FitnessTestExerciseType.squat:
        return _squatCounter.count;
      case FitnessTestExerciseType.abdominal:
        return _abdominalCounter.count;
      default:
        return 0;
    }
  }

  /// Calidad actual del ejercicio activo
  double get currentQuality {
    switch (_currentExerciseType) {
      case FitnessTestExerciseType.pushup:
        return _pushupCounter.formQuality;
      case FitnessTestExerciseType.squat:
        return _squatCounter.formQuality;
      case FitnessTestExerciseType.abdominal:
        return _abdominalCounter.formQuality;
      default:
        return 0.0;
    }
  }

  /// Mensaje de fase actual
  String get phaseMessage {
    switch (_currentExerciseType) {
      case FitnessTestExerciseType.pushup:
        return _pushupCounter.getPhaseMessage();
      case FitnessTestExerciseType.squat:
        return _squatCounter.getPhaseMessage();
      case FitnessTestExerciseType.abdominal:
        return _abdominalCounter.getPhaseMessage();
      default:
        return 'Preparando...';
    }
  }

  /// Contadores finales por ejercicio
  int get pushupCount => _pushupCounter.count;
  int get squatCount => _squatCounter.count;
  int get abdominalCount => _abdominalCounter.count;

  /// Calidades finales por ejercicio
  double get pushupQuality => _pushupCounter.formQuality;
  double get squatQuality => _squatCounter.formQuality;
  double get abdominalQuality => _abdominalCounter.formQuality;

  // === Métodos de control ===

  /// Establece el tipo de ejercicio actual y lo inicia
  void setExerciseType(FitnessTestExerciseType type) {
    // Detener ejercicio anterior
    _stopCurrentExercise();

    _currentExerciseType = type;

    // Iniciar nuevo ejercicio
    switch (type) {
      case FitnessTestExerciseType.pushup:
        _pushupCounter.startSession();
        break;
      case FitnessTestExerciseType.squat:
        _squatCounter.start();
        break;
      case FitnessTestExerciseType.abdominal:
        _abdominalCounter.start();
        break;
    }

    _isActive = true;
    notifyListeners();

    if (kDebugMode) {
      print('🎯 FitnessCounterEngine: Iniciado ${type.displayName}');
    }
  }

  /// Procesa una pose detectada
  void processPose(PoseDetection pose) {
    if (!_isActive || _currentExerciseType == null) return;

    switch (_currentExerciseType!) {
      case FitnessTestExerciseType.pushup:
        _pushupCounter.processPose(pose);
        break;
      case FitnessTestExerciseType.squat:
        _squatCounter.processPose(pose);
        break;
      case FitnessTestExerciseType.abdominal:
        _abdominalCounter.processPose(pose);
        break;
    }

    notifyListeners();
  }

  /// Detiene el ejercicio actual
  void stopCurrentExercise() {
    _stopCurrentExercise();
    notifyListeners();
  }

  void _stopCurrentExercise() {
    if (_currentExerciseType == null) return;

    switch (_currentExerciseType!) {
      case FitnessTestExerciseType.pushup:
        _pushupCounter.endSession();
        break;
      case FitnessTestExerciseType.squat:
        _squatCounter.stop();
        break;
      case FitnessTestExerciseType.abdominal:
        _abdominalCounter.stop();
        break;
    }

    _isActive = false;

    if (kDebugMode) {
      print('⏹️ FitnessCounterEngine: Detenido ${_currentExerciseType!.displayName}');
    }
  }

  /// Reinicia todos los contadores
  void resetAll() {
    _pushupCounter.resetCount();
    _squatCounter.reset();
    _abdominalCounter.reset();
    _currentExerciseType = null;
    _isActive = false;
    notifyListeners();

    if (kDebugMode) {
      print('🔄 FitnessCounterEngine: Reiniciado');
    }
  }

  /// Obtiene resultados actuales
  Map<String, dynamic> getResults() {
    return {
      'pushupCount': pushupCount,
      'squatCount': squatCount,
      'abdominalCount': abdominalCount,
      'pushupQuality': pushupQuality,
      'squatQuality': squatQuality,
      'abdominalQuality': abdominalQuality,
      'totalReps': pushupCount + squatCount + abdominalCount,
    };
  }

  @override
  void dispose() {
    _pushupCounter.dispose();
    _squatCounter.dispose();
    _abdominalCounter.dispose();
    super.dispose();
  }
}

