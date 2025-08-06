Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms

# Create a simple but effective icon
$bitmap = New-Object System.Drawing.Bitmap(64, 64)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

# Clear to white background
$graphics.Clear([System.Drawing.Color]::White)

# Define colors - Office style
$oneNoteBlue = [System.Drawing.Color]::FromArgb(114, 49, 163)  # OneNote purple
$excelGreen = [System.Drawing.Color]::FromArgb(16, 124, 16)    # Excel green
$orange = [System.Drawing.Color]::FromArgb(255, 140, 0)        # Arrow orange

# Create brushes and pens
$blueBrush = New-Object System.Drawing.SolidBrush($oneNoteBlue)
$greenBrush = New-Object System.Drawing.SolidBrush($excelGreen)
$orangeBrush = New-Object System.Drawing.SolidBrush($orange)
$whiteBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
$blackPen = New-Object System.Drawing.Pen([System.Drawing.Color]::Black, 1)

# Draw OneNote section (left)
$graphics.FillRectangle($blueBrush, 4, 12, 20, 30)
$graphics.DrawRectangle($blackPen, 4, 12, 20, 30)

# Add simple lines for text
$whitePen = New-Object System.Drawing.Pen([System.Drawing.Color]::White, 1)
$graphics.DrawLine($whitePen, 6, 18, 20, 18)
$graphics.DrawLine($whitePen, 6, 22, 18, 22)
$graphics.DrawLine($whitePen, 6, 26, 20, 26)
$graphics.DrawLine($whitePen, 6, 30, 16, 30)

# Draw Excel section (right)
$graphics.FillRectangle($greenBrush, 40, 12, 20, 30)
$graphics.DrawRectangle($blackPen, 40, 12, 20, 30)

# Add grid for Excel
for ($i = 1; $i -lt 4; $i++) {
    $x = 40 + ($i * 5)
    $graphics.DrawLine($whitePen, $x, 15, $x, 39)
}
for ($i = 1; $i -lt 5; $i++) {
    $y = 15 + ($i * 5)
    $graphics.DrawLine($whitePen, 43, $y, 57, $y)
}

# Draw arrow (middle)
$arrowPoints = @(
    [System.Drawing.Point]::new(26, 26),
    [System.Drawing.Point]::new(36, 26),
    [System.Drawing.Point]::new(33, 23),
    [System.Drawing.Point]::new(38, 27),
    [System.Drawing.Point]::new(33, 31),
    [System.Drawing.Point]::new(36, 28),
    [System.Drawing.Point]::new(26, 28)
)
$graphics.FillPolygon($orangeBrush, $arrowPoints)

# Save as multiple sizes for ICO
$sizes = @(16, 32, 48, 64)
$iconPath = "windows/runner/resources/app_icon.ico"

# Use .NET's built-in Icon creation
$iconData = [System.IO.MemoryStream]::new()

# Simple approach: just save the 64px version and let Windows handle scaling
try {
    # Convert to icon format (simplified)
    $bitmap.Save("temp_64.png", [System.Drawing.Imaging.ImageFormat]::Png)
    
    # Create a simple ICO file structure manually
    $header = [byte[]](0,0,1,0,1,0,64,64,0,0,1,0,32,0)
    $size = (Get-Item "temp_64.png").Length
    $offset = 22
    $header += [BitConverter]::GetBytes([int]$size)
    $header += [BitConverter]::GetBytes([int]$offset)
    
    $iconBytes = $header + (Get-Content "temp_64.png" -Raw -Encoding Byte)
    [System.IO.File]::WriteAllBytes($iconPath, $iconBytes)
    
    Write-Host "Custom icon created successfully!"
}
catch {
    Write-Host "Error creating icon: $($_.Exception.Message)"
    # Fallback: restore original
    Copy-Item "windows/runner/resources/app_icon_backup.ico" $iconPath -Force
    Write-Host "Restored original icon"
}
finally {
    # Cleanup
    if (Test-Path "temp_64.png") { Remove-Item "temp_64.png" }
    $graphics.Dispose()
    $bitmap.Dispose()
    $blueBrush.Dispose()
    $greenBrush.Dispose()
    $orangeBrush.Dispose()
    $whiteBrush.Dispose()
    $blackPen.Dispose()
    $whitePen.Dispose()
}
