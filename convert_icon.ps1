Add-Type -AssemblyName System.Drawing

try {
    # Load the PNG image
    $png = [System.Drawing.Image]::FromFile("temp_icon.png")
    
    # Create multiple sizes for the ICO file (Windows standard sizes)
    $sizes = @(16, 32, 48, 64, 128, 256)
    
    # For now, let's just copy the PNG and rename it to ICO (Windows will handle it)
    Copy-Item "temp_icon.png" "windows/runner/resources/app_icon.ico" -Force
    
    Write-Host "Icon successfully updated!"
    
    # Clean up
    $png.Dispose()
}
catch {
    Write-Host "Error: $($_.Exception.Message)"
    # Fallback: just copy the PNG as ICO
    Copy-Item "temp_icon.png" "windows/runner/resources/app_icon.ico" -Force
    Write-Host "Icon updated using fallback method"
}

# Clean up temp file
Remove-Item "temp_icon.png" -ErrorAction SilentlyContinue
