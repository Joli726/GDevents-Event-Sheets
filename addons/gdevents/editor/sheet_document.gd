## Документ листа событий: данные в памяти, мутации, отмена и сохранение.
##
## События адресуются путём — массивом индексов: [3] это events[3],
## [3, 0] — первое подсобытие внутри него. Отмена сделана снимками целиком:
## листы маленькие, а так исключён целый класс багов с частичным откатом.
class_name GdeSheetDocument
extends RefCounted

signal changed
signal dirty_changed(is_dirty: bool)

const MAX_UNDO := 100

var path: String = ""
var data: Dictionary = {}

## Снимки хранятся глубокой копией, а не через JSON: круг через JSON
## превращал целые числа в дробные, и после отмены лист сохранялся уже другим.
var _undo: Array[Dictionary] = []
var _redo: Array[Dictionary] = []
var _dirty: bool = false


static func create_empty(name: String) -> GdeSheetDocument:
	var doc := GdeSheetDocument.new()
	doc.data = {
		"format": GdeSheetFormat.CURRENT,
		"name": name,
		"extends": "Node2D",
		"objects": [],
		"variables": {},
		"events": [],
	}
	return doc


func load_from(p: String) -> String:
	var f := FileAccess.open(p, FileAccess.READ)
	if f == null:
		return GdeI18n.t("не открывается %s") % p
	var text := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		return GdeI18n.t("некорректный JSON в %s") % p
	var m := GdeSheetFormat.migrate(parsed)
	if str(m["error"]) != "":
		return "%s: %s" % [p, m["error"]]
	path = p
	data = m["data"]
	_undo.clear()
	_redo.clear()
	# Лист старого формата обновлён в памяти — пусть автосохранение запишет
	# его уже новым, иначе обновление повторялось бы при каждом открытии.
	_set_dirty(int(m["from"]) < GdeSheetFormat.CURRENT)
	changed.emit()
	return ""


func save() -> String:
	if path.is_empty():
		return GdeI18n.t("у листа нет пути")
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return GdeI18n.t("не записывается %s") % path
	f.store_string(JSON.stringify(_normalize(data), "  ", false) + "\n")
	f.close()
	_set_dirty(false)
	return ""


## JSON в Godot читает любое число как float, и без этого простое открытие
## и сохранение листа превращало бы «score: 0» в «score: 0.0» и шумело в диффах.
static func _normalize(v: Variant) -> Variant:
	match typeof(v):
		TYPE_FLOAT:
			var f: float = v
			if is_equal_approx(f, roundf(f)) and absf(f) < 9.0e15:
				return int(roundf(f))
			return f
		TYPE_DICTIONARY:
			var d: Dictionary = {}
			for k: Variant in (v as Dictionary):
				d[k] = _normalize((v as Dictionary)[k])
			return d
		TYPE_ARRAY:
			var a: Array = []
			for x: Variant in (v as Array):
				a.append(_normalize(x))
			return a
		_:
			return v


func is_dirty() -> bool:
	return _dirty


func _set_dirty(v: bool) -> void:
	if _dirty != v:
		_dirty = v
		dirty_changed.emit(v)


# ----------------------------------------------------------- отмена/повтор ---

func _snapshot() -> void:
	_undo.append(data.duplicate(true))
	if _undo.size() > MAX_UNDO:
		_undo.pop_front()
	_redo.clear()


func can_undo() -> bool:
	return not _undo.is_empty()


func can_redo() -> bool:
	return not _redo.is_empty()


func undo() -> void:
	if _undo.is_empty():
		return
	_redo.append(data.duplicate(true))
	data = _undo.pop_back()
	_set_dirty(true)
	changed.emit()


func redo() -> void:
	if _redo.is_empty():
		return
	_undo.append(data.duplicate(true))
	data = _redo.pop_back()
	_set_dirty(true)
	changed.emit()


func _commit() -> void:
	_set_dirty(true)
	changed.emit()


# -------------------------------------------------------------- навигация ---

## Массив, в котором лежит событие по данному пути (events или children).
func container_of(p: Array) -> Array:
	var list: Array = data.get("events", [])
	for i in range(p.size() - 1):
		var e: Dictionary = list[p[i]]
		if not e.has("children"):
			e["children"] = []
		list = e["children"]
	return list


func event_at(p: Array) -> Variant:
	if p.is_empty():
		return null
	var list := container_of(p)
	var idx: int = p[p.size() - 1]
	if idx < 0 or idx >= list.size():
		return null
	return list[idx]


