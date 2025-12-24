import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/pose_keypoint.dart';
import '../models/pushup_session.dart';
import 'pose_analyzer.dart';
import 'session_storage.dart';
import '../utils/pose_validator.dart'; // Para isInPlankPosition

/// Estados de fase de una flexión
enum PushUpPhase {
  up, // Posición arriba (brazos extendidos)
  down, // Posición abajo (brazos flexionados)
  transition, // En transición entre posiciones
}

/// Contador de flexiones con validación de forma
class PushUpCounter extends ChangeNotifier {
  final PoseAnalyzer _analyzer = PoseAnalyzer();

  // Estado actual
  int _count = 0;
  int _invalidCount = 0;
  PushUpPhase _currentPhase = PushUpPhase.up;
  PushUpPhase _previousPhase = PushUpPhase.up;
  PoseDetection? _currentPose;

  // Sesión actual
  PushUpSession? _currentSession;
  bool _isSessionActive = false;
  Timer? _sessionTimer;

  // Calidad de forma
  double _currentFormQuality = 0.0;
  final List<double> _formQualityHistory = [];

  // Detalles de repeticiones
  final List<RepDetail> _reps = [];

  // Ángulos actuales
  Map<String, double> _currentAngles = {};

  // Feedback
  String _feedback = 'Prepárate';

  // Control de rebote (evitar contar múltiples veces)
  DateTime? _lastRepTime;
  static const Duration minRepDuration = Duration(milliseconds: 500);

  // Suavizado de detección: evitar flicker por falsos negativos temporales
  int _consecutiveInvalidFrames = 0;
  static const int invalidFrameThreshold =
      3; // tolerar hasta 3 frames inválidos
  DateTime? _lastValidPoseTime;
  PoseDetection? _lastValidPose;
  static const Duration lastValidPoseKeepDuration = Duration(seconds: 2);

  // ✅ SISTEMA DE CONFIRMACIÓN DE FASES (2 frames consecutivos - AJUSTADO)
  final List<PushUpPhase> _phaseHistory = [];
  static const int phaseConfirmationFrames =
      2; // REDUCIDO de 3 a 2 para mejor respuesta

  // ✅ HISTORIAL DE ÁNGULOS para validar rango completo
  final List<double> _elbowAngleHistory = [];
  double? _maxElbowInRep; // Ángulo máximo alcanzado en la rep actual
  double? _minElbowInRep; // Ángulo mínimo alcanzado en la rep actual
  bool _hasReachedTop = false; // Confirmó posición arriba
  bool _hasReachedBottom = false; // Confirmó posición abajo

  // Getters
  int get count => _count;
  int get invalidCount => _invalidCount;
  PushUpPhase get currentPhase => _currentPhase;
  PoseDetection? get currentPose => _currentPose;
  double get formQuality => _currentFormQuality;
  String get feedback => _feedback;
  Map<String, double> get angles => _currentAngles;
  bool get isSessionActive => _isSessionActive;
  PushUpSession? get currentSession => _currentSession;
  List<RepDetail> get reps => List.unmodifiable(_reps);

