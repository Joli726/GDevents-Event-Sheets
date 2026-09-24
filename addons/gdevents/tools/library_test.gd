## Безголовый тест всей библиотеки инструкций:
##   godot --headless res://addons/gdevents/tools/library_test.tscn
##
## Каждое условие (и с «НЕ»), каждое действие и каждое выражение — встроенные,
## из поведений и из расширений — собирается в отдельный лист, компилируется и дважды
## выполняется на живом объекте со всеми поведениями разом. Руками столько не
## перепроверить, а поломки тут тихие: так нашлись условия, которые всегда
## были «false», «Удалить все», ломавшее скрипт, и настройки-галочки,
## падавшие в игре на «true == 1.0».
##
## Сценой, а не через --script: нужна автозагрузка Gde.
extends Node2D

## Объект собирается здесь же и сохраняется во временную сцену: рантайм
## узнаёт экземпляры объекта по файлу сцены.
const HERO_SCENE := "user://gde_library_hero.tscn"

## Действия, которые уносят со сцены сам тест: смена и перезапуск сцены,
## выход, пауза, удаление подопытного. Звук и сохранения — бутафорскими
## путями они только ругаются. Удаление проверяет runtime_test.
const SKIP := ["scene.change", "scene.restart", "system.quit", "scene.pause",
	"object.delete", "object.delete_all", "audio.play", "audio.play_music",
	"audio.play_pitch", "save.save", "save.load", "save.delete"]


## Ловит ошибки скриптов, которые иначе ушли бы в консоль незамеченными.
class ErrorCatcher extends Logger:
	var errors: Array[String] = []

	func _log_error(function: String, file: String, line: int, code: String, rationale: String,
			_editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_SCRIPT:
			errors.append("%s (%s, %s:%d)" % [rationale if rationale != "" else code, function, file.get_file(), line])

	func _log_message(_message: String, _error: bool) -> void:
		pass


var _fails: int = 0
var _checks: int = 0
var _reg: GdeRegistry
var _catcher := ErrorCatcher.new()


func _ready() -> void:
	# Тест сверяет русские надписи — язык плагина здесь русский.
	GdeI18n.set_language("ru", false)
	_reg = GdeRegistry.load_default()
	add_child(Camera2D.new())
	_make_hero()
	await get_tree().physics_frame
	await get_tree().process_frame
	OS.add_logger(_catcher)

	var conds := {}
	var acts := {}
	for id: String in _reg.conditions:
		conds[id] = _reg.conditions[id]
	for id: String in _reg.actions:
		acts[id] = _reg.actions[id]
	for b: String in _reg.behaviors:
		var entry: Dictionary = _reg.behaviors[b]
		for m: String in (entry.get("conditions", {}) as Dictionary):
			conds["%s::%s" % [b, m]] = _reg.condition("%s::%s" % [b, m])
		for m: String in (entry.get("actions", {}) as Dictionary):
			acts["%s::%s" % [b, m]] = _reg.action("%s::%s" % [b, m])

	var before := _fails
	for id: String in conds:
		var d: Dictionary = conds[id]
		_run("условие %s" % id, [{"id": id, "params": _params(d, "+")}], [])
		_run("условие НЕ %s" % id, [{"id": id, "params": _params(d, "+"), "inverted": true}], [])
	_summary("условий", conds.size(), before)

	before = _fails
	var n_acts := 0
	for id: String in acts:
		if id in SKIP:
			continue
		n_acts += 1
		var d: Dictionary = acts[id]
		_run("действие %s" % id, [], [{"id": id, "params": _params(d, "+")}])
		if d.has("code_assign"):
			_run("действие %s (=)" % id, [], [{"id": id, "params": _params(d, "=")}])
	_summary("действий", n_acts, before)

	before = _fails
	var n_expr := 0
	for name: String in _reg.expressions:
		n_expr += 1
		_run_expr(name, _reg.free_expr(name))
	for name: String in _reg.object_expressions:
		n_expr += 1
		_run_expr("Hero.%s" % name, _reg.object_expr(name))
	for b: String in _reg.behaviors:
		for name: String in ((_reg.behaviors[b] as Dictionary).get("expressions", {}) as Dictionary):
			n_expr += 1
			_run_expr("Hero.%s::%s" % [b, name], _reg.behavior_expr(b, name))
	# Выражения расширений: Clock::Hour() и т. п.
	for key: String in _reg.ext_expressions:
		n_expr += 1
		var parts := key.split("::")
		_run_expr(key, _reg.ext_expr(parts[0], parts[1]))
	_summary("выражений", n_expr, before)

	OS.remove_logger(_catcher)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(HERO_SCENE))
	print("—— проверок: %d, провалено: %d" % [_checks, _fails])
	get_tree().quit(1 if _fails > 0 else 0)


