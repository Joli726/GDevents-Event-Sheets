## Листы из документации собираются: урок, руководство для авторов и README
## не должны расходиться с библиотекой.
##   godot --headless --quit-after 600 res://addons/gdevents/tools/docs_test.tscn
## Проверяются блоки ```json с ключом "format" — это целые листы. Сцена, а не
## --script: для проверки компиляции нужна автозагрузка Gde.
extends Node

const FILES := [
	"res://addons/gdevents/docs/TUTORIAL.md",
	"res://addons/gdevents/docs/TUTORIAL.ru.md",
	"res://addons/gdevents/docs/AUTHORING.md",
	"res://addons/gdevents/README.md",
	"res://addons/gdevents/README.ru.md",
]

var _fails: int = 0
var _checks: int = 0


func _ready() -> void:
	GdeI18n.set_language("ru", false)
	var reg := GdeRegistry.load_default()
	var found := 0
	for path: String in FILES:
		var text := FileAccess.get_file_as_string(path)
		var n := 0
		for block: String in _json_blocks(text):
			var parsed: Variant = JSON.parse_string(block)
			if not (parsed is Dictionary) or not (parsed as Dictionary).has("format"):
				continue
			n += 1
			found += 1
			var r := GdeGenerator.generate(parsed, reg, "res://docs_test.gdes.json")
			var errs: Array = r["errors"]
			_ok(errs.is_empty(), "%s, лист %d собирается%s" % [path.get_file(), n,
					"" if errs.is_empty() else ": " + "; ".join(PackedStringArray(errs))])
			if errs.is_empty():
				var ce := GdeBuild.compile_error(r["code"])
				_ok(ce.is_empty(), "%s, лист %d компилируется%s" % [path.get_file(), n, "" if ce.is_empty() else ": " + ce])
	_ok(found >= 3, "в документации найдено листов: %d" % found)
	print("—— проверок: %d, провалено: %d" % [_checks, _fails])
	get_tree().quit(1 if _fails > 0 else 0)


static func _json_blocks(text: String) -> Array[String]:
	var out: Array[String] = []
	var parts := text.split("```json\n")
	for i in range(1, parts.size()):
		var end := parts[i].find("\n```")
		if end >= 0:
			out.append(parts[i].substr(0, end))
	return out


func _ok(cond: bool, what: String) -> void:
	_checks += 1
	if cond:
		print("  ✓ %s" % what)
	else:
		_fails += 1
		print("  ✗ %s" % what)
