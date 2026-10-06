extends Node

const PORT: int = 7777

var is_host: bool = false
var local_nickname: String = ""
var local_peer_id: int = 1
var players_data: Dictionary = {}
var selected_map: int = 0
var selected_mode: int = 0

signal player_joined(peer_id: int, nickname: String)
signal player_left(peer_id: int)
signal connection_failed()
signal connected_to_server()

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)

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
	player_joined.emit(sender_id, nickname)
	for peer_id in players_data:
		if peer_id != sender_id:
			rpc_id(peer_id, "add_player", sender_id, nickname)
	rpc_id(sender_id, "sync_all_players", players_data)

@rpc("authority", "reliable", "call_local")
func add_player(peer_id: int, nickname: String) -> void:
	players_data[peer_id] = {"nickname": nickname}
	player_joined.emit(peer_id, nickname)

@rpc("authority", "reliable", "call_local")
func sync_all_players(data: Dictionary) -> void:
	players_data = data

func _on_peer_connected(id: int) -> void:
	if not is_host:
		return

func _on_peer_disconnected(id: int) -> void:
	players_data.erase(id)
	player_left.emit(id)

func _on_connected_to_server() -> void:
	connected_to_server.emit()

func _on_connection_failed() -> void:
	connection_failed.emit()

func is_connected_to_server() -> bool:
	return multiplayer.multiplayer_peer != null and multiplayer.get_peers().size() > 0

func get_player_count() -> int:
	return players_data.size()
