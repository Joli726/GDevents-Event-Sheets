## Собрать тестовые листы плагина.
##
## Листы внутри addons обычная сборка нарочно не трогает — чтобы они не
## появлялись в проекте пользователя. Здесь собираем их явно.
## Запуск: godot --headless --script res://addons/gdevents/tools/build_tests.gd
extends SceneTree

const SHEETS := ["res://addons/gdevents/tests/selftest.gdes.json"]


func _init() -> void:
	var reg := GdeRegistry.load_default()
	for e: String in reg.errors:
		print("реестр: ", e)
	var failed := 0
	for s: String in SHEETS:
		var res := GdeBuild.build_one(s, reg)
		for line: String in res["log"]:
			print(line)
		if not res["ok"]:
			failed += 1
	if failed > 0:
		print("СБОРКА ТЕСТОВ ПРОВАЛЕНА: ", failed)
	quit(1 if failed > 0 else 0)
