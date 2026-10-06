extends CanvasLayer

signal game_cancel_requested

@onready var panel: PanelContainer = $Panel
@onready var resume_btn: Button = $Panel/VBox/ResumeBtn
@onready var music_slider: HSlider = $Panel/VBox/MusicSlider
@onready var sfx_slider: HSlider = $Panel/VBox/SFXSlider
@onready var accept_game_btn: Button = $Panel/VBox/AcceptGameBtn
@onready var cancel_game_btn: Button = $Panel/VBox/CancelGameBtn
@onready var exit_btn: Button = $Panel/VBox/ExitBtn
@onready var bot_count_label: Label = $Panel/VBox/BotCountLabel
@onready var bot_slider: HSlider = $Panel/VBox/BotSlider
@onready var add_bot_btn: Button = $Panel/VBox/AddBotBtn
@onready var remove_bot_btn: Button = $Panel/VBox/RemoveBotBtn

var is_visible: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if panel:
		panel.visible = false
	if resume_btn:
		resume_btn.pressed.connect(_on_resume)
	if music_slider:
		music_slider.value_changed.connect(_on_music_changed)
	if sfx_slider:
		sfx_slider.value_changed.connect(_on_sfx_changed)
	if accept_game_btn:
		accept_game_btn.pressed.connect(_on_accept_game)
	if cancel_game_btn:
		cancel_game_btn.pressed.connect(_on_cancel_game)
	if exit_btn:
		exit_btn.pressed.connect(_on_exit)
	if bot_slider:
		bot_slider.value_changed.connect(_on_bot_slider_changed)
	if add_bot_btn:
		add_bot_btn.pressed.connect(_on_add_bot)
	if remove_bot_btn:
		remove_bot_btn.pressed.connect(_on_remove_bot)

func show_menu() -> void:
	if panel:
		panel.visible = true
	is_visible = true
	get_tree().paused = true
	_update_bot_ui()

func hide_menu() -> void:
	if panel:
		panel.visible = false
	is_visible = false
	get_tree().paused = false

func _update_bot_ui() -> void:
	var world: Node = get_parent()
	if not world or not world.has_method("_get_bot_count"):
		return
	var count: int = world._get_bot_count()
	if bot_count_label:
		bot_count_label.text = "Bots: " + str(count)
	if bot_slider:
		bot_slider.value = count

func _on_resume() -> void:
	hide_menu()

func _on_music_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value / 100.0))

func _on_sfx_changed(value: float) -> void:
	pass

func _on_accept_game() -> void:
	hide_menu()

func _on_cancel_game() -> void:
	hide_menu()
	game_cancel_requested.emit()

func _on_exit() -> void:
	get_tree().quit()

func _on_bot_slider_changed(value: float) -> void:
	var world: Node = get_parent()
	if not world:
		return
	var target_count: int = int(value)
	var current_count: int = world._get_bot_count()
	if target_count > current_count:
		for i in range(target_count - current_count):
			world.add_bot(world._get_avg_player_level())
	elif target_count < current_count:
		for i in range(current_count - target_count):
			var last_bot_id: int = world.bots.keys().back()
			world.remove_bot(last_bot_id)
	_update_bot_ui()

func _on_add_bot() -> void:
	var world: Node = get_parent()
	if world:
		world.add_bot(world._get_avg_player_level())
	_update_bot_ui()

func _on_remove_bot() -> void:
	var world: Node = get_parent()
	if world and not world.bots.is_empty():
		var last_bot_id: int = world.bots.keys().back()
		world.remove_bot(last_bot_id)
	_update_bot_ui()
