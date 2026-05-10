param(
  [switch]$BuildApk,
  [switch]$Release
)

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Split-Path -Parent $scriptDir
$envFile = Join-Path $root ".env"
$flutter = "E:\flutter\bin\flutter.bat"

if (-not (Test-Path $flutter)) {
  $flutter = "flutter"
}

if (Test-Path $envFile) {
  Get-Content $envFile | ForEach-Object {
    $line = $_.Trim()
    if ($line.Length -eq 0 -or $line.StartsWith("#") -or -not $line.Contains("=")) {
      return
    }
    $parts = $line.Split("=", 2)
    $name = $parts[0].Trim()
    $value = $parts[1].Trim().Trim('"').Trim("'")
    if ($name.Length -gt 0) {
      Set-Item -Path "Env:$name" -Value $value
    }
  }
}

$defineNames = @(
  "SUPABASE_URL",
  "SUPABASE_API_KEY",
  "GROQ_API_KEY",
  "GROQ_PROXY_ENDPOINT",
  "DEEPGRAM_API_KEY",
  "DEEPGRAM_TTS_MODEL",
  "MAPTILER_KEY",
  "DATA_GOV_API_KEY"
)

$defines = @()
foreach ($name in $defineNames) {
  $value = [Environment]::GetEnvironmentVariable($name)
  if (-not [string]::IsNullOrWhiteSpace($value)) {
    $defines += "--dart-define=$name=$value"
  }
}

Push-Location $root
try {
  if ($BuildApk) {
    $mode = if ($Release) { "--release" } else { "--debug" }
    & $flutter build apk $mode @defines
  } else {
    & $flutter run @defines
  }
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }
} finally {
  Pop-Location
}
