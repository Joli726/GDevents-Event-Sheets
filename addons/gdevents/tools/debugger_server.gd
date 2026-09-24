## Вместо редактора в тесте отладчика: принимает соединение игры, запущенной
## с --remote-debug, и печатает снимки GDevents, которые она присылает.
##   godot --headless --script res://addons/gdevents/tools/debugger_server.gd -- <порт> <секунд>
## Протокол отладчика Godot — те же пакеты, что StreamPeer.put_var: длина и
## Variant, а в нём [имя сообщения, поток, данные].
extends SceneTree

var _server := TCPServer.new()
var _peer: StreamPeerTCP = null
var _deadline: int = 0
var _states: int = 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var port := int(args[0]) if args.size() > 0 else 6010
	_deadline = Time.get_ticks_msec() + int(float(args[1]) * 1000.0 if args.size() > 1 else 20000.0)
	if _server.listen(port, "127.0.0.1") != OK:
		print("GDE_DBG_LISTEN_FAILED")
		quit(1)
		return
	print("GDE_DBG_LISTENING %d" % port)


func _process(_delta: float) -> bool:
	if _peer == null and _server.is_connection_available():
		_peer = _server.take_connection()
		print("GDE_DBG_CONNECTED")
	if _peer != null:
		_peer.poll()
		while _peer.get_status() == StreamPeerTCP.STATUS_CONNECTED and _peer.get_available_bytes() > 4:
			var msg: Variant = _peer.get_var()
			if msg is Array and (msg as Array).size() >= 3 and str(msg[0]) == "gdevents:state":
				_states += 1
				var data: Array = msg[2]
				print("GDE_DBG_STATE ", JSON.stringify(data[0]))
		if _peer.get_status() != StreamPeerTCP.STATUS_CONNECTED and _states > 0:
			print("GDE_DBG_DONE %d" % _states)
			quit(0)
			return true
	if Time.get_ticks_msec() > _deadline:
		print("GDE_DBG_TIMEOUT %d" % _states)
		quit(0 if _states > 0 else 1)
		return true
	return false
