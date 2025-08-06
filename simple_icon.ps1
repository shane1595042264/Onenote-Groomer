# Create a modern icon for DocFlow AI
Add-Type -AssemblyName System.Drawing

$size = 64
$bitmap = New-Object System.Drawing.Bitmap($size, $size)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

# Clear with light background
$graphics.Clear([System.Drawing.Color]::FromArgb(248, 249, 250))

# Colors
$noteBlue = [System.Drawing.Color]::FromArgb(88, 101, 242)
$excelGreen = [System.Drawing.Color]::FromArgb(16, 137, 62)
$arrowOrange = [System.Drawing.Color]::FromArgb(255, 89, 94)

# Brushes
$noteBrush = New-Object System.Drawing.SolidBrush($noteBlue)
$excelBrush = New-Object System.Drawing.SolidBrush($excelGreen)
$arrowBrush = New-Object System.Drawing.SolidBrush($arrowOrange)
$whiteBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)

# Document (left)
$graphics.FillRectangle($noteBrush, 5, 12, 18, 24)
# Add paper fold
$graphics.FillPolygon($whiteBrush, @(
    [System.Drawing.Point]::new(19, 12),
    [System.Drawing.Point]::new(23, 16),
    [System.Drawing.Point]::new(19, 16)
))

# Text lines
$linePen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(200, 255, 255, 255), 1)
$graphics.DrawLine($linePen, 8, 18, 18, 18)
$graphics.DrawLine($linePen, 8, 22, 16, 22)
$graphics.DrawLine($linePen, 8, 26, 19, 26)
$graphics.DrawLine($linePen, 8, 30, 14, 30)

# Spreadsheet (right)
$graphics.FillRectangle($excelBrush, 41, 12, 18, 24)

# Grid
$gridPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(180, 255, 255, 255), 1)
for ($i = 1; $i -lt 3; $i++) {
    $x = 41 + ($i * 6)
    $graphics.DrawLine($gridPen, $x, 15, $x, 33)
}
for ($i = 1; $i -lt 4; $i++) {
    $y = 15 + ($i * 5)
    $graphics.DrawLine($gridPen, 44, $y, 56, $y)
}

# Arrow
$graphics.FillRectangle($arrowBrush, 26, 23, 12, 3)
$graphics.FillPolygon($arrowBrush, @(
    [System.Drawing.Point]::new(36, 20),
    [System.Drawing.Point]::new(41, 24),
    [System.Drawing.Point]::new(36, 28)
))

# AI badge
$aiBadge = [System.Drawing.Color]::FromArgb(255, 193, 7)
$aiBrush = New-Object System.Drawing.SolidBrush($aiBadge)
$graphics.FillEllipse($aiBrush, 47, 40, 12, 12)

$aiFont = New-Object System.Drawing.Font("Arial", 6, [System.Drawing.FontStyle]::Bold)
$graphics.DrawString("AI", $aiFont, $whiteBrush, 50, 43)

# Save PNG
$bitmap.Save("icon.png", [System.Drawing.Imaging.ImageFormat]::Png)

Write-Host "Modern icon created as icon.png"
Write-Host ""
Write-Host "To convert to ICO format:"
Write-Host "1. Go to https://convertico.com"
Write-Host "2. Upload icon.png"
Write-Host "3. Download the ICO file"
Write-Host "4. Replace windows/runner/resources/app_icon.ico"

# Cleanup
$graphics.Dispose()
$bitmap.Dispose()
$noteBrush.Dispose()
$excelBrush.Dispose()
$arrowBrush.Dispose()
$whiteBrush.Dispose()
$aiBrush.Dispose()
$linePen.Dispose()
$gridPen.Dispose()
$aiFont.Dispose()
