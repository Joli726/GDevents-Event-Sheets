## Отладчик событий: связь запущенной игры с редактором.
##
## Игра, запущенная из редактора, десять раз в секунду присылает сработавшие
## события и значения переменных (GdeRuntime.debug_snapshot). Панель листа
## подсвечивает сработавшие события, а во вкладке «GDevents» отладчика Godot
## видно переменные сцены и глобальные — живыми, во время игры.
@tool
class_name GdeDebuggerPlugin
extends EditorDebuggerPlugin

const PREFIX := "gdevents"

## Панель листа событий — ей уходят сработавшие события.
var panel: Node = null
var _views: Dictionary = {}


func _has_capture(prefix: String) -> bool:
	return prefix == PREFIX


func _capture(message: String, data: Array, session_id: int) -> bool:
	if message != PREFIX + ":state" or data.is_empty() or not (data[0] is Dictionary):
		return false
	var st: Dictionary = data[0]
	if is_instance_valid(panel) and panel.has_method("show_debug_state"):
		panel.call("show_debug_state", st)
	var view: Variant = _views.get(session_id)
	if is_instance_valid(view):
		(view as GdeDebugView).show_state(st)
	return true


func _setup_session(session_id: int) -> void:
	var view := GdeDebugView.new()
	view.name = "GDevents"
	var session := get_session(session_id)
	session.add_session_tab(view)
	_views[session_id] = view
	session.stopped.connect(func():
		if is_instance_valid(panel) and panel.has_method("clear_debug"):
			panel.call("clear_debug"))
