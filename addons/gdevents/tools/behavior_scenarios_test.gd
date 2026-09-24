## Безголовый тест новых поведений — каждое в своём маленьком мире:
##   godot --headless --quit-after 20000 res://addons/gdevents/tools/behavior_scenarios_test.tscn
##
## В отличие от behavior_test, где все поведения живут на одной сцене и
## проверяются по номерам кадров, здесь сценарии идут по очереди: построить
## мир, прокрутить физику, проверить, убрать. Так новый сценарий не сдвигает
## чужие кадры и не задевает чужие объекты.
##
## Сценой, а не через --script: нужна автозагрузка Gde.
extends Node2D

const PATROL := preload("res://addons/gdevents/behaviors/patrol_enemy/patrol_enemy.gd")
const PATHFINDER := preload("res://addons/gdevents/behaviors/pathfinder/pathfinder.gd")
const HOMING := preload("res://addons/gdevents/behaviors/homing/homing.gd")
const ORBIT := preload("res://addons/gdevents/behaviors/orbit/orbit.gd")
const SHOOT := preload("res://addons/gdevents/behaviors/shoot/shoot.gd")

var _fails: int = 0
var _checks: int = 0


func _ready() -> void:
	# Тест сверяет русские надписи — язык плагина здесь русский.
	GdeI18n.set_language("ru", false)
	# Объекты «как из листа»: поведения ищут друг друга по именам.
	Gde.register_objects([
		{"name": "Player", "scene": "res://addons/gdevents/tests/player_virtual.tscn"},
		{"name": "Enemy", "scene": "res://addons/gdevents/tests/enemy_virtual.tscn"},
		{"name": "Boss", "scene": "res://addons/gdevents/tests/boss_virtual.tscn"},
	])
	await _patrol_enemy()
	await _pathfinder()
	await _homing()
	await _orbit()
	_report()


# ------------------------------------------------------------- сценарии ---

func _patrol_enemy() -> void:
	print("— Патрульный враг")
	var w := _world()
	_static(w, Vector2(0, 100), Vector2(400, 20))          # платформа от -200 до 200
	_static(w, Vector2(-190, 60), Vector2(20, 60))         # стена у левого края
	var e := _character(w, Vector2(0, 70), Vector2(20, 20))
	var b := _beh(e, PATROL, {"walk_speed": 240.0, "turn_pause": 0.0, "target_object": "Player",
			"sight_range": 200.0, "chase_speed": 300.0, "lose_time": 0.3})
	var turns: Array[int] = [0]
	b.connect("turned", func() -> void: turns[0] += 1)
	var min_x := INF
	var max_x := -INF
	for i in 200:
		await get_tree().physics_frame
		min_x = minf(min_x, e.global_position.x)
		max_x = maxf(max_x, e.global_position.x)
	_ok(e.global_position.y < 95.0, "патруль: не упал с платформы")
	_ok(max_x > 150.0 and max_x < 205.0, "патруль: дошёл до правого края и развернулся (x до %.0f)" % max_x)
	_ok(min_x > -185.0 and min_x < -150.0, "патруль: развернулся, упёршись в стену (x от %.0f)" % min_x)
	_ok(turns[0] >= 2, "патруль: сигнал turned на каждом развороте")
	_ok(bool(b.call("is_patrolling")), "патруль: без цели — патрулирует")

	# Игрок впереди, в пределах взгляда: враг замечает и гонится.
	b.set("walk_speed", 0.0)
	await _frames(2)
	var dir := float(b.call("direction"))
	var p := _tagged(w, "Player", e.global_position + Vector2(120.0 * dir, 0.0))
	var spotted: Array[bool] = [false]
	b.connect("spotted", func() -> void: spotted[0] = true)
	await _frames(3)
	_ok(spotted[0] and bool(b.call("is_chasing")), "погоня: заметил игрока впереди")
	var before := e.global_position.distance_to(p.global_position)
	await _frames(10)
	_ok(e.global_position.distance_to(p.global_position) < before - 20.0, "погоня: приближается к игроку")
	_eq(b.call("state_name"), "chase", "погоня: состояние текстом")

	# Игрок пропал из виду — поиск, потом возвращение на место старта.
	b.set("walk_speed", 240.0)
	p.global_position = Vector2(5000, 70)
	await _frames(3)
	_ok(bool(b.call("is_searching")), "поиск: цель пропала — ищет")
	var came_back := false
	for i in 150:
		await get_tree().physics_frame
		if bool(b.call("is_patrolling")):
			came_back = true
			break
	_ok(came_back, "потеря: сдался и вернулся к патрулю")
	_ok(absf(e.global_position.x) < 8.0, "потеря: сначала дошёл до места старта (x = %.0f)" % e.global_position.x)

	# Игрок за спиной не замечается, пока не включено sees_behind.
	b.set("walk_speed", 0.0)
	b.set("return_home", false)
	await _frames(2)
	p.global_position = e.global_position + Vector2(-80.0 * float(b.call("direction")), 0.0)
	await _frames(3)
	_ok(not bool(b.call("is_chasing")), "зрение: игрока за спиной не видит")
	b.set("sees_behind", true)
	await _frames(3)
	_ok(bool(b.call("is_chasing")), "зрение: с «видит за спиной» — замечает")

	# Стена между ними загораживает взгляд.
	b.set("sees_behind", false)
	b.call("back_to_patrol")
	b.set("lose_time", 0.0)
	await _frames(3)
	var d2 := float(b.call("direction"))
	_static(w, e.global_position + Vector2(40.0 * d2, -10.0), Vector2(10, 60))
	p.global_position = e.global_position + Vector2(90.0 * d2, 0.0)
	await _frames(4)
	_ok(not bool(b.call("sees_target")), "зрение: стена загораживает игрока")
	w.queue_free()
	await _frames(2)


