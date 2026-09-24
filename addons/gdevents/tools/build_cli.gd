## Сборка из командной строки:
##   godot --headless --script res://addons/gdevents/tools/build_cli.gd
extends SceneTree


func _initialize() -> void:
	var report := GdeBuild.build_all()
	for line: String in report["log"]:
		print(line)
	print("—— собрано: %d, ошибок: %d" % [report["ok"], report["failed"]])
	quit(1 if report["failed"] > 0 else 0)
