# Guía de Exportación Android

## Requisitos Previos

### 1. Instalar Android Build Template
En Godot Editor:
- `Editor > Manage Export Templates`
- Descargar e instalar templates para tu versión de Godot

### 2. Configurar Java Development Kit (JDK)
- Descargar JDK 17 o superior: https://adoptium.net/
- Configurar variable de entorno `JAVA_HOME`
- En Godot: `Editor > Editor Settings > Export > Android > Java SDK Path`

### 3. Configurar Android SDK
- Descargar Android Studio: https://developer.android.com/studio
- Instalar SDK desde Android Studio
- En Godot: `Editor > Editor Settings > Export > Android > Android SDK Path`

## Generar Keystore

### Debug Keystore (para testing)
```bash
keytool -keyalg RSA -genkeypair -alias androiddebugkey -keypass android -storepass android -keystore debug.keystore -dname "CN=Android Debug,O=Android,C=US" -validity 9999
```

### Release Keystore (para distribución)
```bash
keytool -keyalg RSA -genkeypair -alias shipwar -keypass TU_PASSWORD -storepass TU_PASSWORD -keystore shipwar-release.keystore -dname "CN=Ship War,O=ShipWar,C=US" -validity 10000
```

**IMPORTANTE:** Guarda tu release keystore en lugar seguro. Si lo pierdes, no podrás actualizar tu app en Google Play.

## Configurar Export en Godot

### 1. Abrir Export Dialog
- `Project > Export`
- Agregar preset Android (ya configurado en `export_presets.cfg`)

### 2. Configurar Keystore
- Seleccionar preset Android
- En "Keystore":
  - Debug: seleccionar `debug.keystore`
  - Release: seleccionar `shipwar-release.keystore`
  - Ingresar contraseñas correspondientes

### 3. Configurar Identidad
- **Package Unique Name**: `com.shipwar.game` (o tu dominio)
- **Package Name**: `Ship War`
- **Version Code**: incrementar en cada actualización
- **Version Name**: versión visible (ej: "1.0.0")

### 4. Iconos (Opcional)
- Preparar iconos en diferentes tamaños:
  - Main: 192x192 px
  - Adaptive Foreground: 300x187 px
  - Adaptive Background: 300x187 px
  - Monochrome: 300x187 px

## Exportar APK

### Debug Build (para testing)
1. `Project > Export`
2. Seleccionar Android
3. Click "Export Project"
4. Guardar como `ShipWarGame-debug.apk`

### Release Build (para distribución)
1. `Project > Export`
2. Seleccionar Android
3. Click "Export Project" (con Release keystore configurado)
4. Guardar como `ShipWarGame.apk`

## Instalar en Dispositivo

### Método 1: USB Debugging
1. Activar "Opciones de desarrollador" en Android
2. Activar "Depuración USB"
3. Conectar dispositivo por USB
4. En terminal:
```bash
adb install ShipWarGame.apk
```

### Método 2: Transferencia Manual
1. Copiar APK al dispositivo (USB, email, cloud)
2. Abrir archivo APK en dispositivo
3. Permitir "Instalar desde fuentes desconocidas" si es necesario
4. Instalar

## Testing LAN en Android

1. Instalar APK en 2+ dispositivos Android
2. Conectar todos a la misma red WiFi
3. En dispositivo host:
   - Abrir app
   - Ingresar nickname
   - Seleccionar mapa y modo
   - Click "Create Game (Host)"
   - Anotar IP mostrada
4. En dispositivos clientes:
   - Abrir app
   - Ingresar nickname
   - Ingresar IP del host
   - Click "Join Game (Client)"

## Optimizaciones para Android

### Performance
- **Renderer**: OpenGL 3 (configurado en `project.godot`)
- **FPS Target**: 60 FPS
- **Touch Controls**: Optimizados para pantalla táctil

### Batería
- Reducir partículas si es necesario
- Ajustar frecuencia de actualización de red

### Red
- Solo requiere WiFi local
- No requiere conexión a internet
- Puerto UDP 7777 debe estar abierto en red local

## Troubleshooting

### Error: "No export template found"
- Instalar templates desde `Editor > Manage Export Templates`

### Error: "Keystore not found"
- Verificar rutas de keystore en configuración de export
- Regenerar keystore si es necesario

### Error: "ADB not found"
- Instalar Android SDK
- Configurar ruta en `Editor Settings > Export > Android`

### Juego no conecta en LAN
- Verificar que dispositivos estén en misma red WiFi
- Verificar que firewall no bloquee puerto 7777
- Verificar IP correcta del host

### Touch controls no funcionan
- Verificar que escena tenga TouchControls habilitado
- Probar en dispositivo real (no emulador)

## Publicación en Google Play

Para publicar en Google Play Store:
1. Crear cuenta de desarrollador ($25 USD)
2. Preparar assets:
   - Icono 512x512
   - Screenshots
   - Descripción
   - Categoría: Games > Action
3. Firmar APK con release keystore
4. Subir a Google Play Console
5. Completar formulario de contenido
6. Enviar para revisión

## Builds Adicionales

### Crear build automatizado (CI/CD)
```bash
# Exportar desde línea de comandos
godot --headless --export-release "Android" build/android/ShipWarGame.apk
```

### Versionado
Incrementar `version/code` en `export_presets.cfg` antes de cada release:
```ini
version/code=2  # incrementar en cada update
version/name="1.0.1"
```
