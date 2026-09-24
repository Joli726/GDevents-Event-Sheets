## Свои копии поведений и возврат к встроенным.
##
## Встроенное поведение в addons/ никогда не правится: это всегда целый,
## заведомо рабочий «дефолт», а обновление плагина не сотрёт чужих правок.
## Править можно копию. Она лежит в res://behaviors/<имя>/<имя>.gd — с тем же
## именем файла, а значит, с тем же именем поведения, — и заменяет встроенное
## во всём проекте: реестр берёт её вместо встроенного, а сцены объектов
## переключаются на её скрипт с сохранением всех настроек.
##
## Рядом с копией, в скрытой папке .gdevents, лежат встроенная версия на
## момент копирования и история версий — чтобы можно было откатиться.
## Скрытую папку не видят ни реестр, ни файловая система Godot, ни экспорт.
@tool
class_name GdeBehaviorLibrary
extends RefCounted

const USER_DIR := "res://behaviors"
const BUILTIN_DIR := "res://addons/gdevents/behaviors"
const META_DIR := ".gdevents"


# ------------------------------------------------------------------ что есть ---

## "builtin" — встроенное, "copy" — своя копия встроенного, "own" — своё
## поведение без встроенного прообраза.
static func kind_of(entry: Dictionary) -> String:
	var path := str(entry.get("path", ""))
	if path.begins_with(BUILTIN_DIR + "/"):
		return "builtin"
	if not str(entry.get("builtin_path", "")).is_empty():
		return "copy"
	return "own"


## Где лежит (или ляжет) копия встроенного поведения.
static func copy_path_for(builtin_path: String) -> String:
	return USER_DIR.path_join(builtin_path.get_base_dir().get_file()).path_join(builtin_path.get_file())


static func meta_dir_for(behavior_path: String) -> String:
	return behavior_path.get_base_dir().path_join(META_DIR)


## md5 исходника -> собирается ли он. Проверка компилирует скрипт, а
## вызывается на каждое обновление списка поведений.
static var _broken_cache: Dictionary = {}


## Скрипт не собирается — объекты с этим поведением в игре не работают.
## Смотрим на файл, а не на скрипт из кэша: тот не знает, что файл поправили.
static func is_broken(path: String) -> bool:
	if path.is_empty() or not FileAccess.file_exists(path):
		return false
	var src := FileAccess.get_file_as_string(path)
	var key := src.md5_text()
	if _broken_cache.has(key):
		return _broken_cache[key]
	var broken: bool
	if GdeBuild._gde_visible():
		broken = not GdeBuild.compile_error(src).is_empty()
	else:
		# Без автозагрузки Gde компилятор не поймёт ни одно поведение —
		# остаётся спросить загруженный скрипт.
		var s := ResourceLoader.load(path, "Script") as Script
		broken = s == null or not s.can_instantiate()
	_broken_cache[key] = broken
	return broken


## Сцены проекта, в которых стоит скрипт path. addons/ не трогаем: там
## тестовые сцены плагина.
static func scenes_using(path: String) -> Array[String]:
	var out: Array[String] = []
	var needle := "path=\"%s\"" % path
	for scene: String in project_scenes():
		if FileAccess.get_file_as_string(scene).contains(needle):
			out.append(scene)
	return out


static func project_scenes(root: String = "res://") -> Array[String]:
	var out: Array[String] = []
	var d := DirAccess.open(root)
	if d == null:
		return out
	d.list_dir_begin()
	var name := d.get_next()
	while name != "":
		var full := root.path_join(name)
		if d.current_is_dir():
			if not name.begins_with(".") and not (root == "res://" and name == "addons"):
				out.append_array(project_scenes(full))
		elif name.ends_with(".tscn"):
			out.append(full)
		name = d.get_next()
	d.list_dir_end()
	return out


# --------------------------------------------------------------- своя копия ---

