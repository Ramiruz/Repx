"""
SOLUCIÓN DEFINITIVA: Convertir usando ONNX (mucho más rápido que TensorFlow)
El modelo yolo11n-pose.pt ya está descargado, solo necesitamos convertirlo
"""

from pathlib import Path
import sys

def convert_with_onnx():
    print("\n" + "="*70)
    print("🔄 CONVERSIÓN YOLO11 → ONNX → TFLITE")
    print("   (Alternativa rápida sin TensorFlow completo)")
    print("="*70 + "\n")
    
    # Verificar que existe el .pt
    if not Path("yolo11n-pose.pt").exists():
        print("❌ No se encontró yolo11n-pose.pt")
        print("   Ejecuta primero: python download_yolo_model.py")
        return False
    
    print("✅ Modelo PyTorch encontrado: yolo11n-pose.pt\n")
    
    # Importar ultralytics
    try:
        from ultralytics import YOLO
    except ImportError:
        print("❌ Ultralytics no instalado")
        return False
    
    # Cargar modelo
    print("📦 Cargando modelo...")
    model = YOLO('yolo11n-pose.pt')
    print("✅ Modelo cargado\n")
    
    # OPCIÓN 1: Exportar a ONNX (muy rápido, no necesita TensorFlow)
    print("🔄 PASO 1: Exportando a ONNX...")
    print("   (Esto es rápido y no requiere TensorFlow)\n")
    
    try:
        onnx_path = model.export(
            format='onnx',
            imgsz=640,
            simplify=True,
            opset=12
        )
        print(f"✅ ONNX generado: {onnx_path}\n")
        
        # Mover ONNX a assets para usarlo con onnxruntime
        assets_dir = Path("assets/models")
        assets_dir.mkdir(parents=True, exist_ok=True)
        
        import shutil
        onnx_target = assets_dir / "yolov11_pose.onnx"
        shutil.copy2(onnx_path, onnx_target)
        
        size_mb = onnx_target.stat().st_size / (1024 * 1024)
        print(f"✅ ONNX copiado a: {onnx_target}")
        print(f"📊 Tamaño: {size_mb:.2f} MB\n")
        
        print("="*70)
        print("🎉 ¡MODELO ONNX LISTO!")
        print("="*70 + "\n")
        
        print("📋 AHORA NECESITAS:")
        print("1. Usar 'onnxruntime_flutter' en lugar de tflite_flutter\n")
        
        print("Actualiza pubspec.yaml:")
        print("  dependencies:")
        print("    onnxruntime: ^1.14.0  # en lugar de tflite_flutter\n")
        
        print("O ALTERNATIVA 2 (siguiente paso):")
        print("  Convertir ONNX → TFLite con onnx-tf")
        print("  Ejecuta: python convert_onnx_to_tflite.py\n")
        
        return True
        
    except Exception as e:
        print(f"❌ Error exportando ONNX: {e}\n")
        return False

if __name__ == "__main__":
    success = convert_with_onnx()
    
    if success:
        print("✨ Modelo ONNX listo para usar en Flutter!\n")
        print("💡 PRÓXIMO PASO:")
        print("   1. Cambia a onnxruntime (recomendado)")
        print("   2. O ejecuta: pip install onnx-tf && python convert_onnx_to_tflite.py\n")
    
    sys.exit(0 if success else 1)
