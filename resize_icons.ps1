Add-Type -AssemblyName System.Drawing

$logoPath = "c:\Users\psks1\OneDrive\Desktop\Android Apps\Veena\assets\images\app_logo.png"
$resDir = "c:\Users\psks1\OneDrive\Desktop\Android Apps\Veena\android\app\src\main\res"
$iosDir = "c:\Users\psks1\OneDrive\Desktop\Android Apps\Veena\ios\Runner\Assets.xcassets"
$webDir = "c:\Users\psks1\OneDrive\Desktop\Android Apps\Veena\web"

function Resize-Image {
    param(
        [string]$SourcePath,
        [string]$DestPath,
        [int]$Width,
        [int]$Height
    )
    $src = [System.Drawing.Image]::FromFile($SourcePath)
    $bmp = New-Object System.Drawing.Bitmap($Width, $Height)
    $graphics = [System.Drawing.Graphics]::FromImage($bmp)
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $graphics.DrawImage($src, 0, 0, $Width, $Height)
    $bmp.Save($DestPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $graphics.Dispose()
    $bmp.Dispose()
    $src.Dispose()
    Write-Host "Created ${Width}x${Height}: $DestPath"
}

Write-Host "========================================="
Write-Host "  ANDROID LAUNCHER ICONS (mipmap)"
Write-Host "========================================="

$androidIcons = @{
    "mdpi"    = 48
    "hdpi"    = 72
    "xhdpi"   = 96
    "xxhdpi"  = 144
    "xxxhdpi" = 192
}

foreach ($density in $androidIcons.Keys) {
    $size = $androidIcons[$density]
    $dir = "$resDir\mipmap-$density"
    if (Test-Path "$dir\ic_launcher.png") {
        Resize-Image -SourcePath $logoPath -DestPath "$dir\ic_launcher.png" -Width $size -Height $size
    }
    if (Test-Path "$dir\launcher_icon.png") {
        Resize-Image -SourcePath $logoPath -DestPath "$dir\launcher_icon.png" -Width $size -Height $size
    }
}

Write-Host ""
Write-Host "========================================="
Write-Host "  ANDROID SPLASH IMAGES (drawable)"
Write-Host "========================================="

$splashSizes = @{
    "mdpi"    = 288
    "hdpi"    = 432
    "xhdpi"   = 576
    "xxhdpi"  = 768
    "xxxhdpi" = 1152
}

foreach ($density in $splashSizes.Keys) {
    $size = $splashSizes[$density]
    
    # Day mode
    $dayDir = "$resDir\drawable-$density"
    if (Test-Path "$dayDir\splash.png") {
        Resize-Image -SourcePath $logoPath -DestPath "$dayDir\splash.png" -Width $size -Height $size
    }
    if (Test-Path "$dayDir\android12splash.png") {
        Resize-Image -SourcePath $logoPath -DestPath "$dayDir\android12splash.png" -Width $size -Height $size
    }
    if (Test-Path "$dayDir\branding.png") {
        Resize-Image -SourcePath $logoPath -DestPath "$dayDir\branding.png" -Width ([int]($size * 0.4)) -Height ([int]($size * 0.12))
    }

    # Night mode
    $nightDir = "$resDir\drawable-night-$density"
    if (Test-Path "$nightDir\splash.png") {
        Resize-Image -SourcePath $logoPath -DestPath "$nightDir\splash.png" -Width $size -Height $size
    }
    if (Test-Path "$nightDir\android12splash.png") {
        Resize-Image -SourcePath $logoPath -DestPath "$nightDir\android12splash.png" -Width $size -Height $size
    }
    if (Test-Path "$nightDir\branding.png") {
        Resize-Image -SourcePath $logoPath -DestPath "$nightDir\branding.png" -Width ([int]($size * 0.4)) -Height ([int]($size * 0.12))
    }
}

Write-Host ""
Write-Host "========================================="
Write-Host "  iOS APP ICONS"
Write-Host "========================================="

$iosIcons = @(
    @{ Name = "Icon-App-1024x1024@1x.png"; Size = 1024 }
    @{ Name = "Icon-App-20x20@1x.png"; Size = 20 }
    @{ Name = "Icon-App-20x20@2x.png"; Size = 40 }
    @{ Name = "Icon-App-20x20@3x.png"; Size = 60 }
    @{ Name = "Icon-App-29x29@1x.png"; Size = 29 }
    @{ Name = "Icon-App-29x29@2x.png"; Size = 58 }
    @{ Name = "Icon-App-29x29@3x.png"; Size = 87 }
    @{ Name = "Icon-App-40x40@1x.png"; Size = 40 }
    @{ Name = "Icon-App-40x40@2x.png"; Size = 80 }
    @{ Name = "Icon-App-40x40@3x.png"; Size = 120 }
    @{ Name = "Icon-App-50x50@1x.png"; Size = 50 }
    @{ Name = "Icon-App-50x50@2x.png"; Size = 100 }
    @{ Name = "Icon-App-57x57@1x.png"; Size = 57 }
    @{ Name = "Icon-App-57x57@2x.png"; Size = 114 }
    @{ Name = "Icon-App-60x60@2x.png"; Size = 120 }
    @{ Name = "Icon-App-60x60@3x.png"; Size = 180 }
    @{ Name = "Icon-App-72x72@1x.png"; Size = 72 }
    @{ Name = "Icon-App-72x72@2x.png"; Size = 144 }
    @{ Name = "Icon-App-76x76@1x.png"; Size = 76 }
    @{ Name = "Icon-App-76x76@2x.png"; Size = 152 }
    @{ Name = "Icon-App-83.5x83.5@2x.png"; Size = 167 }
)

$appIconDir = "$iosDir\AppIcon.appiconset"
foreach ($icon in $iosIcons) {
    $dest = "$appIconDir\$($icon.Name)"
    if (Test-Path $dest) {
        Resize-Image -SourcePath $logoPath -DestPath $dest -Width $icon.Size -Height $icon.Size
    }
}

Write-Host ""
Write-Host "========================================="
Write-Host "  iOS LAUNCH + BRANDING IMAGES"
Write-Host "========================================="

$launchImageDir = "$iosDir\LaunchImage.imageset"
$launchImages = @(
    @{ Name = "LaunchImage.png"; Size = 288 }
    @{ Name = "LaunchImage@2x.png"; Size = 576 }
    @{ Name = "LaunchImage@3x.png"; Size = 864 }
    @{ Name = "LaunchImageDark.png"; Size = 288 }
    @{ Name = "LaunchImageDark@2x.png"; Size = 576 }
    @{ Name = "LaunchImageDark@3x.png"; Size = 864 }
)

foreach ($img in $launchImages) {
    $dest = "$launchImageDir\$($img.Name)"
    if (Test-Path $dest) {
        Resize-Image -SourcePath $logoPath -DestPath $dest -Width $img.Size -Height $img.Size
    }
}

$brandingDir = "$iosDir\BrandingImage.imageset"
$brandingImages = @(
    @{ Name = "BrandingImage.png"; W = 114; H = 34 }
    @{ Name = "BrandingImage@2x.png"; W = 228; H = 68 }
    @{ Name = "BrandingImage@3x.png"; W = 342; H = 102 }
    @{ Name = "BrandingImageDark.png"; W = 114; H = 34 }
    @{ Name = "BrandingImageDark@2x.png"; W = 228; H = 68 }
    @{ Name = "BrandingImageDark@3x.png"; W = 342; H = 102 }
)

foreach ($img in $brandingImages) {
    $dest = "$brandingDir\$($img.Name)"
    if (Test-Path $dest) {
        Resize-Image -SourcePath $logoPath -DestPath $dest -Width $img.W -Height $img.H
    }
}

# iOS background images (solid dark)
$bgDir = "$iosDir\LaunchBackground.imageset"
if (Test-Path "$bgDir\background.png") {
    $bmp = New-Object System.Drawing.Bitmap(1, 1)
    $bmp.SetPixel(0, 0, [System.Drawing.Color]::FromArgb(255, 18, 18, 18))
    $bmp.Save("$bgDir\background.png", [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Host "Created 1x1 dark bg: background.png"
}
if (Test-Path "$bgDir\darkbackground.png") {
    $bmp = New-Object System.Drawing.Bitmap(1, 1)
    $bmp.SetPixel(0, 0, [System.Drawing.Color]::FromArgb(255, 18, 18, 18))
    $bmp.Save("$bgDir\darkbackground.png", [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Host "Created 1x1 dark bg: darkbackground.png"
}

Write-Host ""
Write-Host "========================================="
Write-Host "  WEB ICONS"
Write-Host "========================================="

$webIcons = @(
    @{ Name = "favicon.png"; Size = 32; Dir = $webDir }
    @{ Name = "Icon-192.png"; Size = 192; Dir = "$webDir\icons" }
    @{ Name = "Icon-512.png"; Size = 512; Dir = "$webDir\icons" }
    @{ Name = "Icon-maskable-192.png"; Size = 192; Dir = "$webDir\icons" }
    @{ Name = "Icon-maskable-512.png"; Size = 512; Dir = "$webDir\icons" }
    @{ Name = "app_logo.png"; Size = 512; Dir = "$webDir\icons" }
)

foreach ($icon in $webIcons) {
    $dest = "$($icon.Dir)\$($icon.Name)"
    if (Test-Path $dest) {
        Resize-Image -SourcePath $logoPath -DestPath $dest -Width $icon.Size -Height $icon.Size
    }
}

Write-Host ""
Write-Host "========================================="
Write-Host "  ALL DONE! Every icon resized."
Write-Host "========================================="
