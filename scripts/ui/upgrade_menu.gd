extends CanvasLayer

var world: Node2D

@onready var panel: PanelContainer = $Panel
@onready var ship_btn: Button = $Panel/VBox/ShipBtn
@onready var weapon_btn: Button = $Panel/VBox/WeaponBtn
@onready var shield_btn: Button = $Panel/VBox/ShieldBtn
@onready var radar_btn: Button = $Panel/VBox/RadarBtn
@onready var ship_level_label: Label = $Panel/VBox/ShipLevel
@onready var weapon_level_label: Label = $Panel/VBox/WeaponLevel
@onready var shield_level_label: Label = $Panel/VBox/ShieldLevel
@onready var radar_level_label: Label = $Panel/VBox/RadarLevel
@onready var title_label: Label = $Panel/VBox/Title

func setup(world_ref: Node2D) -> void:
	world = world_ref

func _ready() -> void:
	if ship_btn:
		ship_btn.pressed.connect(_on_upgrade.bind("ship"))
	if weapon_btn:
		weapon_btn.pressed.connect(_on_upgrade.bind("weapon"))
	if shield_btn:
		shield_btn.pressed.connect(_on_upgrade.bind("shield"))
	if radar_btn:
		radar_btn.pressed.connect(_on_upgrade.bind("radar"))
	hide_menu()

func show_menu(points: int) -> void:
	if panel:
		panel.visible = true
	update_display(points)

func hide_menu() -> void:
	if panel:
		panel.visible = false

func update_display(points: int) -> void:
	var ship: Ship = world.get_local_ship() if world else null
	if ship:
		if ship_level_label:
			ship_level_label.text = "Barco: " + str(ship.ship_level)
		if weapon_level_label:
			weapon_level_label.text = "Arma: " + str(ship.weapon_level)
		if shield_level_label:
			shield_level_label.text = "Escudo: " + str(ship.shield_level)
		if radar_level_label:
			radar_level_label.text = "Radar: " + str(ship.radar_level)
		if ship_btn:
			ship_btn.disabled = ship.ship_level >= 5 or points <= 0
		if weapon_btn:
			weapon_btn.disabled = ship.weapon_level >= 5 or points <= 0
		if shield_btn:
			shield_btn.disabled = ship.shield_level >= 5 or points <= 0
		if radar_btn:
			radar_btn.disabled = ship.radar_level >= 5 or points <= 0

func _on_upgrade(type: String) -> void:
	if world:
		world.request_upgrade.rpc_id(1, type)
	hide_menu()

func _input(event: InputEvent) -> void:
	if panel and panel.visible:
		if event.is_action_pressed("ui_cancel"):
			hide_menu()
