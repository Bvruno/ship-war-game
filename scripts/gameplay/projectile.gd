extends Area2D
class_name Projectile

var direction: Vector2 = Vector2.RIGHT
var damage: float = 10.0
var max_range: float = 300.0
var owner_id: int = -1
var source_ship: Ship

var start_position: Vector2
var speed: float = 400.0
var has_hit: bool = false

func _ready() -> void:
	start_position = global_position
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	var traveled: float = global_position.distance_to(start_position)
	if traveled >= max_range:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if has_hit:
		return
	if body == source_ship:
		return
	if body is Ship:
		var target_ship: Ship = body as Ship
		if target_ship.player_id == owner_id:
			return
		if target_ship.is_invincible:
			return
		var distance: float = global_position.distance_to(target_ship.global_position)
		var multiplier: float = GameData.get_damage_multiplier(
			target_ship.current_hp, target_ship.max_hp, distance
		)
		var final_damage: float = damage * multiplier
		if target_ship.is_local_player():
			target_ship.take_damage(final_damage, owner_id)
		else:
			target_ship.take_damage_sync.rpc_id(target_ship.player_id, final_damage, owner_id)
		if source_ship and source_ship.is_local_player():
			source_ship.add_damage_dealt(final_damage)
		has_hit = true
		queue_free()
	elif body.is_in_group("islands"):
		has_hit = true
		queue_free()
