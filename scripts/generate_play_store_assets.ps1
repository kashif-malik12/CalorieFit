$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$brandingDir = Join-Path $root 'assets\branding'
$outputDir = Join-Path $root 'output\play_store'

function Ensure-Directory {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path | Out-Null
    }
}

function New-RoundedRectPath {
    param(
        [System.Drawing.RectangleF]$Rect,
        [float]$Radius
    )

    $diameter = $Radius * 2
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $path.AddArc($Rect.X, $Rect.Y, $diameter, $diameter, 180, 90)
    $path.AddArc($Rect.Right - $diameter, $Rect.Y, $diameter, $diameter, 270, 90)
    $path.AddArc($Rect.Right - $diameter, $Rect.Bottom - $diameter, $diameter, $diameter, 0, 90)
    $path.AddArc($Rect.X, $Rect.Bottom - $diameter, $diameter, $diameter, 90, 90)
    $path.CloseFigure()
    return $path
}

function Draw-CoverImage {
    param(
        [System.Drawing.Graphics]$Graphics,
        [System.Drawing.Image]$Image,
        [System.Drawing.RectangleF]$Bounds
    )

    $srcRatio = $Image.Width / $Image.Height
    $dstRatio = $Bounds.Width / $Bounds.Height

    if ($srcRatio -gt $dstRatio) {
        $scaledHeight = $Bounds.Height
        $scaledWidth = $scaledHeight * $srcRatio
        $x = $Bounds.X - (($scaledWidth - $Bounds.Width) / 2)
        $y = $Bounds.Y
    } else {
        $scaledWidth = $Bounds.Width
        $scaledHeight = $scaledWidth / $srcRatio
        $x = $Bounds.X
        $y = $Bounds.Y - (($scaledHeight - $Bounds.Height) / 2)
    }

    $Graphics.DrawImage($Image, $x, $y, $scaledWidth, $scaledHeight)
}

Ensure-Directory $outputDir

$markPath = Join-Path $brandingDir 'caloriefit_mark.png'
$logoPath = Join-Path $brandingDir 'caloriefit_logo.png'
$splashPath = Join-Path $brandingDir 'caloriefit_splash.png'

$mark = [System.Drawing.Image]::FromFile($markPath)
$logo = [System.Drawing.Image]::FromFile($logoPath)
$splash = [System.Drawing.Image]::FromFile($splashPath)

$iconOut = Join-Path $outputDir 'play-icon-512.png'
$featureOut = Join-Path $outputDir 'feature-graphic-1024x500.png'

$iconBitmap = New-Object System.Drawing.Bitmap(512, 512)
$iconGraphics = [System.Drawing.Graphics]::FromImage($iconBitmap)
$iconGraphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$iconGraphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$iconGraphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$iconGraphics.Clear([System.Drawing.Color]::White)
$iconGraphics.DrawImage($mark, 0, 0, 512, 512)
$iconBitmap.Save($iconOut, [System.Drawing.Imaging.ImageFormat]::Png)
$iconGraphics.Dispose()
$iconBitmap.Dispose()

$width = 1024
$height = 500
$featureBitmap = New-Object System.Drawing.Bitmap($width, $height)
$g = [System.Drawing.Graphics]::FromImage($featureBitmap)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

$bgRect = [System.Drawing.RectangleF]::new(0, 0, $width, $height)
$bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    $bgRect,
    [System.Drawing.ColorTranslator]::FromHtml('#0B3C49'),
    [System.Drawing.ColorTranslator]::FromHtml('#3AC47D'),
    18.0
)
$g.FillRectangle($bgBrush, $bgRect)

$shapeBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(26, 255, 255, 255))
$g.FillEllipse($shapeBrush, -60, -110, 360, 360)
$g.FillEllipse($shapeBrush, 770, 180, 300, 300)

$phoneShadowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(45, 7, 30, 38))
$phoneRect = [System.Drawing.RectangleF]::new(710, 54, 230, 392)
$phoneShadowRect = [System.Drawing.RectangleF]::new($phoneRect.X + 10, $phoneRect.Y + 14, $phoneRect.Width, $phoneRect.Height)
$phoneShadowPath = New-RoundedRectPath -Rect $phoneShadowRect -Radius 34
$g.FillPath($phoneShadowBrush, $phoneShadowPath)

$phoneBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(245, 255, 255, 255))
$phonePath = New-RoundedRectPath -Rect $phoneRect -Radius 34
$g.FillPath($phoneBrush, $phonePath)

$screenRect = [System.Drawing.RectangleF]::new(726, 74, 198, 352)
$screenPath = New-RoundedRectPath -Rect $screenRect -Radius 26
$clipState = $g.Save()
$g.SetClip($screenPath)
Draw-CoverImage -Graphics $g -Image $splash -Bounds $screenRect
$g.Restore($clipState)

$notchBrush = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml('#0B3C49'))
$notchRect = [System.Drawing.RectangleF]::new(784, 82, 80, 14)
$notchPath = New-RoundedRectPath -Rect $notchRect -Radius 7
$g.FillPath($notchBrush, $notchPath)

$headlineFont = New-Object System.Drawing.Font('Segoe UI', 46, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
$subFont = New-Object System.Drawing.Font('Segoe UI', 22, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
$chipFont = New-Object System.Drawing.Font('Segoe UI', 18, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
$whiteBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
$mutedBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(232, 242, 248, 250))
$accentChipBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(34, 255, 255, 255))

$g.DrawImage($logo, 72, 62, 420, 112)
$g.DrawString('Local-first calorie tracking', $headlineFont, $whiteBrush, 76, 190)
$g.DrawString('Track meals, macros, custom foods, and history with a clean offline-first journal.', $subFont, $mutedBrush, [System.Drawing.RectangleF]::new(78, 258, 560, 70))

$chip1 = [System.Drawing.RectangleF]::new(78, 350, 164, 44)
$chip2 = [System.Drawing.RectangleF]::new(256, 350, 186, 44)
$chip3 = [System.Drawing.RectangleF]::new(456, 350, 152, 44)

foreach ($chip in @($chip1, $chip2, $chip3)) {
    $chipPath = New-RoundedRectPath -Rect $chip -Radius 20
    $g.FillPath($accentChipBrush, $chipPath)
    $chipPath.Dispose()
}

$g.DrawString('Meal logging', $chipFont, $whiteBrush, 104, 360)
$g.DrawString('Macro targets', $chipFont, $whiteBrush, 283, 360)
$g.DrawString('Food search', $chipFont, $whiteBrush, 486, 360)

$markGlowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(22, 255, 255, 255))
$g.FillEllipse($markGlowBrush, 542, 42, 120, 120)
$g.DrawImage($mark, 564, 64, 76, 76)

$featureBitmap.Save($featureOut, [System.Drawing.Imaging.ImageFormat]::Png)

$markGlowBrush.Dispose()
$accentChipBrush.Dispose()
$mutedBrush.Dispose()
$whiteBrush.Dispose()
$chipFont.Dispose()
$subFont.Dispose()
$headlineFont.Dispose()
$notchPath.Dispose()
$notchBrush.Dispose()
$screenPath.Dispose()
$phonePath.Dispose()
$phoneBrush.Dispose()
$phoneShadowPath.Dispose()
$phoneShadowBrush.Dispose()
$shapeBrush.Dispose()
$bgBrush.Dispose()
$g.Dispose()
$featureBitmap.Dispose()

$splash.Dispose()
$logo.Dispose()
$mark.Dispose()

Write-Host "Generated Play assets:"
Write-Host " - $iconOut"
Write-Host " - $featureOut"
