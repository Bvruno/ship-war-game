# Ship War Game

Juego de guerra de barcos medieval pixel art multijugador LAN desarrollado en Godot 4.3.

## Características

- **Multijugador LAN P2P**: Un jugador crea la partida (host), otros se unen por IP
- **5 mapas marinos distintos**:
  - Open Sea: Mapa abierto básico
  - Archipelago: 7 islas dispersas
  - Fjord: Pasos estrechos entre acantilados
  - Volcanic: 3 volcanes con lava
  - Storm: Arrecifes en aguas tormentosas
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
  - Libre: Undir barcos y sumar puntos, respawn automático
  - Torre: Controlar zona central por 60 segundos para ganar
- **Bots con IA**:
  - Comportamiento adaptativo (patrullar, perseguir, atacar, huir)
  - Nivel escalado al promedio de jugadores
  - Agregar/quitar en tiempo real
- **Audio procedural**:
  - Sonidos retro generados (disparos, impactos, explosiones, mejoras)
  - Sistema de volumen independiente
- **Efectos visuales**:
  - Velas caen con daño
  - Fuego en barco cuando HP < 50%
  - Explosión de partículas al morir
  - Estela de agua al moverse
  - Flash rojo al recibir daño
  - Parpadeo de inmunidad en respawn
- **Controles táctiles**: Joysticks virtuales para movimiento y puntería
- **Minimapa**: Muestra posición de barcos (verde=local, azul=bots, rojo=enemigos)
- **Sistema de upgrades**: Menú visual para mejorar stats en tiempo real

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

### Para desarrollar
- **Godot 4.3** o superior

### Para exportar a Android
- Android Build Templates instalados
- JDK 17 o superior
- Android SDK
- Keystore (debug o release)

Ver [Guía de Exportación Android](docs/EXPORT_ANDROID.md) para instrucciones detalladas.

## Cómo jugar

### En PC (para testing)

1. Abrir proyecto en Godot 4.3
2. Ejecutar (F5) - se abre menú principal
3. Escribir nickname
4. Seleccionar mapa (Open Sea, Archipelago, Fjord, Volcanic, Storm)
5. Seleccionar modo (Free For All, Tower Defense)
6. Para host:
   - Click "Create Game (Host)"
   - Anotar IP mostrada
   - Opcionalmente agregar bots con "+ Bot"
7. Para cliente (en otra ventana):
   - Click "Join Game (Client)"
   - Ingresar IP del host
   - Click botón

### En Android

1. Exportar proyecto como APK (ver guía)
2. Instalar APK en 2+ dispositivos
3. Conectar todos a misma red WiFi
4. Host crea partida, clientes se unen con IP

## Estructura del proyecto

```
ship-war-game/
├── scenes/
│   ├── main_menu/       # Menú principal con selección de mapa/modo
│   ├── game/            # Escenas de juego (ship, projectile, world, tower)
│   ├── bots/            # Escena de bot con IA
│   ├── maps/            # 5 mapas distintos
│   ├── ui/              # HUD, upgrade menu, touch controls
│   └── effects/         # Partículas de agua
├── scripts/
│   ├── network/         # Multiplayer manager (P2P)
│   ├── gameplay/        # Lógica de juego (ship, projectile, world, bot_ai, tower_mode)
│   ├── data/            # Balance y stats del juego
│   ├── ui/              # Scripts de UI y controles táctiles
│   ├── audio/           # AudioManager con generación procedural
│   └── effects/         # Scripts de efectos visuales
├── assets/
│   ├── sprites/         # Sprites pixel art
│   ├── sounds/          # SFX retro (generados proceduralmente)
│   └── fonts/
├── docs/
│   └── EXPORT_ANDROID.md  # Guía completa de exportación Android
└── resources/           # Resources de Godot
```

## Desarrollo

### Fases completadas

- **Fase 1**: Prototipo core - estructura básica, sistema de barco, proyectiles, HUD, menú LAN
- **Fase 2**: Networking completo - sincronización P2P, upgrades visuales, efectos de daño, respawn con inmunidad
- **Fase 3**: Sistema de bots con IA (patrullar, perseguir, atacar, huir), spawn con nivel escalado
- **Fase 4**: 5 mapas distintos + modo Torre con zona de control
- **Fase 5**: Audio procedural (sonidos retro generados) + polish visual (water trail, mejoras de partículas)
- **Fase 6**: Configuración de export Android + documentación completa

### Arquitectura técnica

- **Networking**: MultiplayerSynchronizer + RPCs (ENet/UDP)
- **IA**: Máquina de estados (patrol, chase, attack, flee)
- **Audio**: AudioStreamGenerator para generación procedural
- **Física**: CharacterBody2D para barcos, Area2D para proyectiles
- **Renderizado**: gl_compatibility para máxima compatibilidad Android

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

### Fórmulas de daño

```
daño_final = daño_base * multiplicador_distancia * factor_hp

donde:
- multiplicador_distancia = 1.5 (muy cerca) → 0.7 (lejos)
- factor_hp = max(0.5, hp_actual / hp_max)
```

## Créditos

Desarrollado con Godot 4.3

### Tecnología
- **Engine**: Godot 4.3 (GDScript)
- **Networking**: High-level multiplayer API (ENet/UDP)
- **Audio**: Generación procedural con AudioStreamGenerator
- **IA**: Sistema de máquina de estados

### Assets
- **Arte**: Pixel art procedural (placeholders)
- **Sonidos**: Retro style generado proceduralmente
- **Fuentes**: Sistema por defecto de Godot

## Licencia

MIT License

## Contribuciones

Este es un proyecto de demostración. Para sugerencias o mejoras:
1. Crear issue en GitHub
2. Describir el problema o sugerencia
3. Adjuntar screenshots si es relevante

## Roadmap Futuro (Opcional)

- [ ] Sprites pixel art profesionales
- [ ] Más tipos de armas (cañones, morteros, torpedos)
- [ ] Power-ups en mapa (velocidad, daño, escudo temporal)
- [ ] Sistema de logros
- [ ] Rankings locales
- [ ] Más mapas (10+)
- [ ] Modo campaña con misiones
- [ ] Personalización de barco (colores, banderas)
- [ ] Chat de voz integrado
- [ ] Soporte para gamepads físicos
