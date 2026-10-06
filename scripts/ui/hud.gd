extends CanvasLayer

var world: Node2D

@onready var hp_bar: ProgressBar = $MarginContainer/VBoxContainer/HPBar
@onready var shield_bar: ProgressBar = $MarginContainer/VBoxContainer/ShieldBar
@onready var cooldown_bar: ProgressBar = $MarginContainer/VBoxContainer/CooldownBar
@onready var score_label: Label = $MarginContainer/VBoxContainer/ScoreLabel
@onready var player_count_label: Label = $MarginContainer/VBoxContainer/PlayerCountLabel
@onready var minimap: Control = $MinimapPanel/Minimap
@onready var upgrade_button: Button = $UpgradeButton

func setup(world_ref: Node2D) -> void:
	world = world_ref

func _process(_delta: float) -> void:
	if world:
		var ship: Ship = world.get_local_ship()
		if ship:
			cooldown_bar.value = 1.0 - ship.get_cooldown_ratio()

func update_hp(current: float, max_val: float) -> void:
	if hp_bar:
		hp_bar.max_value = max_val
		hp_bar.value = current

func update_shield(current: float, max_val: float) -> void:
	if shield_bar:
		shield_bar.max_value = max_val
		shield_bar.value = current

func update_score(score: int) -> void:
	if score_label:
		score_label.text = "Score: " + str(score)

func update_player_count(count: int) -> void:
	if player_count_label:
		player_count_label.text = "Players: " + str(count)

func show_upgrade_menu(points: int) -> void:
	if upgrade_button:
		upgrade_button.visible = true
		upgrade_button.text = "Upgrade (" + str(points) + ")"

func hide_upgrade_menu() -> void:
	if upgrade_button:
		upgrade_button.visible = false

func _on_upgrade_button_pressed() -> void:
	hide_upgrade_menu()
