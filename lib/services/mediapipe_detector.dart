import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../models/pose_keypoint.dart';

/// Detector de pose utilizando Google ML Kit (MediaPipe)
/// No requiere archivos de modelo externos - funciona out-of-the-box
class MediaPipeDetector {
  PoseDetector? _poseDetector;
  bool _isInitialized = false;
  bool _isProcessing = false; // Flag para evitar colas de frames
  bool _orientationLogged = false; // Flag para validar orientación solo una vez

  bool get isInitialized => _isInitialized;

  /// Inicializa el detector de pose con opciones optimizadas
  Future<void> initialize() async {
    try {
      // Configuración para máxima precisión y performance
      final options = PoseDetectorOptions(
        model:
            PoseDetectionModel.accurate, // Modelo preciso para contar flexiones
        mode: PoseDetectionMode
            .stream, // Stream mode para video continuo - mejor para push-ups
      );

      _poseDetector = PoseDetector(options: options);
      _isInitialized = true;

      print('✅ MediaPipe Pose Detector inicializado (modo STREAM + ACCURATE)');
    } catch (e) {
      print('❌ Error al inicializar MediaPipe: $e');
      _isInitialized = false;
    }
  }

  /// Detecta la pose en un frame de la cámara
  Future<List<PoseKeypoint>> detectPose(
    CameraImage cameraImage,
    int sensorOrientation,
  ) async {
    if (!_isInitialized || _poseDetector == null) {
      return [];
    }

    // Si ya se está procesando un frame, descartamos este para evitar backlog
    if (_isProcessing) {
      return [];
    }

    _isProcessing = true;

    // 🔍 VALIDACIÓN DE ORIENTACIÓN (solo primera vez)
    if (!_orientationLogged) {
      _validateSensorOrientation(sensorOrientation);
      _orientationLogged = true;
    }

    try {
      // Convertir CameraImage a InputImage para ML Kit (operación costosa)
      final inputImage = _convertCameraImage(cameraImage, sensorOrientation);
      if (inputImage == null) {
        if (kDebugMode) print('⚠️ InputImage es null - error en conversión');
        return [];
      }

      // Detectar poses
      // Esperar resultado del detector. processImage es async y ejecuta
      // procesamiento nativo; no queremos múltiples invocaciones simultáneas.
      final poses = await _poseDetector!.processImage(inputImage);

      if (poses.isEmpty) {
        return []; // No hay poses detectadas
      }

      // Convertir la primera pose detectada a nuestro formato
      final keypoints = _convertPoseToKeypoints(
        poses.first,
        cameraImage.width.toDouble(),
        cameraImage.height.toDouble(),
      );

      if (keypoints.isNotEmpty) {
        if (kDebugMode) {
          // Logs ligeros solo en modo debug
          // ignore: avoid_print
          print('MediaPipeDetector: ${keypoints.length} keypoints');
          final validKeypoints =
              keypoints.where((k) => k.confidence > 0.3).length;
          // ignore: avoid_print
          print('  → $validKeypoints válidos');
        }
      }

      return keypoints;
    } catch (e) {
      // Solo logear errores únicos
      if (!e.toString().contains('IllegalArgumentException')) {
        if (kDebugMode) print('❌ Error en detección: $e');
      }
      return [];
    } finally {
      // Liberar flag para procesar siguiente frame
      _isProcessing = false;
    }
  }

