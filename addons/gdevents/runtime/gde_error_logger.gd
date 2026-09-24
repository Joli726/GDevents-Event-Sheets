## Ошибка во время игры — с указанием события листа.
##
## Godot показывает ошибку строкой собранного .gd, а человек работает с
## листом и этого файла не видел. Собранный скрипт несёт карту GDE_EVENTS
## «строка → событие»; этот журнал ловит ошибку, ищет в её стеке строку
## собранного листа и дописывает под ней: «это событие 5 листа level:
## ЕСЛИ Клавиша Left нажата».
class_name GdeErrorLogger
extends Logger

## Последнее сообщение — для тестов.
var last_message: String = ""

var _mutex := Mutex.new()
var _busy: bool = false
## Одну и ту же ошибку в каждом кадре не повторять.
var _seen: Dictionary = {}
## Файл -> карта событий или [] (не лист).
var _maps: Dictionary = {}


func _log_error(_function: String, file: String, line: int, _code: String, _rationale: String,
		_editor_notify: bool, _error_type: int, script_backtraces: Array[ScriptBacktrace]) -> void:
	_mutex.lock()
	if _busy:
		_mutex.unlock()
		return
	_busy = true
	_mutex.unlock()

	var hit := locate(file, line)
	if hit.is_empty():
		for bt: ScriptBacktrace in script_backtraces:
			for i in range(bt.get_frame_count()):
				hit = locate(bt.get_frame_file(i), bt.get_frame_line(i))
				if not hit.is_empty():
					break
			if not hit.is_empty():
				break
	if not hit.is_empty():
		var key := "%s:%d" % [hit["sheet"], hit["line"]]
		if not _seen.has(key):
			_seen[key] = true
			last_message = GdeI18n.t("GDevents: ошибка выше — в событии %s листа %s: %s") % [
					hit["event"], hit["sheet"], hit["what"]]
			printerr(last_message)

	_mutex.lock()
	_busy = false
	_mutex.unlock()


## Событие листа для строки собранного скрипта или {} — не лист.
## {"sheet", "event", "what", "line"}
func locate(file: String, line: int) -> Dictionary:
	if not file.ends_with(".gd") or line <= 0:
		return {}
	var map: Array = _map_of(file)
	var best: Array = []
	for entry: Array in map:
		if int(entry[0]) <= line:
			best = entry
		else:
			break
	if best.is_empty():
		return {}
	return {"sheet": str(_sheet_of(file)), "event": str(best[1]), "what": str(best[2]), "line": line}


func _map_of(file: String) -> Array:
	if _maps.has(file):
		return _maps[file]
	var out: Array = []
	if ResourceLoader.exists(file):
		var s := ResourceLoader.load(file, "", ResourceLoader.CACHE_MODE_REUSE) as Script
		if s != null:
			var consts := s.get_script_constant_map()
			if consts.get("GDE_EVENTS") is Array:
				out = consts["GDE_EVENTS"]
	_maps[file] = out
	return out


func _sheet_of(file: String) -> String:
	var s := ResourceLoader.load(file, "", ResourceLoader.CACHE_MODE_REUSE) as Script
	if s != null:
		return str(s.get_script_constant_map().get("GDE_SHEET", file))
	return file
