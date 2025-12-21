import 'dart:typed_data';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../models/pose_keypoint.dart';

/// Detector de pose para PULL-UPS (modo PORTRAIT)
/// Este detector está optimizado para orientación vertical (portrait)
/// NO USAR para push-ups (landscape)
class MediaPipeDetectorPullUp {
  PoseDetector? _poseDetector;
  bool _isInitialized = false;
  bool _orientationLogged = false;

  bool get isInitialized => _isInitialized;

  /// Inicializa el detector de pose
  Future<void> initialize() async {
    try {
      final options = PoseDetectorOptions(
        model: PoseDetectionModel.accurate,
        mode: PoseDetectionMode.stream,
      );

      _poseDetector = PoseDetector(options: options);
      _isInitialized = true;

      print('✅ [PullUp] MediaPipe Detector PORTRAIT inicializado');
    } catch (e) {
      print('❌ [PullUp] Error al inicializar MediaPipe: $e');
      _isInitialized = false;
    }
  }

  /// Detecta pose en modo PORTRAIT
  Future<List<PoseKeypoint>> detectPose(
    CameraImage cameraImage,
    int sensorOrientation,
  ) async {
    if (!_isInitialized || _poseDetector == null) {
      return [];
    }

    if (!_orientationLogged) {
      _validateSensorOrientation(sensorOrientation);
      _orientationLogged = true;
    }

    try {
      final inputImage = _convertCameraImage(cameraImage, sensorOrientation);
      if (inputImage == null) {
        print('⚠️ [PullUp] InputImage es null');
        return [];
      }

      final poses = await _poseDetector!.processImage(inputImage);

      if (poses.isEmpty) {
        return [];
      }

      // 🔄 CLAVE PARA PORTRAIT: Intercambiar width/height
      // MediaPipe rota la imagen internamente, necesitamos normalizar
      // con las dimensiones POST-rotación (portrait)
      final imageWidth = cameraImage.height.toDouble(); // ← SWAPPED
      final imageHeight = cameraImage.width.toDouble(); // ← SWAPPED

      final keypoints = _convertPoseToKeypoints(
        poses.first,
        imageWidth,
        imageHeight,
      );

      if (keypoints.isNotEmpty) {
        print('🎯 [PullUp] ${keypoints.length} keypoints detectados');

        final validKeypoints =
            keypoints.where((k) => k.confidence > 0.1).length;
        print('   → $validKeypoints válidos (>10%)');

        final leftShoulder =
            keypoints.where((k) => k.name == 'left_shoulder').firstOrNull;
        if (leftShoulder != null) {
          print(
              '   left_shoulder: x=${leftShoulder.x.toStringAsFixed(3)} y=${leftShoulder.y.toStringAsFixed(3)} conf=${(leftShoulder.confidence * 100).toStringAsFixed(0)}%');
        }
      }

      return keypoints;
    } catch (e) {
      if (!e.toString().contains('IllegalArgumentException')) {
        print('❌ [PullUp] Error en detección: $e');
      }
      return [];
    }
  }

  /// Convierte CameraImage a InputImage
  InputImage? _convertCameraImage(CameraImage image, int sensorOrientation) {
    try {
      final bytes = <int>[];
      for (final Plane plane in image.planes) {
        bytes.addAll(plane.bytes);
      }
      final Uint8List allBytes = Uint8List.fromList(bytes);

      final imageSize = Size(image.width.toDouble(), image.height.toDouble());

      InputImageFormat inputImageFormat = InputImageFormat.nv21;

      if (image.format.group == ImageFormatGroup.bgra8888) {
        inputImageFormat = InputImageFormat.bgra8888;
      }

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
        bytes: allBytes,
        metadata: inputImageMetadata,
      );
    } catch (e) {
      print('❌ [PullUp] Error convirtiendo imagen: $e');
      return null;
    }
  }

  /// Convierte Pose a PoseKeypoint con normalización PORTRAIT
  List<PoseKeypoint> _convertPoseToKeypoints(
    Pose pose,
    double imageWidth,
    double imageHeight,
  ) {
    final keypoints = <PoseKeypoint>[];

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

    bool loggedSample = false;

    landmarkMap.forEach((mlkitType, name) {
      final landmark = pose.landmarks[mlkitType];
      if (landmark != null) {
        // Normalizar con dimensiones portrait (intercambiadas)
        final normalizedX = landmark.x / imageWidth;
        final normalizedY = landmark.y / imageHeight;

        if (!loggedSample && name == 'left_shoulder') {
          print(
              '🎯 [PullUp] CALIBRACIÓN: RAW(${landmark.x.toStringAsFixed(2)}, ${landmark.y.toStringAsFixed(2)}) px '
              '→ NORM(${normalizedX.toStringAsFixed(6)}, ${normalizedY.toStringAsFixed(6)})');
          print('   imageWidth=$imageWidth, imageHeight=$imageHeight');
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

  void _validateSensorOrientation(int sensorOrientation) {
    const expectedOrientation = 270;

    print('📐 [PullUp] Orientación del sensor: $sensorOrientation°');

    if (sensorOrientation != expectedOrientation) {
      print('⚠️ [PullUp] ADVERTENCIA: Orientación inesperada');
      print('   Esperado: $expectedOrientation°');
      print('   Actual: $sensorOrientation°');
    } else {
      print('✅ [PullUp] Orientación correcta para portrait');
    }
  }

  Future<void> dispose() async {
    await _poseDetector?.close();
    _poseDetector = null;
    _isInitialized = false;
    print('🗑️ [PullUp] MediaPipe Detector liberado');
  }
}
