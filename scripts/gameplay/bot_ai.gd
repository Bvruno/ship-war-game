extends Node
class_name BotAI

var ship: Ship
var target: Ship = null
var patrol_target: Vector2 = Vector2.ZERO
var state: String = "patrol"
var detection_range: float = 400.0
var attack_range: float = 250.0
var flee_threshold: float = 0.3

var decision_timer: float = 0.0
var decision_interval: float = 0.5

var world_bounds: Rect2 = Rect2(0, 0, 1280, 720)

var aggression_level: float = 1.0
var preferred_distance: float = 200.0
var strafe_preference: float = 0.5

func _ready() -> void:
	ship = get_parent() as Ship
	_randomize_behavior()
	_pick_new_patrol_point()

func _randomize_behavior() -> void:
	aggression_level = randf_range(0.7, 1.3)
	preferred_distance = randf_range(150.0, 300.0)
	strafe_preference = randf_range(0.3, 0.7)
	decision_interval = randf_range(0.4, 0.7)
	flee_threshold = randf_range(0.2, 0.4)

func _physics_process(delta: float) -> void:
	if not ship:
		return
	
	decision_timer -= delta
	if decision_timer <= 0.0:
		_make_decision()
		decision_timer = decision_interval
	
	match state:
		"patrol":
			_patrol_behavior(delta)
		"chase":
			_chase_behavior(delta)
		"attack":
			_attack_behavior(delta)
		"flee":
			_flee_behavior(delta)

func _make_decision() -> void:
	target = _find_nearest_enemy()
	
	var hp_ratio: float = ship.current_hp / ship.max_hp
	
	if hp_ratio < flee_threshold and target:
		state = "flee"
		return
	
	if target:
		var distance: float = ship.global_position.distance_to(target.global_position)
		if distance <= attack_range:
			state = "attack"
		elif distance <= detection_range:
			state = "chase"
		else:
			state = "patrol"
	else:
		state = "patrol"

func _find_nearest_enemy() -> Ship:
	var nearest: Ship = null
	var nearest_dist: float = detection_range
	
	for node in get_tree().get_nodes_in_group("ships"):
		if node == ship or not node is Ship:
			continue
		var enemy: Ship = node as Ship
		if enemy.is_invincible:
			continue
		var dist: float = ship.global_position.distance_to(enemy.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy
	
	return nearest

func _patrol_behavior(_delta: float) -> void:
	var direction: Vector2 = (patrol_target - ship.global_position).normalized()
	ship.set_move_input(direction * 0.6)
	
	if ship.global_position.distance_to(patrol_target) < 50.0:
		_pick_new_patrol_point()
	
	if ship.global_position.x < world_bounds.position.x + 50 or \
	   ship.global_position.x > world_bounds.end.x - 50 or \
	   ship.global_position.y < world_bounds.position.y + 50 or \
	   ship.global_position.y > world_bounds.end.y - 50:
		patrol_target = world_bounds.get_center()
	
	if randf() < 0.005 * aggression_level:
		ship.try_fire()

func _chase_behavior(_delta: float) -> void:
	if not target:
		state = "patrol"
		return
	
	var direction: Vector2 = (target.global_position - ship.global_position).normalized()
	ship.set_move_input(direction * 0.8)
	ship.set_aim_direction(direction)

func _attack_behavior(_delta: float) -> void:
	if not target:
		state = "patrol"
		return
	
	var direction: Vector2 = (target.global_position - ship.global_position).normalized()
	ship.set_aim_direction(direction)
	
	var distance: float = ship.global_position.distance_to(target.global_position)
	var move_dir: Vector2 = Vector2.ZERO
	
	if distance < preferred_distance - 30:
		move_dir = -direction
	elif distance > preferred_distance + 30:
		move_dir = direction
	else:
		var perpendicular: Vector2 = direction.rotated(PI / 2.0)
		var strafe_dir: float = 1.0 if randf() > 0.5 else -1.0
		if randf() < strafe_preference:
			move_dir = perpendicular * strafe_dir
	
	ship.set_move_input(move_dir * 0.7)
	
	ship.try_fire()

func _flee_behavior(_delta: float) -> void:
	if not target:
		state = "patrol"
		return
	
	var away: Vector2 = (ship.global_position - target.global_position).normalized()
	ship.set_move_input(away)
	ship.set_aim_direction(-away)

func _pick_new_patrol_point() -> void:
	patrol_target = Vector2(
		randf_range(world_bounds.position.x + 100, world_bounds.end.x - 100),
		randf_range(world_bounds.position.y + 100, world_bounds.end.y - 100)
	)

func set_difficulty(avg_level: int) -> void:
	ship.ship_level = clampi(avg_level, 1, 5)
	ship.weapon_level = clampi(avg_level - 1, 1, 5)
	ship.shield_level = clampi(avg_level - 1, 1, 5)
	ship.radar_level = clampi(avg_level, 1, 5)
	ship._recalculate_stats()
	ship.current_hp = ship.max_hp
	ship.current_shield = ship.max_shield
	
	detection_range = 300.0 + (ship.radar_level - 1) * 50.0
	attack_range = 200.0 + (ship.weapon_level - 1) * 30.0
	world_bounds = Rect2(0, 0, 2500, 2500)
	_randomize_behavior()

func _process(_delta: float) -> void:
	# Bot auto-upgrades
	if ship.upgrade_points > 0:
		_try_upgrade()

func _try_upgrade() -> void:
	# Prioriza upgrades basándose en estrategia
	var upgrades: Array[String] = []
	if ship.ship_level < 5:
		upgrades.append("ship")
	if ship.weapon_level < 5:
		upgrades.append("weapon")
	if ship.shield_level < 5:
		upgrades.append("shield")
	if ship.radar_level < 5:
		upgrades.append("radar")
	
	if upgrades.is_empty():
		return
	
	# Elige un upgrade aleatorio
	var choice: String = upgrades[randi() % upgrades.size()]
	
	# Ejecuta el upgrade
	match choice:
		"ship":
			ship.upgrade_ship()
		"weapon":
			ship.upgrade_weapon()
		"shield":
			ship.upgrade_shield()
		"radar":
			ship.upgrade_radar()