## Подопытный: тело со всеми поведениями разом, чтобы каждой инструкции
## было на ком выполниться по-настоящему.
func _make_hero() -> void:
	var body := CharacterBody2D.new()
	body.name = "Hero"
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	body.add_child(shape)
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = SpriteFrames.new()
	body.add_child(sprite)
	for b: String in _reg.behaviors:
		var node := Node.new()
		node.name = b
		node.set_script(load(str((_reg.behaviors[b] as Dictionary)["path"])))
		# Цель — он сам: без неё преследование и урон только ругаются
		# на пустое имя объекта и забивают вывод теста.
		if "target_object" in node:
			node.set("target_object", "Hero")
		body.add_child(node)
	for c: Node in body.get_children():
		c.owner = body
	var ps := PackedScene.new()
	ps.pack(body)
	body.free()
	ResourceSaver.save(ps, HERO_SCENE)
	add_child((load(HERO_SCENE) as PackedScene).instantiate())


func _val(kind: String, modop: String) -> String:
	match kind:
		"object", "objname":
			return "Hero"
		"string":
			return "\"a\""
		"raw", "varname":
			return "v"
		"cmpop":
			return "="
		"modop":
			return modop
		_:
			return "1"


func _params(d: Dictionary, modop: String) -> Array:
	var out: Array = []
	for p: Dictionary in d.get("params", []):
		out.append(_val(str(p.get("kind", "number")), modop))
	return out


func _run_expr(title: String, def: Dictionary) -> void:
	var args: Array[String] = []
	for k: Variant in def.get("params", []):
		match str(k):
			"string":
				args.append("\"a\"")
			"raw", "varname":
				# Count(), DistanceTo() и AngleTo() ждут имя объекта.
				args.append("Hero" if str(def.get("name", "")).get_slice("::", 0) in ["Count", "DistanceTo", "AngleTo"] else "v")
			_:
				args.append("1")
	var call := "%s(%s)" % [title, ", ".join(args)]
	_run("выражение %s" % call, [], [{"id": "system.print", "params": ["ToString(%s)" % call]}])


func _run(title: String, conds: Array, acts: Array) -> void:
	_checks += 1
	var sheet := {
		"objects": [{"name": "Hero", "scene": HERO_SCENE}],
		"variables": {"v": 1},
		"events": [{"type": "standard", "conditions": conds, "actions": acts}],
	}
	var r := GdeGenerator.generate(sheet, _reg, "res://library_test.gdes.json")
	if not (r["errors"] as Array).is_empty():
		_fail(title, "ошибки сборки: %s" % [r["errors"]])
		return
	var code: String = r["code"]
	if not conds.is_empty() and code.contains("\tif false:"):
		_fail(title, "условие собралось в «false» — в библиотеке нет шаблона")
		return
	var s := GDScript.new()
	s.source_code = code
	if s.reload() != OK:
		_fail(title, "собранный код не компилируется")
		return
	var runner := Node2D.new()
	runner.set_script(s)
	_catcher.errors.clear()
	add_child(runner)
	runner.set_process(false)
	runner.call("_process", 0.016)
	runner.call("_process", 0.016)
	remove_child(runner)
	runner.free()
	if not _catcher.errors.is_empty():
		_fail(title, "ошибка в игре: %s" % "; ".join(_catcher.errors.slice(0, 2)))


func _fail(title: String, why: String) -> void:
	_fails += 1
	print("  ✗ %s — %s" % [title, why])


func _summary(what: String, n: int, fails_before: int) -> void:
	if _fails == fails_before:
		print("  ✓ %s: %d — все собираются и выполняются" % [what, n])
