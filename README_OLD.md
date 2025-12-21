# 🏋️ Contador de Flexiones con IA

Aplicación Flutter para contar flexiones de pecho (push-ups) en tiempo real usando visión artificial con YOLOv11 y OpenCV.

## ✨ Características Principales

- ✅ **Detección de Pose en Tiempo Real** con YOLOv11
- ✅ **Análisis de Forma** con validación de ángulos
- ✅ **Contador Inteligente** que solo cuenta repeticiones válidas
- ✅ **UI Moderna** con gradientes y animaciones
- ✅ **Feedback en Tiempo Real** sobre la técnica
- ✅ **Estadísticas de Sesión** con historial
- ✅ **Indicadores Visuales** de ángulos y calidad

## 📋 Requisitos

- Flutter SDK (3.24.5 o superior)
- Dart 3.5.4 o superior
- Android SDK 28+ o iOS 12+
- Cámara en el dispositivo

## 🚀 Instalación

### 1. Clonar y configurar

```bash
cd "d:\programacion 5.0\contador flexiones"
flutter pub get
```

### 2. Configurar el Modelo YOLO (IMPORTANTE)

⚠️ **El modelo YOLOv11 NO está incluido**. Debes obtenerlo y convertirlo a TFLite:

#### Opción A: Descargar modelo preentrenado

