## Проверка инструкций по-настоящему: условие, действие или выражение
## собирается в отдельный лист, компилируется и дважды выполняется на живом
## объекте. Общая механика для library_test (вся библиотека) и check.tscn
## (один файл поведения или расширения).
##
## Нужна автозагрузка Gde — запускать сценой, а не через --script.
##
##   var chk := GdeInstructionCheck.new(reg)
##   add_child(chk)
##   await chk.prepare()
##   var why := chk.condition("Shoot::can_fire")   # "" — всё хорошо
##   chk.finish()
class_name GdeInstructionCheck
extends Node2D

## Подопытный объект сохраняется во временную сцену: рантайм узнаёт
## экземпляры объекта по файлу сцены.
const HERO_SCENE := "user://gde_check_hero.tscn"
const HERO := "Hero"

## Действия, которые уносят со сцены саму проверку: смена и перезапуск
## сцены, выход, пауза, удаление подопытного. Звук и сохранения с
## бутафорскими путями только ругаются.
const SKIP := ["scene.change", "scene.restart", "scene.change_fade", "system.quit", "scene.pause",
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


var reg: GdeRegistry
var _catcher := ErrorCatcher.new()
var _hero: Node


func _init(registry: GdeRegistry) -> void:
	reg = registry


## Собрать подопытного со всеми поведениями разом и начать ловить ошибки.
func prepare() -> void:
	add_child(Camera2D.new())
	var body := CharacterBody2D.new()
	body.name = HERO
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	body.add_child(shape)
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = SpriteFrames.new()
	body.add_child(sprite)
	for b: String in reg.behaviors:
		var node := Node.new()
		node.name = b
		node.set_script(load(str((reg.behaviors[b] as Dictionary)["path"])))
		# Цель — он сам: без неё преследование и урон только ругаются
		# на пустое имя объекта и забивают вывод.
		if "target_object" in node:
			node.set("target_object", HERO)
		body.add_child(node)
	for c: Node in body.get_children():
		c.owner = body
	var ps := PackedScene.new()
	ps.pack(body)
	body.free()
	ResourceSaver.save(ps, HERO_SCENE)
	# Сразу известен рантайму: поведения с целью «Hero» ищут его с первого кадра.
	Gde.register_objects([{"name": HERO, "scene": HERO_SCENE}])
	_hero = (load(HERO_SCENE) as PackedScene).instantiate()
	add_child(_hero)
	await get_tree().physics_frame
	await get_tree().process_frame
	OS.add_logger(_catcher)


## Действие удалило подопытного («Разрушить», «Удалить»…) — создаём
## нового, иначе все следующие проверки прошли бы вхолостую, без объекта.
func _revive_hero() -> void:
	if is_instance_valid(_hero) and not _hero.is_queued_for_deletion() \
			and _hero.is_in_group(Gde.GROUP_PREFIX + HERO):
		return
	if is_instance_valid(_hero) and not _hero.is_queued_for_deletion():
		_hero.free()
	_hero = (load(HERO_SCENE) as PackedScene).instantiate()
	add_child(_hero)


## Убрать подопытного, пока он ещё что-нибудь не создал из удалённой сцены.
func finish() -> void:
	OS.remove_logger(_catcher)
	# Всех: «Точка появления» на подопытном успевает наплодить его копий.
	for n: Node in get_tree().get_nodes_in_group(Gde.GROUP_PREFIX + HERO):
		if is_instance_valid(n) and n != _hero:
			n.free()
	if is_instance_valid(_hero):
		_hero.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(HERO_SCENE))


## Проверить условие — и с «НЕ». "" — всё хорошо, иначе — что не так.
func condition(id: String) -> String:
	var d: Variant = reg.condition(id)
	if d == null:
		return GdeI18n.t("нет такого условия")
	var why := _run([{"id": id, "params": _params(d, "+")}], [])
	if why.is_empty():
		why = _run([{"id": id, "params": _params(d, "+"), "inverted": true}], [])
		if not why.is_empty():
			why = GdeI18n.t("с «НЕ»: %s") % why
	return why


func action(id: String) -> String:
	var d: Variant = reg.action(id)
	if d == null:
		return GdeI18n.t("нет такого действия")
	var why := _run([], [{"id": id, "params": _params(d, "+")}])
	if why.is_empty() and (d as Dictionary).has("code_assign"):
		why = _run([], [{"id": id, "params": _params(d, "=")}])
		if not why.is_empty():
			why = GdeI18n.t("со знаком «=»: %s") % why
	return why


## Выражение: call_name — как его пишут в листе: Hour, Hero.X, Hero.Shoot::Ammo, Clock::Hour.
func expression(call_name: String, def: Dictionary) -> String:
	var args: Array[String] = []
	for k: Variant in def.get("params", []):
		match str(k):
			"string":
				args.append("\"a\"")
			"raw", "varname":
				# Count(), DistanceTo() и AngleTo() ждут имя объекта.
				args.append(HERO if str(def.get("name", "")).get_slice("::", 0) in ["Count", "DistanceTo", "AngleTo"] else "v")
			_:
				args.append("1")
	var call := "%s(%s)" % [call_name, ", ".join(args)]
	# В текстовую переменную, а не в вывод: печать сотен значений только шумит.
	return _run([], [{"id": "var.set_string", "params": ["t", "ToString(%s)" % call]}])


func _val(kind: String, modop: String) -> String:
	match kind:
		"object", "objname":
			return HERO
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


func _run(conds: Array, acts: Array) -> String:
	var sheet := {
		"objects": [{"name": HERO, "scene": HERO_SCENE}],
		"variables": {"v": 1, "t": ""},
		"events": [{"type": "standard", "conditions": conds, "actions": acts}],
	}
	var r := GdeGenerator.generate(sheet, reg, "res://gdevents_check.gdes.json")
	if not (r["errors"] as Array).is_empty():
		return GdeI18n.t("ошибки сборки: %s") % ", ".join(r["errors"])
	var code: String = r["code"]
	if not conds.is_empty() and code.contains("\tif false:"):
		return GdeI18n.t("условие собралось в «false» — у него нет шаблона кода")
	var s := GDScript.new()
	s.source_code = code
	if s.reload() != OK:
		return GdeI18n.t("собранный код не компилируется")
	var runner := Node2D.new()
	runner.set_script(s)
	_catcher.errors.clear()
	add_child(runner)
	runner.set_process(false)
	runner.call("_process", 0.016)
	runner.call("_process", 0.016)
	remove_child(runner)
	runner.free()
	_revive_hero()
	if not _catcher.errors.is_empty():
		return GdeI18n.t("ошибка в игре: %s") % "; ".join(_catcher.errors.slice(0, 2))
	return ""
