#!/usr/bin/env python3
"""
DocFlow AI - Custom App Icon Generator
Creates a professional icon representing document processing with AI
"""

from PIL import Image, ImageDraw, ImageFont
import os

def create_docflow_icon():
    """Create a modern DocFlow AI icon"""
    
    # Icon sizes needed for Windows
    sizes = [16, 24, 32, 48, 64, 128, 256, 512, 1024]
    
    for size in sizes:
        # Create canvas
        img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        
        # Colors - Modern blue gradient matching your Arch theme
        primary_blue = (0, 87, 184)      # #0057B8 - Arch primary blue
        light_blue = (91, 194, 231)      # #5BC2E7 - Arch light blue
        accent_blue = (0, 71, 153)       # Darker blue for depth
        white = (255, 255, 255)
        
        # Calculate dimensions
        margin = size * 0.1
        content_size = size - (2 * margin)
        
        # Background - Rounded rectangle with gradient effect
        corner_radius = size * 0.15
        
        # Create background with subtle gradient
        for i in range(int(content_size)):
            alpha = i / content_size
            color = tuple(int(primary_blue[j] * (1 - alpha * 0.3) + accent_blue[j] * alpha * 0.3) for j in range(3))
            draw.rectangle([
                margin + i, margin,
                margin + i + 1, margin + content_size
            ], fill=color + (255,))
        
        # Add rounded corners effect
        draw.rounded_rectangle([
            margin, margin,
            margin + content_size, margin + content_size
        ], radius=corner_radius, fill=None, outline=light_blue, width=max(1, size//64))
        
        # Document icon (left side)
        doc_width = content_size * 0.35
        doc_height = content_size * 0.6
        doc_x = margin + content_size * 0.15
        doc_y = margin + content_size * 0.2
        
        # Document background
        draw.rounded_rectangle([
            doc_x, doc_y,
            doc_x + doc_width, doc_y + doc_height
        ], radius=size//32, fill=white, outline=light_blue, width=max(1, size//128))
        
        # Document lines
        line_count = max(3, size // 64)
        line_spacing = doc_height / (line_count + 1)
        line_width = doc_width * 0.7
        line_x = doc_x + doc_width * 0.15
        
        for i in range(line_count):
            line_y = doc_y + line_spacing * (i + 1)
            line_thickness = max(1, size // 128)
            draw.rectangle([
                line_x, line_y - line_thickness//2,
                line_x + line_width * (0.8 if i == line_count-1 else 1), line_y + line_thickness//2
            ], fill=primary_blue)
        
        # Arrow (flow indicator)
        arrow_size = content_size * 0.15
        arrow_x = margin + content_size * 0.55
        arrow_y = margin + content_size * 0.4
        
        # Arrow shaft
        shaft_width = max(2, size // 64)
        draw.rectangle([
            arrow_x, arrow_y - shaft_width//2,
            arrow_x + arrow_size, arrow_y + shaft_width//2
        ], fill=light_blue)
        
        # Arrow head
        head_size = arrow_size * 0.4
        arrow_points = [
            (arrow_x + arrow_size, arrow_y),
            (arrow_x + arrow_size - head_size, arrow_y - head_size//2),
            (arrow_x + arrow_size - head_size, arrow_y + head_size//2)
        ]
        draw.polygon(arrow_points, fill=light_blue)
        
        # Spreadsheet icon (right side)
        sheet_width = content_size * 0.3
        sheet_height = content_size * 0.5
        sheet_x = margin + content_size * 0.65
        sheet_y = margin + content_size * 0.25
        
        # Spreadsheet background
        draw.rounded_rectangle([
            sheet_x, sheet_y,
            sheet_x + sheet_width, sheet_y + sheet_height
        ], radius=size//32, fill=white, outline=light_blue, width=max(1, size//128))
        
        # Grid lines
        grid_rows = max(3, size // 80)
        grid_cols = max(2, size // 100)
        
        # Horizontal lines
        for i in range(1, grid_rows):
            grid_y = sheet_y + (sheet_height / grid_rows) * i
            draw.line([
                sheet_x, grid_y,
                sheet_x + sheet_width, grid_y
            ], fill=primary_blue, width=max(1, size//256))
        
        # Vertical lines
        for i in range(1, grid_cols):
            grid_x = sheet_x + (sheet_width / grid_cols) * i
            draw.line([
                grid_x, sheet_y,
                grid_x, sheet_y + sheet_height
            ], fill=primary_blue, width=max(1, size//256))
        
        # AI accent - small circuit pattern or brain icon in corner
        if size >= 64:
            ai_size = size * 0.15
            ai_x = margin + content_size * 0.75
            ai_y = margin + content_size * 0.05
            
            # Simple circuit pattern
            circuit_color = (153, 204, 34)  # Arch green for AI accent
            draw.ellipse([
                ai_x, ai_y,
                ai_x + ai_size, ai_y + ai_size
            ], fill=circuit_color, outline=white, width=max(1, size//256))
            
            # Small connection lines if size permits
            if size >= 128:
                line_len = ai_size * 0.3
                draw.line([ai_x + ai_size//2, ai_y, ai_x + ai_size//2, ai_y - line_len], fill=circuit_color, width=max(1, size//256))
                draw.line([ai_x + ai_size, ai_y + ai_size//2, ai_x + ai_size + line_len, ai_y + ai_size//2], fill=circuit_color, width=max(1, size//256))
        
        # Save the icon
        icon_path = f'windows/runner/resources/app_icon_{size}x{size}.ico' if size <= 256 else f'icons/app_icon_{size}.png'
        os.makedirs(os.path.dirname(icon_path), exist_ok=True)
        
        if size <= 256:
            # For ICO files, save as PNG first then convert
            png_path = f'icons/app_icon_{size}.png'
            os.makedirs('icons', exist_ok=True)
            img.save(png_path, 'PNG')
            print(f"Created {png_path}")
        else:
            img.save(icon_path, 'PNG')
            print(f"Created {icon_path}")
    
    # Create the main ICO file with multiple sizes
    try:
        ico_sizes = [16, 24, 32, 48, 64, 128, 256]
        ico_images = []
        
        for size in ico_sizes:
            png_path = f'icons/app_icon_{size}.png'
            if os.path.exists(png_path):
                ico_images.append(Image.open(png_path))
        
        if ico_images:
            ico_images[0].save(
                'windows/runner/resources/app_icon.ico',
                format='ICO',
                sizes=[(img.width, img.height) for img in ico_images],
                append_images=ico_images[1:]
            )
            print("Created windows/runner/resources/app_icon.ico")
            
    except Exception as e:
        print(f"Warning: Could not create ICO file: {e}")
        print("You may need to install Pillow with ICO support: pip install Pillow[ico]")

def create_macos_icons():
    """Create macOS app icons"""
    macos_sizes = [16, 32, 64, 128, 256, 512, 1024]
    
    macos_path = 'macos/Runner/Assets.xcassets/AppIcon.appiconset'
    os.makedirs(macos_path, exist_ok=True)
    
    for size in macos_sizes:
        png_path = f'icons/app_icon_{size}.png'
        if os.path.exists(png_path):
            # Copy to macOS location
            macos_icon_path = f'{macos_path}/app_icon_{size}.png'
            Image.open(png_path).save(macos_icon_path, 'PNG')
            print(f"Created {macos_icon_path}")

if __name__ == "__main__":
    print("🎨 Creating DocFlow AI custom icons...")
    create_docflow_icon()
    create_macos_icons()
    print("✅ Icon creation complete!")
    print("\n📁 Generated files:")
    print("  - windows/runner/resources/app_icon.ico (Windows)")
    print("  - icons/app_icon_*.png (All sizes)")
    print("  - macos/Runner/Assets.xcassets/AppIcon.appiconset/ (macOS)")
