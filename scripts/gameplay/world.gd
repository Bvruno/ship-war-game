extends Node2D

signal game_over

const SHIP_SCENE: PackedScene = preload("res://scenes/game/ship.tscn")
const BOT_SCENE: PackedScene = preload("res://scenes/bots/bot_ship.tscn")

var players: Dictionary = {}
var bots: Dictionary = {}
var local_player_id: int = -1
var game_mode: int = GameData.GameMode.FREE_FOR_ALL
var map_id: int = GameData.MapId.OPEN_SEA
var dead_ships: Dictionary = {}
var next_bot_id: int = -1
var tower_mode_node: Node = null

@onready var hud: CanvasLayer = $HUD
@onready var touch_controls: CanvasLayer = $TouchControls
@onready var upgrade_menu: CanvasLayer = $HUD/UpgradeMenu
@onready var spawn_points: Array[Vector2] = [
	Vector2(200, 200),
	Vector2(1080, 200),
	Vector2(200, 520),
	Vector2(1080, 520),
	Vector2(640, 100),
	Vector2(640, 620)
]

func _ready() -> void:
	game_mode = MultiplayerManager.selected_mode
	map_id = MultiplayerManager.selected_map
	if hud:
		hud.setup(self)
	if touch_controls:
		var tc_script = preload("res://scripts/ui/touch_controls.gd")
		touch_controls.set_script(tc_script)
		touch_controls.setup(self)
	if upgrade_menu:
		var um_script = preload("res://scripts/ui/upgrade_menu.gd")
		upgrade_menu.set_script(um_script)
		upgrade_menu.setup(self)
	var options_menu: Node = get_node_or_null("OptionsMenu")
	if options_menu and options_menu.has_signal("game_cancel_requested"):
		options_menu.game_cancel_requested.connect(_on_game_cancel)
	_connect_upgrade_buttons()
	if game_mode == GameData.GameMode.TOWER_DEFENSE:
		_activate_tower_mode()
	if multiplayer.is_server():
		_create_local_player_as_host()
	else:
		_request_spawn()

func _activate_tower_mode() -> void:
	var tower_mode_scene: PackedScene = preload("res://scenes/game/tower_mode.tscn")
	tower_mode_node = tower_mode_scene.instantiate()
	tower_mode_node.world = self
	add_child(tower_mode_node)
	tower_mode_node.game_over.connect(_on_tower_game_over)
	if hud:
		hud.show_tower_ui(true)

func _connect_upgrade_buttons() -> void:
	if upgrade_menu:
		var ship_btn: Button = upgrade_menu.get_node_or_null("Panel/VBox/ShipBtn")
		var weapon_btn: Button = upgrade_menu.get_node_or_null("Panel/VBox/WeaponBtn")
		var shield_btn: Button = upgrade_menu.get_node_or_null("Panel/VBox/ShieldBtn")
		var radar_btn: Button = upgrade_menu.get_node_or_null("Panel/VBox/RadarBtn")
		var close_btn: Button = upgrade_menu.get_node_or_null("Panel/VBox/CloseBtn")
		if ship_btn:
			ship_btn.pressed.connect(_on_upgrade.bind("ship"))
		if weapon_btn:
			weapon_btn.pressed.connect(_on_upgrade.bind("weapon"))
		if shield_btn:
			shield_btn.pressed.connect(_on_upgrade.bind("shield"))
		if radar_btn:
			radar_btn.pressed.connect(_on_upgrade.bind("radar"))
		if close_btn:
			close_btn.pressed.connect(_on_close_upgrade)

func _on_upgrade(type: String) -> void:
	request_upgrade.rpc_id(1, type)
	if upgrade_menu:
		upgrade_menu.hide_menu()

func _on_close_upgrade() -> void:
	if hud:
		hud.close_upgrade_menu()
	if upgrade_menu:
		upgrade_menu.hide_menu()

func _create_local_player_as_host() -> void:
	var my_id: int = multiplayer.get_unique_id()
	var nickname: String = MultiplayerManager.local_nickname
	var spawn_idx: int = players.size() % spawn_points.size()
	_spawn_ship(my_id, nickname, spawn_points[spawn_idx])

