
Add-Type -AssemblyName System.Drawing

$maxWidth = 1600
$maxHeight = 1600
$quality = 80

$imageFiles = Get-ChildItem -Path "assets\img\gallery" -Include "*.jpg", "*.jpeg", "*.png" -Recurse

foreach ($file in $imageFiles) {
    if ($file.Length -gt 500000) {
        # Only process files larger than 500KB
        Write-Host "Processing $($file.Name)..."
        try {
            $img = [System.Drawing.Image]::FromFile($file.FullName)
            
            # Calculate new dimensions
            $newWidth = $img.Width
            $newHeight = $img.Height
            
            if ($img.Width -gt $maxWidth -or $img.Height -gt $maxHeight) {
                $ratioX = $maxWidth / $img.Width
                $ratioY = $maxHeight / $img.Height
                $ratio = [Math]::Min($ratioX, $ratioY)
                
                $newWidth = [int]($img.Width * $ratio)
                $newHeight = [int]($img.Height * $ratio)
            }
            
            $newImg = new-object System.Drawing.Bitmap $newWidth, $newHeight
            $graph = [System.Drawing.Graphics]::FromImage($newImg)
            $graph.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $graph.DrawImage($img, 0, 0, $newWidth, $newHeight)
            
            $img.Dispose() # Release file handle
            
            # Save logic for JPEG
            $codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/jpeg" }
            $encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
            $encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, $quality)
            
            # Save to temporary file
            $tempPath = $file.FullName + ".tmp"
            $newImg.Save($tempPath, $codec, $encoderParams)
            
            $newImg.Dispose()
            $graph.Dispose()
            
            # Replace original
            Move-Item -Path $tempPath -Destination $file.FullName -Force
            Write-Host "Resized $($file.Name)"
        }
        catch {
            Write-Host "Error processing $($file.Name): $_"
            if ($img) { $img.Dispose() }
        }
    }
}
Write-Host "Image optimization complete."
