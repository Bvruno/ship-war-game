extends CanvasLayer

var world: Node2D

@onready var hp_bar: ProgressBar = $TopLeft/VBoxContainer/HPBar
@onready var hp_label: Label = $TopLeft/VBoxContainer/HPLabel
@onready var shield_bar: ProgressBar = $TopLeft/VBoxContainer/ShieldBar
@onready var shield_label: Label = $TopLeft/VBoxContainer/ShieldLabel
@onready var cooldown_bar: ProgressBar = $TopLeft/VBoxContainer/CooldownBar
@onready var score_label: Label = $TopLeft/VBoxContainer/ScoreLabel
@onready var player_count_label: Label = $TopLeft/VBoxContainer/PlayerCountLabel
@onready var points_label: Label = $TopLeft/VBoxContainer/PointsLabel
@onready var minimap: Control = $MinimapPanel/Minimap
@onready var upgrade_panel: PanelContainer = $UpgradeMenu/Panel
@onready var add_bot_btn: Button = $BotControls/AddBotBtn
@onready var remove_bot_btn: Button = $BotControls/RemoveBotBtn
@onready var tower_panel: PanelContainer = $TowerUI/TowerPanel
@onready var tower_timer_label: Label = $TowerUI/TowerPanel/VBox/TimerLabel
@onready var tower_status_label: Label = $TowerUI/TowerPanel/VBox/StatusLabel
@onready var game_over_panel: PanelContainer = $GameOverPanel
@onready var options_btn: Button = $OptionsBtn

var upgrade_menu_script = preload("res://scripts/ui/upgrade_menu.gd")
var _upgrade_menu: Control
var _upgrade_menu_closed: bool = false

func setup(world_ref: Node2D) -> void:
	world = world_ref

func _ready() -> void:
	if upgrade_panel:
		upgrade_panel.visible = false
	if add_bot_btn:
		add_bot_btn.pressed.connect(_on_add_bot)
	if remove_bot_btn:
		remove_bot_btn.pressed.connect(_on_remove_bot)
	if tower_panel:
		tower_panel.visible = false
	if game_over_panel:
		game_over_panel.visible = false
	if options_btn:
		options_btn.pressed.connect(_on_options_pressed)

func _process(_delta: float) -> void:
	if not world:
		return
	var ship: Ship = world.get_local_ship()
	if ship:
		if cooldown_bar:
			cooldown_bar.value = 1.0 - ship.get_cooldown_ratio()
	_update_minimap(ship)
	_update_tower_ui()

func _on_add_bot() -> void:
	if not world:
		return
	var avg_level: int = world._get_avg_player_level()
	world.add_bot(avg_level)

func _on_remove_bot() -> void:
	if not world:
		return
	if world.bots.is_empty():
		return
	var last_bot_id: int = world.bots.keys().back()
	world.remove_bot(last_bot_id)

func _update_minimap(local_ship: Ship) -> void:
	if not minimap:
		return
	for child in minimap.get_children():
		child.queue_free()
	var world_rect: Rect2 = Rect2(0, 0, 2500, 2500)
	var map_size: Vector2 = minimap.size
	for id in world.players:
		var ship: Ship = world.players[id] as Ship
		var map_pos: Vector2 = Vector2(
			ship.global_position.x / world_rect.size.x * map_size.x,
			ship.global_position.y / world_rect.size.y * map_size.y
		)
		var dot: ColorRect = ColorRect.new()
		var my_id: int = multiplayer.get_unique_id()
		if id == my_id:
			dot.color = Color.GREEN
		elif ship.is_bot:
			dot.color = Color.CORNFLOWER_BLUE
		else:
			dot.color = Color.RED
		dot.size = Vector2(6, 6)
		dot.position = map_pos - Vector2(3, 3)
		minimap.add_child(dot)

func update_hp(current: float, max_val: float) -> void:
	if hp_bar:
		hp_bar.max_value = max_val
		hp_bar.value = current
		hp_bar.modulate = Color(0.8, 0.2, 0.2, 1)  # Rojo
	if hp_label:
		hp_label.text = "HP: %d/%d" % [int(current), int(max_val)]

