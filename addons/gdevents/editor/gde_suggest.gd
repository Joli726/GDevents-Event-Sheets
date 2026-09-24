## Подсказки для полей параметров.
##
## Смысл простой: в поле «выражение» надо помнить, что бывает Player.X(),
## RandomInRange(a, b) и Variable(score). Держать это в голове незачем —
## редактор сам показывает, что подходит именно сюда: имена анимаций берутся
## из сцены объекта, файлы звуков — из проекта, выражения — из реестра.
@tool
class_name GdeSuggest
extends RefCounted

const KEYS := [
	"Space", "Enter", "Escape", "Tab", "Backspace", "Shift", "Ctrl", "Alt",
	"Left", "Right", "Up", "Down",
	"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M",
	"N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
	"0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
	"F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12",
]

const SOUND_EXT := ["ogg", "wav", "mp3"]

static var _files_cache: Dictionary = {}


## Список подсказок: [{"text": видимое, "insert": что подставить, "hint": пояснение}].
static func build(id: String, param_index: int, param_def: Dictionary,
		reg: GdeRegistry, doc: GdeSheetDocument, params: Array) -> Array:
	var kind := str(param_def.get("kind", "number"))
	var label := str(param_def.get("label", "")).to_lower()

	if kind == "raw" and (label.contains(GdeI18n.t("клавиш")) or id.begins_with("key.")):
		return _plain(KEYS, GdeI18n.t("клавиша"))
	if id.begins_with("input.") :
		return _plain(_input_actions(), GdeI18n.t("действие ввода из настроек проекта"))
	if id == "scene.change":
		return _plain(_files(["tscn"]), GdeI18n.t("сцена"))
	if id.begins_with("audio."):
		return _plain(_files(SOUND_EXT), GdeI18n.t("звуковой файл"))
	if id.contains("animation") and kind != "number":
		return _plain(_animations(doc, params), GdeI18n.t("анимация объекта"))

	if kind == "number" or kind == "string":
		return _expressions(reg, doc, _objects_in(params))
	return []


## Объекты, с которыми эта инструкция уже работает. Их выражения нужны
## почти всегда, так что им место в начале списка.
static func _objects_in(params: Array) -> Array[String]:
	var out: Array[String] = []
	for p: Variant in params:
		var s := str(p).strip_edges()
		if not s.is_empty() and not out.has(s):
			out.append(s)
	return out


# ------------------------------------------------------------- выражения ---

static func _expressions(reg: GdeRegistry, doc: GdeSheetDocument,
		prefer: Array[String] = []) -> Array:
	var out: Array = []
	if reg == null:
		return out

	var names: Array = doc.object_names() if doc != null else []
	# Сначала те, кто уже упомянут в этой же инструкции.
	var ordered: Array[String] = []
	for p: String in prefer:
		if names.has(p):
			ordered.append(p)
	for obj: Variant in names:
		if not ordered.has(str(obj)):
			ordered.append(str(obj))

	for o: String in ordered:
		for name: String in reg.object_expressions:
			var d: Dictionary = reg.object_expressions[name]
			out.append({
				"text": "%s.%s(%s)" % [o, name, _args(d)],
				"insert": "%s.%s(" % [o, name],
				"hint": str(d.get("description", GdeI18n.t("Выражение объекта"))),
			})
		for beh: String in _behaviors_of(doc, o):
			var b: Variant = reg.behaviors.get(beh)
			if b == null:
				continue
			var table: Dictionary = (b as Dictionary).get("expressions", {})
			for name: String in table:
				var d2: Dictionary = table[name]
				out.append({
					"text": "%s.%s::%s(%s)" % [o, beh, name, _args(d2)],
					"insert": "%s.%s::%s(" % [o, beh, name],
					"hint": str(d2.get("description", GdeI18n.t("Выражение поведения «%s»") % beh)),
				})

	if doc != null:
		for v: String in (doc.data.get("variables", {}) as Dictionary):
			out.append({
				"text": "Variable(%s)" % v,
				"insert": "Variable(%s)" % v,
				"hint": GdeI18n.t("Переменная сцены"),
			})

	for name: String in reg.expressions:
		var d: Dictionary = reg.expressions[name]
		out.append({
			"text": "%s(%s)" % [name, _args(d)],
			"insert": "%s(" % name,
			"hint": str(d.get("description", GdeI18n.t("Общее выражение"))),
		})
	for key: String in reg.ext_expressions:
		var e: Dictionary = reg.ext_expressions[key]
		out.append({
			"text": "%s(%s)" % [key, _args(e)],
			"insert": "%s(" % key,
			"hint": str(e.get("description", GdeI18n.t("Выражение расширения"))),
		})
	return out


