extends Node

signal status_changed(message: String)
signal opponent_updated(progress: float, lane: float, speed: float, display_name: String)
var socket := WebSocketPeer.new()
var connected := false
var player_name := "Driver"
var server_url := ""
var room_id := ""

func connect_to_server(url: String, display_name: String) -> void:
	server_url = url
	player_name = display_name.left(18)
	var err := socket.connect_to_url(url)
	if err != OK:
		status_changed.emit("Unable to connect: %s" % error_string(err))
		return
	status_changed.emit("Connecting to race server…")

func _process(_delta: float) -> void:
	socket.poll()
	match socket.get_ready_state():
		WebSocketPeer.STATE_OPEN:
			if not connected:
				connected = true
				socket.send_text(JSON.stringify({"type":"join", "name":player_name}))
				status_changed.emit("Searching for opponent…")
			while socket.get_available_packet_count() > 0:
				var parsed = JSON.parse_string(socket.get_packet().get_string_from_utf8())
				if parsed is Dictionary: _handle_message(parsed)
		WebSocketPeer.STATE_CLOSED:
			if connected:
				connected = false
				status_changed.emit("Disconnected from race server")

func _handle_message(data: Dictionary) -> void:
	match str(data.get("type", "")):
		"waiting": status_changed.emit("Waiting for another driver…")
		"matched":
			room_id = str(data.get("roomId", ""))
			status_changed.emit("Matched: %s" % str(data.get("opponentName", "Rival")))
		"state": opponent_updated.emit(float(data.get("progress", 0)), float(data.get("lane", 0)), float(data.get("speed", 0)), "Opponent")
		"opponent_left": status_changed.emit("Opponent left the race")
		"opponent_finished": status_changed.emit("Opponent finished")

func send_state(progress: float, lane: float, speed: float) -> void:
	if connected and socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		socket.send_text(JSON.stringify({"type":"state", "progress":progress, "lane":lane, "speed":speed}))

func send_finish() -> void:
	if connected: socket.send_text(JSON.stringify({"type":"finish"}))

func disconnect_from_server() -> void:
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		socket.send_text(JSON.stringify({"type":"leave"}))
		socket.close()
	connected = false
