extends Node2D

signal game_over(winner_id: int)

var world: Node2D
var control_timers: Dictionary = {}
var max_time: float = 60.0
var controlling_players: Dictionary = {}

@onready var tower: Area2D = $Tower

func _ready() -> void:
	if tower:
		tower.body_entered.connect(_on_body_entered)
		tower.body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
	for id in controlling_players.keys():
		if world and world.players.has(id):
			control_timers[id] = control_timers.get(id, 0.0) + delta
			if control_timers[id] >= max_time:
				game_over.emit(id)
				return

func _on_body_entered(body: Node2D) -> void:
	if body is Ship:
		var ship: Ship = body as Ship
		controlling_players[ship.player_id] = true

func _on_body_exited(body: Node2D) -> void:
	if body is Ship:
		var ship: Ship = body as Ship
		controlling_players.erase(ship.player_id)

func get_control_time(player_id: int) -> float:
	return control_timers.get(player_id, 0.0)

func is_controlling(player_id: int) -> bool:
	return controlling_players.has(player_id)

func get_all_times() -> Dictionary:
	return control_timers.duplicate()
