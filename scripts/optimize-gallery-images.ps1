param(
  [string]$SourceDir = (Join-Path $PSScriptRoot "..\assets\gallery\2025-2026"),
  [int]$MaxLongEdge = 1600,
  [ValidateRange(1, 100)]
  [int]$Quality = 82
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

function Get-JpegEncoder {
  return [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() |
    Where-Object { $_.MimeType -eq "image/jpeg" } |
    Select-Object -First 1
}

function Set-Orientation {
  param(
    [Parameter(Mandatory = $true)]
    [System.Drawing.Image]$Image
  )

  $orientationId = 0x0112

  if (-not ($Image.PropertyIdList -contains $orientationId)) {
    return
  }

  $orientationValue = [BitConverter]::ToUInt16($Image.GetPropertyItem($orientationId).Value, 0)

  switch ($orientationValue) {
    2 { $Image.RotateFlip([System.Drawing.RotateFlipType]::RotateNoneFlipX) }
    3 { $Image.RotateFlip([System.Drawing.RotateFlipType]::Rotate180FlipNone) }
    4 { $Image.RotateFlip([System.Drawing.RotateFlipType]::Rotate180FlipX) }
    5 { $Image.RotateFlip([System.Drawing.RotateFlipType]::Rotate90FlipX) }
    6 { $Image.RotateFlip([System.Drawing.RotateFlipType]::Rotate90FlipNone) }
    7 { $Image.RotateFlip([System.Drawing.RotateFlipType]::Rotate270FlipX) }
    8 { $Image.RotateFlip([System.Drawing.RotateFlipType]::Rotate270FlipNone) }
  }

  try {
    $Image.RemovePropertyItem($orientationId)
  } catch {
  }
}

function Save-Jpeg {
  param(
    [Parameter(Mandatory = $true)]
    [System.Drawing.Image]$Image,
    [Parameter(Mandatory = $true)]
    [string]$DestinationPath,
    [Parameter(Mandatory = $true)]
    [int]$Quality,
    [Parameter(Mandatory = $true)]
    [System.Drawing.Imaging.ImageCodecInfo]$Encoder
  )

  $qualityEncoder = [System.Drawing.Imaging.Encoder]::Quality
  $encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
  $encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter($qualityEncoder, [long]$Quality)

  try {
    $Image.Save($DestinationPath, $Encoder, $encoderParams)
  } finally {
    $encoderParams.Dispose()
  }
}

function Resize-Image {
  param(
    [Parameter(Mandatory = $true)]
    [System.Drawing.Image]$SourceImage,
    [Parameter(Mandatory = $true)]
    [int]$MaxLongEdge
  )

  $longEdge = [Math]::Max($SourceImage.Width, $SourceImage.Height)

  if ($longEdge -le $MaxLongEdge) {
    return $null
  }

  $scale = $MaxLongEdge / [double]$longEdge
  $targetWidth = [Math]::Max(1, [int][Math]::Round($SourceImage.Width * $scale))
  $targetHeight = [Math]::Max(1, [int][Math]::Round($SourceImage.Height * $scale))

  $bitmap = New-Object System.Drawing.Bitmap($targetWidth, $targetHeight)
  $bitmap.SetResolution($SourceImage.HorizontalResolution, $SourceImage.VerticalResolution)

  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  try {
    $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

    $destinationRect = New-Object System.Drawing.Rectangle(0, 0, $targetWidth, $targetHeight)
    $graphics.DrawImage($SourceImage, $destinationRect, 0, 0, $SourceImage.Width, $SourceImage.Height, [System.Drawing.GraphicsUnit]::Pixel)
  } finally {
    $graphics.Dispose()
  }

  return $bitmap
}

$resolvedSourceDir = Resolve-Path $SourceDir
$jpegEncoder = Get-JpegEncoder

if (-not $jpegEncoder) {
  throw "JPEG encoder not found."
}

$results = foreach ($file in Get-ChildItem -Path $resolvedSourceDir -Filter *.jpg | Sort-Object Name) {
  $sourceStream = [System.IO.File]::OpenRead($file.FullName)
  try {
    $loadedImage = [System.Drawing.Image]::FromStream($sourceStream, $false, $false)
    $sourceImage = New-Object System.Drawing.Bitmap($loadedImage)
    $loadedImage.Dispose()
  } finally {
    $sourceStream.Dispose()
  }

  try {
    Set-Orientation -Image $sourceImage

    $outputImage = Resize-Image -SourceImage $sourceImage -MaxLongEdge $MaxLongEdge
    $imageToSave = if ($outputImage) { $outputImage } else { $sourceImage }

    $width = $imageToSave.Width
    $height = $imageToSave.Height
    $tempPath = [System.IO.Path]::Combine($file.DirectoryName, [System.IO.Path]::GetRandomFileName() + ".jpg")
    $oldSizeBytes = $file.Length

    try {
      Save-Jpeg -Image $imageToSave -DestinationPath $tempPath -Quality $Quality -Encoder $jpegEncoder
      if (Test-Path $file.FullName) {
        Remove-Item $file.FullName -Force
      }
      [System.IO.File]::Move($tempPath, $file.FullName)
    } finally {
      if (Test-Path $tempPath) {
        Remove-Item $tempPath -Force
      }
      if ($outputImage) {
        $outputImage.Dispose()
      }
    }

    $updatedFile = Get-Item $file.FullName

    [PSCustomObject]@{
      Name = $file.Name
      Width = $width
      Height = $height
      OldSizeMB = [Math]::Round($oldSizeBytes / 1MB, 2)
      NewSizeMB = [Math]::Round($updatedFile.Length / 1MB, 2)
      SavedMB = [Math]::Round(($oldSizeBytes - $updatedFile.Length) / 1MB, 2)
    }
  } finally {
    $sourceImage.Dispose()
  }
}

$results | Format-Table -AutoSize

$oldTotal = ($results | Measure-Object -Property OldSizeMB -Sum).Sum
$newTotal = ($results | Measure-Object -Property NewSizeMB -Sum).Sum
$savedTotal = ($results | Measure-Object -Property SavedMB -Sum).Sum

Write-Host ""
Write-Host ("Total before: {0} MB" -f [Math]::Round($oldTotal, 2))
Write-Host ("Total after:  {0} MB" -f [Math]::Round($newTotal, 2))
Write-Host ("Saved:        {0} MB" -f [Math]::Round($savedTotal, 2))




