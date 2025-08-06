Add-Type -AssemblyName System.Drawing

# Create a 256x256 bitmap
$bitmap = New-Object System.Drawing.Bitmap(256, 256)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.SmoothingMode = 'AntiAlias'

# Clear background to white
$graphics.Clear([System.Drawing.Color]::White)

# Define colors
$blueBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(0, 120, 215))
$greenBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(16, 124, 16))
$orangeBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 165, 0))
$whiteBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
$blackPen = New-Object System.Drawing.Pen([System.Drawing.Color]::Black, 2)

# Draw OneNote document (left side - blue)
$graphics.FillRectangle($blueBrush, 30, 50, 80, 120)
$graphics.DrawRectangle($blackPen, 30, 50, 80, 120)

# Add lines to represent text in OneNote
$whitePen = New-Object System.Drawing.Pen([System.Drawing.Color]::White, 3)
$graphics.DrawLine($whitePen, 40, 70, 100, 70)
$graphics.DrawLine($whitePen, 40, 85, 90, 85)
$graphics.DrawLine($whitePen, 40, 100, 95, 100)
$graphics.DrawLine($whitePen, 40, 115, 85, 115)
$graphics.DrawLine($whitePen, 40, 130, 75, 130)

# Draw Excel spreadsheet (right side - green)
$graphics.FillRectangle($greenBrush, 150, 50, 80, 120)
$graphics.DrawRectangle($blackPen, 150, 50, 80, 120)

# Draw grid lines for Excel
$gridPen = New-Object System.Drawing.Pen([System.Drawing.Color]::White, 1)
for ($i = 1; $i -lt 5; $i++) {
    $x = 150 + ($i * 16)
    $graphics.DrawLine($gridPen, $x, 60, $x, 160)
}
for ($i = 1; $i -lt 7; $i++) {
    $y = 60 + ($i * 15)
    $graphics.DrawLine($gridPen, 160, $y, 220, $y)
}

# Draw conversion arrow (middle)
$arrowPoints = @(
    [System.Drawing.Point]::new(115, 105),
    [System.Drawing.Point]::new(140, 105),
    [System.Drawing.Point]::new(135, 100),
    [System.Drawing.Point]::new(145, 110),
    [System.Drawing.Point]::new(135, 120),
    [System.Drawing.Point]::new(140, 115),
    [System.Drawing.Point]::new(115, 115)
)
$graphics.FillPolygon($orangeBrush, $arrowPoints)

# Add title text
$font = New-Object System.Drawing.Font("Arial", 14, [System.Drawing.FontStyle]::Bold)
$blackBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::Black)
$graphics.DrawString("OneNote", $font, $blackBrush, 25, 180)
$graphics.DrawString("to Excel", $font, $blackBrush, 160, 180)

# Save as PNG first
$bitmap.Save("temp_icon.png", [System.Drawing.Imaging.ImageFormat]::Png)

# Clean up
$graphics.Dispose()
$bitmap.Dispose()
$whitePen.Dispose()
$gridPen.Dispose()
$font.Dispose()

Write-Host "Icon created successfully as temp_icon.png"