  /// Convierte CameraImage a InputImage con rotación correcta
  InputImage? _convertCameraImage(CameraImage image, int sensorOrientation) {
    try {
      // Concatenar todos los bytes de los planos de forma eficiente
      final bytesBuilder = BytesBuilder(copy: false);
      for (final Plane plane in image.planes) {
        bytesBuilder.add(plane.bytes);
      }
      final Uint8List allBytes = bytesBuilder.toBytes();

      final imageSize = Size(image.width.toDouble(), image.height.toDouble());

      // Determinar formato - Android usa NV21 para YUV420
      InputImageFormat inputImageFormat = InputImageFormat.nv21;

      if (image.format.group == ImageFormatGroup.bgra8888) {
        inputImageFormat = InputImageFormat.bgra8888;
      }

      // Convertir orientación del sensor a InputImageRotation
      InputImageRotation rotation;
      switch (sensorOrientation) {
        case 90:
          rotation = InputImageRotation.rotation90deg;
          break;
        case 180:
          rotation = InputImageRotation.rotation180deg;
          break;
        case 270:
          rotation = InputImageRotation.rotation270deg;
          break;
        default:
          rotation = InputImageRotation.rotation0deg;
      }

      final inputImageMetadata = InputImageMetadata(
        size: imageSize,
        rotation: rotation,
        format: inputImageFormat,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      return InputImage.fromBytes(
          bytes: allBytes, metadata: inputImageMetadata);
    } catch (e) {
      if (kDebugMode) print('❌ Error convirtiendo imagen: $e');
      return null;
    }
  }

  /// Convierte Pose de ML Kit a lista de PoseKeypoint
  /// [imageWidth] y [imageHeight] son las dimensiones reales de la imagen
  List<PoseKeypoint> _convertPoseToKeypoints(
    Pose pose,
    double imageWidth,
    double imageHeight,
  ) {
    final keypoints = <PoseKeypoint>[];

    // Mapeo de landmarks de ML Kit a nuestros keypoints
    final landmarkMap = {
      PoseLandmarkType.nose: 'nose',
      PoseLandmarkType.leftEye: 'left_eye',
      PoseLandmarkType.rightEye: 'right_eye',
      PoseLandmarkType.leftEar: 'left_ear',
      PoseLandmarkType.rightEar: 'right_ear',
      PoseLandmarkType.leftShoulder: 'left_shoulder',
      PoseLandmarkType.rightShoulder: 'right_shoulder',
      PoseLandmarkType.leftElbow: 'left_elbow',
      PoseLandmarkType.rightElbow: 'right_elbow',
      PoseLandmarkType.leftWrist: 'left_wrist',
      PoseLandmarkType.rightWrist: 'right_wrist',
      PoseLandmarkType.leftHip: 'left_hip',
      PoseLandmarkType.rightHip: 'right_hip',
      PoseLandmarkType.leftKnee: 'left_knee',
      PoseLandmarkType.rightKnee: 'right_knee',
      PoseLandmarkType.leftAnkle: 'left_ankle',
      PoseLandmarkType.rightAnkle: 'right_ankle',
    };

    // Log de debug para ver valores reales
    bool loggedSample = false;

    landmarkMap.forEach((mlkitType, name) {
      final landmark = pose.landmarks[mlkitType];
      if (landmark != null) {
        // ✅ PRECISIÓN MILITAR: Coordenadas nativas sin transformaciones
        // MediaPipe retorna (x, y) en píxeles con origen top-left
        // Normalizar a [0.0, 1.0] con precisión double completa
        final normalizedX = landmark.x / imageWidth;
        final normalizedY = landmark.y / imageHeight;

        // Log de calibración (solo primer frame)
        if (!loggedSample && name == 'left_shoulder') {
          print(
              '🎯 CALIBRACIÓN: RAW(${landmark.x.toStringAsFixed(2)}, ${landmark.y.toStringAsFixed(2)}) px '
              '→ NORM(${normalizedX.toStringAsFixed(6)}, ${normalizedY.toStringAsFixed(6)})');
          loggedSample = true;
        }

        keypoints.add(
          PoseKeypoint(
            name: name,
            x: normalizedX,
            y: normalizedY,
            confidence: landmark.likelihood,
          ),
        );
      }
    });

    return keypoints;
  }

  /// Valida que la orientación del sensor sea la esperada
  void _validateSensorOrientation(int sensorOrientation) {
    const expectedOrientation = 270; // Cámara frontal landscape

    print('📐 Orientación del sensor: $sensorOrientation°');

    if (sensorOrientation != expectedOrientation) {
      print('⚠️ ADVERTENCIA CRÍTICA: Orientación inesperada');
      print('   Esperado: $expectedOrientation° (frontal landscape)');
      print('   Actual: $sensorOrientation°');
      print(
          '   IMPACTO: Skeleton puede aparecer desalineado o rotado incorrectamente');
      print(
          '   SOLUCIÓN: Verificar transformación en DrawingUtils.transformCoordinate()');
    } else {
      print('✅ Orientación correcta para transformación landscape');
    }
  }

  /// Libera recursos
  Future<void> dispose() async {
    await _poseDetector?.close();
    _poseDetector = null;
    _isInitialized = false;
    print('🗑️ MediaPipe Detector liberado');
  }
}
