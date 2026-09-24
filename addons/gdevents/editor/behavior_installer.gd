## Поведения внутри сцены объекта: найти, поставить, убрать.
##
## Три вещи, которые тут важны и которых не было раньше.
##
## 1. Поиск идёт по всему поддереву. Живая сцена почти никогда не плоская:
##    корень — Node2D, а CharacterBody2D с поведениями лежит внутри. Раньше
##    смотрели только прямых детей корня, и такой объект выглядел как
##    «поведений нет», хотя в сцене они были.
## 2. Открытую сцену закрывать не нужно. Если она сейчас в редакторе —
##    правим живое дерево и сохраняем через редактор, ничего не теряя.
## 3. Поведение приносит с собой каркас: узлы, без которых оно не работает
##    (тело, форма столкновения, спрайт), создаются сами.
@tool
class_name GdeBehaviorInstaller
extends RefCounted

## Метка на ноде поведения. Пишется в .tscn и переживает что угодно —
## перезагрузку плагина, ошибку в скрипте, переименование ноды.
const META_KEY := "gde_behavior"
## Узлы, которые поведение создало само при добавлении (пути от корня сцены).
## По ним снятие поведения убирает и его каркас.
const CREATED_KEY := "gde_created"

## Кэш разбора сцен: путь -> {"stamp": int, "list": Array}.
static var _scan_cache: Dictionary = {}
## Кэш «имя поведения по скрипту»: путь скрипта -> имя или "".
static var _script_names: Dictionary = {}


# -------------------------------------------------------------------- поиск ---

## Поведения объекта: [{"name": String, "node": String, "script": String}].
## node — путь ноды от корня сцены, для подсказок в интерфейсе.
static func scan(scene_path: String) -> Array:
	if scene_path.is_empty():
		return []
	var live := _live_root(scene_path)
	if live != null:
		return _collect(live, live)

	var stamp := _stamp(scene_path)
	var cached: Dictionary = _scan_cache.get(scene_path, {})
	if int(cached.get("stamp", -1)) == stamp:
		return cached["list"]

	var root := _open(scene_path)
	if root == null:
		return []
	var list := _collect(root, root)
	root.free()
	_scan_cache[scene_path] = {"stamp": stamp, "list": list}
	return list


## Только имена — этого хватает большинству вызовов.
static func installed(scene_path: String) -> Array[String]:
	var out: Array[String] = []
	for e: Dictionary in scan(scene_path):
		out.append(str(e["name"]))
	return out


static func invalidate(scene_path: String = "") -> void:
	if scene_path.is_empty():
		_scan_cache.clear()
		_script_names.clear()
	else:
		_scan_cache.erase(scene_path)


static func _collect(n: Node, root: Node) -> Array:
	var out: Array = []
	for c: Node in n.get_children():
		var bname := behavior_name_of(c)
		if not bname.is_empty():
			var scr := c.get_script() as Script
			out.append({
				"name": bname,
				"node": String(root.get_path_to(c)),
				"script": scr.resource_path if scr != null else "",
			})
		out.append_array(_collect(c, root))
	return out


## Имя поведения ноды или пустая строка.
##
## Порядок проверок — от надёжного к запасному. Метка стоит в .tscn и не
## зависит ни от того, загрузился ли скрипт, ни от того, компилируется ли
## сейчас GdeBehavior. Именно из-за отсутствия такой метки поведения
## «пропадали» из списка после перезагрузки плагина.
static func behavior_name_of(n: Node) -> String:
	if n.has_meta(META_KEY):
		return str(n.get_meta(META_KEY))
	var s := n.get_script() as Script
	if s == null:
		return ""
	return name_of_script(s)


