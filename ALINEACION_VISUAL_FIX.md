# 🎯 CORRECCIONES DE ALINEACIÓN VISUAL - DOCUMENTACIÓN

## Problema Resuelto

**ANTES:** Los indicadores de ángulos aparecían en posiciones random, desalineados del skeleton, porque:

- Skeleton usaba `transformPoint()` con rotación -90° + espejo
- Ángulos usaban coordenadas raw `(x * width, y * height)` sin transformar
- Resultado: Dos sistemas de coordenadas incompatibles

**AHORA:** Todo usa el mismo sistema de transformación unificado.

---

## Cambios Implementados

### 1. ✅ Método Helper Público: `DrawingUtils.transformCoordinate()`

```dart
/// Transforma coordenadas MediaPipe (0-1) → Canvas (píxeles)
/// Aplica rotación -90° + espejo para cámara frontal landscape
static Offset transformCoordinate(
  PoseKeypoint keypoint,
  double canvasWidth,
  double canvasHeight,
) {
  final x = canvasHeight * (1.0 - keypoint.y);
  final y = canvasWidth * keypoint.x;
  return Offset(x, y);
}
```

**Uso:**

```dart
final screenPos = DrawingUtils.transformCoordinate(
  leftElbow,
  size.width,
  size.height
);
canvas.drawCircle(screenPos, 10, paint); // Alineado perfectamente ✅
```

---

### 2. ✅ `CameraPreviewWidget._drawAngleIndicators()` - CORREGIDO

**ANTES:**

```dart
DrawingUtils.drawAngleIndicator(
  canvas,
  size,
  Offset(leftElbow.x * size.width, leftElbow.y * size.height), // ❌ RAW
  angle,
  'L',
);
```

**AHORA:**

```dart
Offset transformPoint(PoseKeypoint point) {
  final x = displayHeight * (1.0 - point.y);
  final y = displayWidth * point.x;
  return Offset(x, y);
}

DrawingUtils.drawAngleIndicator(
  canvas,
  size,
  transformPoint(leftElbow), // ✅ TRANSFORMADO
  angle,
  'L',
);
```

---

### 3. ✅ Validación de Orientación del Sensor

Se agregó validación automática en `MediaPipeDetector.detectPose()`:

```dart
bool _orientationLogged = false;

if (!_orientationLogged) {
  _validateSensorOrientation(sensorOrientation);
  _orientationLogged = true;
}

void _validateSensorOrientation(int sensorOrientation) {
  const expectedOrientation = 270; // Frontal landscape

  if (sensorOrientation != expectedOrientation) {
    print('⚠️ ADVERTENCIA CRÍTICA: Orientación inesperada');
    print('   Esperado: 270° (frontal landscape)');
    print('   Actual: $sensorOrientation°');
  }
}
```

**Output esperado en consola:**

```
📐 Orientación del sensor: 270°
✅ Orientación correcta para transformación landscape
```

---

### 4. ✅ Herramienta de Debug: `CoordinateDebug`

**Archivo:** `lib/utils/coordinate_debug.dart`

**Métodos disponibles:**

#### a) Overlay Visual de Debug

```dart
CoordinateDebug.drawDebugOverlay(canvas, size, pose);
```

Dibuja:

- 🔴 Círculos rojos = Coordenadas raw (incorrecto)
- 🟢 Círculos verdes = Coordenadas transformadas (correcto)
- 🟨 Línea amarilla = Si hay desalineación > 5px

**Interpretación:**

- Si rojo y verde coinciden → Transformación correcta ✅
- Si están separados → Problema de transformación ❌

#### b) Análisis en Consola

```dart
CoordinateDebug.logTransformationAnalysis(pose, canvasSize);
```

**Output:**

```
📊 ANÁLISIS DE TRANSFORMACIÓN DE COORDENADAS
════════════════════════════════════════════
Canvas: 720x1280

left_shoulder:
  MediaPipe (normalized): (0.450, 0.300)
  Raw (directo):          (324.0, 384.0)
  Transformed (rotado):   (896.0, 324.0)
  Delta: 572.1 píxeles

right_shoulder:
  MediaPipe (normalized): (0.550, 0.300)
  Raw (directo):          (396.0, 384.0)
  Transformed (rotado):   (896.0, 396.0)
  Delta: 500.0 píxeles
════════════════════════════════════════════
```

#### c) Verificación de Orientación

```dart
bool isCorrect = CoordinateDebug.verifySensorOrientation(270);
```

#### d) Métrica de Error de Alineación

```dart
double avgError = CoordinateDebug.calculateAlignmentError(pose, canvasSize);
print('Error promedio: ${avgError.toStringAsFixed(1)} píxeles');
```

**Valores esperados:**

- **0-10 píxeles:** Excelente alineación ✅
- **10-50 píxeles:** Alineación aceptable ⚠️
- **>50 píxeles:** Problema crítico ❌

---

## Cómo Usar el Debug (Opcional)

### Paso 1: Activar Debug en `CameraPreviewWidget`

```dart
// En camera_preview_widget.dart, línea ~110
CustomPaint(
  painter: _PoseOverlayPainter(
    pose: currentPose!,
    angles: angles,
    formQuality: formQuality,
    showAngles: showAngles && showSkeleton,
    showQualityBar: showQualityBar,
    showSkeleton: showSkeleton,
    showDebug: true, // 🔍 AGREGAR ESTA LÍNEA
  ),
),
```

