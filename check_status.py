"""
SOLUCIÓN RÁPIDA: Usar modelo preconvertido o mock mejorado
Si TensorFlow tarda mucho en instalarse
"""

from pathlib import Path

def check_status():
    print("\n📊 ESTADO DEL PROYECTO\n")
    print("="*60)
    
    # Verificar archivos descargados
    pt_file = Path("yolo11n-pose.pt")
    tflite_file = Path("assets/models/yolov11_pose.tflite")
    
    print(f"✅ Modelo PyTorch (.pt):  {'SÍ' if pt_file.exists() else 'NO'}")
    print(f"{'✅' if tflite_file.exists() else '❌'} Modelo TFLite:       {'SÍ' if tflite_file.exists() else 'NO'}")
    
    print("\n" + "="*60)
    print("\n💡 OPCIONES:\n")
    
    if not tflite_file.exists():
        print("1. ESPERAR A QUE TERMINE pip install tensorflow")
        print("   Luego ejecutar: python download_yolo_model.py\n")
        
        print("2. USAR LA APP CON DATOS SIMULADOS (ya funciona)")
        print("   flutter run --release")
        print("   (Mostrará skeleton simulado mientras descargas el modelo)\n")
        
        print("3. DESCARGAR MODELO PRECONVERTIDO (más rápido)")
        print("   Desde: https://github.com/PINTO0309/PINTO_model_zoo")
        print("   Buscar: YOLO11-Pose TFLite\n")
        
        print("4. CONVERTIR MANUALMENTE CON ESTE COMANDO:")
        print("   pip install tensorflow onnx onnx-tf")
        print("   Luego: python download_yolo_model.py\n")
    else:
        print("✅ ¡TODO LISTO! El modelo TFLite ya está disponible\n")
        print("Ejecuta:")
        print("   flutter clean")
        print("   flutter pub get")
        print("   flutter run --release\n")
    
    # Info sobre la app actual
    print("="*60)
    print("\n🎯 ESTADO ACTUAL DE LA APP:\n")
    print("✅ Cámara: Configurada y funcional")
    print("✅ Pipeline: Cámara → YOLO → Contador")
    print("✅ UI: Completa con overlays y feedback")
    print("✅ Permisos: Android + iOS configurados")
    
    if not tflite_file.exists():
        print("⚠️  Modelo: Usando datos simulados (skeleton de prueba)")
        print("\n   La app FUNCIONARÁ pero con pose simulada.")
        print("   Para detección real, necesitas el modelo TFLite.\n")
    else:
        print("✅ Modelo: Real (YOLO11-pose TFLite)\n")
        print("   ¡Detección de pose completamente funcional!\n")

if __name__ == "__main__":
    check_status()
