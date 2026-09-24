## Привязка листа событий к сцене.
##
## Сгенерированный .gd сам по себе не исполняется — его нужно повесить
## на ноду в сцене. Пока это делалось вручную, самый частый исход был
## «собрал, запустил, ничего не происходит».
##
## Лист привязывается дочерней нодой Node2D, а не скриптом на корне:
## корень часто уже занят своим скриптом, и затирать его нельзя.
@tool
class_name GdeSheetBinder
extends RefCounted

const NODE_PREFIX := "События_"


## Сцены, в которых этот лист уже используется.
static func users(script_path: String) -> Array[String]:
	var out: Array[String] = []
	_scan("res://", script_path, out)
	return out


static func _scan(dir_path: String, script_path: String, out: Array[String]) -> void:
	var d := DirAccess.open(dir_path)
	if d == null:
		return
	d.list_dir_begin()
	var name := d.get_next()
	while name != "":
		var full := dir_path.path_join(name)
		if d.current_is_dir():
			if not name.begins_with("."):
				_scan(full, script_path, out)
		elif name.ends_with(".tscn"):
			var f := FileAccess.open(full, FileAccess.READ)
			if f != null:
				if f.get_as_text().contains("\"%s\"" % script_path):
					out.append(full)
				f.close()
		name = d.get_next()
	d.list_dir_end()


static func node_name_for(sheet_path: String) -> String:
	return NODE_PREFIX + sheet_path.get_file().trim_suffix(GdeBuild.SHEET_SUFFIX)


## Повесить лист на сцену. Пустая строка — успех, иначе текст ошибки.
static func attach(scene_path: String, script_path: String, sheet_path: String) -> String:
	var busy := _busy_reason(scene_path)
	if not busy.is_empty():
		return busy
	if not ResourceLoader.exists(script_path):
		return "Сначала нажмите «Собрать» — файл %s ещё не создан" % script_path.get_file()

	var ps: PackedScene = ResourceLoader.load(scene_path, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE)
	if ps == null:
		return "не открывается сцена %s" % scene_path
	var state := PackedScene.GEN_EDIT_STATE_MAIN if Engine.is_editor_hint() else PackedScene.GEN_EDIT_STATE_DISABLED
	var root := ps.instantiate(state)
	if root == null:
		return "не разворачивается сцена %s" % scene_path

	var scr: Script = load(script_path)
	if scr == null:
		root.free()
		return "не загружается %s" % script_path

	var wanted := node_name_for(sheet_path)
	for c: Node in root.get_children():
		var s := c.get_script() as Script
		if s != null and s.resource_path == script_path:
			root.free()
			return "Лист уже привязан к этой сцене (нода «%s»)" % c.name

	var node := Node2D.new()
	node.name = wanted
	node.set_script(scr)
	root.add_child(node)
	node.owner = root

	var packed := PackedScene.new()
	var err := packed.pack(root)
	if err != OK:
		root.free()
		return "не упаковывается сцена (код %d)" % err
	err = ResourceSaver.save(packed, scene_path)
	root.free()
	if err != OK:
		return "не сохраняется %s (код %d)" % [scene_path, err]
	return ""


static func _busy_reason(scene_path: String) -> String:
	if not Engine.is_editor_hint() or not Engine.has_singleton("EditorInterface"):
		return ""
	var ei: Object = Engine.get_singleton("EditorInterface")
	var open_scenes: Variant = ei.call("get_open_scenes")
	if open_scenes is PackedStringArray or open_scenes is Array:
		for s: String in open_scenes:
			if s == scene_path:
				return "Сцена %s открыта во вкладке — закройте её, иначе правки потеряются" \
						% scene_path.get_file()
	return ""