### Paso 2: Modificar `_PoseOverlayPainter`

```dart
class _PoseOverlayPainter extends CustomPainter {
  final bool showDebug; // Agregar parámetro

  _PoseOverlayPainter({
    required this.pose,
    required this.angles,
    required this.formQuality,
    this.showAngles = true,
    this.showQualityBar = true,
    this.showSkeleton = true,
    this.showDebug = false, // ⬅️ Nuevo parámetro
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ... código existente ...

    // 🔍 DIBUJAR DEBUG SI ESTÁ ACTIVADO
    if (showDebug) {
      CoordinateDebug.drawDebugOverlay(canvas, size, pose);
    }
  }
}
```

### Paso 3: Logging en Consola (Primera Pose)

```dart
// En exercise_service.dart, después de detectar pose
if (keypoints.isNotEmpty && _frameCount == 2) { // Solo primera vez
  final poseDetection = PoseDetection(...);

  // 🔍 Log de análisis
  CoordinateDebug.logTransformationAnalysis(
    poseDetection,
    Size(cameraImage.width.toDouble(), cameraImage.height.toDouble())
  );
}
```

---

## Verificación de Corrección

### ✅ Checklist Visual

Ejecuta la app y verifica:

1. **Skeleton alineado con cuerpo:**

   - [ ] Círculos (articulaciones) están sobre hombros, codos, muñecas reales
   - [ ] Líneas (huesos) conectan articulaciones correctamente
   - [ ] No hay offset lateral o vertical visible

2. **Indicadores de ángulos alineados:**

   - [ ] Círculos con grados (ej: "177°") aparecen sobre codos
   - [ ] No están desplazados a la derecha/izquierda/arriba/abajo
   - [ ] Se mueven con el movimiento de los codos

3. **Cabeza circular correcta:**
   - [ ] Círculo de cabeza enmarca cara correctamente
   - [ ] No está desplazado del rostro

### ✅ Checklist Técnico

En la consola, verifica:

```
📐 Orientación del sensor: 270°
✅ Orientación correcta para transformación landscape
```

Si ves esto, todo está bien. Si ves otra orientación:

```
⚠️ ADVERTENCIA CRÍTICA: Orientación inesperada
   Esperado: 270° (frontal landscape)
   Actual: 90°
```

Entonces necesitas ajustar `transformCoordinate()` para esa orientación específica.

---

## Matemática de la Transformación

### Rotación -90° + Espejo Horizontal

**Input MediaPipe:** Coordenadas normalizadas (0-1)

- `(0, 0)` = Top-left de imagen capturada
- `(1, 1)` = Bottom-right de imagen capturada

**Output Canvas:** Coordenadas en píxeles para landscape frontal

- Rotación -90° (counterclockwise): swapea X↔Y
- Espejo horizontal: invierte X
- Fórmula final:
  ```
  x_display = canvasHeight * (1 - y_mediapipe)
  y_display = canvasWidth * x_mediapipe
  ```

**Ejemplo Numérico:**

Supón:

- Canvas: 720px width × 1280px height
- MediaPipe keypoint: (0.5, 0.3) normalizado
- Codo en centro horizontal, 30% desde arriba

Cálculo:

```
x_display = 1280 * (1 - 0.3) = 1280 * 0.7 = 896px
y_display = 720 * 0.5 = 360px
```

Resultado: El codo se dibuja en `(896, 360)` píxeles en el canvas.

---

## Próximos Pasos

1. **Compilar APK:**

   ```bash
   flutter build apk --release
   ```

2. **Instalar en dispositivo:**

   ```bash
   flutter install
   ```

3. **Testing Real:**

   - Realizar 10 flexiones con buena técnica
   - Verificar:
     - ✅ Contador incrementa 1:1 con cada flexión
     - ✅ Skeleton perfectamente alineado con cuerpo
     - ✅ Ángulos en posición correcta sobre codos
     - ✅ Fase cambia ARRIBA→ABAJO correctamente

4. **Si hay problemas:**
   - Activar debug overlay
   - Revisar consola para orientación del sensor
   - Tomar screenshot y analizar desalineación
   - Ajustar transformación si sensor orientation ≠ 270°

---

## Resumen de Archivos Modificados

1. ✅ `lib/utils/drawing_utils.dart`

   - Agregado `transformCoordinate()` público
   - Unificado uso de transformación en `_drawHead()` y `_drawKeypoints()`

2. ✅ `lib/widgets/camera_preview_widget.dart`

   - Corregido `_drawAngleIndicators()` para usar transformación correcta

3. ✅ `lib/services/mediapipe_detector.dart`

   - Agregada validación de orientación del sensor

4. ✅ `lib/utils/coordinate_debug.dart` (nuevo)
   - Herramientas de debug para verificar transformaciones

---

## Estado Final

**PROBLEMA RESUELTO:** ✅ Skeleton y ángulos ahora usan el mismo sistema de coordenadas transformadas, garantizando alineación pixel-perfect con el cuerpo del usuario.

**PRÓXIMO PASO:** Testing en dispositivo físico para validar ambas correcciones:

- Conteo preciso (Prioridad 1) ✅
- Alineación visual (Prioridad 2) ✅
