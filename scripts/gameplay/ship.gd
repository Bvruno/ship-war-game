extends CharacterBody2D
class_name Ship

signal hp_changed(current_hp: float, max_hp: float)
signal shield_changed(current_shield: float, max_shield: float)
signal ship_died(ship_id: int, killer_id: int)
signal upgrade_points_earned(points: int)
signal visual_state_changed()

@export var player_id: int = 0
@export var nickname: String = "Player"
@export var is_bot: bool = false

var ship_level: int = 1
var weapon_level: int = 1
var shield_level: int = 1
var radar_level: int = 1

var max_hp: float = 120.0
var current_hp: float = 120.0
var max_shield: float = 60.0
var current_shield: float = 60.0
var speed: float = 80.0
var turn_speed: float = 2.5
var fire_cooldown: float = 1.5
var fire_cooldown_timer: float = 0.0
var aim_angle: float = 15.0
var fire_angle: float = 20.0
var weapon_damage: float = 8.0
var projectile_range: float = 300.0
var shield_regen_rate: float = 8.0
var shield_regen_timer: float = 0.0
var hp_regen_rate: float = 2.0
var hp_regen_timer: float = 0.0
var is_invincible: bool = false
var invincible_timer: float = 0.0

# Combo system
var combo_count: int = 0
var combo_timer: float = 0.0

var aim_direction: Vector2 = Vector2.RIGHT
var aim_side: int = 1

var upgrade_points: int = 0
var damage_dealt: float = 0.0
var score: int = 0

var move_input: Vector2 = Vector2.ZERO

var projectile_scene: PackedScene

@onready var sync: MultiplayerSynchronizer = $MultiplayerSynchronizer
@onready var hull_rect: ColorRect = $Hull
@onready var sail_rect: ColorRect = $Sail
@onready var cannon_down: ColorRect = $CannonDown
@onready var cannon_up: ColorRect = $CannonUp
@onready var aim_line: Line2D = $AimLine
@onready var spread_left: Line2D = $SpreadLeft
@onready var spread_right: Line2D = $SpreadRight
@onready var ui_container: Node2D = $UIContainer
@onready var nick_label: Label = $UIContainer/NickLabel
@onready var invincible_flash: Timer = $InvincibleFlash
@onready var water_trail: Node2D = $WaterTrail
@onready var hp_bar: ProgressBar = $UIContainer/HPBar
@onready var shield_bar: ProgressBar = $UIContainer/ShieldBar
@onready var camera: Camera2D = $Camera2D

const AIM_INDICATOR_LENGTH: float = 80.0

var _is_local: bool = false
var _damage_flash_timer: float = 0.0

func _ready() -> void:
	projectile_scene = preload("res://scenes/game/projectile.tscn")
	_recalculate_stats()
	current_hp = max_hp
	current_shield = max_shield
	add_to_group("ships")
	_is_local = (multiplayer.get_unique_id() == player_id) or is_bot
	if sync:
		sync.set_multiplayer_authority(player_id)
	if water_trail:
		water_trail.follow_node = self
	if nick_label:
		nick_label.text = nickname
	# Enable camera only for local player
	if camera and not is_bot and multiplayer.get_unique_id() == player_id:
		camera.enabled = true

func is_local_player() -> bool:
	if is_bot:
		return true
	return multiplayer.get_unique_id() == player_id

func _recalculate_stats() -> void:
	max_hp = GameData.get_stat(GameData.SHIP_HP, ship_level)
	speed = GameData.get_stat(GameData.SHIP_SPEED, ship_level)
	turn_speed = GameData.get_stat(GameData.SHIP_TURN_SPEED, ship_level)
	fire_angle = GameData.get_stat(GameData.SHIP_FIRE_ANGLE, ship_level)
	weapon_damage = GameData.get_stat(GameData.WEAPON_DAMAGE, weapon_level)
	aim_angle = GameData.get_stat(GameData.WEAPON_AIM_ANGLE, weapon_level)
	fire_cooldown = GameData.get_stat(GameData.WEAPON_COOLDOWN, weapon_level)
	max_shield = GameData.get_stat(GameData.SHIELD_MAX, shield_level)
	shield_regen_rate = GameData.get_stat(GameData.SHIELD_REGEN_RATE, shield_level)
	hp_regen_rate = GameData.get_stat(GameData.HP_REGEN_RATE, ship_level)
	projectile_range = GameData.get_stat(GameData.WEAPON_RANGE, weapon_level)

func _physics_process(delta: float) -> void:
	if fire_cooldown_timer > 0.0:
		fire_cooldown_timer -= delta
	if invincible_timer > 0.0:
		invincible_timer -= delta
		if invincible_timer <= 0.0:
			is_invincible = false
	_process_regen(delta)
	if is_local_player():
		_process_movement(delta)
	_process_visual_effects(delta)

