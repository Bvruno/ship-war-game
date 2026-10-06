# Ship War Game

Juego de guerra de barcos medieval pixel art multijugador LAN desarrollado en Godot 4.3.

## Características

- **Multijugador LAN P2P**: Un jugador crea la partida (host), otros se unen por IP
- **5 mapas marinos distintos** (en desarrollo)
- **Sistema de mejoras progresivas**:
  - 5 niveles de barco (HP + velocidad)
  - 5 niveles de armamento (daño + precisión + recarga)
  - 5 niveles de escudo (resistencia + recarga)
  - 5 niveles de radar (alcance de disparo)
- **Combate táctico**:
  - Disparos laterales con ángulos
  - Daño escalado por distancia (más cerca = más daño)
  - Escudo regenera tras 3s sin daño
  - Daño reducido proporcional a vida perdida
- **2 modos de juego**:
  - Libre: Undir barcos y sumar puntos
  - Torre: Controlar zona por tiempo
- **Efectos visuales**: Velas caen, fuego al recibir daño, explosión al morir
- **Controles táctiles**: Joysticks virtuales para movimiento y puntería
- **Minimapa**: Muestra posición de barcos enemigos
- **Bots**: IA básica para llenar partidas o practicar

## Controles

### Teclado (PC)
- **WASD**: Movimiento
- **Mouse**: Apuntar
- **Espacio**: Disparar

### Táctil (Android)
- **Joystick izquierdo**: Movimiento
- **Joystick derecho**: Apuntar
- **Botón FIRE**: Disparar

## Requisitos

- **Godot 4.3** o superior
- Para Android: Configurar export template

## Cómo jugar

### En PC (para testing)

1. Abrir proyecto en Godot 4.3
2. Ejecutar (F5) - se abre menú principal
3. Escribir nickname
4. Para host:
   - Click "Create Game (Host)"
   - Anotar IP mostrada
5. Para cliente (en otra ventana):
   - Click "Join Game (Client)"
   - Ingresar IP del host
   - Click botón

### Exportar a Android

1. En Godot: Project > Export
2. Agregar preset Android
3. Configurar keystore (debug o release)
4. Export Project > .apk
5. Instalar en dispositivos Android en misma red WiFi

## Estructura del proyecto

```
ship-war-game/
├── scenes/
│   ├── main_menu/       # Menú principal
│   ├── game/            # Escenas de juego (ship, projectile, world)
│   └── ui/              # HUD, upgrade menu, touch controls
├── scripts/
│   ├── network/         # Multiplayer manager
│   ├── gameplay/        # Lógica de juego (ship, projectile, world)
│   ├── data/            # Balance y stats
│   └── ui/              # Scripts de UI
├── assets/
│   ├── sprites/         # Sprites pixel art
│   ├── sounds/          # SFX retro
│   └── fonts/
└── resources/           # Resources de Godot
```

## Desarrollo

### Fases completadas

- **Fase 1**: Prototipo core - estructura básica, sistema de barco, proyectiles, HUD, menú LAN
- **Fase 2**: Networking completo - sincronización P2P, upgrades visuales, efectos de daño, respawn con inmunidad

### Próximas fases

- **Fase 3**: Bots con IA básica
- **Fase 4**: 4 mapas adicionales + modo Torre
- **Fase 5**: Sonidos retro + polish visual
- **Fase 6**: Export Android + optimización

## Balance

Stats por nivel (1-5):

| Stat | Nivel 1 | Nivel 5 |
|------|---------|---------|
| HP | 100 | 300 |
| Velocidad | 80 | 140 |
| Daño arma | 10 | 34 |
| Precisión ángulo | 15° | 3° |
| Cooldown arma | 1.5s | 0.6s |
| Escudo max | 50 | 150 |
| Regen escudo | 10/s | 25/s |
| Alcance radar | 300px | 600px |

## Créditos

Desarrollado con Godot 4.3
Arte: Pixel art moderno (assets libres + procedural)
Sonidos: Retro style (jsfxr/bfxr)

## Licencia

MIT License
