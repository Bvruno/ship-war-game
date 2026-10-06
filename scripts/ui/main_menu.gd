extends Control

@onready var nickname_input: LineEdit = $VBoxContainer/NicknameInput
@onready var create_game_btn: Button = $VBoxContainer/CreateGameBtn
@onready var join_game_btn: Button = $VBoxContainer/JoinGameBtn
@onready var ip_input: LineEdit = $VBoxContainer/IPInput
@onready var status_label: Label = $StatusLabel

func _ready() -> void:
	create_game_btn.pressed.connect(_on_create_game)
	join_game_btn.pressed.connect(_on_join_game)
	var saved_name: String = _load_nickname()
	if saved_name != "":
		nickname_input.text = saved_name

func _on_create_game() -> void:
	var nickname: String = nickname_input.text.strip_edges()
	if nickname.is_empty():
		status_label.text = "Enter a nickname!"
		return
	_save_nickname(nickname)
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var err: Error = peer.create_server(MultiplayerManager.PORT, GameData.MAX_PLAYERS)
	if err != OK:
		status_label.text = "Failed to create server"
		return
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	status_label.text = "Waiting for players..."
	MultiplayerManager.start_host(nickname)
	get_tree().change_scene_to_file("res://scenes/game/world.tscn")

func _on_join_game() -> void:
	var nickname: String = nickname_input.text.strip_edges()
	var ip: String = ip_input.text.strip_edges()
	if nickname.is_empty():
		status_label.text = "Enter a nickname!"
		return
	if ip.is_empty():
		status_label.text = "Enter host IP!"
		return
	_save_nickname(nickname)
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var err: Error = peer.create_client(ip, MultiplayerManager.PORT)
	if err != OK:
		status_label.text = "Failed to connect"
		return
	multiplayer.multiplayer_peer = peer
	MultiplayerManager.start_client(nickname)
	status_label.text = "Connecting..."
	get_tree().change_scene_to_file("res://scenes/game/world.tscn")

func _save_nickname(name: String) -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("player", "nickname", name)
	config.save("user://player.cfg")

func _load_nickname() -> String:
	var config: ConfigFile = ConfigFile.new()
	if config.load("user://player.cfg") == OK:
		return config.get_value("player", "nickname", "")
	return ""