## Сделать свою копию встроенного поведения и переключить на неё все сцены.
## {"error": String, "path": путь копии, "scenes": переключённые сцены}.
static func make_copy(bname: String, reg: GdeRegistry) -> Dictionary:
	var entry: Dictionary = reg.behaviors.get(bname, {})
	if entry.is_empty():
		return {"error": "поведения «%s» нет" % bname}
	if kind_of(entry) != "builtin":
		return {"error": "«%s» — уже не встроенное поведение, копировать нечего" % bname}
	var builtin := str(entry["path"])
	var dst := copy_path_for(builtin)
	if FileAccess.file_exists(dst):
		return {"error": "копия уже есть: %s" % dst}
	var src := FileAccess.get_file_as_string(builtin)
	if src.is_empty():
		return {"error": "не читается %s" % builtin}

	var err := _write(dst, src)
	if not err.is_empty():
		return {"error": err}
	var meta := meta_dir_for(dst)
	_write(meta.path_join("base.gd.txt"), src)
	_write_json(meta.path_join("copy.json"), {
		"behavior": bname,
		"builtin": builtin,
		"base_md5": src.md5_text(),
		"created": Time.get_datetime_string_from_system(false, true),
	})
	await _editor_register(dst)
	var sw := await switch_scripts(builtin, dst)
	return {"error": "; ".join(sw["errors"]), "path": dst, "scenes": sw["changed"]}


