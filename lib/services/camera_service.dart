import 'package:camera/camera.dart';

/// Servicio para gestionar la cámara del dispositivo
class CameraService {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  int _sensorOrientation = 0;

  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;
  List<CameraDescription> get cameras => _cameras;
  int get sensorOrientation => _sensorOrientation;

  /// Inicializa la cámara
  ///
  /// Parámetros:
  /// - [cameraIndex]: Índice de la cámara a usar (0 = trasera, 1 = frontal)
  /// - [resolution]: Resolución deseada (por defecto: medium para rendimiento)
  Future<bool> initializeCamera({
    int cameraIndex = 1, // Por defecto cámara frontal
    ResolutionPreset resolution =
        ResolutionPreset.high, // AUMENTAR resolución para mejor detección
  }) async {
    try {
      print('📹 [CameraService] Iniciando inicialización...');

      // Obtener cámaras disponibles
      _cameras = await availableCameras();
      print('📹 [CameraService] Cámaras encontradas: ${_cameras.length}');

      if (_cameras.isEmpty) {
        print('❌ [CameraService] No se encontraron cámaras disponibles');
        return false;
      }

      // Validar índice
      if (cameraIndex >= _cameras.length) {
        cameraIndex = 0;
      }

      print('📹 [CameraService] Usando cámara: ${_cameras[cameraIndex].name}');
      print(
          '📹 [CameraService] Dirección: ${_cameras[cameraIndex].lensDirection}');

      // Crear controlador de cámara
      _controller = CameraController(
        _cameras[cameraIndex],
        resolution,
        enableAudio: false,
        imageFormatGroup:
            ImageFormatGroup.yuv420, // Formato eficiente para procesamiento
      );

      print('📹 [CameraService] CameraController creado, inicializando...');

      // Inicializar controlador
      await _controller!.initialize();

      print('📹 [CameraService] Initialize() completado');
      print('📹 [CameraService] Controller value: ${_controller!.value}');

      // Guardar orientación del sensor
      _sensorOrientation = _cameras[cameraIndex].sensorOrientation;

      _isInitialized = true;
      print('✅ [CameraService] Cámara inicializada exitosamente');
      print('   - Name: ${_cameras[cameraIndex].name}');
      print('   - Orientation: $_sensorOrientation°');
      print('   - Preview size: ${_controller!.value.previewSize}');

      return true;
    } catch (e) {
      print('❌ [CameraService] Error inicializando cámara: $e');
      print('❌ [CameraService] Stack trace: ${StackTrace.current}');
      _isInitialized = false;
      return false;
    }
  }

  /// Cambia entre cámara frontal y trasera
  Future<bool> switchCamera() async {
    if (_cameras.length < 2) {
      print('Solo hay una cámara disponible');
      return false;
    }

    try {
      final currentIndex = _cameras.indexOf(_controller!.description);
      final newIndex = (currentIndex + 1) % _cameras.length;

      await dispose();
      return await initializeCamera(cameraIndex: newIndex);
    } catch (e) {
      print('Error cambiando cámara: $e');
      return false;
    }
  }

  /// Inicia el streaming de imágenes
  ///
  /// Parámetros:
  /// - [onImage]: Callback que recibe cada frame capturado
  Future<void> startImageStream(Function(CameraImage) onImage) async {
    if (!_isInitialized || _controller == null) {
      throw Exception('La cámara no está inicializada');
    }

    if (_controller!.value.isStreamingImages) {
      print('El streaming ya está activo');
      return;
    }

    try {
      await _controller!.startImageStream((CameraImage image) {
        onImage(image);
      });
      print('Streaming de imágenes iniciado');
    } catch (e) {
      print('Error iniciando streaming: $e');
      rethrow;
    }
  }

  /// Detiene el streaming de imágenes
  Future<void> stopImageStream() async {
    if (!_isInitialized || _controller == null) {
      return;
    }

    if (!_controller!.value.isStreamingImages) {
      return;
    }

    try {
      await _controller!.stopImageStream();
      print('Streaming de imágenes detenido');
    } catch (e) {
      print('Error deteniendo streaming: $e');
    }
  }

  /// Pausa la cámara
  Future<void> pausePreview() async {
    if (_controller != null && _isInitialized) {
      await _controller!.pausePreview();
    }
  }

  /// Reanuda la cámara
  Future<void> resumePreview() async {
    if (_controller != null && _isInitialized) {
      await _controller!.resumePreview();
    }
  }

  /// Libera los recursos de la cámara
  Future<void> dispose() async {
    if (_controller != null) {
      try {
        if (_controller!.value.isStreamingImages) {
          await _controller!.stopImageStream();
        }
        await _controller!.dispose();
        _controller = null;
        _isInitialized = false;
        print('Cámara liberada');
      } catch (e) {
        print('Error liberando cámara: $e');
      }
    }
  }

  /// Obtiene información de la cámara actual
  String getCameraInfo() {
    if (_controller == null || !_isInitialized) {
      return 'Cámara no inicializada';
    }

    final camera = _controller!.description;
    return '${camera.name} - ${camera.lensDirection.name}';
  }

  /// Verifica si la cámara es frontal
  bool get isFrontCamera {
    if (_controller == null) return false;
    return _controller!.description.lensDirection == CameraLensDirection.front;
  }
}

