import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/pose_keypoint.dart';
import '../models/pullup_session.dart';
import '../utils/pullup_validator.dart';
import 'session_storage_pullup.dart';

/// Estados de fase de un Pull-Up
enum PullUpPhase {
  down, // Posición abajo (brazos extendidos, colgando)
  up, // Posición arriba (barbilla sobre barra)
  transition, // En transición entre posiciones
}

/// Contador de Pull-Ups con validación de forma
class PullUpCounter extends ChangeNotifier {
  // Estado actual
  int _count = 0;
  int _invalidCount = 0;
  PullUpPhase _currentPhase = PullUpPhase.down;
  PoseDetection? _currentPose;

  // Altura de la barra calibrada (0-1, donde 0 = top, 1 = bottom)
  double _barHeight = 0.3;

  // Sesión actual
  PullUpSession? _currentSession;
  bool _isSessionActive = false;
  Timer? _sessionTimer;

  // Calidad de forma
  double _currentFormQuality = 0.0;
  final List<double> _formQualityHistory = [];

  // Detalles de repeticiones
  final List<RepDetail> _reps = [];

  // Feedback
  String _feedback = 'Cuélgate de la barra';

  // Control de rebote
  DateTime? _lastRepTime;
  // Anti-rebote: tiempo mínimo entre repeticiones válidas.
  // Se reduce ligeramente para permitir ritmos normales, pero mantener protección.
  static const Duration minRepDuration = Duration(milliseconds: 600);

  // Sistema de confirmación de fases
  final List<PullUpPhase> _phaseHistory = [];
  static const int phaseConfirmationFrames = 2;

  // Historial de alturas para validar rango completo
  double? _maxHeightInRep; // Altura máxima (más arriba = menor valor Y)
  double? _minHeightInRep; // Altura mínima (más abajo = mayor valor Y)
  bool _hasReachedTop = false;
  bool _hasReachedBottom = false;

  // Tracking de tiempo en posiciones
  DateTime? _timeEnteredUp;
  DateTime? _timeEnteredDown;
  Duration _totalUpTime = Duration.zero;
  Duration _totalDownTime = Duration.zero;

  // Getters
  int get count => _count;
  int get invalidCount => _invalidCount;
  PullUpPhase get currentPhase => _currentPhase;
  PoseDetection? get currentPose => _currentPose;
  double get formQuality => _currentFormQuality;
  double get averageFormQuality {
    if (_formQualityHistory.isEmpty) return 0.0;
    return _formQualityHistory.reduce((a, b) => a + b) /
        _formQualityHistory.length;
  }

  String get feedback => _feedback;
  bool get isSessionActive => _isSessionActive;
  PullUpSession? get currentSession => _currentSession;
  List<RepDetail> get reps => List.unmodifiable(_reps);
  double get barHeight => _barHeight;

  /// Duración de la sesión actual
  Duration get sessionDuration {
    if (!_isSessionActive || _currentSession == null) {
      return Duration.zero;
    }
    return DateTime.now().difference(_currentSession!.startTime);
  }

  /// Ritmo promedio (reps por minuto)
  double get averagePace {
    if (_count == 0 || _currentSession == null) return 0.0;
    final minutes = sessionDuration.inSeconds / 60.0;
    if (minutes == 0) return 0.0;
    return _count / minutes;
  }

  /// Tiempo total en posición UP
  Duration get timeInUpPosition {
    Duration total = _totalUpTime;
    if (_currentPhase == PullUpPhase.up && _timeEnteredUp != null) {
      total += DateTime.now().difference(_timeEnteredUp!);
    }
    return total;
  }

  /// Tiempo total en posición DOWN
  Duration get timeInDownPosition {
    Duration total = _totalDownTime;
    if (_currentPhase == PullUpPhase.down && _timeEnteredDown != null) {
      total += DateTime.now().difference(_timeEnteredDown!);
    }
    return total;
  }

  /// ROM actual (rango de movimiento como porcentaje)
  double get currentROM {
    if (_maxHeightInRep == null || _minHeightInRep == null) return 0.0;
    return (_minHeightInRep! - _maxHeightInRep!).clamp(0.0, 1.0);
  }

  /// Establece la altura de la barra calibrada
  void setBarHeight(double height) {
    _barHeight = height.clamp(0.0, 1.0);
    notifyListeners();
  }

