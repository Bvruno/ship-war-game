extends CharacterBody2D
class_name Ship

signal hp_changed(current_hp: float, max_hp: float)
signal shield_changed(current_shield: float, max_shield: float)
signal ship_died(ship_id: int)
signal upgrade_points_earned(points: int)

@export var player_id: int = 0
@export var nickname: String = "Player"
@export var is_bot: bool = false

# Upgrade levels (1-5 each)
var ship_level: int = 1
var weapon_level: int = 1
var shield_level: int = 1
var radar_level: int = 1

# Runtime stats
var max_hp: float = 100.0
var current_hp: float = 100.0
var max_shield: float = 50.0
var current_shield: float = 50.0
var speed: float = 80.0
var fire_cooldown: float = 1.5
var fire_cooldown_timer: float = 0.0
var aim_angle: float = 15.0
var fire_angle: float = 20.0
var weapon_damage: float = 10.0
var projectile_range: float = 300.0
var shield_regen_rate: float = 10.0
var shield_regen_timer: float = 0.0
var is_invincible: bool = false
var invincible_timer: float = 0.0

# Aiming
var aim_direction: Vector2 = Vector2.RIGHT

# Upgrade points
var upgrade_points: int = 0
var damage_dealt: float = 0.0

# Score
var score: int = 0

# Movement input
var move_input: Vector2 = Vector2.ZERO

# Projectiles
var projectile_scene: PackedScene

func _ready() -> void:
	projectile_scene = preload("res://scenes/game/projectile.tscn")
	_recalculate_stats()
	current_hp = max_hp
	current_shield = max_shield

func _recalculate_stats() -> void:
	max_hp = GameData.get_stat(GameData.SHIP_HP, ship_level)
	speed = GameData.get_stat(GameData.SHIP_SPEED, ship_level)
	fire_angle = GameData.get_stat(GameData.SHIP_FIRE_ANGLE, ship_level)
	weapon_damage = GameData.get_stat(GameData.WEAPON_DAMAGE, weapon_level)
	aim_angle = GameData.get_stat(GameData.WEAPON_AIM_ANGLE, weapon_level)
	fire_cooldown = GameData.get_stat(GameData.WEAPON_COOLDOWN, weapon_level)
	max_shield = GameData.get_stat(GameData.SHIELD_MAX, shield_level)
	shield_regen_rate = GameData.get_stat(GameData.SHIELD_REGEN_RATE, shield_level)
	projectile_range = GameData.get_stat(GameData.RADAR_RANGE, radar_level)

func _physics_process(delta: float) -> void:
	if fire_cooldown_timer > 0.0:
		fire_cooldown_timer -= delta
	if invincible_timer > 0.0:
		invincible_timer -= delta
		if invincible_timer <= 0.0:
			is_invincible = false
	_process_shield_regen(delta)
	_process_movement(delta)

func _process_movement(delta: float) -> void:
	var input_dir: Vector2 = move_input.normalized()
	velocity = input_dir * speed
	move_and_slide()
	if velocity.length() > 0.1:
		rotation = velocity.angle()

func _process_shield_regen(delta: float) -> void:
	if current_shield < max_shield:
		shield_regen_timer += delta
		if shield_regen_timer >= GameData.SHIELD_REGEN_DELAY:
			current_shield = minf(current_shield + shield_regen_rate * delta, max_shield)
			shield_changed.emit(current_shield, max_shield)

func set_move_input(direction: Vector2) -> void:
	move_input = direction

func set_aim_direction(direction: Vector2) -> void:
	aim_direction = direction.normalized()

func try_fire() -> bool:
	if fire_cooldown_timer > 0.0:
		return false
	_fire_projectiles()
	fire_cooldown_timer = fire_cooldown
	return true

func _fire_projectiles() -> void:
	var base_angle: float = aim_direction.angle()
	var half_fire: float = deg_to_rad(fire_angle)
	var half_aim: float = deg_to_rad(aim_angle)
	var shots: int = 1 + (weapon_level - 1) / 2
	for i in shots:
		var offset: float = 0.0
		if shots > 1:
			offset = lerp(-half_aim, half_aim, float(i) / float(shots - 1))
		var angle: float = base_angle + offset
		var spread: float = randf_range(-half_aim * 0.1, half_aim * 0.1)
		_spawn_projectile(angle + spread)

func _spawn_projectile(angle: float) -> void:
	var proj: Projectile = projectile_scene.instantiate() as Projectile
	proj.global_position = global_position
	proj.direction = Vector2.RIGHT.rotated(angle)
	proj.damage = weapon_damage
	proj.max_range = projectile_range
	proj.owner_id = player_id
	proj.source_ship = self
	proj.rotation = angle
	get_tree().current_scene.add_child(proj)

func take_damage(amount: float, attacker_id: int) -> void:
	if is_invincible:
		return
	shield_regen_timer = 0.0
	var remaining: float = amount
	if current_shield > 0.0:
		var absorbed: float = minf(current_shield, remaining)
		current_shield -= absorbed
		remaining -= absorbed
		shield_changed.emit(current_shield, max_shield)
	if remaining > 0.0:
		current_hp -= remaining
		hp_changed.emit(current_hp, max_hp)
	if current_hp <= 0.0:
		_die(attacker_id)

func heal(amount: float) -> void:
	current_hp = minf(current_hp + amount, max_hp)
	hp_changed.emit(current_hp, max_hp)

func start_invincibility() -> void:
	is_invincible = true
	invincible_timer = GameData.RESPAWN_INVINCIBLE_TIME

func add_damage_dealt(amount: float) -> void:
	damage_dealt += amount
	var new_points: int = int(damage_dealt / GameData.UPGRADE_POINTS_PER_DAMAGE)
	if new_points > upgrade_points:
		var earned: int = new_points - upgrade_points
		upgrade_points = new_points
		upgrade_points_earned.emit(earned)

func upgrade_ship() -> void:
	if upgrade_points <= 0:
		return
	ship_level = mini(ship_level + 1, 5)
	upgrade_points -= 1
	_recalculate_stats()
	current_hp = minf(current_hp, max_hp)

func upgrade_weapon() -> void:
	if upgrade_points <= 0:
		return
	weapon_level = mini(weapon_level + 1, 5)
	upgrade_points -= 1
	_recalculate_stats()

func upgrade_shield() -> void:
	if upgrade_points <= 0:
		return
	shield_level = mini(shield_level + 1, 5)
	upgrade_points -= 1
	_recalculate_stats()
	current_shield = minf(current_shield, max_shield)

func upgrade_radar() -> void:
	if upgrade_points <= 0:
		return
	radar_level = mini(radar_level + 1, 5)
	upgrade_points -= 1
	_recalculate_stats()

func reset_to_level_1() -> void:
	ship_level = 1
	weapon_level = 1
	shield_level = 1
	radar_level = 1
	upgrade_points = 0
	damage_dealt = 0.0
	_recalculate_stats()
	current_hp = max_hp
	current_shield = max_shield
	hp_changed.emit(current_hp, max_hp)
	shield_changed.emit(current_shield, max_shield)

func _die(killer_id: int) -> void:
	ship_died.emit(player_id)
	queue_free()

func get_cooldown_ratio() -> float:
	return fire_cooldown_timer / maxf(fire_cooldown, 0.01)
