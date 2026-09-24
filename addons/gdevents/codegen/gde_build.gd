## Сборка листов событий. Используется и из редактора, и из CLI.
##
## Каждый res://**/*.gdes.json превращается в соседний .gd с тем же именем.
class_name GdeBuild
extends RefCounted

const SHEET_SUFFIX := ".gdes.json"


## debug = false — для экспорта без отладки: без строк «событие сработало».
static func build_all(root: String = "res://", debug: bool = true) -> Dictionary:
	var lines: Array[String] = []
	var reg := GdeRegistry.load_default()
	for e: String in reg.errors:
		lines.append(GdeI18n.t("  реестр: %s") % e)
	if not reg.behaviors.is_empty():
		lines.append(GdeI18n.t("Поведения: %s") % ", ".join(reg.behaviors.keys()))
	# Своя копия или своё поведение с ошибкой — листы соберутся, а объекты
	# в игре молча перестанут двигаться. Сказать об этом до запуска.
	for bn: String in reg.behaviors:
		var bp := str((reg.behaviors[bn] as Dictionary)["path"])
		if bp.begins_with(GdeBehaviorLibrary.USER_DIR + "/") and GdeBehaviorLibrary.is_broken(bp):
			lines.append(GdeI18n.t("  ! поведение «%s» (%s) не собирается — объекты с ним в игре не работают") % [bn, bp])

	var ok := 0
	var failed := 0
	for sheet_path: String in find_sheets(root):
		var r := build_one(sheet_path, reg, debug)
		lines.append_array(r["log"])
		if r["ok"]:
			ok += 1
		else:
			failed += 1
	return {"ok": ok, "failed": failed, "log": lines}


static func build_one(sheet_path: String, reg: GdeRegistry, debug: bool = true) -> Dictionary:
	var lines: Array[String] = []
	var f := FileAccess.open(sheet_path, FileAccess.READ)
	if f == null:
		return {"ok": false, "log": [GdeI18n.t("✗ %s: не открывается") % sheet_path]}
	var text := f.get_as_text()
	f.close()

	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		return {"ok": false, "log": [GdeI18n.t("✗ %s: некорректный JSON") % sheet_path]}

	var m := GdeSheetFormat.migrate(parsed)
	if str(m["error"]) != "":
		return {"ok": false, "log": ["✗ %s: %s" % [sheet_path, m["error"]]]}

	var res := GdeGenerator.generate(m["data"], reg, sheet_path, debug)
	var errors: Array = res["errors"]
	var warnings: Array = res["warnings"]

	for w: String in warnings:
		lines.append("  ! %s" % w)
	if not errors.is_empty():
		lines.append("✗ %s" % sheet_path)
		for e: String in errors:
			lines.append("    %s" % e)
		return {"ok": false, "log": lines}

	var code: String = res["code"]
	var compile_err := compile_error(code)
	if compile_err != "":
		lines.append("✗ %s" % sheet_path)
		lines.append(GdeI18n.t("    собранный GDScript не компилируется (%s) — это ошибка GDevents, а не листа; строка с ошибкой — выше в консоли")
				% compile_err)
		return {"ok": false, "log": lines}

	var out_path := sheet_path.substr(0, sheet_path.length() - SHEET_SUFFIX.length()) + ".gd"
	var out := FileAccess.open(out_path, FileAccess.WRITE)
	if out == null:
		lines.append(GdeI18n.t("✗ %s: не записывается %s") % [sheet_path, out_path])
		return {"ok": false, "log": lines}
	out.store_string(code)
	out.close()
	lines.append("✓ %s → %s" % [sheet_path.get_file(), out_path.get_file()])
	return {"ok": true, "log": lines}


## Скомпилировать собранный код, не записывая его. "" — всё в порядке.
##
## Генератор может ошибиться сам (так было с дробными переменными), и тогда
## «✓ собрано» врало бы, а игра падала на загрузке скрипта. Проверка нужна
## автозагрузке Gde: в редакторе и в запущенной сцене она есть, а при сборке
## через --script — нет, и там проверку пропускаем, чтобы не ругаться зря.
static func compile_error(code: String) -> String:
	if not _gde_visible():
		return ""
	var s := GDScript.new()
	s.source_code = code
	var err := s.reload()
	return "" if err == OK else error_string(err)


static func _gde_visible() -> bool:
	if Engine.is_editor_hint():
		return true
	var tree := Engine.get_main_loop() as SceneTree
	return tree != null and tree.root.has_node("Gde")


static func find_sheets(root: String) -> Array[String]:
	var out: Array[String] = []
	var d := DirAccess.open(root)
	if d == null:
		return out
	d.list_dir_begin()
	var name := d.get_next()
	while name != "":
		var full := root.path_join(name)
		if d.current_is_dir():
			if not name.begins_with(".") and name != "addons":
				out.append_array(find_sheets(full))
		elif name.ends_with(SHEET_SUFFIX):
			out.append(full)
		name = d.get_next()
	d.list_dir_end()
	return out