static func _args(d: Dictionary) -> String:
	var params: Array = d.get("params", [])
	if params.is_empty():
		return ""
	var bits: Array[String] = []
	for i in range(params.size()):
		bits.append(str(params[i]))
	return ", ".join(bits)


static func _behaviors_of(doc: GdeSheetDocument, obj: String) -> Array[String]:
	if doc == null:
		return []
	for o: Dictionary in doc.objects():
		if str(o.get("name", "")) == obj:
			return GdeBehaviorInstaller.installed(str(o.get("scene", "")))
	return []


# --------------------------------------------------------------- ресурсы ---

static func _plain(items: Array, hint: String) -> Array:
	var out: Array = []
	for i: Variant in items:
		out.append({"text": str(i), "insert": str(i), "hint": hint})
	return out


## Имена анимаций из сцены объекта — чтобы не списывать их вручную
## и не ловить потом молчаливое «нет такой анимации».
static func _animations(doc: GdeSheetDocument, params: Array) -> Array[String]:
	var out: Array[String] = []
	if doc == null or params.is_empty():
		return out
	var obj := str(params[0])
	for o: Dictionary in doc.objects():
		if str(o.get("name", "")) != obj:
			continue
		var scene := str(o.get("scene", ""))
		if not ResourceLoader.exists(scene):
			return out
		var ps: PackedScene = load(scene)
		if ps == null:
			return out
		var root := ps.instantiate(PackedScene.GEN_EDIT_STATE_DISABLED)
		_collect_animations(root, out)
		root.free()
		return out
	return out


static func _collect_animations(n: Node, out: Array[String]) -> void:
	if n is AnimatedSprite2D:
		var fr := (n as AnimatedSprite2D).sprite_frames
		if fr != null:
			for a: StringName in fr.get_animation_names():
				if not out.has(String(a)):
					out.append(String(a))
	elif n is AnimationPlayer:
		for a: StringName in (n as AnimationPlayer).get_animation_list():
			if not out.has(String(a)):
				out.append(String(a))
	for c: Node in n.get_children():
		_collect_animations(c, out)


static func _input_actions() -> Array[String]:
	var out: Array[String] = []
	for a: StringName in InputMap.get_actions():
		out.append(String(a))
	out.sort()
	return out


static func _files(exts: Array) -> Array[String]:
	var key := ",".join(exts)
	if _files_cache.has(key):
		return _files_cache[key]
	var out: Array[String] = []
	_walk("res://", exts, out)
	out.sort()
	_files_cache[key] = out
	return out


static func _walk(dir_path: String, exts: Array, out: Array[String]) -> void:
	var d := DirAccess.open(dir_path)
	if d == null:
		return
	d.list_dir_begin()
	var name := d.get_next()
	while name != "":
		if name.begins_with("."):
			name = d.get_next()
			continue
		var full := dir_path.path_join(name)
		if d.current_is_dir():
			if name != "addons":
				_walk(full, exts, out)
		else:
			var e := name.get_extension().to_lower()
			if exts.has(e):
				out.append(full)
			elif e == "import" and exts.has(name.get_basename().get_extension().to_lower()):
				out.append(full.trim_suffix(".import"))
		name = d.get_next()
	d.list_dir_end()


static func invalidate() -> void:
	_files_cache.clear()