## Имя поведения по его скрипту. Результат кэшируется: разбор исходника
## стоит дорого, а вызывается это на каждый узел каждой сцены.
static func name_of_script(s: Script) -> String:
	var key := s.resource_path
	if not key.is_empty() and _script_names.has(key):
		return _script_names[key]
	var src := s.get_source_code()
	if src.is_empty() and not key.is_empty():
		# Скрипт мог прийти из кэша без исходника — читаем файл сами.
		var f := FileAccess.open(key, FileAccess.READ)
		if f != null:
			src = f.get_as_text()
			f.close()
	var out := ""
	if src.contains("extends GdeBehavior"):
		var re := RegEx.create_from_string("^\\s*##\\s*@behavior\\s+(.+)$")
		for line: String in src.split("\n"):
			var m := re.search(line)
			if m != null:
				out = m.get_string(1).strip_edges()
				break
		if out.is_empty() and not key.is_empty():
			out = pascal(key.get_file().get_basename())
	if not key.is_empty():
		_script_names[key] = out
	return out


# ---------------------------------------------------------------- установка ---

## Поставить поведение. Возвращает {"error": String, "created": Array[String]}.
## spec — описание каркаса из реестра: {"target": "CharacterBody2D",
## "needs": [{"type": "CollisionShape2D", "name": "Форма"}]}.
static func add(scene_path: String, bname: String, script_path: String,
		spec: Dictionary = {}) -> Dictionary:
	var scr: Script = load(script_path)
	if scr == null:
		return {"error": GdeI18n.t("не загружается скрипт %s") % script_path, "created": []}

	var session := await _begin(scene_path)
	var root: Node = session.get("root")
	if root == null:
		return {"error": str(session.get("error", GdeI18n.t("не открывается сцена"))), "created": []}

	for e: Dictionary in _collect(root, root):
		if str(e["name"]) == bname:
			_abort(session)
			return {"error": GdeI18n.t("поведение «%s» уже есть у этого объекта") % bname, "created": []}

	var built := _scaffold(root, spec)
	var host: Node = built["host"]

	var node := Node.new()
	node.name = _unique_name(host, bname)
	node.set_script(scr)
	node.set_meta(META_KEY, bname)
	host.add_child(node)
	node.owner = root
	var made: Array = built["nodes"]
	if not made.is_empty():
		var paths: Array[String] = []
		for m: Node in made:
			paths.append(String(root.get_path_to(m)))
		node.set_meta(CREATED_KEY, paths)

	var err := await _commit(session)
	invalidate(scene_path)
	return {"error": err, "created": built["created"]}


static func remove(scene_path: String, bname: String, reg: GdeRegistry = null) -> String:
	return str((await remove_with_scaffold(scene_path, bname, reg))["error"])


## Снять поведение вместе с узлами, которые оно само создало при добавлении.
## Каркас уходит целиком или остаётся целиком: остаётся, если в него
## положили что-то своё (узел вручную, другое поведение) или каким-то его
## узлом пользуется другое поведение объекта — например, спрайтом
## платформера пользуется «Сочность». Половина каркаса хуже любого из двух:
## тело без формы падает сквозь пол. Поведения, поставленные до того,
## как появилась эта запись, снимаются по-старому, без каркаса.
## {"error": String, "removed": Array[String] — имена удалённых узлов}
static func remove_with_scaffold(scene_path: String, bname: String, reg: GdeRegistry = null) -> Dictionary:
	var session := await _begin(scene_path)
	var root: Node = session.get("root")
	if root == null:
		return {"error": str(session.get("error", GdeI18n.t("не открывается сцена"))), "removed": []}

	var target: Node = _find_behavior(root, bname)
	if target == null:
		_abort(session)
		return {"error": GdeI18n.t("поведения «%s» на объекте нет") % bname, "removed": []}

	var candidates: Array[Node] = []
	for p: Variant in target.get_meta(CREATED_KEY, []):
		var n := root.get_node_or_null(NodePath(str(p)))
		if n != null and n != root and n != target and not candidates.has(n):
			candidates.append(n)

	var host := target.get_parent()
	host.remove_child(target)
	target.queue_free()

	var removed: Array[String] = []
	if not candidates.is_empty() and _scaffold_free(root, bname, candidates, reg):
		# Удаляем верхние узлы каркаса — вложенные уходят вместе с ними.
		for n2: Node in candidates:
			if _has_ancestor_in(n2, candidates):
				continue
			removed.append(str(n2.name))
		for n3: Node in candidates:
			if not _has_ancestor_in(n3, candidates) and is_instance_valid(n3):
				n3.get_parent().remove_child(n3)
				n3.queue_free()

	var err := await _commit(session)
	invalidate(scene_path)
	return {"error": err, "removed": removed}


