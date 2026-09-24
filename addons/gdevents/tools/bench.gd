## Нагрузка: сколько стоит кадр листа, когда объектов много.
##   godot --headless res://addons/gdevents/tools/bench.tscn
##
## 500 врагов и 300 пуль, типичный лист: все движутся, пули бьют врагов,
## враги умирают, счёт растёт, «только что столкнулся» и «касается сверху». Замеряется только сам лист (_process
## раннера), без отрисовки. Дважды: объекты с формами без физики (габариты)
## и с Area2D (физика Godot).
extends Node2D

const ENEMIES := 500
const BULLETS := 300
const FRAMES := 120
## Порог провала: кадр при 30 FPS. Задача порога — поймать возврат к проверке
## «каждый с каждым» (было 1700 мс), а не спорить с медленной машиной CI.
const BUDGET_MS := 33.0

var _fails: int = 0
var _checks: int = 0
var _reg: GdeRegistry


func _ready() -> void:
	GdeI18n.set_language("ru", false)
	_reg = GdeRegistry.load_default()
	Gde.register_objects([
		{"name": "Enemy", "scene": "res://addons/gdevents/tests/enemy_virtual.tscn"},
		{"name": "Bullet", "scene": "res://addons/gdevents/tests/bullet_virtual.tscn"},
	])
	for with_area: bool in [false, true]:
		await _run(with_area)
	print("—— проверок: %d, провалено: %d" % [_checks, _fails])
	get_tree().quit(1 if _fails > 0 else 0)


func _run(with_area: bool) -> void:
	var title := "с Area2D" if with_area else "габариты без физики"
	var nodes: Array[Node] = []
	for i in range(ENEMIES):
		nodes.append(_thing("Enemy", Vector2((i % 50) * 40, int(i / 50.0) * 40), with_area))
	for j in range(BULLETS):
		nodes.append(_thing("Bullet", Vector2((j % 30) * 67 + 13, 700 + int(j / 30.0) * 30), with_area))
	var sheet := {"objects": [], "variables": {"score": 0}, "events": [
		{"conditions": [], "actions": [
			{"id": "object.x", "params": ["Enemy", "+", "30 * TimeDelta()"]},
			{"id": "object.y", "params": ["Bullet", "-", "600 * TimeDelta()"]}]},
		{"conditions": [{"id": "object.collision", "params": ["Bullet", "Enemy"]}], "actions": [
			{"id": "object.variable", "params": ["Enemy", "hp", "-", "1"]},
			{"id": "object.delete", "params": ["Bullet"]},
			{"id": "var.modify", "params": ["score", "+", "1"]}]},
		{"conditions": [{"id": "object.variable", "params": ["Enemy", "hp", "<", "-2"]}], "actions": [
			{"id": "object.delete", "params": ["Enemy"]}]},
		{"conditions": [{"id": "object.collision_start", "params": ["Enemy", "Bullet"]}], "actions": [
			{"id": "var.modify", "params": ["starts", "+", "1"]}]},
		{"conditions": [{"id": "object.touch_top", "params": ["Bullet", "Enemy"]}], "actions": [
			{"id": "var.modify", "params": ["tops", "+", "1"]}]},
		{"conditions": [{"id": "object.count", "params": ["Bullet", "<", "1"]}], "actions": [
			{"id": "var.modify", "params": ["empty", "=", "1"]}]},
	]}
	for o: String in ["Enemy", "Bullet"]:
		(sheet["objects"] as Array).append({"name": o, "scene": "res://addons/gdevents/tests/%s_virtual.tscn" % o.to_lower()})
	var r := GdeGenerator.generate(sheet, _reg, "res://bench.gdes.json", false)
	var s := GDScript.new()
	s.source_code = r["code"]
	s.reload()
	var runner := Node2D.new()
	runner.set_script(s)
	add_child(runner)
	runner.set_process(false)
	Gde.var_set("score", 0.0)
	# Area2D узнают соседей только после шага физики.
	await get_tree().physics_frame
	await get_tree().physics_frame
	var total := 0.0
	var worst := 0.0
	for f in range(FRAMES):
		var t0 := Time.get_ticks_usec()
		runner.call("_process", 1.0 / 60.0)
		var ms := (Time.get_ticks_usec() - t0) / 1000.0
		total += ms
		worst = maxf(worst, ms)
		# Настоящий следующий кадр: кэши «на кадр» не должны жить между замерами.
		await get_tree().physics_frame if with_area else get_tree().process_frame
	var avg := total / FRAMES
	print("  %s: %d врагов, %d пуль — кадр листа в среднем %.2f мс, худший %.2f мс, попаданий %d"
			% [title, ENEMIES, BULLETS, avg, worst, int(Gde.var_get("score"))])
	_ok(avg < BUDGET_MS, "%s: средний кадр листа меньше %.0f мс" % [title, BUDGET_MS])
	_ok(Gde.var_get("score") > 0.0, "%s: пули попадают" % title)
	runner.free()
	for n: Node in nodes:
		if is_instance_valid(n):
			n.free()


func _thing(obj: String, at: Vector2, with_area: bool) -> Node2D:
	var n: Node2D = Area2D.new() if with_area else Node2D.new()
	n.position = at
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(16, 16)
	cs.shape = rect
	n.add_child(cs)
	add_child(n)
	n.add_to_group(Gde.GROUP_PREFIX + obj)
	return n


func _ok(cond: bool, what: String) -> void:
	_checks += 1
	if cond:
		print("  ✓ %s" % what)
	else:
		_fails += 1
		print("  ✗ %s" % what)
