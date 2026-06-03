Add-Type -AssemblyName System.Drawing

$size = 128
$bmp = New-Object System.Drawing.Bitmap($size, $size)

# Colors
$bgColor = [System.Drawing.Color]::FromArgb(255, 30, 32, 44)        # dark navy
$borderColor = [System.Drawing.Color]::FromArgb(255, 80, 84, 110)   # subtle frame
$textColor = [System.Drawing.Color]::FromArgb(255, 240, 240, 240)   # near-white
$accentColor = [System.Drawing.Color]::FromArgb(255, 255, 200, 90)  # gold brackets+colons

# Fill background
for ($y = 0; $y -lt $size; $y++) {
    for ($x = 0; $x -lt $size; $x++) {
        $bmp.SetPixel($x, $y, $bgColor)
    }
}

# Draw 2px border frame
for ($i = 0; $i -lt $size; $i++) {
    $bmp.SetPixel($i, 0, $borderColor)
    $bmp.SetPixel($i, 1, $borderColor)
    $bmp.SetPixel($i, $size - 1, $borderColor)
    $bmp.SetPixel($i, $size - 2, $borderColor)
    $bmp.SetPixel(0, $i, $borderColor)
    $bmp.SetPixel(1, $i, $borderColor)
    $bmp.SetPixel($size - 1, $i, $borderColor)
    $bmp.SetPixel($size - 2, $i, $borderColor)
}

# Pixel font glyphs (7 rows tall). '1' = pixel on, '0' = off.
# Widths vary per char.
$font = @{
    '[' = @('11','10','10','10','10','10','11')
    ']' = @('11','01','01','01','01','01','11')
    'H' = @('10001','10001','10001','11111','10001','10001','10001')
    ':' = @('0','0','1','0','0','1','0')
    'm' = @('00000','00000','11010','10101','10101','10101','10101')
    's' = @('00000','00000','01111','10000','01110','00001','11110')
}

# Color per char (accent for brackets/colons)
$colorFor = @{
    '[' = $accentColor
    ']' = $accentColor
    ':' = $accentColor
    'H' = $textColor
    'm' = $textColor
    's' = $textColor
}

$text = "[HH:mm:ss]"
$scale = 2
$gap = 1 * $scale

# Compute total width
$totalW = 0
$charsArr = $text.ToCharArray()
for ($i = 0; $i -lt $charsArr.Length; $i++) {
    $ch = [string]$charsArr[$i]
    $glyph = $font[$ch]
    $w = $glyph[0].Length * $scale
    $totalW += $w
    if ($i -lt $charsArr.Length - 1) { $totalW += $gap }
}

$textHeight = 7 * $scale
$startX = [int](($size - $totalW) / 2)
$startY = [int](($size - $textHeight) / 2)

# Draw text
$cursorX = $startX
foreach ($chr in $charsArr) {
    $ch = [string]$chr
    $glyph = $font[$ch]
    $color = $colorFor[$ch]
    $glyphW = $glyph[0].Length

    for ($row = 0; $row -lt 7; $row++) {
        $rowStr = $glyph[$row]
        for ($col = 0; $col -lt $glyphW; $col++) {
            if ($rowStr[$col] -eq '1') {
                # Scale up pixel
                for ($dy = 0; $dy -lt $scale; $dy++) {
                    for ($dx = 0; $dx -lt $scale; $dx++) {
                        $px = $cursorX + ($col * $scale) + $dx
                        $py = $startY + ($row * $scale) + $dy
                        $bmp.SetPixel($px, $py, $color)
                    }
                }
            }
        }
    }
    $cursorX += $glyphW * $scale + $gap
}

# Decorative clock-tick marks at corners
$tickColor = $accentColor
# top-left corner inner ticks
$bmp.SetPixel(8, 8, $tickColor)
$bmp.SetPixel(9, 8, $tickColor)
$bmp.SetPixel(8, 9, $tickColor)
# top-right
$bmp.SetPixel($size - 9, 8, $tickColor)
$bmp.SetPixel($size - 10, 8, $tickColor)
$bmp.SetPixel($size - 9, 9, $tickColor)
# bottom-left
$bmp.SetPixel(8, $size - 9, $tickColor)
$bmp.SetPixel(9, $size - 9, $tickColor)
$bmp.SetPixel(8, $size - 10, $tickColor)
# bottom-right
$bmp.SetPixel($size - 9, $size - 9, $tickColor)
$bmp.SetPixel($size - 10, $size - 9, $tickColor)
$bmp.SetPixel($size - 9, $size - 10, $tickColor)

# Save
$outPath = Join-Path $PSScriptRoot "src\main\resources\assets\whenchat\icon.png"
$outDir = Split-Path $outPath -Parent
if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}
$bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
Write-Output "Saved: $outPath"