func _process_movement(_delta: float) -> void:
	var keyboard_dir: Vector2 = Vector2.ZERO
	if not is_bot:
		if Input.is_action_pressed("move_right"):
			keyboard_dir.x += 1.0
		if Input.is_action_pressed("move_left"):
			keyboard_dir.x -= 1.0
		if Input.is_action_pressed("move_down"):
			keyboard_dir.y += 1.0
		if Input.is_action_pressed("move_up"):
			keyboard_dir.y -= 1.0
		if Input.is_action_just_pressed("fire"):
			try_fire()
		var mouse_pos: Vector2 = get_global_mouse_position()
		var to_mouse: Vector2 = (mouse_pos - global_position).normalized()
		if to_mouse.length() > 0.01:
			var right_side: Vector2 = Vector2.DOWN.rotated(rotation)
			var left_side: Vector2 = Vector2.UP.rotated(rotation)
			var right_angle: float = right_side.angle()
			var left_angle: float = left_side.angle()
			var mouse_angle: float = to_mouse.angle()
			var relative_right: float = mouse_angle - right_angle
			while relative_right > PI:
				relative_right -= TAU
			while relative_right < -PI:
				relative_right += TAU
			var relative_left: float = mouse_angle - left_angle
			while relative_left > PI:
				relative_left -= TAU
			while relative_left < -PI:
				relative_left += TAU
			var half_aim: float = deg_to_rad(aim_angle)
			var base_angle: float
			var relative: float
			if absf(relative_right) <= absf(relative_left):
				base_angle = right_angle
				relative = relative_right
				aim_side = 1
			else:
				base_angle = left_angle
				relative = relative_left
				aim_side = -1
			var clamped: float = clampf(relative, -half_aim, half_aim)
			aim_direction = Vector2.RIGHT.rotated(base_angle + clamped)
	var input_dir: Vector2 = move_input + keyboard_dir
	if input_dir.length() > 1.0:
		input_dir = input_dir.normalized()
	velocity = input_dir * speed
	move_and_slide()
	# Map boundary limit (2500x2500)
	global_position.x = clampf(global_position.x, 30.0, 2470.0)
	global_position.y = clampf(global_position.y, 30.0, 2470.0)
	# Check island collision damage
	if get_slide_collision_count() > 0:
		for i in get_slide_collision_count():
			var collision: KinematicCollision2D = get_slide_collision(i)
			if collision and collision.get_collider() is StaticBody2D:
				if is_local_player():
					var impact_damage: float = velocity.length() * 0.1
					take_damage(impact_damage, -1)
	if velocity.length() > 0.1:
		var target_rotation: float = velocity.angle()
		rotation = lerp_angle(rotation, target_rotation, turn_speed * get_physics_process_delta_time())

func _process_regen(delta: float) -> void:
	# Shield regen
	if current_shield < max_shield:
		shield_regen_timer += delta
		if shield_regen_timer >= GameData.SHIELD_REGEN_DELAY:
			current_shield = minf(current_shield + shield_regen_rate * delta, max_shield)
			if is_local_player():
				shield_changed.emit(current_shield, max_shield)
	# HP regen (slower, starts after longer delay)
	if current_hp < max_hp and current_hp > 0:
		hp_regen_timer += delta
		if hp_regen_timer >= GameData.HP_REGEN_DELAY:
			current_hp = minf(current_hp + hp_regen_rate * delta, max_hp)
			if is_local_player():
				hp_changed.emit(current_hp, max_hp)
	# Combo timeout
	if combo_count > 0:
		combo_timer += delta
		if combo_timer >= GameData.COMBO_TIMEOUT:
			combo_count = 0
			combo_timer = 0.0

func _process_visual_effects(delta: float) -> void:
	if _damage_flash_timer > 0.0:
		_damage_flash_timer -= delta
		if hull_rect:
			hull_rect.color = Color(1, 0.3, 0.3, 1) if fmod(_damage_flash_timer, 0.1) > 0.05 else Color(0.5, 0.35, 0.15, 1)
	else:
		if hull_rect:
			hull_rect.color = Color(0.5, 0.35, 0.15, 1)
	if is_invincible and hull_rect:
		hull_rect.color.a = 0.4 if fmod(invincible_timer, 0.2) > 0.1 else 1.0
	# Keep UI container upright (no rotation)
	if ui_container:
		ui_container.rotation = -rotation
	_update_damage_visuals()
	_update_aim_indicators()