func update_shield(current: float, max_val: float) -> void:
	if shield_bar:
		shield_bar.max_value = max_val
		shield_bar.value = current
		shield_bar.modulate = Color(0.2, 0.5, 0.8, 1)  # Azul
	if shield_label:
		shield_label.text = "Escudo: %d/%d" % [int(current), int(max_val)]

func update_score(score: int) -> void:
	if score_label:
		score_label.text = "Puntos: " + str(score)

func update_player_count(count: int) -> void:
	if player_count_label:
		player_count_label.text = "Jugadores: " + str(count)

func update_upgrade_points(points: int) -> void:
	if points_label:
		points_label.text = "Mejoras: " + str(points)
	if points <= 0:
		_upgrade_menu_closed = false
		if upgrade_panel:
			upgrade_panel.visible = false
	elif not _upgrade_menu_closed:
		if upgrade_panel:
			upgrade_panel.visible = true
		_update_upgrade_buttons()

func close_upgrade_menu() -> void:
	_upgrade_menu_closed = true
	if upgrade_panel:
		upgrade_panel.visible = false

func reset_upgrade_closed() -> void:
	_upgrade_menu_closed = false

func _update_upgrade_buttons() -> void:
	var ship: Ship = world.get_local_ship() if world else null
	if not ship:
		return
	for btn_name in ["ShipBtn", "WeaponBtn", "ShieldBtn", "RadarBtn"]:
		var btn: Button = upgrade_panel.get_node_or_null("VBox/" + btn_name)
		if btn:
			match btn_name:
				"ShipBtn": btn.disabled = ship.ship_level >= 5
				"WeaponBtn": btn.disabled = ship.weapon_level >= 5
				"ShieldBtn": btn.disabled = ship.shield_level >= 5
				"RadarBtn": btn.disabled = ship.radar_level >= 5

func show_upgrade_menu(points: int) -> void:
	if upgrade_panel:
		upgrade_panel.visible = true
	update_upgrade_points(points)

func hide_upgrade_menu() -> void:
	if upgrade_panel:
		upgrade_panel.visible = false

func _on_ship_upgrade_pressed() -> void:
	if world:
		world.request_upgrade.rpc_id(1, "ship")
	hide_upgrade_menu()

func _on_weapon_upgrade_pressed() -> void:
	if world:
		world.request_upgrade.rpc_id(1, "weapon")
	hide_upgrade_menu()

func _on_shield_upgrade_pressed() -> void:
	if world:
		world.request_upgrade.rpc_id(1, "shield")
	hide_upgrade_menu()

func _on_radar_upgrade_pressed() -> void:
	if world:
		world.request_upgrade.rpc_id(1, "radar")
	hide_upgrade_menu()

func _on_close_upgrade_pressed() -> void:
	hide_upgrade_menu()

func show_tower_ui(show: bool) -> void:
	if tower_panel:
		tower_panel.visible = show

func _update_tower_ui() -> void:
	if not world or not world.tower_mode_node:
		return
	if not tower_panel or not tower_panel.visible:
		return
	var my_id: int = multiplayer.get_unique_id()
	var my_time: float = world.tower_mode_node.get_control_time(my_id)
	var controlling: bool = world.tower_mode_node.is_controlling(my_id)
	if tower_timer_label:
		tower_timer_label.text = "Tiempo: " + str(snapped(my_time, 0.1)) + "s / 60s"
	if tower_status_label:
		tower_status_label.text = "Control: SI" if controlling else "Control: NO"

func show_game_over(message: String) -> void:
	if game_over_panel:
		game_over_panel.visible = true
		var label: Label = game_over_panel.get_node_or_null("Label")
		if label:
			label.text = message

func _on_options_pressed() -> void:
	if world:
		var options_menu: Node = world.get_node_or_null("OptionsMenu")
		if options_menu:
			options_menu.show_menu()
