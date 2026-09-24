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
const FLOCK := preload("res://addons/gdevents/behaviors/flock/flock.gd")
const CAR := preload("res://addons/gdevents/behaviors/car/car.gd")
const GRID := preload("res://addons/gdevents/behaviors/grid_step/grid_step.gd")
const PLATFORMER := preload("res://addons/gdevents/behaviors/platformer/platformer.gd")
const PLATFORM := preload("res://addons/gdevents/behaviors/platform/platform.gd")
const LADDER := preload("res://addons/gdevents/behaviors/ladder/ladder.gd")
const PUSHABLE := preload("res://addons/gdevents/behaviors/pushable/pushable.gd")
const CHECKPOINT := preload("res://addons/gdevents/behaviors/checkpoint/checkpoint.gd")
const DESTRUCTIBLE := preload("res://addons/gdevents/behaviors/destructible/destructible.gd")
const HEALTH := preload("res://addons/gdevents/behaviors/health/health.gd")
const RUNNER_SCENE := "user://gde_scenario_runner.tscn"

const SCENARIOS: Array[String] = ["patrol_enemy", "pathfinder", "homing", "orbit", "flock", "car", "grid_step", "platforms", "ladder", "pushable", "checkpoint", "destructible"]

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
		{"name": "Runner", "scene": RUNNER_SCENE},
	])
	# Один сценарий: GDE_SCENARIO=pushable godot --headless … — удобно, когда чинишь.
	var only := OS.get_environment("GDE_SCENARIO")
	for name: String in SCENARIOS:
		if not only.is_empty() and name != only:
			continue
		await call("_" + name)
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


func _flock() -> void:
	print("— Стая")
	seed(7)
	var w := _world()
	w.position = Vector2(0, 8000)
	var fish: Array[Node2D] = []
	var behs: Array[Node] = []
	for i in 8:
		var f := _node(w, Vector2(randf_range(-60, 60), randf_range(-60, 60)))
		fish.append(f)
		behs.append(_beh(f, FLOCK, {"max_speed": 100.0, "wander": 0.0, "avoid_walls": false}))
	await _frames(240)
	var min_d := INF
	var center := Vector2.ZERO
	var heading := Vector2.ZERO
	for i in fish.size():
		center += fish[i].global_position
		heading += Vector2.RIGHT.rotated(deg_to_rad(float(behs[i].call("course"))))
		for j in range(i + 1, fish.size()):
			min_d = minf(min_d, fish[i].global_position.distance_to(fish[j].global_position))
	center /= fish.size()
	var spread := 0.0
	for f: Node2D in fish:
		spread = maxf(spread, f.global_position.distance_to(center))
	_ok(min_d > 12.0, "стая: не налезают друг на друга (ближе всего %.0f px)" % min_d)
	_ok(spread < 110.0, "стая: держатся вместе (дальше всех от центра %.0f px)" % spread)
	_ok(heading.length() / fish.size() > 0.8, "стая: летят в одну сторону (согласие %.2f)" % (heading.length() / fish.size()))

	# Вожак: стая тянется к нему.
	var leader := _tagged(w, "Player", center - w.global_position + Vector2(600, 0))
	for b: Node in behs:
		b.call("follow", "Player")
	var d0 := center.distance_to(leader.global_position)
	await _frames(240)
	var c1 := Vector2.ZERO
	var h1 := Vector2.ZERO
	for i in fish.size():
		c1 += fish[i].global_position
		h1 += Vector2.RIGHT.rotated(deg_to_rad(float(behs[i].call("course"))))
	c1 /= fish.size()
	var toward := h1.normalized().dot((leader.global_position - c1).normalized())
	_ok(c1.distance_to(leader.global_position) < d0 - 200.0 and toward > 0.8,
			"стая: летит за вожаком (было %.0f px, стало %.0f, курс на вожака %.2f)"
			% [d0, c1.distance_to(leader.global_position), toward])
	for f: Node2D in fish:
		f.queue_free()

	# Стена впереди: одиночка огибает её, а не пролетает насквозь.
	_static(w, Vector2(3060, 0), Vector2(20, 400))
	var lone := _node(w, Vector2(3000, 0))
	var lb := _beh(lone, FLOCK, {"max_speed": 100.0, "wander": 0.0, "flock_name": "one"})
	lb.call("push", 0.0, 100.0)
	var crossed := false
	for i in 120:
		await get_tree().physics_frame
		if lone.global_position.x - w.global_position.x > 3050.0:
			crossed = true
	_ok(not crossed, "стая: стену впереди облетает, а не проходит насквозь")
	w.queue_free()
	await _frames(2)


