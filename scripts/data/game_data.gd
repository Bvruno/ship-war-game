extends Node

# Game balance data - all stats by level (1-5)

# Ship level: HP and speed
const SHIP_HP: Array[float] = [100.0, 150.0, 200.0, 250.0, 300.0]
const SHIP_SPEED: Array[float] = [80.0, 95.0, 110.0, 125.0, 140.0]
const SHIP_FIRE_ANGLE: Array[float] = [20.0, 25.0, 30.0, 35.0, 40.0]

# Weapon level: damage, accuracy (aim angle), cooldown
const WEAPON_DAMAGE: Array[float] = [10.0, 16.0, 22.0, 28.0, 34.0]
const WEAPON_AIM_ANGLE: Array[float] = [15.0, 12.0, 9.0, 6.0, 3.0]
const WEAPON_COOLDOWN: Array[float] = [1.5, 1.25, 1.0, 0.8, 0.6]

# Shield level: max shield, regen rate (per second)
const SHIELD_MAX: Array[float] = [50.0, 75.0, 100.0, 125.0, 150.0]
const SHIELD_REGEN_RATE: Array[float] = [10.0, 15.0, 20.0, 22.5, 25.0]
const SHIELD_REGEN_DELAY: float = 3.0

# Radar level: projectile range
const RADAR_RANGE: Array[float] = [300.0, 375.0, 450.0, 525.0, 600.0]

# Damage multiplier by distance (closer = more damage)
const DAMAGE_DISTANCE_MIN: float = 50.0
const DAMAGE_DISTANCE_MAX: float = 500.0
const DAMAGE_CLOSE_MULTIPLIER: float = 1.5
const DAMAGE_FAR_MULTIPLIER: float = 0.7

# HP to damage ratio: current_hp / max_hp scales damage output
const MIN_DAMAGE_FACTOR: float = 0.5

# Upgrade points earned per damage dealt
const UPGRADE_POINTS_PER_DAMAGE: float = 100.0

# Respawn invincibility time (seconds)
const RESPAWN_INVINCIBLE_TIME: float = 2.0

# Max players per game
const MAX_PLAYERS: int = 6

# Game modes
enum GameMode { FREE_FOR_ALL, TOWER_DEFENSE }

# Map data
enum MapId { OPEN_SEA, ARCHIPELAGO, FJORD, VOLCANIC, STORM }

static func get_stat(array: Array, level: int) -> float:
	var idx: int = clampi(level - 1, 0, array.size() - 1)
	return array[idx]

static func get_damage_multiplier(current_hp: float, max_hp: float, distance: float) -> float:
	var hp_factor: float = maxf(MIN_DAMAGE_FACTOR, current_hp / maxf(max_hp, 1.0))
	var t: float = clampf(distance / DAMAGE_DISTANCE_MAX, 0.0, 1.0)
	var dist_factor: float = lerpf(DAMAGE_CLOSE_MULTIPLIER, DAMAGE_FAR_MULTIPLIER, t)
	return hp_factor * dist_factor