func instructions_of(p: Array, kind: String) -> Array:
	var e: Variant = event_at(p)
	if e == null:
		return []
	var d: Dictionary = e
	if not d.has(kind):
		d[kind] = []
	return d[kind]


## Является ли `inner` потомком `outer` (или им самим).
static func is_inside(inner: Array, outer: Array) -> bool:
	if inner.size() < outer.size():
		return false
	for i in range(outer.size()):
		if inner[i] != outer[i]:
			return false
	return true


# ---------------------------------------------------------------- события ---

func add_event(parent: Array, index: int, type: String = "standard") -> Array:
	_snapshot()
	var e: Dictionary = {"type": type}
	match type:
		"comment":
			e["text"] = GdeI18n.t("Комментарий")
		"group":
			e["name"] = GdeI18n.t("Группа")
			e["children"] = []
		"foreach":
			e["object"] = ""
			e["conditions"] = []
			e["actions"] = []
			e["children"] = []
		"repeat":
			e["count"] = "1"
			e["actions"] = []
			e["children"] = []
		_:
			e["conditions"] = []
			e["actions"] = []
			e["children"] = []

	var list: Array
	if parent.is_empty():
		if not data.has("events"):
			data["events"] = []
		list = data["events"]
	else:
		var pe: Variant = event_at(parent)
		if pe == null:
			_undo.pop_back()
			return []
		var ped: Dictionary = pe
		if not ped.has("children"):
			ped["children"] = []
		list = ped["children"]

	var at: int = clampi(index, 0, list.size())
	list.insert(at, e)
	_commit()
	return parent + [at]


## Вставить готовое событие — для вставки из буфера.
func insert_event(parent: Array, index: int, e: Dictionary) -> Array:
	_snapshot()
	var list: Array
	if parent.is_empty():
		if not data.has("events"):
			data["events"] = []
		list = data["events"]
	else:
		var pe: Variant = event_at(parent)
		if pe == null:
			_undo.pop_back()
			return []
		var ped: Dictionary = pe
		if not ped.has("children"):
			ped["children"] = []
		list = ped["children"]
	var at: int = clampi(index, 0, list.size())
	list.insert(at, e)
	_commit()
	return parent + [at]


func remove_event(p: Array) -> void:
	if event_at(p) == null:
		return
	_snapshot()
	container_of(p).remove_at(p[p.size() - 1])
	_commit()


func duplicate_event(p: Array) -> void:
	var e: Variant = event_at(p)
	if e == null:
		return
	_snapshot()
	var list := container_of(p)
	list.insert(p[p.size() - 1] + 1, (e as Dictionary).duplicate(true))
	_commit()


## Переместить событие. Возвращает новый путь или пустой массив при отказе.
func move_event(from: Array, to_parent: Array, to_index: int) -> Array:
	if event_at(from) == null:
		return []
	# Нельзя утащить событие внутрь самого себя.
	if is_inside(to_parent, from):
		return []
	_snapshot()
	var src := container_of(from)
	var src_idx: int = from[from.size() - 1]
	var e: Variant = src[src_idx]
	src.remove_at(src_idx)

	var dst: Array
	if to_parent.is_empty():
		dst = data["events"]
	else:
		# Путь назначения мог сдвинуться из-за изъятия события выше по списку.
		var adjusted := _adjust_after_removal(to_parent, from)
		var pe: Variant = event_at(adjusted)
		if pe == null:
			src.insert(src_idx, e)
			_redo.clear()
			_undo.pop_back()
			return []
		var ped: Dictionary = pe
		if not ped.has("children"):
			ped["children"] = []
		dst = ped["children"]
		to_parent = adjusted

	var at: int = clampi(to_index, 0, dst.size())
	if dst == src and src_idx < at:
		at -= 1
	dst.insert(at, e)
	_commit()
	return to_parent + [at]


## После удаления события по пути `removed` пути его бывших соседей снизу
## сдвигаются на единицу вверх.
static func _adjust_after_removal(p: Array, removed: Array) -> Array:
	var out := p.duplicate()
	var depth := removed.size() - 1
	if out.size() > depth:
		var same_branch := true
		for i in range(depth):
			if out[i] != removed[i]:
				same_branch = false
				break
		if same_branch and out[depth] > removed[depth]:
			out[depth] -= 1
	return out


func set_event_field(p: Array, key: String, value: Variant) -> void:
	var e: Variant = event_at(p)
	if e == null:
		return
	_snapshot()
	(e as Dictionary)[key] = value
	_commit()