func _update_aim_indicators() -> void:
	var half_aim: float = deg_to_rad(aim_angle)
	var base_dir: Vector2 = Vector2.DOWN if aim_side == 1 else Vector2.UP
	var spread_left_pos: Vector2 = base_dir.rotated(-half_aim) * AIM_INDICATOR_LENGTH
	var spread_right_pos: Vector2 = base_dir.rotated(half_aim) * AIM_INDICATOR_LENGTH
	var aim_local: Vector2 = aim_direction.rotated(-rotation)
	var aim_pos: Vector2 = aim_local * AIM_INDICATOR_LENGTH
	if aim_line:
		aim_line.points = PackedVector2Array([Vector2.ZERO, aim_pos])
	if spread_left:
		spread_left.points = PackedVector2Array([Vector2.ZERO, spread_left_pos])
	if spread_right:
		spread_right.points = PackedVector2Array([Vector2.ZERO, spread_right_pos])
	if cannon_down:
		cannon_down.visible = (aim_side == 1)
	if cannon_up:
		cannon_up.visible = (aim_side == -1)

func _update_damage_visuals() -> void:
	var hp_ratio: float = current_hp / maxf(max_hp, 1.0)
	if sail_rect:
		if hp_ratio < 0.66:
			sail_rect.color.a = 0.7
		if hp_ratio < 0.33:
			sail_rect.color.a = 0.4
		else:
			sail_rect.color.a = 1.0
	if nick_label:
		nick_label.text = nickname
	if hp_bar:
		hp_bar.value = hp_ratio * 100.0
	if shield_bar:
		shield_bar.value = (current_shield / maxf(max_shield, 1.0)) * 100.0

func set_move_input(direction: Vector2) -> void:
	move_input = direction

func set_aim_direction(direction: Vector2) -> void:
	var dir: Vector2 = direction.normalized()
	var right_side: Vector2 = Vector2.DOWN.rotated(rotation)
	var left_side: Vector2 = Vector2.UP.rotated(rotation)
	var right_angle: float = right_side.angle()
	var left_angle: float = left_side.angle()
	var dir_angle: float = dir.angle()
	var relative_right: float = dir_angle - right_angle
	while relative_right > PI:
		relative_right -= TAU
	while relative_right < -PI:
		relative_right += TAU
	var relative_left: float = dir_angle - left_angle
	while relative_left > PI:
		relative_left -= TAU
	while relative_left < -PI:
		relative_left += TAU
	var half_aim: float = deg_to_rad(aim_angle)
	if absf(relative_right) <= absf(relative_left):
		var clamped: float = clampf(relative_right, -half_aim, half_aim)
		aim_direction = Vector2.RIGHT.rotated(right_angle + clamped)
		aim_side = 1
	else:
		var clamped: float = clampf(relative_left, -half_aim, half_aim)
		aim_direction = Vector2.RIGHT.rotated(left_angle + clamped)
		aim_side = -1

func try_fire() -> bool:
	if not is_local_player():
		return false
	if fire_cooldown_timer > 0.0:
		return false
	_fire_projectiles()
	rpc("fire_sync", aim_direction, fire_cooldown, weapon_level, ship_level, radar_level, aim_side)
	fire_cooldown_timer = fire_cooldown
	if AudioManager:
		AudioManager.play_fire()
	return true

@rpc("any_peer", "call_local", "reliable")
func fire_sync(aim_dir: Vector2, cooldown: float, w_level: int, s_level: int, r_level: int, side: int) -> void:
	var sender_id: int = multiplayer.get_remote_sender_id()
	if sender_id != player_id:
		return
	aim_direction = aim_dir
	aim_side = side
	weapon_level = w_level
	ship_level = s_level
	radar_level = r_level
	_recalculate_stats()
	_fire_projectiles()
	fire_cooldown_timer = cooldown

func _fire_projectiles() -> void:
	var bullet_spread_rad: float = deg_to_rad(GameData.BULLET_SPREAD)
	var shots: int = 1 + (weapon_level - 1) / 2
	var base_angle: float = aim_direction.angle()
	if shots == 1:
		_spawn_projectile(base_angle)
	else:
		for i in shots:
			var offset: float = lerp(-bullet_spread_rad, bullet_spread_rad, float(i) / float(shots - 1))
			var angle: float = base_angle + offset
			_spawn_projectile(angle)

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

@rpc("any_peer", "call_local", "reliable")
func take_damage_sync(amount: float, attacker_id: int) -> void:
	take_damage(amount, attacker_id)

