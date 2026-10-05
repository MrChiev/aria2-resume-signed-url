<#
Pre-sizes the target file BEFORE you generate a signed URL.

Why: with --file-allocation=none, aria2's parallel connections write at far
offsets and NTFS zero-fills everything before them. The disk hits 100% and the
download stalls at DL:0B, often long enough for a 5-minute signed URL to expire.
Doing the zero-fill first (no URL needed) avoids that.

Usage:
  .\prealloc.ps1 -Path "C:\Users\you\Downloads\Server\bigfile.tar.gz" -Size 53027644164

Size = the number after the "/" in the "Content-Range: bytes 0-0/<size>" line
printed by the Range test in download.bat.
#>
param(
    [Parameter(Mandatory=$true)][string]$Path,
    [Parameter(Mandatory=$true)][long]$Size
)

$dir = Split-Path $Path -Parent
if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }

if ((Test-Path $Path) -and ((Get-Item $Path).Length -ge $Size)) {
    Write-Host "File is already $Size bytes or larger. Nothing to do." -ForegroundColor Yellow
    return
}

$fs = [System.IO.File]::Open($Path, 'OpenOrCreate', 'ReadWrite', 'None')
try {
    $fs.SetLength($Size)
    $null = $fs.Seek($Size - 1, 'Begin')
    $fs.WriteByte(0)
} finally {
    $fs.Close()
}
Write-Host "Done. $Path is now $Size bytes." -ForegroundColor Green
