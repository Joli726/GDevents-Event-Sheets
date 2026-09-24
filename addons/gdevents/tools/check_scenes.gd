## Проверить сцены всех объектов всех листов проекта и напечатать находки.
## godot --headless res://addons/gdevents/tools/check_scenes.tscn
##
## Именно сценой, а не через --script: без автозагрузки Gde скрипты
## поведений не компилируются, и проверка вышла бы ложно-чистой.
extends Node


func _ready() -> void:
	var reg := GdeRegistry.load_default()
	var total := 0
	for sheet: String in GdeBuild.find_sheets("res://"):
		var doc := GdeSheetDocument.new()
		if not doc.load_from(sheet).is_empty():
			continue
		print("== %s" % sheet)
		for o: Dictionary in doc.objects():
			var scene := str(o.get("scene", ""))
			var list := GdeSceneCheck.check(scene, reg, doc.object_names())
			if list.is_empty():
				print("  %s — в порядке" % o["name"])
				continue
			print("  %s (%s):" % [o["name"], scene])
			for it: Dictionary in list:
				total += 1
				var fixes: Array[String] = []
				for f: Dictionary in it["fixes"]:
					fixes.append(str(f["label"]))
				print("    [%s] %s" % ["ОШИБКА" if it["level"] == "error" else "внимание", it["text"]])
				if not fixes.is_empty():
					print("        исправить: %s" % " | ".join(fixes))
	print("—— находок: %d" % total)
	get_tree().quit()