## Можно ли убрать каркас: внутри только его узлы, и другим поведениям
## объекта ни один из них не нужен.
static func _scaffold_free(root: Node, bname: String, ours: Array[Node], reg: GdeRegistry) -> bool:
	for n: Node in ours:
		for c: Node in n.get_children():
			if not ours.has(c):
				return false
	for e: Dictionary in _collect(root, root):
		var other := str(e["name"])
		if other == bname:
			continue
		var node := root.get_node_or_null(NodePath(str(e["node"])))
		if node == null:
			continue
		var h := node.get_parent()
		# Поведение живёт внутри каркаса (его тело — наше тело).
		if ours.has(h) or _has_ancestor_in(h, ours):
			return false
		if reg == null or not reg.behaviors.has(other):
			continue
		var bd: Dictionary = reg.behaviors[other]
		for nd: Variant in bd.get("needs", []):
			if not (nd is Dictionary):
				continue
			for a: Variant in (nd as Dictionary).get("any", [(nd as Dictionary).get("type", "")]):
				var used: Node = h if h.is_class(str(a)) else _find_class(h, str(a))
				if used != null and (ours.has(used) or _has_ancestor_in(used, ours)):
					return false
	return true


static func _has_ancestor_in(n: Node, set: Array[Node]) -> bool:
	var p := n.get_parent()
	while p != null:
		if set.has(p):
			return true
		p = p.get_parent()
	return false


static func _find_behavior(n: Node, bname: String) -> Node:
	for c: Node in n.get_children():
		if behavior_name_of(c) == bname:
			return c
		var r := _find_behavior(c, bname)
		if r != null:
			return r
	return null


static func _unique_name(parent: Node, want: String) -> String:
	if parent.get_node_or_null(NodePath(want)) == null:
		return want
	var i := 2
	while parent.get_node_or_null(NodePath("%s%d" % [want, i])) != null:
		i += 1
	return "%s%d" % [want, i]


# ------------------------------------------------------------------ каркас ---

## Достроить сцену до того, что поведению нужно для работы.
## Возвращает {"host": Node, "created": Array[String]}.
static func _scaffold(root: Node, spec: Dictionary) -> Dictionary:
	var created: Array[String] = []
	var nodes: Array[Node] = []
	var target := str(spec.get("target", ""))
	var host := root

	if not target.is_empty():
		var found := root if root.is_class(target) else _find_class(root, target)
		if found != null:
			host = found
		else:
			# Самый частый сценарий — «создал пустую сцену, кинул поведение».
			# Корень менять нельзя (редактор держит на него ссылку), поэтому
			# нужное тело появляется внутри корня. Событиям это не мешает:
			# Gde.main() сам находит тело и считает позицию по нему.
			var made := _make(target)
			if made != null:
				host = made
				host.name = _unique_name(root, target)
				root.add_child(host)
				host.owner = root
				created.append("%s (%s)" % [host.name, target])
				nodes.append(host)

	for need: Variant in spec.get("needs", []):
		var nd: Dictionary = need
		var cls := str(nd.get("type", ""))
		if cls.is_empty():
			continue
		var alts: Array = nd.get("any", [cls])
		# Форма столкновения работает только внутри тела или области: у
		# «Урона при касании» раньше форма ложилась рядом с только что
		# созданной Area2D, и шипы никого не били.
		var parent := host
		var is_shape := cls == "CollisionShape2D" or cls == "CollisionPolygon2D"
		if is_shape:
			var body: Node = host if host is CollisionObject2D else _find_class(host, "CollisionObject2D")
			if body != null:
				parent = body
		var already := false
		for a: Variant in alts:
			if is_shape:
				if _has_child_of(parent, str(a)):
					already = true
					break
			elif host.is_class(str(a)) or _find_class(host, str(a)) != null:
				already = true
				break
		if already:
			continue
		var child := _make(cls)
		if child == null:
			continue
		child.name = _unique_name(parent, str(nd.get("name", cls)))
		parent.add_child(child)
		child.owner = root
		created.append("%s (%s)" % [child.name, cls])
		nodes.append(child)

	return {"host": host, "created": created, "nodes": nodes}


