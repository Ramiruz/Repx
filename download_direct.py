"""
OPCIÓN 1: Descargar modelo YOLOv11 TFLite PRECONVERTIDO
(Más rápido - sin necesidad de TensorFlow)
"""

import urllib.request
import os
from pathlib import Path

def download_preconverted_model():
    print("\n" + "="*70)
    print("📥 DESCARGA DIRECTA DE MODELO YOLO11-POSE TFLITE")
    print("="*70 + "\n")
    
    # URLs de modelos preconvertidos
    # Estos son modelos que ya están en formato TFLite
    urls = {
        "yolo11n-pose (recomendado)": "https://github.com/ultralytics/assets/releases/download/v8.3.0/yolo11n-pose.tflite",
        "yolo11s-pose (más preciso)": "https://github.com/ultralytics/assets/releases/download/v8.3.0/yolo11s-pose.tflite",
    }
    
    print("Modelos disponibles:")
    for i, (name, url) in enumerate(urls.items(), 1):
        print(f"{i}. {name}")
    
    choice = input("\nElige modelo (1-2, Enter=1): ").strip() or "1"
    
    selected_url = list(urls.values())[int(choice)-1] if choice in ["1", "2"] else list(urls.values())[0]
    model_name = list(urls.keys())[int(choice)-1] if choice in ["1", "2"] else list(urls.keys())[0]
    
    print(f"\n📥 Descargando {model_name}...")
    print(f"URL: {selected_url}\n")
    
    # Crear directorio assets/models
    assets_dir = Path("assets/models")
    assets_dir.mkdir(parents=True, exist_ok=True)
    
    target_file = assets_dir / "yolov11_pose.tflite"
    
    try:
        # Descargar con barra de progreso
        def show_progress(block_num, block_size, total_size):
            downloaded = block_num * block_size
            percent = min(100, (downloaded / total_size) * 100)
            bar_len = 50
            filled = int(bar_len * percent / 100)
            bar = '█' * filled + '-' * (bar_len - filled)
            print(f'\r[{bar}] {percent:.1f}%', end='', flush=True)
        
        urllib.request.urlretrieve(selected_url, target_file, show_progress)
        print("\n")
        
        # Verificar tamaño
        size_mb = target_file.stat().st_size / (1024 * 1024)
        print(f"✅ Modelo descargado: {target_file}")
        print(f"📊 Tamaño: {size_mb:.2f} MB\n")
        
        print("="*70)
        print("🎉 ¡LISTO PARA USAR!")
        print("="*70 + "\n")
        print("Ejecuta:")
        print("  flutter clean")
        print("  flutter pub get")
        print("  flutter run --release\n")
        
        return True
        
    except Exception as e:
        print(f"\n❌ Error descargando: {e}")
        print("\n💡 Alternativa: Descarga manualmente desde:")
        print(f"   {selected_url}")
        print(f"   Y guárdalo como: {target_file}\n")
        return False

if __name__ == "__main__":
    success = download_preconverted_model()
    exit(0 if success else 1)
