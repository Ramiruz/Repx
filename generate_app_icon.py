#!/usr/bin/env python3
"""
Script para generar el icono de la app con una pesa
"""
from PIL import Image, ImageDraw
import os

def create_dumbbell_icon(size=1024):
    """Crea un icono de pesa con diseño moderno"""
    
    # Crear imagen con fondo
    img = Image.new('RGBA', (size, size), (10, 14, 39, 255))  # #0A0E27
    draw = ImageDraw.Draw(img)
    
    # Colores
    cyan = (0, 229, 255, 255)  # #00E5FF
    white = (255, 255, 255, 255)
    dark = (26, 26, 46, 255)
    
    # Dimensiones de la pesa
    center_x, center_y = size // 2, size // 2
    
    # Barra central (horizontal)
    bar_width = int(size * 0.5)
    bar_height = int(size * 0.08)
    bar_left = center_x - bar_width // 2
    bar_top = center_y - bar_height // 2
    
    # Dibujar barra central con gradiente simulado
    for i in range(3):
        offset = i * 2
        color_intensity = 255 - (i * 30)
        bar_color = (0, int(color_intensity * 0.9), color_intensity, 255)
        draw.rounded_rectangle(
            [bar_left + offset, bar_top + offset, 
             bar_left + bar_width - offset, bar_top + bar_height - offset],
            radius=bar_height // 4,
            fill=bar_color
        )
    
    # Discos/pesas a los lados
    disc_width = int(size * 0.15)
    disc_height = int(size * 0.28)
    disc_radius = int(size * 0.02)
    
    # Función para dibujar un disco con efecto 3D
    def draw_disc(x, y, is_left=True):
        # Sombra
        shadow_offset = int(size * 0.01)
        draw.rounded_rectangle(
            [x + shadow_offset, y + shadow_offset, 
             x + disc_width + shadow_offset, y + disc_height + shadow_offset],
            radius=disc_radius,
            fill=(0, 0, 0, 100)
        )
        
        # Disco principal
        draw.rounded_rectangle(
            [x, y, x + disc_width, y + disc_height],
            radius=disc_radius,
            fill=dark
        )
        
        # Borde cyan
        border_width = int(size * 0.008)
        draw.rounded_rectangle(
            [x, y, x + disc_width, y + disc_height],
            radius=disc_radius,
            outline=cyan,
            width=border_width
        )
        
        # Líneas decorativas
        line_count = 3
        line_spacing = disc_height // (line_count + 1)
        for i in range(1, line_count + 1):
            line_y = y + (line_spacing * i)
            line_margin = int(disc_width * 0.2)
            draw.line(
                [x + line_margin, line_y, x + disc_width - line_margin, line_y],
                fill=cyan,
                width=int(size * 0.004)
            )
    
    # Discos izquierdos
    disc_y = center_y - disc_height // 2
    left_disc_x = bar_left - disc_width - int(size * 0.02)
    draw_disc(left_disc_x, disc_y, is_left=True)
    
    # Discos derechos
    right_disc_x = bar_left + bar_width + int(size * 0.02)
    draw_disc(right_disc_x, disc_y, is_left=False)
    
    # Agarre central (detalle)
    grip_width = int(size * 0.12)
    grip_height = int(size * 0.12)
    grip_x = center_x - grip_width // 2
    grip_y = center_y - grip_height // 2
    
    # Círculo de agarre
    draw.ellipse(
        [grip_x, grip_y, grip_x + grip_width, grip_y + grip_height],
        fill=dark,
        outline=cyan,
        width=int(size * 0.008)
    )
    
    # Líneas de textura en el agarre
    texture_lines = 5
    for i in range(texture_lines):
        angle = (360 / texture_lines) * i
        import math
        start_radius = grip_width * 0.25
        end_radius = grip_width * 0.45
        start_x = center_x + int(start_radius * math.cos(math.radians(angle)))
        start_y = center_y + int(start_radius * math.sin(math.radians(angle)))
        end_x = center_x + int(end_radius * math.cos(math.radians(angle)))
        end_y = center_y + int(end_radius * math.sin(math.radians(angle)))
        draw.line([start_x, start_y, end_x, end_y], fill=cyan, width=int(size * 0.003))
    
    return img

def create_foreground_icon(size=1024):
    """Crea el icono foreground (solo la pesa, sin fondo)"""
    
    # Crear imagen transparente
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Colores
    cyan = (0, 229, 255, 255)
    white = (255, 255, 255, 255)
    dark = (26, 26, 46, 255)
    
    # Padding para adaptive icon
    padding = int(size * 0.15)
    actual_size = size - (padding * 2)
    center_x, center_y = size // 2, size // 2
    
    # Barra central
    bar_width = int(actual_size * 0.5)
    bar_height = int(actual_size * 0.08)
    bar_left = center_x - bar_width // 2
    bar_top = center_y - bar_height // 2
    
    draw.rounded_rectangle(
        [bar_left, bar_top, bar_left + bar_width, bar_top + bar_height],
        radius=bar_height // 4,
        fill=white
    )
    
    # Discos
    disc_width = int(actual_size * 0.15)
    disc_height = int(actual_size * 0.28)
    disc_radius = int(actual_size * 0.02)
    disc_y = center_y - disc_height // 2
    
    # Disco izquierdo
    left_disc_x = bar_left - disc_width - int(actual_size * 0.02)
    draw.rounded_rectangle(
        [left_disc_x, disc_y, left_disc_x + disc_width, disc_y + disc_height],
        radius=disc_radius,
        fill=white
    )
    
    # Disco derecho
    right_disc_x = bar_left + bar_width + int(actual_size * 0.02)
    draw.rounded_rectangle(
        [right_disc_x, disc_y, right_disc_x + disc_width, disc_y + disc_height],
        radius=disc_radius,
        fill=white
    )
    
    # Agarre central
    grip_width = int(actual_size * 0.12)
    grip_height = int(actual_size * 0.12)
    grip_x = center_x - grip_width // 2
    grip_y = center_y - grip_height // 2
    
    draw.ellipse(
        [grip_x, grip_y, grip_x + grip_width, grip_y + grip_height],
        fill=cyan,
        outline=white,
        width=int(actual_size * 0.008)
    )
    
    return img

# Generar iconos
print("Generando icono de la app...")

# Icono principal
icon = create_dumbbell_icon(1024)
icon.save("assets/icon/app_icon.png")
print("✅ Icono principal creado: assets/icon/app_icon.png")

# Icono foreground para adaptive icon
foreground = create_foreground_icon(1024)
foreground.save("assets/icon/app_icon_foreground.png")
print("✅ Icono foreground creado: assets/icon/app_icon_foreground.png")

print("\n🎨 Iconos generados exitosamente!")
print("📝 Ahora ejecuta: flutter pub get")
print("📝 Luego ejecuta: dart run flutter_launcher_icons")
