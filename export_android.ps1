# Script para exportar Ship War Game a Android
# Ejecutar este script con PowerShell

$godot = "C:\Users\bruno\Downloads\Godot_v4.6.3-stable_win64\Godot_v4.6.3-stable_win64_console.exe"
$projectPath = "C:\Users\bruno\guerra-barcos\ship-war-game"
$outputPath = "$projectPath\build\ShipWarGame.apk"

# Configurar variables de entorno
$env:JAVA_HOME = "C:\Program Files\Java\jdk-21"
$env:ANDROID_HOME = "C:\Users\bruno\AppData\Local\Android\Sdk"
$env:ANDROID_SDK_ROOT = $env:ANDROID_HOME

Write-Host "==================================="
Write-Host "Exportando Ship War Game a Android"
Write-Host "==================================="
Write-Host ""
Write-Host "Godot: $godot"
Write-Host "Proyecto: $projectPath"
Write-Host "Output: $outputPath"
Write-Host "JAVA_HOME: $env:JAVA_HOME"
Write-Host "ANDROID_HOME: $env:ANDROID_HOME"
Write-Host ""

# Crear directorio de build si no existe
if (-not (Test-Path "$projectPath\build")) {
    New-Item -ItemType Directory -Force -Path "$projectPath\build" | Out-Null
}

Write-Host "Iniciando exportación..."
Write-Host ""

# Ejecutar exportación
& $godot --path $projectPath --export-release "Android" $outputPath --verbose 2>&1 | ForEach-Object {
    if ($_ -match "ERROR|error|Cannot|configuration|Success|Done|BUILD") {
        Write-Host $_ -ForegroundColor Yellow
    } elseif ($_ -match "100%|Packaging|Building") {
        Write-Host $_ -ForegroundColor Green
    } else {
        Write-Host $_
    }
}

# Verificar si el APK se creó
if (Test-Path $outputPath) {
    $apkSize = (Get-Item $outputPath).Length / 1MB
    Write-Host ""
    Write-Host "==================================="
    Write-Host "¡EXPORTACIÓN EXITOSA!" -ForegroundColor Green
    Write-Host "==================================="
    Write-Host "APK creado: $outputPath"
    Write-Host "Tamaño: $([math]::Round($apkSize, 2)) MB"
    Write-Host ""
    Write-Host "Para instalar en Android:"
    Write-Host "1. Copia el APK a tu dispositivo Android"
    Write-Host "2. Abre el archivo APK en el dispositivo"
    Write-Host "3. Permite instalación desde fuentes desconocidas si es necesario"
    Write-Host "4. Instala y disfruta el juego!"
} else {
    Write-Host ""
    Write-Host "==================================="
    Write-Host "EXPORTACIÓN FALLÓ" -ForegroundColor Red
    Write-Host "==================================="
    Write-Host "El APK no se creó. Revisa los errores arriba."
}