func _car() -> void:
	print("— Машина")
	var w := _world()
	w.position = Vector2(0, 10000)
	var c := _character(w, Vector2(0, 0), Vector2(30, 16))
	var b := _beh(c, CAR, {"default_controls": false})
	for i in 60:
		b.call("gas")
		await get_tree().physics_frame
	_ok(c.position.x > 150.0 and absf(c.position.y) < 1.0, "машина: газ — едет вперёд (x = %.0f)" % c.position.x)
	_ok(float(b.call("forward_speed")) > 380.0, "машина: разогналась почти до предела (%.0f)" % float(b.call("forward_speed")))
	for i in 30:
		b.call("gas")
		b.call("steer_right")
		await get_tree().physics_frame
	_ok(float(b.call("heading")) > 40.0, "машина: руль вправо — повернула (курс %.0f°)" % float(b.call("heading")))
	var drifted: Array[bool] = [false]
	b.connect("drift_started", func() -> void: drifted[0] = true)
	for i in 30:
		b.call("handbrake")
		b.call("steer_right")
		await get_tree().physics_frame
	_ok(drifted[0], "машина: ручник с рулём — занос")
	for i in 120:
		b.call("brake")
		await get_tree().physics_frame
	_ok(bool(b.call("is_reversing")), "машина: тормоз до остановки, дальше — задний ход")
	# Разгон в стену — «врезалась».
	b.call("stop")
	b.call("set_heading", 0.0)
	c.position = Vector2(0, 600)
	_static(w, Vector2(250, 600), Vector2(20, 200))
	var crashed: Array[bool] = [false]
	b.connect("crashed", func(_s: float) -> void: crashed[0] = true)
	for i in 90:
		b.call("gas")
		await get_tree().physics_frame
	_ok(crashed[0], "машина: врезалась в стену на скорости (x = %.0f, скорость %.0f)" % [c.position.x, float(b.call("forward_speed"))])
	w.queue_free()
	await _frames(2)


func _grid_step() -> void:
	print("— Шаг по сетке")
	var w := _world()
	w.position = Vector2(0, 12000)            # 12000 / 32 = 375 — ровно клетка
	var hero := _node(w, Vector2(16, 16))      # клетка (0, 375)
	var hb := _beh(hero, GRID, {"step_time": 0.1})
	var crate := _node(w, Vector2(48, 16))     # клетка (1, 375)
	var cb := _beh(crate, GRID, {"step_time": 0.1, "pushable": true})
	_static(w, Vector2(112, 16), Vector2(32, 32))   # стена в клетке (3, 375)
	await _frames(2)
	hb.call("step_right")
	await _frames(10)
	_eq(hb.call("cell_x"), 1.0, "сетка: шагнул на одну клетку вправо")
	_eq(cb.call("cell_x"), 2.0, "сетка: толкнул ящик на клетку дальше")
	_ok(hero.position.distance_to(Vector2(48, 16)) < 0.5, "сетка: встал ровно в центр клетки")
	var bumped: Array[bool] = [false]
	hb.connect("bumped", func() -> void: bumped[0] = true)
	_ok(not bool(hb.call("can_step", 0.0)), "сетка: за ящиком стена — толкнуть нельзя")
	hb.call("step_right")
	await _frames(10)
	_ok(bumped[0], "сетка: упёрся, сигнал bumped")
	_eq(hb.call("cell_x"), 1.0, "сетка: остался на месте")
	_eq(cb.call("cell_x"), 2.0, "сетка: ящик у стены не сдвинулся")
	# Непроходимый сосед снизу — войти нельзя.
	var rock := _node(w, Vector2(48, 48))      # клетка (1, 376)
	_beh(rock, GRID, {})
	await _frames(2)
	_ok(not bool(hb.call("can_step", 1.0)), "сетка: клетка занята другим — не войти")
	hb.call("step_up")
	await _frames(10)
	_eq(hb.call("cell_y"), 374.0, "сетка: шагнул вверх")
	_eq(hb.call("steps_taken"), 2.0, "сетка: шагов сделано два")
	w.queue_free()
	await _frames(2)