func take_damage(amount: float, attacker_id: int) -> void:
	if is_invincible:
		return
	shield_regen_timer = 0.0
	hp_regen_timer = 0.0
	_damage_flash_timer = 0.3
	var remaining: float = amount
	if current_shield > 0.0:
		var absorbed: float = minf(current_shield, remaining)
		current_shield -= absorbed
		remaining -= absorbed
		if is_local_player():
			shield_changed.emit(current_shield, max_shield)
			if AudioManager:
				AudioManager.play_shield_hit()
	if remaining > 0.0:
		current_hp -= remaining
		if is_local_player():
			hp_changed.emit(current_hp, max_hp)
			if AudioManager:
				AudioManager.play_hull_hit()
	visual_state_changed.emit()
	if current_hp <= 0.0:
		_die(attacker_id)

func heal(amount: float) -> void:
	current_hp = minf(current_hp + amount, max_hp)
	if is_local_player():
		hp_changed.emit(current_hp, max_hp)

func start_invincibility() -> void:
	is_invincible = true
	invincible_timer = GameData.RESPAWN_INVINCIBLE_TIME

func add_damage_dealt(amount: float) -> void:
	damage_dealt += amount
	var combo_mult: float = GameData.COMBO_BONUS[mini(combo_count, GameData.COMBO_BONUS.size() - 1)]
	var effective_damage: float = amount * combo_mult
	var new_points: int = int(damage_dealt / GameData.UPGRADE_POINTS_PER_DAMAGE)
	if new_points > upgrade_points:
		var earned: int = new_points - upgrade_points
		upgrade_points = new_points
		if is_local_player():
			upgrade_points_earned.emit(earned)

func register_kill() -> void:
	combo_count += 1
	combo_timer = 0.0
	if is_local_player():
		score += 100 * combo_count

func upgrade_ship() -> void:
	if upgrade_points <= 0 or ship_level >= 5:
		return
	var hp_ratio: float = current_hp / maxf(max_hp, 1.0)
	ship_level += 1
	upgrade_points -= 1
	_recalculate_stats()
	current_hp = hp_ratio * max_hp
	if is_local_player():
		hp_changed.emit(current_hp, max_hp)
	rpc("sync_upgrade", ship_level, weapon_level, shield_level, radar_level)
	if is_local_player() and AudioManager:
		AudioManager.play_upgrade()

func upgrade_weapon() -> void:
	if upgrade_points <= 0 or weapon_level >= 5:
		return
	weapon_level += 1
	upgrade_points -= 1
	_recalculate_stats()
	rpc("sync_upgrade", ship_level, weapon_level, shield_level, radar_level)
	if is_local_player() and AudioManager:
		AudioManager.play_upgrade()

func upgrade_shield() -> void:
	if upgrade_points <= 0 or shield_level >= 5:
		return
	var shield_ratio: float = current_shield / maxf(max_shield, 1.0)
	shield_level += 1
	upgrade_points -= 1
	_recalculate_stats()
	current_shield = shield_ratio * max_shield
	if is_local_player():
		shield_changed.emit(current_shield, max_shield)
	rpc("sync_upgrade", ship_level, weapon_level, shield_level, radar_level)
	if is_local_player() and AudioManager:
		AudioManager.play_upgrade()

func upgrade_radar() -> void:
	if upgrade_points <= 0 or radar_level >= 5:
		return
	radar_level += 1
	upgrade_points -= 1
	_recalculate_stats()
	rpc("sync_upgrade", ship_level, weapon_level, shield_level, radar_level)
	if is_local_player() and AudioManager:
		AudioManager.play_upgrade()

@rpc("any_peer", "call_local", "reliable")
func sync_upgrade(s_lv: int, w_lv: int, sh_lv: int, r_lv: int) -> void:
	var sender_id: int = multiplayer.get_remote_sender_id()
	if sender_id != player_id:
		return
	ship_level = s_lv
	weapon_level = w_lv
	shield_level = sh_lv
	radar_level = r_lv
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
	if is_local_player():
		hp_changed.emit(current_hp, max_hp)
		shield_changed.emit(current_shield, max_shield)

func _die(killer_id: int) -> void:
	_spawn_explosion()
	if is_local_player() and AudioManager:
		AudioManager.play_explosion()
	ship_died.emit(player_id, killer_id)
	queue_free()

func _spawn_explosion() -> void:
	var explosion: GPUParticles2D = GPUParticles2D.new()
	explosion.global_position = global_position
	explosion.emitting = true
	explosion.one_shot = true
	explosion.amount = 40
	explosion.lifetime = 0.8
	var mat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	mat.direction = Vector3.ZERO
	mat.initial_velocity_min = 50.0
	mat.initial_velocity_max = 150.0
	mat.gravity = Vector3.ZERO
	mat.scale_min = 2.0
	mat.scale_max = 5.0
	mat.color = Color(1.0, 0.6, 0.0)
	explosion.process_material = mat
	get_tree().current_scene.add_child(explosion)

func get_cooldown_ratio() -> float:
	return fire_cooldown_timer / maxf(fire_cooldown, 0.01)
