## Сборка листов событий. Используется и из редактора, и из CLI.
##
## Каждый res://**/*.gdes.json превращается в соседний .gd с тем же именем.
class_name GdeBuild
extends RefCounted

const SHEET_SUFFIX := ".gdes.json"


static func build_all(root: String = "res://") -> Dictionary:
	var lines: Array[String] = []
	var reg := GdeRegistry.load_default()
	for e: String in reg.errors:
		lines.append("  реестр: %s" % e)
	if not reg.behaviors.is_empty():
		lines.append("Поведения: %s" % ", ".join(reg.behaviors.keys()))

	var ok := 0
	var failed := 0
	for sheet_path: String in find_sheets(root):
		var r := build_one(sheet_path, reg)
		lines.append_array(r["log"])
		if r["ok"]:
			ok += 1
		else:
			failed += 1
	return {"ok": ok, "failed": failed, "log": lines}


static func build_one(sheet_path: String, reg: GdeRegistry) -> Dictionary:
	var lines: Array[String] = []
	var f := FileAccess.open(sheet_path, FileAccess.READ)
	if f == null:
		return {"ok": false, "log": ["✗ %s: не открывается" % sheet_path]}
	var text := f.get_as_text()
	f.close()

	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		return {"ok": false, "log": ["✗ %s: некорректный JSON" % sheet_path]}

	var res := GdeGenerator.generate(parsed, reg, sheet_path)
	var errors: Array = res["errors"]
	var warnings: Array = res["warnings"]

	for w: String in warnings:
		lines.append("  ! %s" % w)
	if not errors.is_empty():
		lines.append("✗ %s" % sheet_path)
		for e: String in errors:
			lines.append("    %s" % e)
		return {"ok": false, "log": lines}

	var out_path := sheet_path.substr(0, sheet_path.length() - SHEET_SUFFIX.length()) + ".gd"
	var out := FileAccess.open(out_path, FileAccess.WRITE)
	if out == null:
		lines.append("✗ %s: не записывается %s" % [sheet_path, out_path])
		return {"ok": false, "log": lines}
	out.store_string(res["code"])
	out.close()
	lines.append("✓ %s → %s" % [sheet_path.get_file(), out_path.get_file()])
	return {"ok": true, "log": lines}


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
