import 'dart:async';
import 'camera_service.dart';
import 'mediapipe_detector.dart';
import 'pushup_counter.dart';
import '../models/pose_keypoint.dart';

/// Servicio que integra cámara, detección MediaPipe y conteo de flexiones
class ExerciseService {
  final CameraService _cameraService = CameraService();
  final MediaPipeDetector _poseDetector = MediaPipeDetector();
  final PushUpCounter counter;

  bool _isProcessing = false;
  bool _isInitialized = false;
  Timer? _processingTimer;
  int _frameCount = 0;
  bool _isDetecting = false;

  CameraService get cameraService => _cameraService;
  bool get isInitialized => _isInitialized;

  ExerciseService({required this.counter});

  /// Inicializa todos los servicios
  Future<bool> initialize() async {
    try {
      print('🔧 Inicializando servicios de ejercicio...');

      // 1. Inicializar detector MediaPipe
      print('📦 Cargando detector de pose...');
      await _poseDetector.initialize();

      if (!_poseDetector.isInitialized) {
        print('❌ Error: detector MediaPipe no inicializado');
        return false;
      }

      // 2. Inicializar cámara
      print('📷 Inicializando cámara...');
      final cameraResult = await _cameraService.initializeCamera();

      if (!cameraResult) {
        print('❌ Error: cámara no disponible');
        return false;
      }

      _isInitialized = true;
      print('✅ Servicios inicializados correctamente');
      return true;
    } catch (e) {
      print('❌ Error inicializando servicios: $e');
      _isInitialized = false;
      return false;
    }
  }

  /// Inicia el procesamiento de frames a 30 FPS
  Future<void> startProcessing() async {
    if (_isProcessing) {
      print('⚠️ Procesamiento ya está activo');
      return;
    }

    if (!_isInitialized) {
      print('❌ Servicios no inicializados');
      return;
    }

    _isProcessing = true;
    print('🚀 Iniciando procesamiento optimizado...');

    // Configurar stream de cámara con throttling
    await _cameraService.startImageStream((cameraImage) async {
      if (!_isProcessing) return;

      // Throttling: procesar solo cada 2 frames (~15 FPS efectivo para mejor tiempo real)
      _frameCount++;
      if (_frameCount % 2 != 0) return;

      // Evitar procesamiento concurrente
      if (_isDetecting) return;
      _isDetecting = true;

      try {
        // 1. Detectar pose con orientación correcta
        final keypoints = await _poseDetector.detectPose(
          cameraImage,
          _cameraService.sensorOrientation,
        );

        if (keypoints.isNotEmpty) {
          // 2. Crear PoseDetection
          final averageConfidence =
              keypoints.fold<double>(0.0, (sum, kp) => sum + kp.confidence) /
                  keypoints.length;

          final poseDetection = PoseDetection(
            keypoints: keypoints,
            overallConfidence: averageConfidence,
          );

          // 3. Procesar
          counter.processPose(poseDetection);
        }
      } catch (e) {
        print('❌ Error procesando frame: $e');
      } finally {
        _isDetecting = false;
      }
    });
  }

  /// Detiene el procesamiento de frames
  Future<void> stopProcessing() async {
    if (!_isProcessing) return;

    print('⏸️ Deteniendo procesamiento...');
    _isProcessing = false;
    _processingTimer?.cancel();

    await _cameraService.stopImageStream();
  }

  /// Pausa el procesamiento temporalmente
  void pauseProcessing() {
    if (_isProcessing) {
      _isProcessing = false;
      _processingTimer?.cancel();
      print('⏸️ Procesamiento pausado');
    }
  }

  /// Reanuda el procesamiento
  void resumeProcessing() {
    if (!_isProcessing && _isInitialized) {
      startProcessing();
      print('▶️ Procesamiento reanudado');
    }
  }

  /// Cambia entre cámara frontal y trasera
  Future<bool> switchCamera() async {
    try {
      final wasProcessing = _isProcessing;

      if (wasProcessing) {
        await stopProcessing();
      }

      final result = await _cameraService.switchCamera();

      if (wasProcessing && result) {
        await startProcessing();
      }

      return result;
    } catch (e) {
      print('Error cambiando cámara: $e');
      return false;
    }
  }

  /// Libera todos los recursos
  Future<void> dispose() async {
    await stopProcessing();
    await _cameraService.dispose();
    await _poseDetector.dispose();
    _processingTimer?.cancel();
    _isInitialized = false;
    print('🧹 Servicios de ejercicio liberados');
  }
}