func _pathfinder() -> void:
	print("— Поиск пути")
	var w := _world()
	w.position = Vector2(0, 2000)
	# Стена поперёк дороги: напрямую не пройти, только в обход снизу или сверху.
	_static(w, Vector2(0, -25), Vector2(20, 250))
	var a := _character(w, Vector2(-150, 0), Vector2(16, 16))
	a.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var p := _tagged(w, "Player", Vector2(150, 0))
	var b := _beh(a, PATHFINDER, {"target_object": "Player", "speed": 300.0, "cell_size": 16.0})
	var found: Array[bool] = [false]
	b.connect("path_found", func() -> void: found[0] = true)
	var went_around := false
	var arrived := false
	for i in 300:
		await get_tree().physics_frame
		var ly := a.global_position.y - w.global_position.y
		if absf(a.global_position.x - w.global_position.x) < 20.0 and (ly > 100.0 or ly < -150.0):
			went_around = true
		if bool(b.call("has_arrived")):
			arrived = true
			break
	_ok(found[0], "путь: найден, сигнал path_found")
	_ok(went_around, "путь: обошёл стену, а не упёрся в неё")
	_ok(arrived and a.global_position.distance_to(p.global_position) <= 10.0,
			"путь: дошёл до цели (осталось %.0f px)" % a.global_position.distance_to(p.global_position))

	# Цель замурована со всех сторон — пути нет.
	var box := Vector2(400, 0)
	for side: Array in [[Vector2(0, -40), Vector2(100, 10)], [Vector2(0, 40), Vector2(100, 10)],
			[Vector2(-45, 0), Vector2(10, 90)], [Vector2(45, 0), Vector2(10, 90)]]:
		_static(w, box + (side[0] as Vector2), side[1] as Vector2)
	b.set("partial_path", false)
	b.call("go_to", w.global_position.x + box.x, w.global_position.y + box.y)
	var failed: Array[bool] = [false]
	b.connect("path_failed", func() -> void: failed[0] = true)
	await _frames(5)
	_ok(failed[0] and bool(b.call("no_path")), "путь: до замурованной точки добраться нельзя")
	w.queue_free()
	await _frames(2)


