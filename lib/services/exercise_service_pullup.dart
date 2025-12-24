import 'dart:async';
import 'package:camera/camera.dart';
import 'camera_service.dart';
import 'mediapipe_detector_pullup.dart';
import 'pullup_counter.dart';
import '../models/pose_keypoint.dart';

/// Servicio que integra cámara, detección MediaPipe y conteo de Pull-Ups
class ExerciseServicePullUp {
  final CameraService _cameraService = CameraService();
  final MediaPipeDetectorPullUp _poseDetector = MediaPipeDetectorPullUp();
  final PullUpCounter counter;

  bool _isProcessing = false;
  bool _isInitialized = false;
  int _frameCount = 0;
  bool _isDetecting = false;

  CameraService get cameraService => _cameraService;

  CameraController? get cameraController => _cameraService.controller;

  bool get isInitialized => _isInitialized;

  ExerciseServicePullUp({required this.counter});

  /// Inicializa todos los servicios
  Future<bool> initialize() async {
    try {
      print('🔧 Inicializando servicios Pull-Up...');

      await _poseDetector.initialize();
      if (!_poseDetector.isInitialized) {
        return false;
      }

      final cameraResult = await _cameraService.initializeCamera();
      if (!cameraResult) {
        return false;
      }

      _isInitialized = true;
      return true;
    } catch (e) {
      print('❌ Error inicializando: $e');
      return false;
    }
  }

  /// Inicia el procesamiento de frames
  Future<void> startProcessing() async {
    if (_isProcessing || !_isInitialized) return;

    _isProcessing = true;
    print('🚀 Iniciando procesamiento Pull-Up...');

    await _cameraService.startImageStream((cameraImage) async {
      if (!_isProcessing) return;

      _frameCount++;
      if (_frameCount % 2 != 0) return;

      if (_isDetecting) return;
      _isDetecting = true;

      try {
        final keypoints = await _poseDetector.detectPose(
          cameraImage,
          _cameraService.sensorOrientation,
        );

        if (keypoints.isNotEmpty) {
          final averageConfidence =
              keypoints.fold<double>(0.0, (sum, kp) => sum + kp.confidence) /
                  keypoints.length;

          final poseDetection = PoseDetection(
            keypoints: keypoints,
            overallConfidence: averageConfidence,
          );

          counter.processPose(poseDetection);
        }
      } catch (e) {
        print('❌ Error procesando frame: $e');
      } finally {
        _isDetecting = false;
      }
    });
  }

  /// Detiene el procesamiento
  Future<void> stopProcessing() async {
    if (!_isProcessing) return;
    _isProcessing = false;
    await _cameraService.stopImageStream();
  }

  /// Libera recursos
  Future<void> dispose() async {
    await stopProcessing();
    await _cameraService.dispose();
    _poseDetector.dispose();
  }
}