## Персонаж платформера без клавиатуры: управляем действиями.
func _hero(w: Node, at: Vector2, props: Dictionary = {}) -> Array:
	var h := _character(w, at, Vector2(20, 40))
	var p := {"default_controls": false, "coyote_time": 0.0}
	p.merge(props, true)
	return [h, _beh(h, PLATFORMER, p)]


func _platform(w: Node, at: Vector2, size: Vector2, props: Dictionary) -> Array:
	var body := AnimatableBody2D.new()
	body.position = at
	body.add_child(_rect(size))
	w.add_child(body)
	return [body, _beh(body, PLATFORM, props)]


func _platforms() -> void:
	print("— Платформа")
	var w := _world()
	w.position = Vector2(0, 14000)
	_static(w, Vector2(0, 200), Vector2(6000, 20))      # пол, верх на 190
	# Односторонняя: запрыгнуть снизу, спрыгнуть вниз.
	var ow: Array = _platform(w, Vector2(0, 100), Vector2(200, 10), {"one_way": true})
	var hp: Array = _hero(w, Vector2(0, 160), {"jump_force": 600.0})
	var hero: CharacterBody2D = hp[0]
	await _frames(20)
	(hp[1] as Node).call("simulate_jump")
	await _frames(60)
	_ok(hero.is_on_floor() and hero.position.y < 95.0, "односторонняя: запрыгнул снизу сквозь неё и стоит сверху (y = %.0f)" % hero.position.y)
	var rider: Array[Node] = []
	(ow[1] as Node).connect("stood_on", func(b: Node) -> void: rider.append(b))
	await _frames(3)
	_ok(bool((ow[1] as Node).call("has_rider")), "односторонняя: знает, что на ней стоят")
	(hp[1] as Node).call("simulate_drop")
	await _frames(40)
	_ok(hero.is_on_floor() and hero.position.y > 150.0, "односторонняя: спрыгнул вниз сквозь неё (y = %.0f)" % hero.position.y)
	_ok(bool((hp[1] as Node).call("just_dropped")) or hero.position.y > 150.0, "односторонняя: сигнал и условие спрыгивания")

	# Движущаяся везёт стоящего.
	var mv: Array = _platform(w, Vector2(1000, 100), Vector2(200, 10),
			{"moving": true, "move_x": 300.0, "move_time": 1.0, "end_pause": 0.0, "ease_ends": false})
	var hp2: Array = _hero(w, Vector2(1000, 70))
	var h2: CharacterBody2D = hp2[0]
	await _frames(10)
	var p0 := (mv[0] as Node2D).position.x
	var h0 := h2.position.x
	await _frames(30)
	var moved := (mv[0] as Node2D).position.x - p0
	_ok(moved > 100.0, "движущаяся: едет (сдвинулась на %.0f px)" % moved)
	_ok(absf((h2.position.x - h0) - moved) < 8.0 and h2.is_on_floor(),
			"движущаяся: везёт стоящего (платформа %.0f, персонаж %.0f)" % [moved, h2.position.x - h0])

	# Обычное StaticBody2D тоже везёт: платформа сообщает стоящему свою скорость.
	var st := StaticBody2D.new()
	st.position = Vector2(1500, 100)
	st.add_child(_rect(Vector2(200, 10)))
	w.add_child(st)
	_beh(st, PLATFORM, {"moving": true, "move_x": 300.0, "move_time": 1.0, "end_pause": 0.0, "ease_ends": false})
	var hp6: Array = _hero(w, Vector2(1500, 70))
	var h6: CharacterBody2D = hp6[0]
	await _frames(10)
	var s0 := st.position.x
	var h60 := h6.position.x
	await _frames(30)
	_ok(absf((h6.position.x - h60) - (st.position.x - s0)) < 8.0 and h6.is_on_floor(),
			"движущаяся на StaticBody2D: тоже везёт (платформа %.0f, персонаж %.0f)" % [st.position.x - s0, h6.position.x - h60])

	# Лента конвейера.
	var belt: Array = _platform(w, Vector2(2000, 100), Vector2(400, 10), {"conveyor_speed": 120.0})
	var hp3: Array = _hero(w, Vector2(2000, 70))
	var h3: CharacterBody2D = hp3[0]
	await _frames(10)
	var x3 := h3.position.x
	await _frames(30)
	_ok(h3.position.x - x3 > 40.0, "лента: везёт стоящего вбок (%.0f px за полсекунды)" % (h3.position.x - x3))

	# Рушится и возвращается.
	var cr: Array = _platform(w, Vector2(3000, 100), Vector2(200, 10),
			{"crumbles": true, "crumble_delay": 0.3, "respawn_time": 0.5})
	var hp4: Array = _hero(w, Vector2(3000, 70))
	var h4: CharacterBody2D = hp4[0]
	await _frames(10)
	_ok(bool((cr[1] as Node).call("is_crumbling")), "рушится: встал — задрожала")
	await _frames(25)
	_ok(bool((cr[1] as Node).call("is_broken")), "рушится: через 0.3 с рассыпалась")
	await _frames(20)
	_ok(h4.position.y > 150.0, "рушится: стоявший упал вниз")
	await _frames(25)
	_ok(not bool((cr[1] as Node).call("is_broken")) and (cr[0] as Node2D).visible, "рушится: вернулась через 0.5 с")

	# Батут.
	var tr: Array = _platform(w, Vector2(4000, 150), Vector2(200, 10), {"trampoline": true, "bounce_force": 800.0})
	var hp5: Array = _hero(w, Vector2(4000, 0))
	var h5: CharacterBody2D = hp5[0]
	var bounced: Array[bool] = [false]
	(tr[1] as Node).connect("bounced", func(_b: Node) -> void: bounced[0] = true)
	var lowest := -INF
	var rose := false
	for i in 90:
		await get_tree().physics_frame
		lowest = maxf(lowest, h5.position.y)
		if bounced[0] and h5.velocity.y < -300.0:
			rose = true
	_ok(bounced[0] and rose, "батут: приземлился — подбросило вверх")
	w.queue_free()
	await _frames(2)


