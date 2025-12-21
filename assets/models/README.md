# 🤖 Modelo YOLOv11 - Guía de Configuración

Este directorio debe contener el modelo YOLOv11 convertido a TensorFlow Lite para la detección de poses.

## 📦 Archivo Requerido

```
assets/models/yolov11_pose.tflite
```

**Tamaño esperado**: 5-50 MB (dependiendo de la variante del modelo)

## 🔧 Conversión del Modelo

### Requisitos

```bash
pip install ultralytics torch onnx tensorflow
```

### Opción 1: Modelo Preentrenado (Recomendado)

```python
from ultralytics import YOLO

# Cargar modelo preentrenado de Ultralytics
model = YOLO('yolov11n-pose.pt')  # 'n' = nano (más rápido)
# Alternativas: yolov11s-pose.pt, yolov11m-pose.pt, yolov11l-pose.pt

# Exportar a TFLite
model.export(
    format='tflite',
    imgsz=640,  # Tamaño de entrada (640x640)
    int8=False,  # Usar int8=True para cuantización (modelo más pequeño)
    nms=True     # Incluir Non-Maximum Suppression
)
```

El archivo resultante se llamará `yolov11n-pose_saved_model/yolov11n-pose_float32.tflite`

### Opción 2: Desde ONNX

```python
import onnx
from onnx_tf.backend import prepare
import tensorflow as tf

# 1. Exportar PyTorch → ONNX
model = YOLO('yolov11n-pose.pt')
model.export(format='onnx', imgsz=640)

# 2. Convertir ONNX → TensorFlow
onnx_model = onnx.load('yolov11n-pose.onnx')
tf_rep = prepare(onnx_model)
tf_rep.export_graph('yolov11_pose_tf')

# 3. Convertir TensorFlow → TFLite
converter = tf.lite.TFLiteConverter.from_saved_model('yolov11_pose_tf')
converter.optimizations = [tf.lite.Optimize.DEFAULT]
tflite_model = converter.convert()

# Guardar
with open('yolov11_pose.tflite', 'wb') as f:
    f.write(tflite_model)
```

### Opción 3: Con Cuantización (Modelo más pequeño)

```python
from ultralytics import YOLO

model = YOLO('yolov11n-pose.pt')

# Exportar con cuantización INT8
model.export(
    format='tflite',
    imgsz=640,
    int8=True,  # Reduce tamaño ~4x pero puede perder precisión
    data='coco-pose.yaml'  # Dataset para calibración
)
```

## 📋 Especificaciones del Modelo

### Entrada Esperada

- **Formato**: RGB
- **Tamaño**: 640x640 píxeles
- **Tipo**: float32 [0.0, 1.0] (normalizado)
- **Shape**: `[1, 640, 640, 3]` (batch, height, width, channels)

### Salida Esperada

- **Formato**: 17 keypoints COCO
- **Tipo**: float32
- **Shape**: `[1, num_detections, 51]` donde:
  - `51 = 4 (bbox) + 1 (confidence) + 1 (class) + 45 (17 keypoints × 3)`
  - Cada keypoint: `[x, y, visibility]`

### Keypoints COCO (17 puntos)

```
0:  nose            (nariz)
1:  left_eye        (ojo izquierdo)
2:  right_eye       (ojo derecho)
3:  left_ear        (oreja izquierda)
4:  right_ear       (oreja derecha)
5:  left_shoulder   (hombro izquierdo)   ← Usado para flexiones
6:  right_shoulder  (hombro derecho)     ← Usado para flexiones
7:  left_elbow      (codo izquierdo)     ← CRÍTICO para flexiones
8:  right_elbow     (codo derecho)       ← CRÍTICO para flexiones
9:  left_wrist      (muñeca izquierda)   ← Usado para flexiones
10: right_wrist     (muñeca derecha)     ← Usado para flexiones
11: left_hip        (cadera izquierda)   ← Usado para alineación
12: right_hip       (cadera derecha)     ← Usado para alineación
13: left_knee       (rodilla izquierda)
14: right_knee      (rodilla derecha)
15: left_ankle      (tobillo izquierdo)
16: right_ankle     (tobillo derecho)
```

