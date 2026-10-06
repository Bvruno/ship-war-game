extends Node

const PORT: int = 7777

var is_host: bool = false
var local_nickname: String = ""
var local_peer_id: int = 1
var players_data: Dictionary = {}

signal player_joined(peer_id: int, nickname: String)
signal player_left(peer_id: int)

func start_host(nickname: String) -> void:
	is_host = true
	local_nickname = nickname
	local_peer_id = 1
	players_data[1] = {"nickname": nickname}

func start_client(nickname: String) -> void:
	is_host = false
	local_nickname = nickname
	_register_to_host()

func _register_to_host() -> void:
	rpc_id(1, "register_player", local_nickname)

@rpc("any_peer", "reliable", "call_local")
func register_player(nickname: String) -> void:
	var sender_id: int = multiplayer.get_remote_sender_id()
	players_data[sender_id] = {"nickname": nickname}
	for peer_id in players_data:
		rpc("sync_players", players_data)

@rpc("authority", "reliable", "call_local")
func sync_players(data: Dictionary) -> void:
	players_data = data

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func _on_peer_connected(id: int) -> void:
	if not is_host:
		return

func _on_peer_disconnected(id: int) -> void:
	players_data.erase(id)
	player_left.emit(id)

func is_connected_to_server() -> bool:
	return multiplayer.multiplayer_peer != null
