"""
Alternativa: Exportar YOLOv11 a ONNX y luego a TFLite
(Más rápido si TensorFlow no está disponible)
"""

from pathlib import Path
import shutil
import sys

def export_via_onnx():
    print("\n" + "="*70)
    print("🔄 EXPORTACIÓN YOLO11 VÍA ONNX → TFLITE")
    print("="*70 + "\n")
    
    from ultralytics import YOLO
    
    # Cargar modelo
    print("📥 Cargando modelo YOLO11n-pose...")
    model = YOLO('yolo11n-pose.pt')  # Ya descargado
    print("✅ Modelo cargado\n")
    
    # Intentar exportar directamente a TFLite con opciones simplificadas
    print("🔄 Exportando a TFLite (simplificado)...")
    
    try:
        # Método 1: Sin NMS (más simple)
        result = model.export(format='tflite', imgsz=640, nms=False, simplify=True)
        print(f"✅ Exportación exitosa: {result}\n")
        
    except Exception as e1:
        print(f"❌ Método 1 falló: {e1}\n")
        
        # Método 2: Exportar a ONNX primero
        print("🔄 Intentando vía ONNX...")
        try:
            onnx_result = model.export(format='onnx', imgsz=640, simplify=True)
            print(f"✅ ONNX generado: {onnx_result}\n")
            print("⚠️  Para convertir ONNX→TFLite necesitas:")
            print("   pip install onnx onnx-tf tensorflow\n")
            return False
        except Exception as e2:
            print(f"❌ También falló: {e2}\n")
            return False
    
    # Buscar el .tflite generado
    print("📁 Buscando archivo .tflite...")
    
    tflite_file = None
    for pattern in ["**/*.tflite", "*.tflite"]:
        files = list(Path(".").glob(pattern))
        if files:
            tflite_file = files[0]
            break
    
    if not tflite_file:
        print("❌ No se encontró el .tflite")
        return False
    
    # Mover a assets
    assets_dir = Path("assets/models")
    assets_dir.mkdir(parents=True, exist_ok=True)
    target = assets_dir / "yolov11_pose.tflite"
    
    shutil.copy2(tflite_file, target)
    size_mb = target.stat().st_size / (1024 * 1024)
    
    print(f"✅ Modelo copiado: {target}")
    print(f"📊 Tamaño: {size_mb:.2f} MB\n")
    
    print("🎉 ¡Listo! Ejecuta: flutter clean && flutter pub get && flutter run\n")
    return True

if __name__ == "__main__":
    # Verificar si ya existe el .pt
    if not Path("yolo11n-pose.pt").exists():
        print("❌ Primero ejecuta: python download_yolo_model.py")
        print("   para descargar el modelo base\n")
        sys.exit(1)
    
    success = export_via_onnx()
    sys.exit(0 if success else 1)