@rpc("any_peer", "reliable", "call_local")
func _request_spawn() -> void:
	var sender_id: int = multiplayer.get_remote_sender_id()
	if not multiplayer.is_server():
		return
	var nickname: String = MultiplayerManager.local_nickname
	var spawn_idx: int = players.size() % spawn_points.size()
	var pos: Vector2 = spawn_points[spawn_idx]
	rpc("spawn_ship_for", sender_id, nickname, pos)
	_spawn_ship(sender_id, nickname, pos)

@rpc("authority", "reliable", "call_local")
func spawn_ship_for(peer_id: int, nick: String, pos: Vector2) -> void:
	if players.has(peer_id):
		return
	_spawn_ship(peer_id, nick, pos)

func _spawn_ship(id: int, nick: String, pos: Vector2) -> void:
	if players.has(id):
		return
	var ship: Ship = SHIP_SCENE.instantiate() as Ship
	ship.player_id = id
	ship.nickname = nick
	pos.x = clampf(pos.x, 50.0, 2450.0)
	pos.y = clampf(pos.y, 50.0, 2450.0)
	ship.global_position = pos
	ship.name = "Ship_" + str(id)
	add_child(ship)
	players[id] = ship
	_connect_ship_signals(ship)
	if id == multiplayer.get_unique_id():
		local_player_id = id
		if hud:
			hud.update_hp(ship.current_hp, ship.max_hp)
			hud.update_shield(ship.current_shield, ship.max_shield)
	update_player_count()

func _connect_ship_signals(ship: Ship) -> void:
	ship.hp_changed.connect(_on_ship_hp_changed.bind(ship.player_id))
	ship.shield_changed.connect(_on_ship_shield_changed.bind(ship.player_id))
	ship.ship_died.connect(_on_ship_died.bind(ship.player_id))
	ship.upgrade_points_earned.connect(_on_upgrade_points.bind(ship.player_id))

func _on_ship_hp_changed(current_hp: float, max_hp: float, id: int) -> void:
	if id == multiplayer.get_unique_id() and hud:
		hud.update_hp(current_hp, max_hp)

func _on_ship_shield_changed(current_shield: float, max_shield: float, id: int) -> void:
	if id == multiplayer.get_unique_id() and hud:
		hud.update_shield(current_shield, max_shield)

func _on_ship_died(ship_id: int, killer_id: int, _original_id: int) -> void:
	dead_ships[ship_id] = Time.get_ticks_msec()
	players.erase(ship_id)
	# Remove from bots if it was a bot
	if bots.has(ship_id):
		bots.erase(ship_id)
	# Register kill for combo
	if players.has(killer_id):
		var killer: Ship = players[killer_id] as Ship
		if killer:
			killer.register_kill()
	if hud:
		hud.update_player_count(players.size())
	if multiplayer.is_server():
		_schedule_respawn(ship_id)

func _on_upgrade_points(points: int, id: int) -> void:
	if id == multiplayer.get_unique_id() and hud:
		hud.reset_upgrade_closed()
		hud.update_upgrade_points(points)

func _schedule_respawn(ship_id: int) -> void:
	await get_tree().create_timer(2.0).timeout
	if players.has(ship_id):
		return
	# Bots have negative IDs, players have positive IDs
	if ship_id < 0:
		# Respawn as bot
		var avg_level: int = _get_avg_player_level()
		add_bot(avg_level)
		dead_ships.erase(ship_id)
	else:
		# Respawn as player
		rpc("respawn_player", ship_id)
		_respawn_player_local(ship_id)

@rpc("authority", "reliable", "call_local")
func respawn_player(id: int) -> void:
	_respawn_player_local(id)

func _respawn_player_local(id: int) -> void:
	if players.has(id):
		return
	var nickname: String = "Player" + str(id)
	if MultiplayerManager.players_data.has(id):
		nickname = MultiplayerManager.players_data[id]["nickname"]
	var ship: Ship = SHIP_SCENE.instantiate() as Ship
	ship.player_id = id
	ship.nickname = nickname
	var spawn_idx: int = randi() % spawn_points.size()
	ship.global_position = spawn_points[spawn_idx]
	ship.name = "Ship_" + str(id)
	add_child(ship)
	players[id] = ship
	dead_ships.erase(id)
	_connect_ship_signals(ship)
	ship.start_invincibility()
	if id == multiplayer.get_unique_id() and hud:
		hud.update_hp(ship.current_hp, ship.max_hp)
		hud.update_shield(ship.current_shield, ship.max_shield)
	update_player_count()