## 🎯 Variantes del Modelo

| Variante | Tamaño | Velocidad | Precisión | Recomendación  |
| -------- | ------ | --------- | --------- | -------------- |
| YOLOv11n | ~5 MB  | ~50 FPS   | 85%       | ✅ **Móviles** |
| YOLOv11s | ~12 MB | ~40 FPS   | 88%       | Balanceado     |
| YOLOv11m | ~25 MB | ~30 FPS   | 90%       | Alta precisión |
| YOLOv11l | ~50 MB | ~20 FPS   | 92%       | Computadoras   |

**Para esta app, se recomienda YOLOv11n** (nano) por el balance entre velocidad y precisión en dispositivos móviles.

## ✅ Verificación del Modelo

### Comprobar que el modelo funciona

```python
import tensorflow as tf
import numpy as np

# Cargar modelo
interpreter = tf.lite.Interpreter(model_path="yolov11_pose.tflite")
interpreter.allocate_tensors()

# Obtener detalles de entrada/salida
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

print("=== INPUT ===")
print(f"Shape: {input_details[0]['shape']}")
print(f"Type: {input_details[0]['dtype']}")

print("\n=== OUTPUT ===")
print(f"Shape: {output_details[0]['shape']}")
print(f"Type: {output_details[0]['dtype']}")

# Test con imagen dummy
dummy_input = np.random.rand(1, 640, 640, 3).astype(np.float32)
interpreter.set_tensor(input_details[0]['index'], dummy_input)
interpreter.invoke()
output = interpreter.get_tensor(output_details[0]['index'])

print(f"\n✅ Modelo funciona correctamente!")
print(f"Output shape: {output.shape}")
```

### Comprobar tamaño

```bash
# Windows PowerShell
Get-Item yolov11_pose.tflite | Select-Object Name, @{Name="Size(MB)";Expression={[math]::Round($_.Length/1MB, 2)}}

# Linux/Mac
ls -lh yolov11_pose.tflite
```

## 📚 Recursos Adicionales

- [Ultralytics YOLOv11 Docs](https://docs.ultralytics.com/models/yolov11/)
- [COCO Pose Dataset](https://cocodataset.org/#keypoints-2020)
- [TFLite Converter Guide](https://www.tensorflow.org/lite/convert)
- [YOLO Export Formats](https://docs.ultralytics.com/modes/export/)

## ⚠️ Troubleshooting

### Error: "Failed to load model"

1. Verifica que el archivo se llame **exactamente** `yolov11_pose.tflite`
2. Ejecuta `flutter clean && flutter pub get`
3. Reconstruye la app

### Error: "Invalid input shape"

- El modelo debe aceptar entrada `[1, 640, 640, 3]`
- Revisa la exportación con `imgsz=640`

### Modelo muy lento

- Usa YOLOv11n en lugar de modelos más grandes
- Activa cuantización INT8
- Reduce la resolución de la cámara

### Baja precisión

- No uses cuantización INT8
- Usa YOLOv11s o YOLOv11m
- Ajusta `confidenceThreshold` en `yolo_detector.dart`

## 🔄 Script de Descarga Automática

```bash
# download_model.sh
#!/bin/bash

pip install ultralytics

python3 << EOF
from ultralytics import YOLO

print("📥 Descargando YOLOv11n-pose...")
model = YOLO('yolov11n-pose.pt')

print("🔄 Convirtiendo a TFLite...")
model.export(format='tflite', imgsz=640)

print("✅ Modelo listo!")
EOF

mv yolov11n-pose_saved_model/yolov11n-pose_float32.tflite ./yolov11_pose.tflite
echo "✅ Modelo guardado como yolov11_pose.tflite"
```

---

**Última actualización**: 2024  
**Modelo requerido**: YOLOv11-pose (COCO keypoints)  
**Formato**: TensorFlow Lite (.tflite)