static func _has_child_of(n: Node, cls: String) -> bool:
	for c: Node in n.get_children():
		if c.is_class(cls):
			return true
	return false


static func _find_class(n: Node, cls: String) -> Node:
	for c: Node in n.get_children():
		if c.is_class(cls):
			return c
	for c: Node in n.get_children():
		var r := _find_class(c, cls)
		if r != null:
			return r
	return null


## Новый узел с настройками, при которых он сразу работает, а не молчит.
## Пустой CollisionShape2D бесполезен, пустой AnimatedSprite2D — тоже.
static func _make(cls: String) -> Node:
	if not ClassDB.class_exists(cls) or not ClassDB.can_instantiate(cls):
		return null
	var n: Node = ClassDB.instantiate(cls)
	match cls:
		"CollisionShape2D":
			var rect := RectangleShape2D.new()
			rect.size = Vector2(32, 32)
			(n as CollisionShape2D).shape = rect
		"AnimatedSprite2D":
			(n as AnimatedSprite2D).sprite_frames = SpriteFrames.new()
		"Label":
			(n as Label).text = GdeI18n.t("Текст")
		"Camera2D":
			(n as Camera2D).enabled = true
	return n


# ------------------------------------------------------------------ сессия ---
#
# Правка сцены идёт либо по живому дереву в редакторе, либо по файлу на диске.
# _begin/_commit прячут эту разницу от вызывающего кода.

static func _begin(scene_path: String) -> Dictionary:
	if not ResourceLoader.exists(scene_path):
		return {"error": GdeI18n.t("сцена %s не найдена") % scene_path}

	var ei := _editor()
	if ei != null and _is_open(ei, scene_path):
		var switched_from := ""
		var cur: Node = ei.call("get_edited_scene_root")
		if cur == null or cur.scene_file_path != scene_path:
			if cur != null:
				switched_from = cur.scene_file_path
			ei.call("open_scene_from_path", scene_path)
			await _idle()
			await _idle()
			cur = ei.call("get_edited_scene_root")
		if cur != null and cur.scene_file_path == scene_path:
			return {"root": cur, "live": true, "path": scene_path, "back": switched_from}

	var root := _open(scene_path)
	if root == null:
		return {"error": GdeI18n.t("не открывается сцена %s") % scene_path}
	return {"root": root, "live": false, "path": scene_path}


static func _commit(session: Dictionary) -> String:
	var root: Node = session["root"]
	var path := str(session["path"])
	if not bool(session.get("live", false)):
		var packed := PackedScene.new()
		var err := packed.pack(root)
		if err != OK:
			root.free()
			return GdeI18n.t("не упаковывается сцена (код %d)") % err
		err = ResourceSaver.save(packed, path)
		root.free()
		return "" if err == OK else GdeI18n.t("не сохраняется %s (код %d)") % [path, err]

	var ei := _editor()
	if ei == null:
		return GdeI18n.t("редактор недоступен")
	ei.call("mark_scene_as_unsaved")
	var err: int = ei.call("save_scene")
	if err != OK:
		return GdeI18n.t("не сохраняется открытая сцена (код %d)") % err
	var back := str(session.get("back", ""))
	if not back.is_empty():
		ei.call("open_scene_from_path", back)
	return ""


