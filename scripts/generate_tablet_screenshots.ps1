$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$inputDir = Join-Path $root 'assets\branding\screenshots'
$out7Dir = Join-Path $inputDir 'tablet-7'
$out10Dir = Join-Path $inputDir 'tablet-10'
$logoPath = Join-Path $root 'assets\branding\caloriefit_logo.png'

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

function Draw-ContainImage {
    param(
        [System.Drawing.Graphics]$Graphics,
        [System.Drawing.Image]$Image,
        [System.Drawing.RectangleF]$Bounds
    )

    $srcRatio = $Image.Width / $Image.Height
    $dstRatio = $Bounds.Width / $Bounds.Height

    if ($srcRatio -gt $dstRatio) {
        $drawWidth = $Bounds.Width
        $drawHeight = $drawWidth / $srcRatio
        $x = $Bounds.X
        $y = $Bounds.Y + (($Bounds.Height - $drawHeight) / 2)
    } else {
        $drawHeight = $Bounds.Height
        $drawWidth = $drawHeight * $srcRatio
        $x = $Bounds.X + (($Bounds.Width - $drawWidth) / 2)
        $y = $Bounds.Y
    }

    $Graphics.DrawImage($Image, $x, $y, $drawWidth, $drawHeight)
}

function New-TabletComposite {
    param(
        [string]$InputPath,
        [string]$OutputPath,
        [int]$Width,
        [int]$Height,
        [string]$Headline
    )

    $source = [System.Drawing.Image]::FromFile($InputPath)
    $logo = [System.Drawing.Image]::FromFile($logoPath)

    $bmp = New-Object System.Drawing.Bitmap($Width, $Height)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

    $bgRect = [System.Drawing.RectangleF]::new(0, 0, $Width, $Height)
    $bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        $bgRect,
        [System.Drawing.ColorTranslator]::FromHtml('#ECF7F1'),
        [System.Drawing.ColorTranslator]::FromHtml('#DDF3E5'),
        90.0
    )
    $g.FillRectangle($bgBrush, $bgRect)

    $shapeBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(40, 11, 60, 73))
    $g.FillEllipse($shapeBrush, -120, -140, 520, 520)
    $g.FillEllipse($shapeBrush, $Width - 360, $Height - 300, 420, 420)

    $g.DrawImage($logo, 88, 74, 360, 96)

    $titleFont = New-Object System.Drawing.Font('Segoe UI', 44, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $subtitleFont = New-Object System.Drawing.Font('Segoe UI', 23, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
    $titleBrush = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml('#0B3C49'))
    $mutedBrush = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml('#40616A'))

    $g.DrawString($Headline, $titleFont, $titleBrush, 90, 190)
    $g.DrawString('Local-first calorie tracking with meals, macros, templates, and history.', $subtitleFont, $mutedBrush, [System.Drawing.RectangleF]::new(92, 250, $Width - 184, 44))

    $shadowBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(35, 15, 39, 46))
    $deviceRect = [System.Drawing.RectangleF]::new(190, 350, $Width - 380, $Height - 520)
    $shadowRect = [System.Drawing.RectangleF]::new($deviceRect.X + 14, $deviceRect.Y + 20, $deviceRect.Width, $deviceRect.Height)
    $shadowPath = New-RoundedRectPath -Rect $shadowRect -Radius 42
    $g.FillPath($shadowBrush, $shadowPath)

    $deviceBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(250, 255, 255, 255))
    $devicePath = New-RoundedRectPath -Rect $deviceRect -Radius 42
    $g.FillPath($deviceBrush, $devicePath)

    $screenRect = [System.Drawing.RectangleF]::new($deviceRect.X + 34, $deviceRect.Y + 34, $deviceRect.Width - 68, $deviceRect.Height - 68)
    $screenPath = New-RoundedRectPath -Rect $screenRect -Radius 22
    $clip = $g.Save()
    $g.SetClip($screenPath)
    $screenBgBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    $g.FillRectangle($screenBgBrush, $screenRect)
    Draw-ContainImage -Graphics $g -Image $source -Bounds $screenRect
    $g.Restore($clip)

    $cameraBrush = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml('#0B3C49'))
    $g.FillEllipse($cameraBrush, ($Width / 2) - 8, $deviceRect.Y + 12, 16, 16)

    $chipFont = New-Object System.Drawing.Font('Segoe UI', 18, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $chipBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(24, 11, 60, 73))
    $chipTextBrush = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml('#0B3C49'))

    $chipLabels = @('Track meals', 'Hit macros', 'Stay local')
    $chipX = 200
    foreach ($label in $chipLabels) {
        $size = $g.MeasureString($label, $chipFont)
        $chipRect = [System.Drawing.RectangleF]::new($chipX, $Height - 112, $size.Width + 34, 42)
        $chipPath = New-RoundedRectPath -Rect $chipRect -Radius 18
        $g.FillPath($chipBrush, $chipPath)
        $g.DrawString($label, $chipFont, $chipTextBrush, $chipRect.X + 17, $chipRect.Y + 9)
        $chipX += [int]($chipRect.Width + 14)
        $chipPath.Dispose()
    }

    Ensure-Directory (Split-Path -Parent $OutputPath)
    $bmp.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)

    $chipTextBrush.Dispose()
    $chipBrush.Dispose()
    $chipFont.Dispose()
    $cameraBrush.Dispose()
    $screenBgBrush.Dispose()
    $screenPath.Dispose()
    $deviceBrush.Dispose()
    $devicePath.Dispose()
    $shadowBrush.Dispose()
    $shadowPath.Dispose()
    $mutedBrush.Dispose()
    $titleBrush.Dispose()
    $subtitleFont.Dispose()
    $titleFont.Dispose()
    $shapeBrush.Dispose()
    $bgBrush.Dispose()
    $g.Dispose()
    $bmp.Dispose()
    $logo.Dispose()
    $source.Dispose()
}

Ensure-Directory $out7Dir
Ensure-Directory $out10Dir

$files = Get-ChildItem $inputDir -File | Where-Object { $_.Extension -match '^\.(png|jpe?g)$' } | Sort-Object Name
$index = 1
foreach ($file in $files) {
    $baseName = ('screen-{0:D2}' -f $index)
    New-TabletComposite -InputPath $file.FullName -OutputPath (Join-Path $out7Dir "$baseName-7inch.png") -Width 1600 -Height 2560 -Headline 'Built for focused daily logging'
    New-TabletComposite -InputPath $file.FullName -OutputPath (Join-Path $out10Dir "$baseName-10inch.png") -Width 1920 -Height 3072 -Headline 'Simple nutrition tracking on a larger screen'
    $index++
}

Write-Host "Generated tablet screenshots in:"
Write-Host " - $out7Dir"
Write-Host " - $out10Dir"
