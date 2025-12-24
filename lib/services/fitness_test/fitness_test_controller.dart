import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import '../../models/pose_keypoint.dart';
import '../../models/fitness_test/fitness_test_state.dart';
import '../../models/fitness_test/fitness_test_result.dart';
import '../../models/fitness_test/fitness_level.dart';
import '../mediapipe_detector.dart';
import 'fitness_counter_engine.dart';
import 'fitness_level_calculator.dart';
import 'fitness_test_storage.dart';
import 'yolo11_interpreter.dart';

/// Controlador principal del Fitness Test
/// 
/// Orquesta todo el flujo del test:
/// - Navegación entre fases
/// - Timers automáticos
/// - Procesamiento de poses
/// - Gestión de estado
class FitnessTestController extends ChangeNotifier {
  /// Estado actual del test
  FitnessTestState _state = FitnessTestState.initial();
  FitnessTestState get state => _state;

  /// Motor de conteo de ejercicios
  final FitnessCounterEngine _counterEngine = FitnessCounterEngine();
  FitnessCounterEngine get counterEngine => _counterEngine;

  /// Intérprete YOLO11 (exclusivo para Fitness Test)
  final Yolo11Interpreter _yoloInterpreter = Yolo11Interpreter();

  /// Detector MediaPipe como fallback
  final MediaPipeDetector _mediapipeDetector = MediaPipeDetector();

  /// Timer para las fases con tiempo
  Timer? _phaseTimer;

  /// StreamController para eventos de cambio de fase
  final StreamController<FitnessTestPhase> _phaseController = 
      StreamController<FitnessTestPhase>.broadcast();
  Stream<FitnessTestPhase> get phaseStream => _phaseController.stream;

  /// ¿Está el controlador inicializado?
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Pose actual detectada
  PoseDetection? _currentPose;
  PoseDetection? get currentPose => _currentPose;

  /// ¿Usar YOLO11 o MediaPipe?
  bool _useYolo = true;
  bool get useYolo => _useYolo;

  // === Inicialización ===

