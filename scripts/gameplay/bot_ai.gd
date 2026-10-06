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

func _ready() -> void:
	ship = get_parent() as Ship
	_pick_new_patrol_point()

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
	ship.set_move_input(direction)
	
	if ship.global_position.distance_to(patrol_target) < 50.0:
		_pick_new_patrol_point()
	
	if randf() < 0.01:
		ship.try_fire()

func _chase_behavior(_delta: float) -> void:
	if not target:
		state = "patrol"
		return
	
	var direction: Vector2 = (target.global_position - ship.global_position).normalized()
	ship.set_move_input(direction)
	ship.set_aim_direction(direction)

func _attack_behavior(_delta: float) -> void:
	if not target:
		state = "patrol"
		return
	
	var direction: Vector2 = (target.global_position - ship.global_position).normalized()
	ship.set_aim_direction(direction)
	
	var perpendicular: Vector2 = direction.rotated(PI / 2.0)
	var strafe: Vector2 = perpendicular * (1.0 if randf() > 0.5 else -1.0)
	ship.set_move_input(strafe * 0.5)
	
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