## Вернуть встроенное поведение. Копия не пропадает: она уходит в историю
## версий и оттуда восстанавливается.
static func reset_to_builtin(bname: String, reg: GdeRegistry) -> Dictionary:
	var entry: Dictionary = reg.behaviors.get(bname, {})
	if kind_of(entry) != "copy":
		return {"error": "у «%s» нет своей копии" % bname}
	var copy := str(entry["path"])
	var builtin := str(entry["builtin_path"])
	var src := FileAccess.get_file_as_string(copy)
	if not src.is_empty():
		save_version(copy, src, "Перед возвратом к встроенной")
	var sw := await switch_scripts(copy, builtin)
	if not (sw["errors"] as Array).is_empty():
		# Часть сцен не переключилась — удалять копию нельзя, они на ней.
		return {"error": "; ".join(sw["errors"]), "scenes": sw["changed"]}
	for p: String in [copy, copy + ".uid"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	_editor_scan()
	return {"error": "", "scenes": sw["changed"]}


## Новое поведение на основе существующего — с новым именем, чтобы, например,
## «Выстрел врага» жил отдельно от «Выстрела игрока».
static func create_from(bname: String, new_name: String, new_title: String,
		reg: GdeRegistry) -> Dictionary:
	var entry: Dictionary = reg.behaviors.get(bname, {})
	if entry.is_empty():
		return {"error": "поведения «%s» нет" % bname}
	var why := name_problem(new_name, reg)
	if not why.is_empty():
		return {"error": why}
	var file := snake(new_name)
	var dst := USER_DIR.path_join(file).path_join(file + ".gd")
	if FileAccess.file_exists(dst):
		return {"error": "файл уже есть: %s" % dst}
	var src := FileAccess.get_file_as_string(str(entry["path"]))
	src = _retag(src, new_name, new_title if not new_title.strip_edges().is_empty() else new_name)
	var err := _write(dst, src)
	if not err.is_empty():
		return {"error": err}
	await _editor_register(dst)
	return {"error": "", "path": dst, "name": new_name}


## Имя нового поведения: латиница с большой буквы, и именно такое, какое
## рантайм выведет из имени файла (EnemyShoot <-> enemy_shoot.gd).
static func name_problem(new_name: String, reg: GdeRegistry) -> String:
	var re := RegEx.create_from_string("^[A-Z][A-Za-z0-9]*$")
	if re.search(new_name) == null:
		return "имя поведения — латиницей с большой буквы, без пробелов: например EnemyShoot"
	if GdeBehaviorInstaller.pascal(snake(new_name)) != new_name:
		return "имя «%s» не восстанавливается из имени файла — уберите подряд идущие заглавные" % new_name
	if reg.behaviors.has(new_name):
		return "поведение «%s» уже есть" % new_name
	return ""


## EnemyShoot -> enemy_shoot
static func snake(pascal_name: String) -> String:
	var out := ""
	for i in range(pascal_name.length()):
		var c := pascal_name[i]
		if i > 0 and c >= "A" and c <= "Z":
			out += "_"
		out += c.to_lower()
	return out


## Сменить имя и заголовок в шапке скрипта поведения.
static func _retag(src: String, new_name: String, new_title: String) -> String:
	var lines := src.split("\n")
	var has_behavior := false
	var has_title := false
	for i in range(lines.size()):
		var l := lines[i]
		if l.strip_edges().begins_with("## @behavior"):
			lines[i] = "## @behavior %s" % new_name
			has_behavior = true
		elif l.strip_edges().begins_with("## @title"):
			lines[i] = "## @title %s" % new_title
			has_title = true
	var out := "\n".join(lines)
	if not has_title:
		out = "## @title %s\n%s" % [new_title, out]
	if not has_behavior:
		out = "## @behavior %s\n%s" % [new_name, out]
	return out


# ------------------------------------------------------- переключение сцен ---

## Во всех сценах проекта заменить скрипт поведения from_path на to_path,
## сохранив значения настроек. {"changed": [...], "errors": [...]}.
static func switch_scripts(from_path: String, to_path: String) -> Dictionary:
	var changed: Array[String] = []
	var errors: Array[String] = []
	# REPLACE: копию могли удалить и создать заново — старый скрипт из кэша
	# с устаревшим исходником тут не годится.
	var to := ResourceLoader.load(to_path, "Script", ResourceLoader.CACHE_MODE_REPLACE) as Script
	if to == null:
		return {"changed": changed, "errors": ["не загружается %s" % to_path]}
	for scene: String in scenes_using(from_path):
		var err: String = await GdeBehaviorInstaller.modify(scene, func(root: Node) -> String:
			return "" if _swap(root, root, from_path, to) > 0 else "—")
		if err == "—":
			continue
		if err.is_empty():
			changed.append(scene)
		else:
			errors.append("%s: %s" % [scene, err])
	GdeBehaviorInstaller.invalidate()
	return {"changed": changed, "errors": errors}


static func _swap(n: Node, root: Node, from_path: String, to: Script) -> int:
	var count := 0
	# Узлы вложенных сцен принадлежат своему файлу — их правит он сам.
	if n == root or n.owner == root:
		var s := n.get_script() as Script
		if s != null and s.resource_path == from_path:
			var vals := GdeBehaviorInstaller._script_values(n)
			n.set_script(to)
			for k: String in vals:
				if k in n:
					n.set(k, vals[k])
			count += 1
	for c: Node in n.get_children():
		count += _swap(c, root, from_path, to)
	return count


# ------------------------------------------------------------------ версии ---

## Запомнить версию исходника поведения. Возвращает путь снимка.
static func save_version(behavior_path: String, source: String, title: String) -> String:
	var dir := meta_dir_for(behavior_path).path_join("versions")
	var stamp := Time.get_datetime_string_from_system(false, false).replace(":", "-").replace("T", "_")
	var file := dir.path_join("%s_%d.gd.txt" % [stamp, Time.get_ticks_usec() % 1000000])
	_write(file, source)
	var index_path := dir.path_join("index.json")
	var index: Array = _read_json(index_path, [])
	index.append({
		"file": file.get_file(),
		"title": title,
		"time": Time.get_datetime_string_from_system(false, true),
		"md5": source.md5_text(),
	})
	_write_json(index_path, index)
	return file


## Версии, новые сверху: [{"file", "path", "title", "time", "md5"}].
static func list_versions(behavior_path: String) -> Array:
	var dir := meta_dir_for(behavior_path).path_join("versions")
	var index: Array = _read_json(dir.path_join("index.json"), [])
	var out: Array = []
	for v: Variant in index:
		if v is Dictionary:
			var d: Dictionary = (v as Dictionary).duplicate()
			d["path"] = dir.path_join(str(d.get("file", "")))
			if FileAccess.file_exists(str(d["path"])):
				out.push_front(d)
	return out


# ---------------------------------------------------------------- файлы ---

static func _write(path: String, text: String) -> String:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return "не записывается %s" % path
	f.store_string(text)
	f.close()
	return ""


static func _write_json(path: String, data: Variant) -> void:
	_write(path, JSON.stringify(data, "\t"))


static func _read_json(path: String, fallback: Variant) -> Variant:
	if not FileAccess.file_exists(path):
		return fallback
	var v: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return v if typeof(v) == typeof(fallback) else fallback


static func _editor_fs() -> Object:
	if not Engine.is_editor_hint() or not Engine.has_singleton("EditorInterface"):
		return null
	return (Engine.get_singleton("EditorInterface") as Object).call("get_resource_filesystem")


## Новый скрипт — редактору, и дождаться, пока тот его увидит и выдаст uid.
## Иначе сохранение открытой сцены, которая уже ссылается на скрипт, ругается
## на неизвестный файл, а ссылка ложится без uid.
static func _editor_register(path: String) -> void:
	var fs := _editor_fs()
	if fs == null:
		return
	fs.call("scan")
	var loop := Engine.get_main_loop() as SceneTree
	var waited := 0
	while loop != null and waited < 600 and (bool(fs.call("is_scanning")) \
			or ResourceLoader.get_resource_uid(path) == ResourceUID.INVALID_ID):
		await loop.process_frame
		waited += 1


static func _editor_scan() -> void:
	var fs := _editor_fs()
	if fs != null:
		fs.call("scan")
