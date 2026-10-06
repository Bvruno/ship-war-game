# Guía Rápida para Exportar Ship War Game a Android

## Estado Actual

✅ Godot 4.6.3 instalado y funcionando
✅ Export templates descargados (1.2 GB)
✅ Android SDK instalado
✅ JDK 21 configurado
✅ Keystore de debug generado
✅ Proyecto validado sin errores de scripts

## Problema Actual

Godot no reconoce automáticamente los templates de Android instalados. Necesita instalación manual desde el editor.

## Pasos para Completar la Exportación

### Opción 1: Desde el Editor de Godot (Recomendado)

1. **Abrir el proyecto en Godot**
   ```
   El editor ya está abierto. Si no, ejecuta:
   C:\Users\bruno\Downloads\Godot_v4.6.3-stable_win64\Godot_v4.6.3-stable_win64.exe
   ```

2. **Verificar/Instalar Export Templates**
   - Menú: `Project > Manage Export Templates`
   - Si dice "Not installed", click en `Download and Install`
   - Espera a que termine (puede tomar varios minutos)

3. **Exportar a Android**
   - Menú: `Project > Export`
   - Selecciona preset "Android"
   - Click en `Export Project`
   - Guarda como: `build/ShipWarGame.apk`
   - Espera a que termine el proceso

4. **Verificar el APK**
   - El archivo debe estar en: `C:\Users\bruno\guerra-barcos\ship-war-game\build\ShipWarGame.apk`
   - Tamaño esperado: ~50-100 MB

### Opción 2: Usar el Script de Export

Una vez que los templates estén instalados correctamente:

```powershell
cd C:\Users\bruno\guerra-barcos\ship-war-game
.\export_android.ps1
```

## Instalar en Android

1. **Transferir el APK al dispositivo Android**
   - Copia vía USB, email, o cloud storage
   - O usa `adb install` si tienes ADB configurado

2. **Permitir instalación**
   - En Android: Settings > Security > Unknown Sources (permitir)
   - O: Settings > Apps > Special Access > Install unknown apps

3. **Instalar y jugar**
   - Abre el archivo APK
   - Click "Install"
   - Abre el juego desde el launcher

## Testing LAN

1. **Instalar en 2+ dispositivos Android**
2. **Conectar todos a la misma red WiFi**
3. **En dispositivo host:**
   - Abrir app
   - Ingresar nickname
   - Seleccionar mapa y modo
   - Click "Create Game (Host)"
   - Anotar IP mostrada
4. **En dispositivos clientes:**
   - Abrir app
   - Ingresar nickname
   - Ingresar IP del host
   - Click "Join Game (Client)"

## Troubleshooting

### "La plantilla de exportación de Android no esta instalada"
- Ve a `Project > Manage Export Templates`
- Click `Download and Install`
- Espera a que termine completamente

### "Cannot export project with preset Android"
- Verifica que el preset Android exista en `Project > Export`
- Verifica que Java SDK y Android SDK estén configurados en `Editor > Editor Settings > Export > Android`

### APK no se instala en Android
- Verifica que "Unknown Sources" esté habilitado
- Verifica que el APK no esté corrupto (debe ser > 10 MB)
- Intenta con otro dispositivo Android

### Juego no conecta en LAN
- Verifica que dispositivos estén en la misma red WiFi
- Verifica que el firewall no bloquee puerto 7777
- Verifica IP correcta del host

## Configuraciones Verificadas

- **Godot**: 4.6.3.stable
- **Templates**: Descargados en `C:\Users\bruno\AppData\Roaming\Godot\export_templates\4.6.3.stable`
- **Java JDK**: 21 en `C:\Program Files\Java\jdk-21`
- **Android SDK**: en `C:\Users\bruno\AppData\Local\Android\Sdk`
- **Build Tools**: 34.0.0
- **Keystore**: debug.keystore (password: android)

## Archivos Generados

- `export_android.ps1` - Script de exportación
- `debug.keystore` - Keystore de debug
- `export_presets.cfg` - Configuración de export Android

## Próximo Paso

**Completa la exportación desde el editor de Godot siguiendo los pasos de la Opción 1.**

Una vez que tengas el APK, ¡el juego está listo para probar en dispositivos Android!
