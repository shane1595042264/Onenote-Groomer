# PowerShell script to create a professional icon for OneNote Groomer
Add-Type -AssemblyName System.Drawing

# Create a clean 128x128 icon
$size = 128
$bitmap = New-Object System.Drawing.Bitmap($size, $size)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

# Background gradient (light blue to white)
$rect = New-Object System.Drawing.Rectangle(0, 0, $size, $size)
$startColor = [System.Drawing.Color]::FromArgb(245, 250, 255)
$endColor = [System.Drawing.Color]::FromArgb(225, 240, 255)
$gradientBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, $startColor, $endColor, 45)
$graphics.FillRectangle($gradientBrush, $rect)

# Define modern colors
$noteColor = [System.Drawing.Color]::FromArgb(88, 101, 242)    # Modern purple
$excelColor = [System.Drawing.Color]::FromArgb(16, 137, 62)    # Excel green
$accentColor = [System.Drawing.Color]::FromArgb(255, 89, 94)   # Modern coral
$textColor = [System.Drawing.Color]::FromArgb(50, 50, 50)      # Dark gray

# Create brushes
$noteBrush = New-Object System.Drawing.SolidBrush($noteColor)
$excelBrush = New-Object System.Drawing.SolidBrush($excelColor)
$accentBrush = New-Object System.Drawing.SolidBrush($accentColor)
$whiteBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)

# Draw document icon (left side)
$docRect = New-Object System.Drawing.Rectangle(15, 25, 35, 45)
$graphics.FillRoundedRectangle($noteBrush, $docRect, 4)

# Add subtle shadow
$shadowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(50, 0, 0, 0))
$shadowRect = New-Object System.Drawing.Rectangle(17, 27, 35, 45)
$graphics.FillRoundedRectangle($shadowBrush, $shadowRect, 4)
$graphics.FillRoundedRectangle($noteBrush, $docRect, 4)

# Add lines to represent text
$linePen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(200, 255, 255, 255), 2)
$graphics.DrawLine($linePen, 20, 35, 42, 35)
$graphics.DrawLine($linePen, 20, 42, 38, 42)
$graphics.DrawLine($linePen, 20, 49, 45, 49)
$graphics.DrawLine($linePen, 20, 56, 35, 56)

# Draw spreadsheet icon (right side)
$xlsRect = New-Object System.Drawing.Rectangle(78, 25, 35, 45)
$graphics.FillRoundedRectangle($excelBrush, $xlsRect, 4)

# Add grid pattern
$gridPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(180, 255, 255, 255), 1)
for ($i = 1; $i -lt 4; $i++) {
    $x = 78 + ($i * 8)
    $graphics.DrawLine($gridPen, $x, 30, $x, 65)
}
for ($i = 1; $i -lt 5; $i++) {
    $y = 30 + ($i * 8)
    $graphics.DrawLine($gridPen, 83, $y, 108, $y)
}

# Draw conversion arrow with modern style
$arrowY = 47
$arrowStartX = 55
$arrowEndX = 73
$arrowBrush = New-Object System.Drawing.SolidBrush($accentColor)

# Arrow body
$graphics.FillRectangle($arrowBrush, $arrowStartX, $arrowY - 2, $arrowEndX - $arrowStartX - 5, 4)

# Arrow head
$arrowHead = @(
    [System.Drawing.Point]::new($arrowEndX - 5, $arrowY - 5),
    [System.Drawing.Point]::new($arrowEndX, $arrowY),
    [System.Drawing.Point]::new($arrowEndX - 5, $arrowY + 5)
)
$graphics.FillPolygon($arrowBrush, $arrowHead)

# Add "AI" badge
$aiBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 193, 7))
$aiRect = New-Object System.Drawing.Rectangle(95, 75, 25, 15)
$graphics.FillRoundedRectangle($aiBrush, $aiRect, 7)

$aiFont = New-Object System.Drawing.Font("Arial", 8, [System.Drawing.FontStyle]::Bold)
$aiText = "AI"
$aiSize = $graphics.MeasureString($aiText, $aiFont)
$aiX = $aiRect.X + ($aiRect.Width - $aiSize.Width) / 2
$aiY = $aiRect.Y + ($aiRect.Height - $aiSize.Height) / 2
$graphics.DrawString($aiText, $aiFont, $whiteBrush, $aiX, $aiY)

# Save as high-quality PNG
$bitmap.Save("onenote_groomer_icon.png", [System.Drawing.Imaging.ImageFormat]::Png)

Write-Host "Icon created as onenote_groomer_icon.png"
Write-Host "You can convert this to ICO format using an online converter like:"
Write-Host "- https://convertico.com"
Write-Host "- https://www.icoconverter.com"
Write-Host "- https://favicon.io/favicon-converter/"

# Cleanup
$graphics.Dispose()
$bitmap.Dispose()
$gradientBrush.Dispose()
$noteBrush.Dispose()
$excelBrush.Dispose()
$accentBrush.Dispose()
$whiteBrush.Dispose()
$shadowBrush.Dispose()
$linePen.Dispose()
$gridPen.Dispose()
$arrowBrush.Dispose()
$aiBrush.Dispose()
$aiFont.Dispose()

# Extension method for rounded rectangles (simple approximation)
Add-Type -TypeDefinition @"
using System;
using System.Drawing;
using System.Drawing.Drawing2D;

public static class GraphicsExtensions
{
    public static void FillRoundedRectangle(this Graphics graphics, Brush brush, Rectangle rect, int radius)
    {
        using (GraphicsPath path = new GraphicsPath())
        {
            path.AddArc(rect.X, rect.Y, radius * 2, radius * 2, 180, 90);
            path.AddArc(rect.Right - radius * 2, rect.Y, radius * 2, radius * 2, 270, 90);
            path.AddArc(rect.Right - radius * 2, rect.Bottom - radius * 2, radius * 2, radius * 2, 0, 90);
            path.AddArc(rect.X, rect.Bottom - radius * 2, radius * 2, radius * 2, 90, 90);
            path.CloseFigure();
            graphics.FillPath(brush, path);
        }
    }
}
"@ -ReferencedAssemblies System.Drawing
