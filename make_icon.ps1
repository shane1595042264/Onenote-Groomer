# Create a simple custom icon with conversion theme
# This creates a 32x32 icon with OneNote -> Excel theme

Add-Type -AssemblyName System.Drawing

# Create bitmap
$bitmap = New-Object System.Drawing.Bitmap(32, 32)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.Clear([System.Drawing.Color]::FromArgb(240, 240, 240))

# Define colors
$blue = [System.Drawing.Color]::FromArgb(68, 114, 196)    # Document blue
$green = [System.Drawing.Color]::FromArgb(70, 120, 70)     # Excel green  
$arrow = [System.Drawing.Color]::FromArgb(255, 140, 0)     # Orange arrow

# Create brushes
$blueBrush = New-Object System.Drawing.SolidBrush($blue)
$greenBrush = New-Object System.Drawing.SolidBrush($green)
$arrowBrush = New-Object System.Drawing.SolidBrush($arrow)
$blackPen = New-Object System.Drawing.Pen([System.Drawing.Color]::Black, 1)

# Draw source document (left)
$graphics.FillRectangle($blueBrush, 2, 6, 10, 14)
$graphics.DrawRectangle($blackPen, 2, 6, 10, 14)

# Draw target spreadsheet (right)  
$graphics.FillRectangle($greenBrush, 20, 6, 10, 14)
$graphics.DrawRectangle($blackPen, 20, 6, 10, 14)

# Draw simple grid in spreadsheet
$whitePen = New-Object System.Drawing.Pen([System.Drawing.Color]::White, 1)
$graphics.DrawLine($whitePen, 23, 9, 27, 9)
$graphics.DrawLine($whitePen, 23, 12, 27, 12)
$graphics.DrawLine($whitePen, 23, 15, 27, 15)
$graphics.DrawLine($whitePen, 25, 8, 25, 17)

# Draw arrow
$graphics.FillRectangle($arrowBrush, 13, 12, 5, 2)
$graphics.FillPolygon($arrowBrush, @(
    [System.Drawing.Point]::new(17, 10),
    [System.Drawing.Point]::new(19, 13),
    [System.Drawing.Point]::new(17, 16)
))

# Save as BMP first, then convert to ICO format
$bmpPath = "temp_icon.bmp"
$icoPath = "windows/runner/resources/app_icon.ico"

$bitmap.Save($bmpPath, [System.Drawing.Imaging.ImageFormat]::Bmp)

# Create a proper ICO file manually
$bmpBytes = [System.IO.File]::ReadAllBytes($bmpPath)
$bmpSize = $bmpBytes.Length

# ICO header (6 bytes) + Directory entry (16 bytes) = 22 bytes
$icoHeader = @(
    0x00, 0x00,  # Reserved
    0x01, 0x00,  # Type (1 = ICO)
    0x01, 0x00   # Count (1 image)
)

$directoryEntry = @(
    0x20,        # Width (32)
    0x20,        # Height (32)  
    0x00,        # Colors (0 = >256 colors)
    0x00,        # Reserved
    0x01, 0x00,  # Planes
    0x20, 0x00   # Bits per pixel (32)
) + [BitConverter]::GetBytes([int32]$bmpSize) + [BitConverter]::GetBytes([int32]22)

$icoBytes = [byte[]]($icoHeader + $directoryEntry) + $bmpBytes

[System.IO.File]::WriteAllBytes($icoPath, $icoBytes)

# Cleanup
Remove-Item $bmpPath -ErrorAction SilentlyContinue
$graphics.Dispose()
$bitmap.Dispose()
$blueBrush.Dispose()
$greenBrush.Dispose()
$arrowBrush.Dispose()
$blackPen.Dispose()
$whitePen.Dispose()

Write-Host "Custom icon created successfully!"