  /// Inicia una nueva sesión de ejercicio
  void startSession({double? barHeight}) {
    if (barHeight != null) {
      _barHeight = barHeight;
    }

    _currentSession = PullUpSession(
      startTime: DateTime.now(),
      barHeight: _barHeight,
    );
    _count = 0;
    _invalidCount = 0;
    _reps.clear();
    _formQualityHistory.clear();
    _currentPhase = PullUpPhase.down;
    _phaseHistory.clear();
    _maxHeightInRep = null;
    _minHeightInRep = null;
    _hasReachedTop = false;
    _hasReachedBottom = false;
    _lastRepTime = null;

    // Reset tracking de tiempo
    _timeEnteredUp = null;
    _timeEnteredDown = null;
    _totalUpTime = Duration.zero;
    _totalDownTime = Duration.zero;

    _isSessionActive = true;
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      notifyListeners();
    });

    print(
        '🏋️ Sesión de Pull-Ups iniciada (barra: ${(_barHeight * 100).toStringAsFixed(0)}%)');
    notifyListeners();
  }

  /// Finaliza la sesión actual
  Future<PullUpSession?> endSession() async {
    if (!_isSessionActive || _currentSession == null) {
      return null;
    }

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

    // Guardar sesión en almacenamiento local (proteger con try/catch)
    try {
      await SessionStoragePullUp.saveSession(session);
      print('✅ [PullUp] Sesión guardada localmente');
    } catch (e) {
      print('❌ [PullUp] Error guardando sesión: $e');
    }

    print(
      '🏁 Sesión Pull-Ups finalizada: $count reps, calidad: ${avgQuality.toStringAsFixed(1)}%',
    );

    notifyListeners();
    return session;
  }

  /// Procesa una nueva pose detectada
  void processPose(PoseDetection pose) {
    if (!_isSessionActive) {
      return;
    }

    print('🔍 [PullUp] Pose recibida: ${pose.keypoints.length} keypoints');

    // 🔧 SIEMPRE actualizar pose para que el skeleton se dibuje
    _currentPose = pose;

    // Validación: debe estar en posición colgando
    if (!PullUpValidator.isHangingPosition(pose)) {
      _feedback = 'Posiciónate correctamente';
      _currentFormQuality = 0.0;
      print('⚠️ [PullUp] No está en posición colgando');
      notifyListeners();
      return;
    }

    print('✅ [PullUp] Posición colgando detectada');

    // Obtener altura de la cabeza
    final headHeight = PullUpValidator.getHeadHeight(pose);
    if (headHeight == null) {
      _feedback = 'No se detecta la cabeza';
      notifyListeners();
      return;
    }

    // Calcular calidad de forma
    _currentFormQuality = PullUpValidator.calculateFormQuality(pose, _barHeight)
        .clamp(0.0, 100.0);

    if (_currentFormQuality >= 0 && _currentFormQuality <= 100) {
      _formQualityHistory.add(_currentFormQuality);
    }
    if (_formQualityHistory.length > 100) {
      _formQualityHistory.removeAt(0);
    }

    // Manejar feedback según el estado
    if (_count == 0 && _currentFormQuality > 40) {
      _feedback = 'Cuélgate de la barra';
    } else if (_currentFormQuality > 40 && _count > 0) {
      _feedback = '';
    }

    // Determinar fase actual basada en la altura de la cabeza respecto a la barra
    // UP: Cabeza está por encima de la barra (headHeight < barHeight porque Y crece hacia abajo)
    // DOWN: Cabeza está por debajo de la barra (headHeight > barHeight)
    // Thresholds más permisivos para mejor detección
    const upThreshold =
        0.05; // Margen ~5% por encima de la barra (más sensible)
    const downThreshold =
        0.08; // Margen ~8% por debajo de la barra (más sensible)

    final previousPhase = _currentPhase;

    if (headHeight < _barHeight - upThreshold) {
      _currentPhase = PullUpPhase.up;
    } else if (headHeight > _barHeight + downThreshold) {
      _currentPhase = PullUpPhase.down;
    } else {
      _currentPhase = PullUpPhase.transition;
    }

    if (_currentPhase != previousPhase) {
      _updatePhaseTimeTracking(previousPhase, _currentPhase);
      print(
          '🔄 [PullUp] Cambio de fase: $previousPhase → $_currentPhase (headHeight: ${headHeight.toStringAsFixed(2)}, bar: ${_barHeight.toStringAsFixed(2)})');
    }

    // Rastrear alturas para validar ROM
    if (_maxHeightInRep == null || headHeight < _maxHeightInRep!) {
      _maxHeightInRep = headHeight;
    }
    if (_minHeightInRep == null || headHeight > _minHeightInRep!) {
      _minHeightInRep = headHeight;
    }

    // Detectar repetición completa
    _detectRepetition(headHeight);

    notifyListeners();
  }

  /// Detecta si se completó una repetición
  void _detectRepetition(double currentHeight) {
    // Marcar que alcanzó posición UP (sin confirmación de frames por simplicidad)
    if (_currentPhase == PullUpPhase.up && !_hasReachedTop) {
      _hasReachedTop = true;
      _feedback = '¡Arriba! Ahora baja controlado';
      print(
          '✅ [PullUp] Alcanzó posición UP - headHeight: ${currentHeight.toStringAsFixed(3)}');
    }

    // Marcar que alcanzó posición DOWN después de haber estado arriba
    if (_currentPhase == PullUpPhase.down &&
        _hasReachedTop &&
        !_hasReachedBottom) {
      _hasReachedBottom = true;
      print(
          '✅ [PullUp] Alcanzó posición DOWN después de UP - headHeight: ${currentHeight.toStringAsFixed(3)}');
    }

    // Detectar repetición completa: DOWN → UP → DOWN
    if (_hasReachedTop &&
        _hasReachedBottom &&
        _currentPhase == PullUpPhase.down) {
      // Validar anti-rebote
      final now = DateTime.now();
      if (_lastRepTime != null &&
          now.difference(_lastRepTime!) < minRepDuration) {
        if (kDebugMode) {
          // ignore: avoid_print
          print(
              '⚠️ [PullUp] Rep ignorada - anti-rebote (${now.difference(_lastRepTime!).inMilliseconds}ms)');
        }
        return;
      }

      // Validar rango de movimiento (ROM) - más permisivo
      if (_minHeightInRep == null || _maxHeightInRep == null) {
        print('⚠️ [PullUp] ROM: alturas nulas, ignorando rep');
        _resetRepState(currentHeight);
        return;
      }

      final rom = _minHeightInRep! - _maxHeightInRep!;
      const minROM = 0.06; // 6% de la pantalla mínimo (más tolerante)

      print(
          '📏 [PullUp] ROM calculado: ${(rom * 100).toStringAsFixed(1)}% (min: ${(minROM * 100).toStringAsFixed(1)}%)');
      print(
          '📏 [PullUp] Alturas - Max: ${_maxHeightInRep!.toStringAsFixed(3)}, Min: ${_minHeightInRep!.toStringAsFixed(3)}');

      if (rom >= minROM) {
        // ✅ Repetición válida
        _count++;
        _lastRepTime = now;

        final repDetail = RepDetail(
          timestamp: now,
          formQuality: _currentFormQuality,
          maxHeight: _maxHeightInRep!,
          minHeight: _minHeightInRep!,
          isValid: true,
        );
        _reps.add(repDetail);

        _feedback = '¡Pull-Up #$_count completo!';
        if (kDebugMode) {
          // ignore: avoid_print
          print(
              '🔥 [PullUp] REP #$_count VÁLIDA - ROM: ${(rom * 100).toStringAsFixed(1)}%');
        }

        // Asegurar que la UI se actualice inmediatamente tras contar
        notifyListeners();
      } else {
        // ❌ ROM insuficiente
        _invalidCount++;
        _feedback = 'Rango incompleto - sube más alto';
        print(
          '❌ [PullUp] REP INVÁLIDA - ROM: ${(rom * 100).toStringAsFixed(1)}% < ${(minROM * 100).toStringAsFixed(1)}%',
        );

        final repDetail = RepDetail(
          timestamp: now,
          formQuality: _currentFormQuality,
          maxHeight: _maxHeightInRep!,
          minHeight: _minHeightInRep!,
          isValid: false,
        );
        _reps.add(repDetail);
      }

      // Reset para próxima repetición
      _resetRepState(currentHeight);
    }
  }

  /// Actualiza el tracking de tiempo por fase
  void _updatePhaseTimeTracking(PullUpPhase oldPhase, PullUpPhase newPhase) {
    final now = DateTime.now();

    // Terminar el tiempo de la fase anterior
    if (oldPhase == PullUpPhase.up && _timeEnteredUp != null) {
      _totalUpTime += now.difference(_timeEnteredUp!);
      _timeEnteredUp = null;
    } else if (oldPhase == PullUpPhase.down && _timeEnteredDown != null) {
      _totalDownTime += now.difference(_timeEnteredDown!);
      _timeEnteredDown = null;
    }

    // Iniciar el tiempo de la nueva fase
    if (newPhase == PullUpPhase.up) {
      _timeEnteredUp = now;
    } else if (newPhase == PullUpPhase.down) {
      _timeEnteredDown = now;
    }
  }

  /// Resetea el estado de la repetición actual (interno)
  void _resetRepState(double currentHeight) {
    _hasReachedTop = false;
    _hasReachedBottom = false;
    _maxHeightInRep = currentHeight;
    _minHeightInRep = currentHeight;
    print('🔄 [PullUp] Estado de repetición reseteado');
  }

  /// Resetea el contador
  void reset() {
    _count = 0;
    _invalidCount = 0;
    _currentPhase = PullUpPhase.down;
    _currentPose = null;
    _currentFormQuality = 0.0;
    _formQualityHistory.clear();
    _reps.clear();
    _feedback = 'Cuélgate de la barra';
    _phaseHistory.clear();
    _maxHeightInRep = null;
    _minHeightInRep = null;
    _hasReachedTop = false;
    _hasReachedBottom = false;
    _lastRepTime = null;
    // Reset time tracking
    _timeEnteredUp = null;
    _timeEnteredDown = null;
    _totalUpTime = Duration.zero;
    _totalDownTime = Duration.zero;
    notifyListeners();
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    super.dispose();
  }
}