func _ladder() -> void:
	print("— Лестница")
	var w := _world()
	w.position = Vector2(0, 16000)
	_static(w, Vector2(0, 200), Vector2(2000, 20))      # пол, верх на 190
	var zone := Area2D.new()
	zone.position = Vector2(40, 90)
	zone.add_child(_rect(Vector2(20, 200)))            # от -10 до 190
	w.add_child(zone)
	var lb := _beh(zone, LADDER, {})
	var hp: Array = _hero(w, Vector2(30, 170))
	var hero: CharacterBody2D = hp[0]
	var pb: Node = hp[1]
	await _frames(10)
	var y0 := hero.position.y
	for i in 30:
		pb.call("simulate_up")
		await get_tree().physics_frame
	_ok(bool(pb.call("is_climbing")), "лестница: «вверх» у лестницы — полез")
	_ok(hero.position.y < y0 - 40.0, "лестница: поднялся (на %.0f px)" % (y0 - hero.position.y))
	_ok(absf(hero.position.x - 40.0) < 1.0, "лестница: встал по центру лестницы")
	_ok(bool(lb.call("has_climber")), "лестница: знает, что по ней лезут")
	var y1 := hero.position.y
	await _frames(20)
	_ok(absf(hero.position.y - y1) < 1.0, "лестница: отпустил — висит, а не падает")
	for i in 20:
		pb.call("simulate_down")
		await get_tree().physics_frame
	_ok(hero.position.y > y1 + 20.0, "лестница: полез вниз")
	pb.call("simulate_jump")
	await _frames(3)
	_ok(not bool(pb.call("is_climbing")) and hero.velocity.y < 0.0, "лестница: прыжок — соскочил")
	await _frames(60)
	for i in 10:
		pb.call("simulate_down")
		await get_tree().physics_frame
	_ok(not bool(pb.call("is_climbing")), "лестница: стоя на полу, «вниз» не цепляется за лестницу")
	w.queue_free()
	await _frames(2)