## Убрать ключ совсем, а не ставить false: лист остаётся таким, каким
## был до включения, и в диффе не остаётся мусора.
func erase_event_field(p: Array, key: String) -> void:
	var e: Variant = event_at(p)
	if e == null or not (e as Dictionary).has(key):
		return
	_snapshot()
	(e as Dictionary).erase(key)
	_commit()


func toggle_disabled(p: Array) -> void:
	var e: Variant = event_at(p)
	if e == null:
		return
	_snapshot()
	var d: Dictionary = e
	d["disabled"] = not d.get("disabled", false)
	_commit()


# ------------------------------------------------------------- инструкции ---

func add_instruction(p: Array, kind: String, id: String, params: Array) -> void:
	var e: Variant = event_at(p)
	if e == null:
		return
	_snapshot()
	var d: Dictionary = e
	if not d.has(kind):
		d[kind] = []
	(d[kind] as Array).append({"id": id, "params": params})
	_commit()


## Вставить готовую строку — для вставки из буфера и перетаскивания.
func insert_instruction(p: Array, kind: String, index: int, inst: Dictionary) -> void:
	var e: Variant = event_at(p)
	if e == null:
		return
	_snapshot()
	var d: Dictionary = e
	if not d.has(kind):
		d[kind] = []
	var list: Array = d[kind]
	list.insert(clampi(index, 0, list.size()), inst)
	_commit()


func remove_instruction(p: Array, kind: String, index: int) -> void:
	var list := instructions_of(p, kind)
	if index < 0 or index >= list.size():
		return
	_snapshot()
	list.remove_at(index)
	_commit()


func set_instruction_params(p: Array, kind: String, index: int, params: Array) -> void:
	var list := instructions_of(p, kind)
	if index < 0 or index >= list.size():
		return
	_snapshot()
	(list[index] as Dictionary)["params"] = params
	_commit()


## Параметры и тумблеры строки за одну правку — и одну отмену.
## Выключенные тумблеры из JSON убираются, чтобы лист не шумел в диффах.
func set_instruction(p: Array, kind: String, index: int, params: Array, flags: Dictionary) -> void:
	var list := instructions_of(p, kind)
	if index < 0 or index >= list.size():
		return
	_snapshot()
	var d: Dictionary = list[index]
	d["params"] = params
	for key: String in ["inverted", "disabled"]:
		if bool(flags.get(key, false)):
			d[key] = true
		else:
			d.erase(key)
	_commit()


## Заменить строку целиком — в окне правки можно сменить и само условие.
func replace_instruction(p: Array, kind: String, index: int, inst: Dictionary) -> void:
	var list := instructions_of(p, kind)
	if index < 0 or index >= list.size():
		return
	_snapshot()
	list[index] = inst
	_commit()


func toggle_instruction_disabled(p: Array, kind: String, index: int) -> void:
	var list := instructions_of(p, kind)
	if index < 0 or index >= list.size():
		return
	_snapshot()
	var d: Dictionary = list[index]
	if d.get("disabled", false):
		d.erase("disabled")
	else:
		d["disabled"] = true
	_commit()


func toggle_instruction_inverted(p: Array, kind: String, index: int) -> void:
	var list := instructions_of(p, kind)
	if index < 0 or index >= list.size():
		return
	_snapshot()
	var d: Dictionary = list[index]
	d["inverted"] = not d.get("inverted", false)
	_commit()


func move_instruction(p: Array, kind: String, from_index: int, to_index: int) -> void:
	var list := instructions_of(p, kind)
	if from_index < 0 or from_index >= list.size():
		return
	_snapshot()
	var item: Variant = list[from_index]
	list.remove_at(from_index)
	list.insert(clampi(to_index if to_index <= from_index else to_index - 1, 0, list.size()), item)
	_commit()


# ----------------------------------------------------------------- объекты ---

func objects() -> Array:
	return data.get("objects", [])


func object_names() -> Array[String]:
	var out: Array[String] = []
	for o: Dictionary in objects():
		out.append(str(o.get("name", "")))
	for g: String in (data.get("groups", {}) as Dictionary):
		out.append(g)
	return out


func add_object(name: String, scene: String) -> void:
	_snapshot()
	if not data.has("objects"):
		data["objects"] = []
	(data["objects"] as Array).append({"name": name, "scene": scene})
	_commit()


func remove_object(index: int) -> void:
	var list: Array = data.get("objects", [])
	if index < 0 or index >= list.size():
		return
	_snapshot()
	list.remove_at(index)
	_commit()