  /// Inicializa el controlador
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Intentar inicializar YOLO11
      try {
        await _yoloInterpreter.initialize();
        _useYolo = _yoloInterpreter.isInitialized;
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ YOLO11 no disponible, usando MediaPipe: $e');
        }
        _useYolo = false;
      }

      // Inicializar MediaPipe como fallback o principal
      if (!_useYolo) {
        await _mediapipeDetector.initialize();
      }

      _isInitialized = true;
      notifyListeners();

      if (kDebugMode) {
        print('✅ FitnessTestController inicializado (YOLO: $_useYolo)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error inicializando FitnessTestController: $e');
      }
      rethrow;
    }
  }

  // === Control de Flujo ===

  /// Inicia el test desde la intro
  void startTest() {
    _state = FitnessTestState(
      startTime: DateTime.now(),
      currentPhase: FitnessTestPhase.intro,
      remainingSeconds: 0,
    );
    _counterEngine.resetAll();
    notifyListeners();

    if (kDebugMode) {
      print('🏁 Fitness Test iniciado');
    }
  }

  /// Avanza a la siguiente fase
  void advanceToNextPhase() {
    final nextPhase = _state.currentPhase.nextPhase;
    _transitionToPhase(nextPhase);
  }

  /// Transiciona a una fase específica
  void _transitionToPhase(FitnessTestPhase phase) {
    // Cancelar timer anterior
    _phaseTimer?.cancel();

    // Detener ejercicio actual si aplica
    if (_state.currentPhase.isExercisePhase) {
      _counterEngine.stopCurrentExercise();
    }

    // Actualizar estado
    _state = _state.copyWith(
      currentPhase: phase,
      remainingSeconds: phase.durationSeconds,
    );

    // Notificar cambio de fase
    _phaseController.add(phase);

    // Iniciar ejercicio si es fase de ejercicio
    if (phase.isExercisePhase && phase.exerciseType != null) {
      _counterEngine.setExerciseType(phase.exerciseType!);
    }

    // Iniciar timer si la fase tiene duración
    if (phase.durationSeconds > 0) {
      _startPhaseTimer();
    }

    notifyListeners();

    if (kDebugMode) {
      print('➡️ Transición a: $phase (${phase.durationSeconds}s)');
    }
  }

  /// Inicia el timer de la fase actual
  void _startPhaseTimer() {
    _phaseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_state.remainingSeconds > 0) {
        _state = _state.copyWith(
          remainingSeconds: _state.remainingSeconds - 1,
          // Actualizar contadores del ejercicio actual
          pushupCount: _counterEngine.pushupCount,
          squatCount: _counterEngine.squatCount,
          abdominalCount: _counterEngine.abdominalCount,
          pushupQuality: _counterEngine.pushupQuality,
          squatQuality: _counterEngine.squatQuality,
          abdominalQuality: _counterEngine.abdominalQuality,
        );
        notifyListeners();
      } else {
        // Timer terminado, avanzar a siguiente fase
        timer.cancel();
        advanceToNextPhase();
      }
    });
  }

  /// Salta el receso actual
  void skipRest() {
    if (_state.currentPhase.isRestPhase) {
      advanceToNextPhase();
    }
  }

  /// Pausa/reanuda el test
  void togglePause() {
    if (_state.isPaused) {
      // Reanudar
      _state = _state.copyWith(isPaused: false);
      if (_state.currentPhase.durationSeconds > 0) {
        _startPhaseTimer();
      }
    } else {
      // Pausar
      _phaseTimer?.cancel();
      _state = _state.copyWith(isPaused: true);
    }
    notifyListeners();
  }

  // === Procesamiento de Poses ===

  /// Procesa un frame de la cámara
  Future<void> processFrame(CameraImage image, int sensorOrientation) async {
    if (!_isInitialized || !_state.currentPhase.isExercisePhase) return;

    try {
      PoseDetection? pose;

      // Intentar con YOLO11 primero
      if (_useYolo) {
        pose = await _yoloInterpreter.detectPose(image, sensorOrientation);
      }

      // Fallback a MediaPipe
      if (pose == null) {
        final keypoints = await _mediapipeDetector.detectPose(image, sensorOrientation);
        if (keypoints.isNotEmpty) {
          pose = PoseDetection(
            keypoints: keypoints,
            overallConfidence: keypoints.fold<double>(0, (sum, kp) => sum + kp.confidence) / keypoints.length,
            timestamp: DateTime.now(),
          );
        }
      }

      if (pose != null) {
        _currentPose = pose;
        _counterEngine.processPose(pose);

        // Actualizar estado con contadores actuales
        _state = _state.copyWith(
          pushupCount: _counterEngine.pushupCount,
          squatCount: _counterEngine.squatCount,
          abdominalCount: _counterEngine.abdominalCount,
          pushupQuality: _counterEngine.pushupQuality,
          squatQuality: _counterEngine.squatQuality,
          abdominalQuality: _counterEngine.abdominalQuality,
        );

        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error procesando frame: $e');
      }
    }
  }

  // === Resultados ===

  /// Genera el resultado final del test
  FitnessTestResult generateResult() {
    final totalReps = _state.totalReps;
    final level = FitnessLevelExtension.fromTotalReps(totalReps);
    
    final suggestions = FitnessLevelCalculator.generateSuggestions(
      pushupCount: _state.pushupCount,
      squatCount: _state.squatCount,
      abdominalCount: _state.abdominalCount,
      pushupQuality: _state.pushupQuality,
      squatQuality: _state.squatQuality,
      abdominalQuality: _state.abdominalQuality,
    );

    return FitnessTestResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      pushupCount: _state.pushupCount,
      squatCount: _state.squatCount,
      abdominalCount: _state.abdominalCount,
      pushupQuality: _state.pushupQuality,
      squatQuality: _state.squatQuality,
      abdominalQuality: _state.abdominalQuality,
      level: level,
      suggestions: suggestions,
      durationSeconds: DateTime.now().difference(_state.startTime).inSeconds,
    );
  }

  /// Guarda el resultado en almacenamiento
  Future<void> saveResult(FitnessTestResult result) async {
    await FitnessTestStorage.saveResult(result);
  }

  /// Reinicia el controlador
  void reset() {
    _phaseTimer?.cancel();
    _state = FitnessTestState.initial();
    _counterEngine.resetAll();
    _currentPose = null;
    notifyListeners();

    if (kDebugMode) {
      print('🔄 FitnessTestController reiniciado');
    }
  }

  @override
  void dispose() {
    _phaseTimer?.cancel();
    _phaseController.close();
    _counterEngine.dispose();
    _yoloInterpreter.dispose();
    _mediapipeDetector.dispose();
    super.dispose();
  }
}