func _pushable() -> void:
	print("— Толкаемый")
	var w := _world()
	w.position = Vector2(0, 18000)
	_static(w, Vector2(0, 200), Vector2(3000, 20))      # пол, верх на 190
	var crate := _character(w, Vector2(100, 170), Vector2(40, 40))
	var cb := _beh(crate, PUSHABLE, {"push_speed": 90.0})
	var hp: Array = _hero(w, Vector2(40, 170))
	var hero: CharacterBody2D = hp[0]
	await _frames(10)
	var x0 := crate.position.x
	_ok(not bool(cb.call("is_pushed")), "ящик: персонаж стоит рядом — не толкает")
	for i in 60:
		(hp[1] as Node).call("simulate_right")
		await get_tree().physics_frame
	_ok(bool(cb.call("is_pushed")), "ящик: персонаж упёрся — толкает")
	_ok(crate.position.x - x0 > 40.0, "ящик: сдвинулся (на %.0f px)" % (crate.position.x - x0))
	_ok(hero.position.x < crate.position.x, "ящик: персонаж идёт за ним, а не сквозь")
	await _frames(15)
	var x1 := crate.position.x
	await _frames(10)
	_ok(absf(crate.position.x - x1) < 0.5 and not bool(cb.call("is_pushed")), "ящик: отпустили — стоит")
	# Стена: ящик упирается и не проходит сквозь.
	_static(w, Vector2(crate.position.x + 60.0, 150), Vector2(20, 80))
	for i in 90:
		(hp[1] as Node).call("simulate_right")
		await get_tree().physics_frame
	_ok(crate.position.x < x1 + 45.0, "ящик: упёрся в стену")
	w.queue_free()
	await _frames(2)


func _checkpoint() -> void:
	print("— Контрольная точка")
	var w := _world()
	w.position = Vector2(0, 20000)
	_static(w, Vector2(0, 200), Vector2(3000, 20))
	var flag1 := _flag(w, Vector2(300, 170))
	var c1 := _beh(flag1, CHECKPOINT, {"player_object": "Player", "respawn_delay": 0.2, "offset_y": -10.0})
	var flag2 := _flag(w, Vector2(900, 170))
	var c2 := _beh(flag2, CHECKPOINT, {"player_object": "Player", "respawn_delay": 0.2})
	var hp: Array = _hero(w, Vector2(100, 170))
	var hero: CharacterBody2D = hp[0]
	hero.add_to_group(Gde.GROUP_PREFIX + "Player")
	var health := _beh(hero, HEALTH, {"max_health": 3.0, "invulnerable_time": 0.0, "blink_on_hit": false})
	await _frames(5)
	_ok(not bool(c1.call("is_active")), "точка: пока не задета — не текущая")
	var active := false
	for i in 90:
		(hp[1] as Node).call("simulate_right")
		await get_tree().physics_frame
		if bool(c1.call("is_active")):
			active = true
			break
	_ok(active and hero.global_position.x - w.global_position.x > 250.0, "точка: пробежал через флаг — он стал текущим")
	for i in 30:
		(hp[1] as Node).call("simulate_right")
		await get_tree().physics_frame
	var far := hero.global_position.x
	health.call("kill")
	await _frames(20)
	_ok(absf(hero.global_position.x - flag1.global_position.x) < 1.0 and far - hero.global_position.x > 100.0,
			"точка: после смерти появился у флага")
	_ok(bool(health.call("is_alive")) and float(health.get("current")) == 3.0, "точка: здоровье полное")
	_ok(bool(health.call("is_invulnerable")), "точка: короткая неуязвимость после появления")
	# Вторая точка перехватывает.
	hero.global_position = flag2.global_position + Vector2(0, -2)
	await _frames(5)
	_ok(bool(c2.call("is_active")) and not bool(c1.call("is_active")), "точка: задел вторую — первая погасла")
	# Игрок удаляется при смерти — точка создаёт его заново.
	var proto := CharacterBody2D.new()
	proto.add_child(_rect(Vector2(20, 40)))
	var hb := Node.new()
	hb.name = "Health"
	hb.set_script(HEALTH)
	hb.set("destroy_on_death", true)
	proto.add_child(hb)
	for c: Node in proto.get_children():
		c.owner = proto
	var ps := PackedScene.new()
	ps.pack(proto)
	proto.free()
	ResourceSaver.save(ps, RUNNER_SCENE)
	var runner := (load(RUNNER_SCENE) as PackedScene).instantiate() as Node2D
	runner.position = Vector2(1500, 170)
	w.add_child(runner)
	var flag3 := _flag(w, Vector2(1500, 170))
	var c3 := _beh(flag3, CHECKPOINT, {"player_object": "Runner", "respawn_delay": 0.1, "is_start": true})
	await _frames(5)
	Gde.behavior(runner, "Health").call("kill")
	await _frames(15)
	var runners := Gde.all_instances("Runner")
	_ok(runners.size() == 1 and runners[0] != runner and (runners[0] as Node2D).global_position.distance_to(flag3.global_position) < 1.0,
			"точка: удалённого при смерти игрока создала заново у себя")
	_eq(c3.call("respawn_count"), 1.0, "точка: считает возрождения")
	for r: Node in runners:
		r.queue_free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(RUNNER_SCENE))
	w.queue_free()
	await _frames(2)


