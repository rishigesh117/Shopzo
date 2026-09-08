Add-Type -AssemblyName System.Drawing

$srcPath = "c:\project\Shopzo\assets\images\shopzo_app_icon.jpg"
$pngPath = "c:\project\Shopzo\assets\images\shopzo_app_icon.png"

$srcImage = [System.Drawing.Image]::FromFile($srcPath)
$bmp = New-Object System.Drawing.Bitmap($srcImage.Width, $srcImage.Height)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$g.DrawImage($srcImage, 0, 0, $srcImage.Width, $srcImage.Height)

$bmp.Save($pngPath, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose()
$bmp.Dispose()
$srcImage.Dispose()

Write-Host "Successfully converted $srcPath to PNG at $pngPath"