  /// Inicia una nueva sesión de ejercicio
  void startSession() {
    _currentSession = PushUpSession(startTime: DateTime.now());
    _count = 0;
    _invalidCount = 0;
    _reps.clear();
    _formQualityHistory.clear();
    _currentPhase = PushUpPhase.up;
    _previousPhase = PushUpPhase.up;
    _lastRepTime = null;
    _analyzer.clearHistory();

    // ✅ Limpiar historial de confirmación
    _phaseHistory.clear();
    _elbowAngleHistory.clear();
    _maxElbowInRep = null;
    _minElbowInRep = null;
    _hasReachedTop = false;
    _hasReachedBottom = false;

    _isSessionActive = true;

    // Iniciar timer para actualizar duración cada segundo
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      notifyListeners(); // Actualiza el UI con la nueva duración
    });

    print('✅ Sesión de flexiones iniciada');
    notifyListeners();
  }

  /// Finaliza la sesión actual
  Future<PushUpSession?> endSession() async {
    if (!_isSessionActive || _currentSession == null) {
      return null;
    }

    // Calcular calidad promedio
    double avgQuality = 0.0;
    if (_formQualityHistory.isNotEmpty) {
      avgQuality = _formQualityHistory.reduce((a, b) => a + b) /
          _formQualityHistory.length;
    }

    final session = _currentSession!.copyWith(
      endTime: DateTime.now(),
      totalReps: _count,
      invalidReps: _invalidCount,
      averageFormQuality: avgQuality,
      reps: List.from(_reps),
    );

    _isSessionActive = false;
    _currentSession = null;
    _sessionTimer?.cancel();
    _sessionTimer = null;

    print(
      '🏁 Sesión finalizada: $count reps, calidad: ${avgQuality.toStringAsFixed(1)}%',
    );

    // 💾 GUARDAR SESIÓN EN ALMACENAMIENTO PERSISTENTE
    try {
      await SessionStorage.saveSession(session);
      print('💾 Sesión guardada exitosamente');
    } catch (e) {
      print('❌ Error guardando sesión: $e');
    }

    notifyListeners();

    return session;
  }

  /// Procesa una nueva pose detectada
  Future<void> processPose(PoseDetection pose) async {
    if (!_isSessionActive) {
      // ignore: avoid_print
      print('⚠️ Sesión no activa, ignorando pose');
      return;
    }

    // 🚨 VALIDACIÓN CRÍTICA PRIMERO: Verificar posición de plancha
    // Si no está en plancha, NO procesar (previene conteo inválido)
    if (!PoseValidator.isInPlankPosition(pose)) {
      // Incrementar contador de frames inválidos
      _consecutiveInvalidFrames++;

      // Usuario NO está en posición de ejercicio (parado, sentado, etc.)
      _feedback = 'Colócate en posición de plancha';
      _currentFormQuality = 0.0;

      if (_consecutiveInvalidFrames >= invalidFrameThreshold) {
        // Tras varios frames inválidos consecutivos, en lugar de limpiar
        // inmediatamente la pose, conservamos la última pose válida durante
        // un breve periodo (mejora estabilidad visual y evita parpadeos)
        final now = DateTime.now();
        if (_lastValidPose != null &&
            _lastValidPoseTime != null &&
            now.difference(_lastValidPoseTime!) <= lastValidPoseKeepDuration) {
          // Mostrar pose suavizada si está disponible
          final smoothed = _analyzer.getSmoothedPose();
          _currentPose = smoothed ?? _lastValidPose;
          notifyListeners();
          return;
        }

        // Si no hay pose válida reciente, entonces limpiar
        _currentPose = null;
        notifyListeners();
        return; // ❌ NO procesar esta pose
      } else {
        // Durante breve periódo inválido, mantener la pose mostrada (evita flicker)
        _currentPose = pose;
        notifyListeners();
        return;
      }
    }

    // Si llegamos aquí, la pose es válida — resetear contador
    _consecutiveInvalidFrames = 0;

    // Guardar última pose válida y su timestamp
    _lastValidPose = pose;
    _lastValidPoseTime = DateTime.now();

    // Guardar pose actual para el UI
    _currentPose = pose;

    // Analizar pose (se ejecuta en Isolate dentro de PoseAnalyzer)
    final analysis = await _analyzer.analyzePose(pose);

    // Actualizar ángulos y calidad (CLAMP para evitar valores exagerados)
    _currentAngles = analysis.angles;
    _currentFormQuality = analysis.validation.formQuality.clamp(0.0, 100.0);
    _feedback = analysis.feedback;

    // Guardar calidad en historial (solo valores válidos)
    if (_currentFormQuality >= 0 && _currentFormQuality <= 100) {
      _formQualityHistory.add(_currentFormQuality);
    }
    if (_formQualityHistory.length > 100) {
      _formQualityHistory.removeAt(0);
    }

    // Actualizar fase actual
    _previousPhase = _currentPhase;

    if (analysis.isUpPosition) {
      _currentPhase = PushUpPhase.up;
    } else if (analysis.isDownPosition) {
      _currentPhase = PushUpPhase.down;
    } else {
      _currentPhase = PushUpPhase.transition;
    }

    // Detectar repetición completa
    _detectRepetition(analysis);

    notifyListeners();
  }

  /// Detecta si se completó una repetición
  void _detectRepetition(PoseAnalysisResult analysis) {
    final avgElbow = analysis.angles['avg_elbow'];

    // ✅ RASTREAR ÁNGULOS para rango completo de movimiento
    if (avgElbow != null) {
      _elbowAngleHistory.add(avgElbow);
      if (_elbowAngleHistory.length > 20) _elbowAngleHistory.removeAt(0);

      // Actualizar máximo y mínimo en la rep actual
      if (_maxElbowInRep == null || avgElbow > _maxElbowInRep!) {
        _maxElbowInRep = avgElbow;
      }
      if (_minElbowInRep == null || avgElbow < _minElbowInRep!) {
        _minElbowInRep = avgElbow;
      }
    }

    // ✅ CONFIRMACIÓN DE FASE: Requiere 3 frames consecutivos
    PushUpPhase? confirmedPhase;

    if (analysis.isUpPosition) {
      _phaseHistory.add(PushUpPhase.up);
    } else if (analysis.isDownPosition) {
      _phaseHistory.add(PushUpPhase.down);
    } else {
      _phaseHistory.add(PushUpPhase.transition);
    }

    // Mantener sólo últimos 5 frames
    if (_phaseHistory.length > 5) _phaseHistory.removeAt(0);

    // Verificar si tenemos 3 frames consecutivos de la misma fase
    if (_phaseHistory.length >= phaseConfirmationFrames) {
      final lastThree =
          _phaseHistory.sublist(_phaseHistory.length - phaseConfirmationFrames);
      if (lastThree.every((p) => p == PushUpPhase.up)) {
        confirmedPhase = PushUpPhase.up;
        _hasReachedTop = true;
      } else if (lastThree.every((p) => p == PushUpPhase.down)) {
        confirmedPhase = PushUpPhase.down;
        _hasReachedBottom = true;
      }
    }

    // Actualizar fase actual solo si está confirmada
    if (confirmedPhase != null) {
      _previousPhase = _currentPhase;
      _currentPhase = confirmedPhase;
    }

    // 🔍 DEBUG EXHAUSTIVO: Log de fases con contexto completo
    print('🔄 Fase: $_previousPhase → $_currentPhase | '
        'Elbow: ${avgElbow?.toStringAsFixed(1)}° | '
        'TOP:$_hasReachedTop BOT:$_hasReachedBottom | '
        'ROM: ${_minElbowInRep?.toStringAsFixed(0)}°-${_maxElbowInRep?.toStringAsFixed(0)}° | '
        'ConfFrames: ${_phaseHistory.length}/$phaseConfirmationFrames | '
        'Valid: ${analysis.validation.isValid}');

    // ✅ VERIFICAR TRANSICIÓN COMPLETA: UP → DOWN con validaciones estrictas
    if (_previousPhase == PushUpPhase.up && _currentPhase == PushUpPhase.down) {
      print('🔥 TRANSICIÓN DETECTADA: UP → DOWN');

      // ✅ VALIDACIÓN 1: Anti-rebote temporal
      if (_lastRepTime != null) {
        final timeSinceLastRep = DateTime.now().difference(_lastRepTime!);
        if (timeSinceLastRep < minRepDuration) {
          print('⚠️ Repetición muy rápida, ignorando');
          return;
        }
      }

      // ✅ VALIDACIÓN 2: Debe haber alcanzado AMBAS posiciones
      if (!_hasReachedTop || !_hasReachedBottom) {
        print('❌ Rep incompleta: TOP=$_hasReachedTop BOT=$_hasReachedBottom');
        _invalidCount++;
        _resetRepTracking();
        return;
      }

      // ✅ VALIDACIÓN 3: Rango de movimiento completo (ROM)
      if (_maxElbowInRep != null && _minElbowInRep != null) {
        final rom = _maxElbowInRep! - _minElbowInRep!;

        // Requiere al menos 40° de rango (AJUSTADO - permite variaciones individuales)
        // Rango típico real: 90-140° (down) a 140-170° (up) = ~50°, pero aceptamos 40° mínimo
        if (rom < 40.0) {
          print(
              '❌ ROM insuficiente: ${rom.toStringAsFixed(1)}\u00b0 (mínimo 40°)');
          _feedback = 'Rango incompleto: ${rom.toStringAsFixed(0)}\u00b0';
          _invalidCount++;
          _resetRepTracking();
          return;
        }

        print(
            '✅ ROM válido: ${rom.toStringAsFixed(1)}\u00b0 (${_minElbowInRep!.toStringAsFixed(0)}\u00b0 → ${_maxElbowInRep!.toStringAsFixed(0)}\u00b0)');
      }

      // ✅ VALIDACIÓN 4: Forma correcta (plancha)
      if (!analysis.validation.isValid) {
        print('❌ Rep rechazada: ${analysis.validation.errors.join(", ")}');
        _feedback = 'Forma incorrecta: ${analysis.validation.errors.first}';
        _invalidCount++;
        _resetRepTracking();
        return;
      }

      // ✅ REP VÁLIDA - CONTAR
      final elbowAngle = avgElbow ?? 0.0;
      final backAngle = analysis.angles['avg_back'] ?? 0.0;

      final repDetail = RepDetail(
        repNumber: _count + 1,
        formQuality: analysis.validation.formQuality,
        elbowAngle: elbowAngle,
        backAngle: backAngle,
        isValid: true,
      );

      _reps.add(repDetail);
      _count++;
      _feedback = '¡Excelente! Rep #$_count ✓';
      print(
        '✅ Repetición válida #$_count - Calidad: ${analysis.validation.formQuality.toStringAsFixed(1)}% '
        'ROM: ${(_maxElbowInRep! - _minElbowInRep!).toStringAsFixed(0)}\u00b0',
      );

      _lastRepTime = DateTime.now();
      _resetRepTracking();
      notifyListeners();
    }
  }

  /// Reinicia el rastreo de repetición actual
  void _resetRepTracking() {
    _maxElbowInRep = null;
    _minElbowInRep = null;
    _hasReachedTop = false;
    _hasReachedBottom = false;
    _phaseHistory.clear();
  }

  /// Reinicia el contador (mantiene la sesión activa)
  void resetCount() {
    _count = 0;
    _invalidCount = 0;
    _reps.clear();
    _formQualityHistory.clear();
    _currentPhase = PushUpPhase.up;
    _previousPhase = PushUpPhase.up;
    _lastRepTime = null;
    _analyzer.clearHistory();

    // Limpiar nuevos historiales
    _phaseHistory.clear();
    _elbowAngleHistory.clear();
    _maxElbowInRep = null;
    _minElbowInRep = null;
    _hasReachedTop = false;
    _hasReachedBottom = false;

    _feedback = 'Contador reiniciado';

    print('🔄 Contador reiniciado');
    notifyListeners();
  }

  /// Obtiene estadísticas de la sesión actual
  Map<String, dynamic> getSessionStats() {
    if (!_isSessionActive || _currentSession == null) {
      return {'active': false};
    }

    final duration = DateTime.now().difference(_currentSession!.startTime);
    final totalReps = _count + _invalidCount;
    final successRate = totalReps > 0 ? (_count / totalReps) * 100 : 0.0;

    double avgQuality = 0.0;
    if (_formQualityHistory.isNotEmpty) {
      avgQuality = _formQualityHistory.reduce((a, b) => a + b) /
          _formQualityHistory.length;
    }

    return {
      'active': true,
      'duration': duration,
      'validReps': _count,
      'invalidReps': _invalidCount,
      'totalReps': totalReps,
      'successRate': successRate,
      'averageQuality': avgQuality,
      'currentPhase': _currentPhase.name,
    };
  }

  /// Obtiene el mensaje de fase actual
  String getPhaseMessage() {
    switch (_currentPhase) {
      case PushUpPhase.up:
        return 'ARRIBA';
      case PushUpPhase.down:
        return 'ABAJO';
      case PushUpPhase.transition:
        return 'TRANSICIÓN';
    }
  }

  /// Obtiene el color para la fase actual
  String getPhaseColor() {
    switch (_currentPhase) {
      case PushUpPhase.up:
        return '#00FF88'; // Verde
      case PushUpPhase.down:
        return '#00D4FF'; // Cyan
      case PushUpPhase.transition:
        return '#FFAA00'; // Naranja
    }
  }

  @override
  void dispose() {
    if (_isSessionActive) {
      endSession();
    }
    super.dispose();
  }
}