## Флажок с зоной касания.
func _flag(w: Node, at: Vector2) -> Node2D:
	var a := Area2D.new()
	a.position = at
	a.add_child(_rect(Vector2(20, 60)))
	w.add_child(a)
	return a


func _destructible() -> void:
	print("— Разрушаемое с добычей")
	var w := _world()
	w.position = Vector2(0, 22000)
	var coin := Node2D.new()
	coin.name = "Coin"
	var coin_scene := PackedScene.new()
	coin_scene.pack(coin)
	coin.free()
	var crate := _sprite_box(w, Vector2(0, 0))
	var db := _beh(crate, DESTRUCTIBLE, {"loot_1": coin_scene, "chance_1": 100.0, "count_1": 3,
			"loot_2": coin_scene, "chance_2": 0.0})
	var got: Array = []
	db.connect("broken", func(loot: Array) -> void: got.append_array(loot))
	db.call("break_now")
	await _frames(1)
	var shards := 0
	for c: Node in get_children():
		if c is GdeDebris:
			shards += 1
	_eq(shards, 9, "разрушаемое: разлетелось на 3×3 осколка")
	_eq(got.size(), 3, "разрушаемое: выпало ровно три монеты (шанс 100%), второго предмета нет (шанс 0%)")
	_ok(not is_instance_valid(crate) or crate.is_queued_for_deletion(), "разрушаемое: сам объект удалён")
	await _frames(70)
	var left := 0
	for c: Node in get_children():
		if c is GdeDebris:
			left += 1
	_eq(left, 0, "разрушаемое: осколки растаяли сами")
	for n: Node in got:
		n.queue_free()
	# От «Здоровья» и от касания.
	var c2 := _sprite_box(w, Vector2(200, 0))
	var d2 := _beh(c2, DESTRUCTIBLE, {"shards_x": 0})
	var h2 := _beh(c2, HEALTH, {"max_health": 1.0})
	var broke: Array[bool] = [false, false]
	d2.connect("broken", func(_l: Array) -> void: broke[0] = true)
	await _frames(2)
	h2.call("kill")
	_ok(broke[0], "разрушаемое: «Здоровье» кончилось — разрушилось")
	var c3 := _sprite_box(w, Vector2(400, 0))
	var d3 := _beh(c3, DESTRUCTIBLE, {"shards_x": 0, "break_on_touch": "Enemy"})
	d3.connect("broken", func(_l: Array) -> void: broke[1] = true)
	await _frames(2)
	_ok(not broke[1], "разрушаемое: без касания — цело")
	var bullet := _tagged(w, "Enemy", Vector2(400, 0))
	bullet.add_child(_rect(Vector2(8, 8)))
	await _frames(2)
	_ok(broke[1], "разрушаемое: коснулся объект из «ломаться от касания» — разрушилось")
	w.queue_free()
	await _frames(2)


func _sprite_box(w: Node, at: Vector2) -> Node2D:
	var n := _node(w, at)
	var img := Image.create(24, 24, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.8, 0.5, 0.2))
	var s := Sprite2D.new()
	s.texture = ImageTexture.create_from_image(img)
	n.add_child(s)
	return n


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
