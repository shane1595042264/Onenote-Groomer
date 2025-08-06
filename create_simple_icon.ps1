# Simple Icon Creator - Creates a basic ICO file that Windows will accept
# This creates a simple geometric design that should work better

Add-Type -AssemblyName System.Drawing

# Create a simple 32x32 icon that follows ICO format properly
$size = 32
$bitmap = New-Object System.Drawing.Bitmap($size, $size)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)

# Enable anti-aliasing
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

# Define simple colors
$blue = [System.Drawing.Color]::FromArgb(255, 70, 130, 200)    # DocFlow blue
$green = [System.Drawing.Color]::FromArgb(255, 80, 200, 120)   # AI green
$white = [System.Drawing.Color]::White
$gray = [System.Drawing.Color]::Gray

# Create brushes
$blueBrush = New-Object System.Drawing.SolidBrush($blue)
$greenBrush = New-Object System.Drawing.SolidBrush($green)
$whiteBrush = New-Object System.Drawing.SolidBrush($white)

# Simple design: Blue circle with "AI" text
$graphics.FillEllipse($blueBrush, 2, 2, 28, 28)
$graphics.DrawEllipse([System.Drawing.Pens]::White, 2, 2, 28, 28)

# Add simple text
$font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
$textRect = [System.Drawing.RectangleF]::new(0, 0, $size, $size)
$format = New-Object System.Drawing.StringFormat
$format.Alignment = [System.Drawing.StringAlignment]::Center
$format.LineAlignment = [System.Drawing.StringAlignment]::Center

$graphics.DrawString("AI", $font, $whiteBrush, $textRect, $format)

# Clean up
$blueBrush.Dispose()
$greenBrush.Dispose() 
$whiteBrush.Dispose()
$font.Dispose()
$format.Dispose()

# Save as temporary PNG first
$tempPng = "temp_icon.png"
$bitmap.Save($tempPng, [System.Drawing.Imaging.ImageFormat]::Png)

$graphics.Dispose()
$bitmap.Dispose()

# Try to convert PNG to ICO using PowerShell
try {
    # Load the PNG
    $png = [System.Drawing.Image]::FromFile((Resolve-Path $tempPng))
    
    # Create a new bitmap from the PNG
    $icoBitmap = New-Object System.Drawing.Bitmap($png, 32, 32)
    
    # Save as ICO (this should create a proper ICO format)
    $icoPath = "windows\runner\resources\app_icon.ico"
    $icoBitmap.Save($icoPath, [System.Drawing.Imaging.ImageFormat]::Icon)
    
    Write-Host "Created proper ICO file: $icoPath"
    
    # Clean up
    $icoBitmap.Dispose()
    $png.Dispose()
    
    # Remove temp file
    Remove-Item $tempPng -Force
    
} catch {
    Write-Host "ICO conversion failed: $($_.Exception.Message)"
    Write-Host "Using original icon instead"
    
    # Remove temp file
    Remove-Item $tempPng -Force -ErrorAction SilentlyContinue
}

Write-Host "Simple icon creation completed!"