func _homing() -> void:
	print("— Самонаведение")
	var w := _world()
	w.position = Vector2(0, 4000)
	var t := _tagged(w, "Enemy", Vector2(0, 200))
	var m := _node(w, Vector2(0, 0))
	var b := _beh(m, HOMING, {"speed": 300.0, "turn_speed": 360.0, "arm_time": 0.0,
			"view_angle": 360.0, "lifetime": 0.0})
	var closest := INF
	for i in 90:
		await get_tree().physics_frame
		closest = minf(closest, m.global_position.distance_to(t.global_position))
	_ok(closest < 12.0, "наведение: развернулось и догнало цель (ближе всего %.0f px)" % closest)
	m.queue_free()

	# Медленный поворот: ракета проскакивает мимо, цель уходит из поля зрения.
	var t2 := _tagged(w, "Enemy", Vector2(1000, 40))
	t.queue_free()
	var m2 := _node(w, Vector2(900, 0))
	var b2 := _beh(m2, HOMING, {"speed": 400.0, "turn_speed": 20.0, "arm_time": 0.0,
			"view_angle": 90.0, "lifetime": 0.0, "retarget": false})
	var lost: Array[bool] = [false]
	b2.connect("lost_target", func() -> void: lost[0] = true)
	var closest2 := INF
	for i in 40:
		await get_tree().physics_frame
		closest2 = minf(closest2, m2.global_position.distance_to(t2.global_position))
	_ok(lost[0] and not bool(b2.call("has_target")), "наведение: проскочило и потеряло цель")
	_ok(closest2 > 10.0, "наведение: с медленным поворотом — промах (ближе всего %.0f px)" % closest2)
	m2.queue_free()

	# Цель за спиной вне поля зрения — не захватывается.
	var m3 := _node(w, Vector2(1300, 0))
	var b3 := _beh(m3, HOMING, {"speed": 0.0, "view_angle": 90.0, "arm_time": 0.0, "lifetime": 0.0})
	await _frames(3)
	_ok(not bool(b3.call("has_target")), "наведение: цель за спиной не захвачена")
	m3.global_rotation = PI
	b3.call("launch", 180.0)
	await _frames(3)
	_ok(bool(b3.call("has_target")), "наведение: развернули к цели — захватило")

	# «Выстрел» запускает самонаводящийся снаряд без прямолинейного полёта.
	var proto := Node2D.new()
	var hb := Node.new()
	hb.name = "Homing"
	hb.set_script(HOMING)
	proto.add_child(hb)
	hb.owner = proto
	var ps := PackedScene.new()
	ps.pack(proto)
	proto.free()
	var gun := _node(w, Vector2(1600, 0))
	var sh := _beh(gun, SHOOT, {"bullet_scene": ps, "fire_rate": 0.0, "magazine": 0,
			"spread": 0.0, "pellets": 1, "aim_by_flip": false, "offset_forward": 0.0})
	var shots: Array[Node] = []
	sh.connect("fired", func(n: Node) -> void: shots.append(n))
	sh.call("fire_at_angle", 90.0)
	await _frames(2)
	_ok(shots.size() == 1, "выстрел: самонаводящийся снаряд создан")
	if shots.size() == 1:
		var bullet := shots[0]
		_ok(Gde.behavior(bullet, "LinearMove", true) == null, "выстрел: прямолинейный полёт не добавлен")
		_ok(absf(float(Gde.behavior(bullet, "Homing").call("heading")) - 90.0) < 1.0,
				"выстрел: ракета стартует туда, куда выстрелили")
		bullet.queue_free()
	w.queue_free()
	await _frames(2)


