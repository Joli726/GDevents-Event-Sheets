## Показать, как библиотека выглядит глазами пользователя: фразы и описания.
## Запуск: godot --headless --script res://addons/gdevents/tools/registry_dump.gd
extends SceneTree


func _init() -> void:
	var reg := GdeRegistry.load_default()
	for e: String in reg.errors:
		print("ОШИБКА РЕЕСТРА: ", e)

	print("== встроенные: условий %d, действий %d, выражений %d + %d"
			% [reg.conditions.size(), reg.actions.size(),
			reg.expressions.size(), reg.object_expressions.size()])

	var no_desc: Array[String] = []
	for table: Dictionary in [reg.conditions, reg.actions]:
		for id: String in table:
			if str((table[id] as Dictionary).get("description", "")).is_empty():
				no_desc.append(id)
	print("== без описания: ", ", ".join(no_desc) if not no_desc.is_empty() else "нет")

	for bname: String in reg.behaviors:
		var b: Dictionary = reg.behaviors[bname]
		print("\n== %s → «%s»  цель: %s  каркас: %s"
				% [bname, b["title"], b["target"] if str(b["target"]) != "" else "любая нода",
				_needs(b["needs"])])
		for table_name: String in ["conditions", "actions"]:
			var t: Dictionary = b[table_name]
			var shown := 0
			for id: String in t:
				var d: Dictionary = t[id]
				if int(d.get("weight", 0)) == 0:
					continue
				shown += 1
				if shown > 3:
					continue
				print("   %s" % GdeText.with_labels(d, "Player"))
				print("      %s" % d.get("description", ""))
			print("   … всего %s: %d" % [table_name, t.size()])
	quit()


func _needs(list: Array) -> String:
	if list.is_empty():
		return "—"
	var out: Array[String] = []
	for n: Variant in list:
		out.append("%s «%s»" % [(n as Dictionary)["type"], (n as Dictionary)["name"]])
	return ", ".join(out)
