extends Node2D

signal game_over

const SHIP_SCENE: PackedScene = preload("res://scenes/game/ship.tscn")

var players: Dictionary = {}
var local_player_id: int = -1
var game_mode: GameData.GameMode = GameData.GameMode.FREE_FOR_ALL
var map_id: GameData.MapId = GameData.MapId.OPEN_SEA

@onready var hud: CanvasLayer = $HUD
@onready var spawn_points: Array[Vector2] = [
	Vector2(200, 200),
	Vector2(1080, 200),
	Vector2(200, 520),
	Vector2(1080, 520),
	Vector2(640, 100),
	Vector2(640, 620)
]

func _ready() -> void:
	if hud:
		hud.setup(self)

func create_local_player(id: int, nickname: String) -> Ship:
	var ship: Ship = SHIP_SCENE.instantiate() as Ship
	ship.player_id = id
	ship.nickname = nickname
	local_player_id = id
	var spawn_idx: int = players.size() % spawn_points.size()
	ship.global_position = spawn_points[spawn_idx]
	add_child(ship)
	players[id] = ship
	_connect_ship_signals(ship)
	return ship

func add_remote_player(id: int, nickname: String, position: Vector2) -> Ship:
	var ship: Ship = SHIP_SCENE.instantiate() as Ship
	ship.player_id = id
	ship.nickname = nickname
	ship.global_position = position
	add_child(ship)
	players[id] = ship
	_connect_ship_signals(ship)
	return ship

func _connect_ship_signals(ship: Ship) -> void:
	ship.hp_changed.connect(_on_ship_hp_changed.bind(ship.player_id))
	ship.shield_changed.connect(_on_ship_shield_changed.bind(ship.player_id))
	ship.ship_died.connect(_on_ship_died)
	ship.upgrade_points_earned.connect(_on_upgrade_points.bind(ship.player_id))

func _on_ship_hp_changed(current_hp: float, max_hp: float, id: int) -> void:
	if id == local_player_id and hud:
		hud.update_hp(current_hp, max_hp)

func _on_ship_shield_changed(current_shield: float, max_shield: float, id: int) -> void:
	if id == local_player_id and hud:
		hud.update_shield(current_shield, max_shield)

func _on_ship_died(ship_id: int) -> void:
	players.erase(ship_id)
	if hud:
		hud.update_player_count(players.size())

func _on_upgrade_points(points: int, id: int) -> void:
	if id == local_player_id and hud:
		hud.show_upgrade_menu(points)

func get_local_ship() -> Ship:
	if players.has(local_player_id):
		return players[local_player_id] as Ship
	return null

func respawn_player(id: int) -> void:
	if players.has(id):
		return
	var nickname: String = "Player" + str(id)
	var ship: Ship = SHIP_SCENE.instantiate() as Ship
	ship.player_id = id
	ship.nickname = nickname
	var spawn_idx: int = randi() % spawn_points.size()
	ship.global_position = spawn_points[spawn_idx]
	ship.reset_to_level_1()
	ship.start_invincibility()
	add_child(ship)
	players[id] = ship
	_connect_ship_signals(ship)
	if id == local_player_id and hud:
		hud.update_hp(ship.current_hp, ship.max_hp)
		hud.update_shield(ship.current_shield, ship.max_shield)

func update_player_count() -> void:
	if hud:
		hud.update_player_count(players.size())