func _orbit() -> void:
	print("— Орбита")
	var w := _world()
	w.position = Vector2(0, 6000)
	var boss := _tagged(w, "Boss", Vector2(0, 0))
	var sats: Array[Node2D] = []
	var behs: Array[Node] = []
	for i in 3:
		var s := _node(w, Vector2(100, 0))
		sats.append(s)
		behs.append(_beh(s, ORBIT, {"center_object": "Boss", "radius": 50.0,
				"degrees_per_second": 90.0, "delete_with_center": true}))
	await _frames(3)
	var even := true
	for s: Node2D in sats:
		if absf(s.global_position.distance_to(boss.global_position) - 50.0) > 0.5:
			even = false
	_ok(even, "орбита: все на радиусе 50 от центра")
	var a0 := float(behs[0].call("angle"))
	var gaps: Array[float] = []
	for i in 3:
		var d := absf(angle_difference(deg_to_rad(float(behs[i].call("angle"))),
				deg_to_rad(float(behs[(i + 1) % 3].call("angle")))))
		gaps.append(rad_to_deg(d))
	_ok(absf(gaps[0] - 120.0) < 1.0 and absf(gaps[1] - 120.0) < 1.0,
			"орбита: трое встали поровну — через 120° (%.0f°, %.0f°)" % [gaps[0], gaps[1]])
	await _frames(30)
	var moved := rad_to_deg(absf(angle_difference(deg_to_rad(a0), deg_to_rad(float(behs[0].call("angle"))))))
	_ok(absf(moved - 45.0) < 3.0, "орбита: за полсекунды повернулись на 45° (%.0f°)" % moved)
	boss.global_position += Vector2(200, 0)
	await _frames(2)
	_ok(absf(sats[0].global_position.distance_to(boss.global_position) - 50.0) < 0.5, "орбита: следует за движущимся центром")
	boss.queue_free()
	await _frames(3)
	var gone := true
	for s: Node2D in sats:
		if is_instance_valid(s) and s.is_inside_tree() and not s.is_queued_for_deletion():
			gone = false
	_ok(gone, "орбита: исчезли вместе с центром")
	w.queue_free()
	await _frames(2)


# ---------------------------------------------------------------- мир ---

func _world() -> Node2D:
	var w := Node2D.new()
	add_child(w)
	return w


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _rect(size: Vector2) -> CollisionShape2D:
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = size
	cs.shape = r
	return cs


func _static(w: Node, at: Vector2, size: Vector2) -> StaticBody2D:
	var s := StaticBody2D.new()
	s.position = at
	s.add_child(_rect(size))
	w.add_child(s)
	return s


func _character(w: Node, at: Vector2, size: Vector2) -> CharacterBody2D:
	var c := CharacterBody2D.new()
	c.position = at
	c.add_child(_rect(size))
	w.add_child(c)
	return c


func _node(w: Node, at: Vector2) -> Node2D:
	var n := Node2D.new()
	n.position = at
	w.add_child(n)
	return n


## Экземпляр объекта листа без сцены: рантайм узнаёт его по группе.
func _tagged(w: Node, obj: String, at: Vector2) -> Node2D:
	var n := Node2D.new()
	n.position = at
	w.add_child(n)
	n.add_to_group(Gde.GROUP_PREFIX + obj)
	return n


func _beh(host: Node, script: Script, props: Dictionary) -> Node:
	var b := Node.new()
	b.set_script(script)
	for k: String in props:
		b.set(k, props[k])
	host.add_child(b)
	return b


# ------------------------------------------------------------ проверки ---

func _ok(cond: bool, what: String) -> void:
	_checks += 1
	if cond:
		print("  ✓ %s" % what)
	else:
		_fails += 1
		print("  ✗ %s" % what)


func _eq(got: Variant, want: Variant, what: String) -> void:
	_checks += 1
	var same := false
	if got is float or got is int:
		same = is_equal_approx(float(got), float(want))
	else:
		same = str(got) == str(want)
	if same:
		print("  ✓ %s" % what)
	else:
		_fails += 1
		print("  ✗ %s — ожидалось %s, получено %s" % [what, want, got])


func _report() -> void:
	print("—— проверок: %d, провалено: %d" % [_checks, _fails])
	get_tree().quit(1 if _fails > 0 else 0)