1. Descarga YOLOv11-pose desde [Ultralytics](https://github.com/ultralytics/ultralytics)
2. Convierte a TFLite:

```python
from ultralytics import YOLO

# Cargar modelo
model = YOLO('yolov11n-pose.pt')

# Exportar a TFLite
model.export(format='tflite', imgsz=640)
```

3. Coloca el archivo `.tflite` en `assets/models/yolov11_pose.tflite`

#### Opción B: Entrenar tu propio modelo

```python
from ultralytics import YOLO

# Entrenar en dataset COCO pose
model = YOLO('yolov11n-pose.yaml')
model.train(data='coco-pose.yaml', epochs=100, imgsz=640)

# Exportar
model.export(format='tflite')
```

#### Verificar tamaño del modelo

El modelo debe ser **< 50MB** para rendimiento óptimo:

```bash
ls -lh assets/models/yolov11_pose.tflite
```

### 3. Actualizar pubspec.yaml

Verifica que `assets/models/` esté incluido:

```yaml
flutter:
  assets:
    - assets/models/
    - assets/sounds/
```

### 4. Ejecutar la aplicación

```bash
# En Android
flutter run -d android

# En iOS
flutter run -d ios

# En modo release (mejor rendimiento)
flutter run --release
```

## 📱 Uso

1. **Iniciar Sesión**: Presiona "Comenzar Ejercicio"
2. **Posicionar Cámara**: Asegúrate de que todo tu cuerpo sea visible
3. **Comenzar**: Presiona "Iniciar Sesión"
4. **Realizar Flexiones**: La app contará automáticamente repeticiones válidas
5. **Ver Feedback**: Observa los indicadores de ángulos y calidad en tiempo real
6. **Finalizar**: Presiona "Finalizar" para ver el resumen de la sesión

## 🎨 Estructura del Proyecto

```
lib/
├── main.dart                     # Punto de entrada de la app
├── models/                       # Modelos de datos
│   ├── pose_keypoint.dart       # Modelo de puntos clave detectados
│   ├── pushup_session.dart      # Modelo de sesión de ejercicio
│   └── exercise_stats.dart      # Modelo de estadísticas
├── services/                     # Lógica de negocio
│   ├── yolo_detector.dart       # Detector YOLOv11 con TFLite
│   ├── pose_analyzer.dart       # Análisis de poses
│   ├── pushup_counter.dart      # Lógica de conteo
│   └── camera_service.dart      # Gestión de cámara
├── utils/                        # Utilidades
│   ├── angle_calculator.dart    # Cálculo de ángulos
│   ├── pose_validator.dart      # Validación de forma
│   └── drawing_utils.dart       # Dibujo de visualizaciones
├── screens/                      # Pantallas de la app
│   ├── home_screen.dart         # Pantalla de inicio
│   ├── exercise_screen.dart     # Pantalla de ejercicio
│   ├── history_screen.dart      # Historial de sesiones
│   └── settings_screen.dart     # Configuración
└── widgets/                      # Widgets reutilizables
    ├── camera_preview_widget.dart  # Preview con skeleton overlay
    ├── counter_display.dart     # Display del contador
    ├── angle_indicator.dart     # Indicadores de ángulos
    ├── feedback_overlay.dart    # Overlay de feedback
    └── stats_card.dart          # Tarjetas de estadísticas
```

## 🧠 Algoritmo de Detección

### Validación de Repetición

```dart
// Fase ARRIBA: Brazos extendidos
- Ángulo de codo > 160°
- Espalda recta (160-180°)

// Fase ABAJO: Brazos flexionados
- Ángulo de codo < 90°
- Espalda recta (160-180°)

// Repetición válida: ABAJO → ARRIBA
if (previousPhase == DOWN && currentPhase == UP) {
  count++;
}
```

### Cálculo de Calidad (0-100%)

- ✅ Espalda recta: +40 puntos
- ✅ Descenso completo: +30 puntos
- ✅ Extensión completa: +30 puntos

## ⚙️ Configuración de Rendimiento

### Optimización de FPS

En `yolo_detector.dart`:

```dart
static const int inputSize = 640;  // Reducir a 416 para más FPS
static const double confidenceThreshold = 0.5;  // Ajustar según precisión
```

### Reducir Latencia

En `camera_service.dart`:

```dart
ResolutionPreset.medium  // Cambiar a .low para dispositivos lentos
```

## 🎨 Personalización de UI

### Colores en `drawing_utils.dart`:

```dart
static const Color primaryColor = Color(0xFF667EEA);    // Azul-púrpura
static const Color secondaryColor = Color(0xFF764BA2);  // Púrpura oscuro
static const Color accentColor = Color(0xFF00D4FF);     // Cyan
static const Color correctColor = Color(0xFF00FF88);    // Verde neón
static const Color errorColor = Color(0xFFFF3366);      // Rojo brillante
```

## 🐛 Solución de Problemas

### Error: "No se pudo cargar el modelo YOLO"

✅ Verifica que el archivo `.tflite` esté en `assets/models/yolov11_pose.tflite`  
✅ Ejecuta `flutter pub get` para actualizar assets  
✅ Limpia y reconstruye: `flutter clean && flutter pub get`

### Error: "Cámara no disponible"

✅ Verifica permisos de cámara en AndroidManifest.xml / Info.plist  
✅ Reinicia la app  
✅ Verifica que el dispositivo tenga cámara funcional

### Bajo rendimiento (<30 FPS)

✅ Usa modo release: `flutter run --release`  
✅ Reduce `inputSize` del modelo a 416 o 320  
✅ Usa `ResolutionPreset.low` en la cámara  
✅ Considera usar un modelo más ligero (YOLOv11n vs YOLOv11m)

## 📊 Especificaciones de Rendimiento

- **FPS Objetivo**: 30 FPS mínimo
- **Latencia**: < 50ms por frame
- **Precisión**: > 90% en detección de keypoints
- **Tamaño del Modelo**: < 50MB

## 📝 TODO / Mejoras Futuras

- [ ] Integración completa de procesamiento de video en tiempo real
- [ ] Implementar `shared_preferences` para persistencia de historial
- [ ] Agregar gráficas de progreso con `fl_chart`
- [ ] Modo espejo para cámara frontal
- [ ] Sonidos de feedback
- [ ] Exportar estadísticas a CSV/PDF
- [ ] Soporte multi-idioma
- [ ] Modo oscuro

## 🤝 Contribuciones

Las contribuciones son bienvenidas. Por favor, abre un issue primero para discutir cambios importantes.

## 📄 Licencia

Este proyecto es de código abierto bajo la licencia MIT.

## 👨‍💻 Autor

Desarrollado con ❤️ usando Flutter

---

**Nota**: Este es un proyecto de demostración/educativo. Para uso en producción, se requiere entrenamiento adicional del modelo y optimizaciones de rendimiento.