static func _abort(session: Dictionary) -> void:
	if not bool(session.get("live", false)):
		var root: Node = session.get("root")
		if root != null:
			root.free()


static func _idle() -> void:
	var loop := Engine.get_main_loop()
	if loop is SceneTree:
		await (loop as SceneTree).process_frame


# --------------------------------------------------------- общий доступ ---

## Прочитать сцену и что-то из неё извлечь. Если сцена открыта во вкладке —
## читаем живое дерево (с несохранёнными правками), иначе копию с диска,
## которую тут же освобождаем. fn получает корень и возвращает что угодно.
static func read(scene_path: String, fn: Callable) -> Variant:
	var live := _live_root(scene_path)
	var root := live if live != null else _open(scene_path)
	if root == null:
		return null
	var out: Variant = fn.call(root)
	if live == null:
		root.free()
	return out


## Изменить сцену. fn получает корень и возвращает текст ошибки или "".
## Открытую вкладку правим вживую и сохраняем через редактор, закрытую —
## на диске. Закрывать сцену ради правки не нужно.
static func modify(scene_path: String, fn: Callable) -> String:
	var session := await _begin(scene_path)
	var root: Node = session.get("root")
	if root == null:
		return str(session.get("error", GdeI18n.t("не открывается сцена")))
	var err := str(fn.call(root))
	if not err.is_empty():
		_abort(session)
		return err
	err = await _commit(session)
	invalidate(scene_path)
	return err


# ---------------------------------------------------------------- свойства ---

## Значения @export-свойств поведения на объекте.
static func properties(scene_path: String, bname: String) -> Dictionary:
	var out: Dictionary = {}
	var live := _live_root(scene_path)
	var root := live if live != null else _open(scene_path)
	if root == null:
		return out
	var node := _find_behavior(root, bname)
	if node != null:
		for p: Dictionary in node.get_property_list():
			var usage := int(p.get("usage", 0))
			if (usage & PROPERTY_USAGE_SCRIPT_VARIABLE) != 0 \
					and (usage & PROPERTY_USAGE_EDITOR) != 0:
				out[str(p["name"])] = node.get(str(p["name"]))
	if live == null:
		root.free()
	return out


static func set_property(scene_path: String, bname: String, prop: String, value: Variant) -> String:
	return await edit_behavior(scene_path, bname, func(node: Node) -> String:
		node.set(prop, value)
		return "")


## Всё, что нужно окну настроек поведения:
## {"node": путь узла от корня, "script": путь скрипта,
##  "props": [{"name", "type", "hint", "hint_string", "group", "value", "default"}],
##  "animations": имена анимаций сцены — для настроек вида *_animation}.
## Порядок props — как в исходнике поведения. Пустой словарь — поведения нет.
static func describe(scene_path: String, bname: String) -> Dictionary:
	var out: Variant = read(scene_path, func(root: Node) -> Variant:
		var node := _find_behavior(root, bname)
		if node == null:
			return {}
		var scr := node.get_script() as Script
		var props: Array = []
		var group := ""
		for p: Dictionary in node.get_property_list():
			var usage := int(p.get("usage", 0))
			if (usage & PROPERTY_USAGE_CATEGORY) != 0:
				group = ""
				continue
			if (usage & PROPERTY_USAGE_GROUP) != 0:
				group = str(p["name"])
				continue
			if (usage & PROPERTY_USAGE_SCRIPT_VARIABLE) == 0 or (usage & PROPERTY_USAGE_EDITOR) == 0:
				continue
			var nm := str(p["name"])
			props.append({
				"name": nm,
				"type": int(p.get("type", TYPE_NIL)),
				"hint": int(p.get("hint", PROPERTY_HINT_NONE)),
				"hint_string": str(p.get("hint_string", "")),
				"group": group,
				"value": node.get(nm),
				"default": scr.get_property_default_value(nm) if scr != null else null,
			})
		return {
			"node": String(root.get_path_to(node)),
			"script": scr.resource_path if scr != null else "",
			"props": props,
			"animations": GdeSceneCheck._sprite_frames(root),
		})
	return out if out is Dictionary else {}