func update_player_count() -> void:
	if hud:
		hud.update_player_count(players.size())

func get_local_ship() -> Ship:
	var my_id: int = multiplayer.get_unique_id()
	if players.has(my_id):
		return players[my_id] as Ship
	return null

@rpc("any_peer", "reliable", "call_local")
func request_upgrade(upgrade_type: String) -> void:
	var sender_id: int = multiplayer.get_remote_sender_id()
	if not players.has(sender_id):
		return
	var ship: Ship = players[sender_id] as Ship
	if ship.upgrade_points <= 0:
		return
	match upgrade_type:
		"ship": ship.upgrade_ship()
		"weapon": ship.upgrade_weapon()
		"shield": ship.upgrade_shield()
		"radar": ship.upgrade_radar()
	rpc("sync_ship_state", sender_id, ship.ship_level, ship.weapon_level, ship.shield_level, ship.radar_level, ship.upgrade_points)

@rpc("authority", "reliable", "call_local")
func sync_ship_state(peer_id: int, s_lv: int, w_lv: int, sh_lv: int, r_lv: int, pts: int) -> void:
	if not players.has(peer_id):
		return
	var ship: Ship = players[peer_id] as Ship
	var hp_ratio: float = ship.current_hp / maxf(ship.max_hp, 1.0)
	var shield_ratio: float = ship.current_shield / maxf(ship.max_shield, 1.0)
	ship.ship_level = s_lv
	ship.weapon_level = w_lv
	ship.shield_level = sh_lv
	ship.radar_level = r_lv
	ship.upgrade_points = pts
	ship._recalculate_stats()
	ship.current_hp = hp_ratio * ship.max_hp
	ship.current_shield = shield_ratio * ship.max_shield
	if peer_id == multiplayer.get_unique_id() and hud:
		hud.update_hp(ship.current_hp, ship.max_hp)
		hud.update_shield(ship.current_shield, ship.max_shield)
		hud.update_upgrade_points(ship.upgrade_points)

func add_bot(avg_level: int = 1) -> Ship:
	var bot: Ship = BOT_SCENE.instantiate() as Ship
	bot.is_bot = true
	bot.player_id = next_bot_id
	next_bot_id -= 1
	bot.nickname = "Bot" + str(bots.size() + 1)
	var spawn_idx: int = (players.size() + bots.size()) % spawn_points.size()
	bot.global_position = spawn_points[spawn_idx]
	bot.name = "BotShip_" + str(bot.player_id)
	add_child(bot)
	bots[bot.player_id] = bot
	players[bot.player_id] = bot
	_connect_ship_signals(bot)
	var bot_ai: BotAI = bot.get_node("BotAI") as BotAI
	if bot_ai:
		bot_ai.set_difficulty(avg_level)
	if hud:
		hud.update_player_count(players.size())
	return bot

func add_bots(count: int, avg_level: int = 1) -> void:
	for i in count:
		if players.size() >= GameData.MAX_PLAYERS:
			break
		add_bot(avg_level)

func remove_bot(bot_id: int) -> void:
	if bots.has(bot_id):
		var bot: Ship = bots[bot_id] as Ship
		bot.queue_free()
		bots.erase(bot_id)
		players.erase(bot_id)
		if hud:
			hud.update_player_count(players.size())

func remove_all_bots() -> void:
	var bot_ids: Array = bots.keys()
	for id in bot_ids:
		remove_bot(id)

func _get_avg_player_level() -> int:
	if players.is_empty():
		return 1
	var total_level: int = 0
	var count: int = 0
	for id in players:
		var ship: Ship = players[id] as Ship
		if ship and not ship.is_bot:
			total_level += ship.ship_level + ship.weapon_level + ship.shield_level + ship.radar_level
			count += 1
	if count == 0:
		return 1
	return clampi(int(float(total_level) / float(count * 4)), 1, 5)

func _get_bot_count() -> int:
	return bots.size()

func _on_tower_game_over(winner_id: int) -> void:
	if hud:
		var winner_name: String = "Unknown"
		if players.has(winner_id):
			winner_name = (players[winner_id] as Ship).nickname
		hud.show_game_over("Tower Winner: " + winner_name)

func _on_game_cancel() -> void:
	MultiplayerManager.reset_state()
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
