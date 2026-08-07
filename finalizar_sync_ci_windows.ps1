param(
    [switch]$Verify,
    [switch]$BuildOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ProjectRoot

function Resolve-WindowsFlutterTool {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $candidateNames = @(
        "$Name.bat",
        "$Name.cmd",
        "$Name.exe"
    )

    foreach ($candidateName in $candidateNames) {
        $command = Get-Command $candidateName -ErrorAction SilentlyContinue |
            Select-Object -First 1
        if ($null -ne $command -and $command.Source) {
            return $command.Source
        }
    }

    # Flutter suele estar instalado en una carpeta cuya entrada de PATH
    # apunta a un wrapper sin extensión. Buscar sus equivalentes Windows.
    $plain = Get-Command $Name -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if ($null -ne $plain -and $plain.Source) {
        foreach ($extension in @(".bat", ".cmd", ".exe")) {
            $withExtension = "$($plain.Source)$extension"
            if (Test-Path -LiteralPath $withExtension) {
                return (Resolve-Path -LiteralPath $withExtension).Path
            }
        }
    }

    # Ruta habitual detectada en esta instalación.
    foreach ($flutterRoot in @(
        $env:FLUTTER_ROOT,
        "D:\flutter"
    )) {
        if ([string]::IsNullOrWhiteSpace($flutterRoot)) {
            continue
        }
        foreach ($extension in @(".bat", ".cmd", ".exe")) {
            $candidate = Join-Path $flutterRoot "bin\$Name$extension"
            if (Test-Path -LiteralPath $candidate) {
                return (Resolve-Path -LiteralPath $candidate).Path
            }
        }
    }

    throw "No se encontró $Name.bat, $Name.cmd o $Name.exe."
}

function Invoke-Checked {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Executable,

        [Parameter(Mandatory = $true)]
        [string[]]$Arguments,

        [Parameter(Mandatory = $true)]
        [string]$Label
    )

    Write-Host ""
    Write-Host "== $Label ==" -ForegroundColor Cyan
    Write-Host "> `"$Executable`" $($Arguments -join ' ')" -ForegroundColor DarkGray

    & $Executable @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$Label terminó con código $LASTEXITCODE."
    }
}

function Assert-Contains {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Text,

        [Parameter(Mandatory = $true)]
        [string]$Description
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "No existe $Path."
    }

    $content = Get-Content -LiteralPath $Path -Raw
    if (-not $content.Contains($Text)) {
        throw "No se encontró '$Description' en $Path."
    }

    Write-Host "OK: $Description" -ForegroundColor Green
}

$Dart = Resolve-WindowsFlutterTool -Name "dart"
$Flutter = Resolve-WindowsFlutterTool -Name "flutter"

Write-Host "Proyecto: $ProjectRoot"
Write-Host "Dart Windows: $Dart"
Write-Host "Flutter Windows: $Flutter"

# Verificar que las correcciones de sincronización ya están presentes.
Assert-Contains `
    -Path "lib\core\database\app_database.dart" `
    -Text "_migrarIdentidadSincronizacionUnidadesV27" `
    -Description "migración SQLite V27 registrada"

Assert-Contains `
    -Path "lib\features\sync\data\mappers\sync_entity_registry.dart" `
    -Text "_applyRemoteMeasurementUnit" `
    -Description "reconciliación de unidades"

Assert-Contains `
    -Path "lib\features\sync\data\mappers\sync_entity_registry.dart" `
    -Text "_mergeRemoteRelationalMasterByNaturalKey" `
    -Description "reconciliación de maestros relacionales"

Assert-Contains `
    -Path "lib\features\sync\data\repositories\sync_repository_impl.dart" `
    -Text "LOCAL_SYNC_APPLY_FAILED" `
    -Description "mensaje técnico de sincronización"

if (-not $BuildOnly) {
    Invoke-Checked `
        -Executable $Dart `
        -Arguments @("format", "lib", "test") `
        -Label "Aplicar formato Dart"

    Invoke-Checked `
        -Executable $Dart `
        -Arguments @(
            "format",
            "--output=none",
            "--set-exit-if-changed",
            "lib",
            "test"
        ) `
        -Label "Verificar el mismo formato de GitHub CI"

    Invoke-Checked `
        -Executable "git.exe" `
        -Arguments @("diff", "--check") `
        -Label "Verificar espacios y conflictos de diff"

    Write-Host ""
    Write-Host "Archivos pendientes:" -ForegroundColor Cyan
    & git.exe status --short
    if ($LASTEXITCODE -ne 0) {
        throw "git status terminó con código $LASTEXITCODE."
    }
}

if ($Verify) {
    Invoke-Checked `
        -Executable $Flutter `
        -Arguments @("pub", "get") `
        -Label "Resolver dependencias"

    Invoke-Checked `
        -Executable $Dart `
        -Arguments @("analyze", "--no-fatal-warnings") `
        -Label "Analizar proyecto"

    Invoke-Checked `
        -Executable $Flutter `
        -Arguments @(
            "test",
            "--no-pub",
            "--exclude-tags",
            "baseline-known-failure"
        ) `
        -Label "Ejecutar el gate de pruebas de CI"

    Invoke-Checked `
        -Executable $Flutter `
        -Arguments @(
            "build",
            "apk",
            "--debug",
            "--no-pub"
        ) `
        -Label "Construir APK debug"
}

Write-Host ""
Write-Host "FINALIZACIÓN CORRECTA" -ForegroundColor Green
Write-Host ""
Write-Host "Para publicar:"
Write-Host '  git add lib'
Write-Host '  git commit -m "fix(sync): reconcile remote master identities"'
Write-Host '  git push origin main'
Write-Host ""
Write-Host "Para construir y verificar todo:"
Write-Host "  .\finalizar_sync_ci_windows.ps1 -Verify"