## Изменить поведение на объекте. fn получает узел поведения и возвращает
## текст ошибки или "". В открытой вкладке правка ложится в историю
## редактора — Ctrl+Z в сцене отменит и её.
static func edit_behavior(scene_path: String, bname: String, fn: Callable) -> String:
	var session := await _begin(scene_path)
	var root: Node = session.get("root")
	if root == null:
		return str(session.get("error", GdeI18n.t("не открывается сцена")))
	var node := _find_behavior(root, bname)
	if node == null:
		_abort(session)
		return GdeI18n.t("поведения «%s» на объекте нет") % bname
	var live := bool(session.get("live", false))
	var before := _script_values(node)
	var err := str(fn.call(node))
	if not err.is_empty():
		if live:
			for k: String in before:
				node.set(k, before[k])
		_abort(session)
		return err
	if live:
		_record_undo(node, bname, before, _script_values(node))
	err = await _commit(session)
	invalidate(scene_path)
	return err


static func _script_values(node: Node) -> Dictionary:
	var out: Dictionary = {}
	for p: Dictionary in node.get_property_list():
		var usage := int(p.get("usage", 0))
		if (usage & PROPERTY_USAGE_SCRIPT_VARIABLE) != 0 and (usage & PROPERTY_USAGE_STORAGE) != 0:
			out[str(p["name"])] = node.get(str(p["name"]))
	return out


## Уже применённую правку — в историю редактора, не применяя повторно.
static func _record_undo(node: Node, bname: String, before: Dictionary, after: Dictionary) -> void:
	var ei := _editor()
	if ei == null or not ei.has_method("get_editor_undo_redo"):
		return
	var ur: Object = ei.call("get_editor_undo_redo")
	if ur == null:
		return
	var changed: Array[String] = []
	for k: String in after:
		if not before.has(k) or typeof(before[k]) != typeof(after[k]) or before[k] != after[k]:
			changed.append(k)
	if changed.is_empty():
		return
	ur.call("create_action", GdeI18n.t("Настройки поведения «%s»") % bname, UndoRedo.MERGE_DISABLE, node)
	for k: String in changed:
		ur.call("add_do_property", node, k, after[k])
		ur.call("add_undo_property", node, k, before.get(k))
	ur.call("commit_action", false)


# ------------------------------------------------------------- вспомогательное ---

static func _editor() -> Object:
	if not Engine.is_editor_hint() or not Engine.has_singleton("EditorInterface"):
		return null
	return Engine.get_singleton("EditorInterface")


static func _is_open(ei: Object, scene_path: String) -> bool:
	var open: Variant = ei.call("get_open_scenes")
	if open is PackedStringArray or open is Array:
		for s: String in open:
			if s == scene_path:
				return true
	return false


## Корень сцены, если она прямо сейчас открыта во вкладке редактора.
static func _live_root(scene_path: String) -> Node:
	var ei := _editor()
	if ei == null:
		return null
	var root: Node = ei.call("get_edited_scene_root")
	if root != null and root.scene_file_path == scene_path:
		return root
	return null


static func _open(scene_path: String) -> Node:
	if not ResourceLoader.exists(scene_path):
		return null
	var ps: PackedScene = ResourceLoader.load(scene_path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE)
	if ps == null:
		return null
	var state := PackedScene.GEN_EDIT_STATE_MAIN if Engine.is_editor_hint() \
			else PackedScene.GEN_EDIT_STATE_DISABLED
	return ps.instantiate(state)


static func _stamp(path: String) -> int:
	return int(FileAccess.get_modified_time(path))


static func pascal(s: String) -> String:
	var out := ""
	for part: String in s.split("_", false):
		if not part.is_empty():
			out += part.substr(0, 1).to_upper() + part.substr(1)
	return out
