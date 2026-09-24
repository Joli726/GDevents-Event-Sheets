## Рантайм GDevents — автолоад `Gde`.
##
## Держит реестр объектов (тип объекта = сцена .tscn), выдаёт экземпляры
## для выборки, хранит переменные и предоставляет хелперы, которые вызывает
## сгенерированный код. Ничего не исполняет сам: логика живёт в .gd,
## сгенерированном из листа событий.
class_name GdeRuntime
extends Node

const GROUP_PREFIX := "__gde_"

## имя объекта -> путь к сцене
var _objects: Dictionary = {}
## путь к сцене -> имя объекта
var _scene_to_obj: Dictionary = {}
## имя группы объектов GDevelop -> Array[String] имён объектов
var _obj_groups: Dictionary = {}

var _global_vars: Dictionary = {}
var _scene_vars: Dictionary = {}

## id раннера -> { prev: Dictionary, now: Dictionary } для «Триггер один раз»
var _once: Dictionary = {}
## id раннера -> { имя таймера: прошедшее время }
var _timers: Dictionary = {}


func _ready() -> void:
	process_priority = -100
	get_tree().node_added.connect(_on_node_added)


# ---------------------------------------------------------------- объекты ---

## Регистрация объектов листа. defs: [{ "name": "Player", "scene": "res://..." }]
func register_objects(defs: Array) -> void:
	for d: Dictionary in defs:
		var n: String = d.get("name", "")
		var s: String = d.get("scene", "")
		if n.is_empty() or s.is_empty():
			push_warning("GDevents: пропущен объект без имени или сцены: %s" % [d])
			continue
		_objects[n] = s
		_scene_to_obj[s] = n
	rescan()


## Регистрация групп объектов GDevelop: { "Враги": ["Goblin", "Orc"] }
func register_object_groups(groups: Dictionary) -> void:
	for g: String in groups:
		_obj_groups[g] = groups[g]


## Разовый проход по дереву — подхватывает то, что уже расставлено в сцене.
func rescan() -> void:
	var root := get_tree().current_scene
	if root == null:
		root = get_tree().root
	_scan_node(root)


func _scan_node(n: Node) -> void:
	_try_tag(n)
	for c: Node in n.get_children():
		_scan_node(c)


func _on_node_added(n: Node) -> void:
	_try_tag(n)


func _try_tag(n: Node) -> void:
	var sp := n.scene_file_path
	if sp.is_empty():
		return
	var obj: String = _scene_to_obj.get(sp, "")
	if obj.is_empty():
		return
	var g := GROUP_PREFIX + obj
	if not n.is_in_group(g):
		n.add_to_group(g)


func is_object(name: String) -> bool:
	return _objects.has(name) or _obj_groups.has(name)


## Все живые экземпляры объекта (или группы объектов GDevelop).
func all_instances(obj: String) -> Array:
	if _obj_groups.has(obj):
		var out: Array = []
		for member: String in _obj_groups[obj]:
			out.append_array(get_tree().get_nodes_in_group(GROUP_PREFIX + member))
		return out
	if not _objects.has(obj):
		push_warning("GDevents: объект «%s» не зарегистрирован" % obj)
		return []
	return get_tree().get_nodes_in_group(GROUP_PREFIX + obj)


func new_context() -> GdePickContext:
	return GdePickContext.new(self)


## Создать экземпляр объекта. Созданное сразу попадает в выборку текущего
## события — как в GDevelop.
func create_object(ctx: GdePickContext, obj: String, x: float, y: float, parent: Node) -> Node:
	var path: String = _objects.get(obj, "")
	if path.is_empty():
		push_error("GDevents: нельзя создать «%s» — объект не зарегистрирован" % obj)
		return null
	var ps: PackedScene = load(path)
	if ps == null:
		push_error("GDevents: не загружается сцена %s" % path)
		return null
	var n := ps.instantiate()
	parent.add_child(n)
	var m := main(n)
	if m != null:
		m.global_position = Vector2(x, y)
	_try_tag(n)
	if ctx != null:
		var list := ctx.pick(obj)
		list.append(n)
		ctx.set_pick(obj, list)
	return n


## Удалить экземпляр. Из выборки убирается немедленно — queue_free()
## отложен до конца кадра, а GDevelop убирает объект сразу.
func delete_object(n: Node) -> void:
	if not is_instance_valid(n):
		return
	for g: StringName in n.get_groups():
		if String(g).begins_with(GROUP_PREFIX):
			n.remove_from_group(g)
	n.queue_free()


## Удалить всё отобранное. GDevelop убирает удалённое и из выборки, поэтому
## следующие действия того же события их уже не увидят.
func delete_picked(ctx: GdePickContext, obj: String) -> void:
	for n: Node in ctx.pick(obj):
		delete_object(n)
	ctx.set_pick(obj, [])


# ----------------------------------------------------------------- выборка ---

## Сузить выборку объекта предикатом. true, если хоть кто-то уцелел.
func filter(ctx: GdePickContext, obj: String, pred: Callable) -> bool:
	var kept: Array = []
	for n: Node in ctx.pick(obj):
		if is_instance_valid(n) and pred.call(n):
			kept.append(n)
	ctx.set_pick(obj, kept)
	return not kept.is_empty()


## Инвертированное условие. В GDevelop «НЕ» не фильтрует выборку — оно лишь
## отвечает true, когда условию не удовлетворяет ни один отобранный экземпляр.
func filter_not(ctx: GdePickContext, obj: String, pred: Callable) -> bool:
	for n: Node in ctx.pick(obj):
		if is_instance_valid(n) and pred.call(n):
			return false
	return true


## Условие на паре объектов (столкновения, дистанция). Сужает ОБА списка:
## слева остаются те, кто совпал хоть с кем-то справа, и наоборот.
func filter_pair(ctx: GdePickContext, a: String, b: String, pred: Callable) -> bool:
	var la := ctx.pick(a)
	var lb := ctx.pick(b)
	var keep_a: Dictionary = {}
	var keep_b: Dictionary = {}
	for x: Node in la:
		if not is_instance_valid(x):
			continue
		for y: Node in lb:
			if not is_instance_valid(y) or x == y:
				continue
			if pred.call(x, y):
				keep_a[x] = true
				keep_b[y] = true
	var ka := keep_a.keys()
	if a == b:
		# Объект против самого себя: список один, уцелевшие — объединение.
		for y: Variant in keep_b:
			if not keep_a.has(y):
				ka.append(y)
		ctx.set_pick(a, ka)
		return not ka.is_empty()
	ctx.set_pick(a, ka)
	ctx.set_pick(b, keep_b.keys())
	return not ka.is_empty()


func filter_pair_not(ctx: GdePickContext, a: String, b: String, pred: Callable) -> bool:
	for x: Node in ctx.pick(a):
		if not is_instance_valid(x):
			continue
		for y: Node in ctx.pick(b):
			if not is_instance_valid(y) or x == y:
				continue
			if pred.call(x, y):
				return false
	return true


# -------------------------------------------------------------- кадр/время ---

## Вызывается сгенерированным кодом в начале каждого кадра листа.
func frame_begin(runner: Node) -> void:
	var id := runner.get_instance_id()
	var st: Dictionary = _once.get(id, {})
	st["prev"] = st.get("now", {})
	st["now"] = {}
	_once[id] = st
	_runner_frames[id] = int(_runner_frames.get(id, 0)) + 1


## «Триггер один раз, пока истинно».
func once(runner: Node, idx: int) -> bool:
	var st: Dictionary = _once.get(runner.get_instance_id(), null)
	if st == null:
		return true
	(st["now"] as Dictionary)[idx] = true
	return not (st["prev"] as Dictionary).has(idx)


func timer_advance(runner: Node, delta: float) -> void:
	var id := runner.get_instance_id()
	var t: Dictionary = _timers.get(id, {})
	var paused: Dictionary = _timers_paused.get(id, {})
	for k: String in t:
		if not paused.has(k):
			t[k] = float(t[k]) + delta
	_timers[id] = t
	# Аккумуляторы «каждые N секунд» живут рядом с таймерами — тот же кадровый такт.
	var e: Dictionary = _every.get(id, {})
	for k: Variant in e:
		e[k] = float(e[k]) + delta
	_every[id] = e


func timer_value(runner: Node, name: String) -> float:
	var t: Dictionary = _timers.get(runner.get_instance_id(), {})
	if not t.has(name):
		t[name] = 0.0
		_timers[runner.get_instance_id()] = t
	return float(t.get(name, 0.0))


func timer_reset(runner: Node, name: String) -> void:
	var id := runner.get_instance_id()
	var t: Dictionary = _timers.get(id, {})
	t[name] = 0.0
	_timers[id] = t


# --------------------------------------------------------------- переменные ---

func begin_scene(initial: Dictionary) -> void:
	_scene_start = _clock
	_scene_vars = initial.duplicate(true)
	_timers.clear()


func _dig(store: Dictionary, path: String, create: bool) -> Array:
	## Возвращает [контейнер, последний_ключ] для пути вида "player.hp".
	var parts := path.split(".", false)
	var cur := store
	for i in range(parts.size() - 1):
		var k := parts[i]
		if not cur.has(k) or not (cur[k] is Dictionary):
			if not create:
				return [null, ""]
			cur[k] = {}
		cur = cur[k]
	return [cur, parts[parts.size() - 1]]


func var_get(path: String, fallback: Variant = 0.0) -> Variant:
	var loc := _dig(_scene_vars, path, false)
	if loc[0] == null:
		return fallback
	return (loc[0] as Dictionary).get(loc[1], fallback)


func var_set(path: String, value: Variant) -> void:
	var loc := _dig(_scene_vars, path, true)
	(loc[0] as Dictionary)[loc[1]] = value


func gvar_get(path: String, fallback: Variant = 0.0) -> Variant:
	var loc := _dig(_global_vars, path, false)
	if loc[0] == null:
		return fallback
	return (loc[0] as Dictionary).get(loc[1], fallback)


func gvar_set(path: String, value: Variant) -> void:
	var loc := _dig(_global_vars, path, true)
	(loc[0] as Dictionary)[loc[1]] = value


## Переменные объекта живут в метаданных ноды — работает на любом типе.
func ovar_get(n: Node, path: String, fallback: Variant = 0.0) -> Variant:
	if not is_instance_valid(n):
		return fallback
	var store: Dictionary = n.get_meta("__gde_vars", {})
	var loc := _dig(store, path, false)
	if loc[0] == null:
		return fallback
	return (loc[0] as Dictionary).get(loc[1], fallback)


func ovar_set(n: Node, path: String, value: Variant) -> void:
	if not is_instance_valid(n):
		return
	var store: Dictionary = n.get_meta("__gde_vars", {})
	var loc := _dig(store, path, true)
	(loc[0] as Dictionary)[loc[1]] = value
	n.set_meta("__gde_vars", store)


# ---------------------------------------------------------------- поведения ---

## Найти ноду-поведение на объекте.
##
## Ищем по всему поддереву, а не только среди прямых детей. Настоящая сцена
## почти никогда не плоская: корень — Node2D, а CharacterBody2D с поведениями
## лежит внутри. Раньше такой объект выглядел как «поведений нет» и в списке,
## и в игре — все действия поведения молча не срабатывали.
func behavior(n: Node, bname: String, quiet: bool = false) -> Node:
	if not is_instance_valid(n):
		return null
	var cached: Dictionary = n.get_meta("__gde_beh", {})
	if cached.has(bname):
		var b: Variant = cached[bname]
		if is_instance_valid(b):
			return b
	var found := _search_behavior(n, bname)
	if found != null:
		cached[bname] = found
		n.set_meta("__gde_beh", cached)
		return found
	if not quiet:
		push_warning("GDevents: у «%s» нет поведения «%s»" % [n.name, bname])
	return null


## Обход в ширину: поведение прямо на объекте важнее такого же поведения
## у вложенного объекта (например, у пули внутри оружия).
func _search_behavior(root: Node, bname: String) -> Node:
	var queue: Array[Node] = [root]
	while not queue.is_empty():
		var n: Node = queue.pop_front()
		for c: Node in n.get_children():
			if c is GdeBehavior and (c as GdeBehavior).behavior_name() == bname:
				return c
			queue.append(c)
	return null


## Все поведения объекта — именами. Нужно диагностике и редактору.
func behaviors_of(n: Node) -> Array[String]:
	var out: Array[String] = []
	if not is_instance_valid(n):
		return out
	var queue: Array[Node] = [n]
	while not queue.is_empty():
		var cur: Node = queue.pop_front()
		for c: Node in cur.get_children():
			if c is GdeBehavior:
				out.append((c as GdeBehavior).behavior_name())
			queue.append(c)
	return out


func has_behavior(n: Node, bname: String) -> bool:
	return behavior(n, bname, true) != null


## Вызовы через эти три хелпера безопасны: если поведение забыли
## добавить на объект, игра не падает, а ругается в консоль.
func beh_call(n: Node, bname: String, method: String, args: Array = []) -> void:
	var b := behavior(n, bname)
	if b != null:
		b.callv(method, args)


func beh_bool(n: Node, bname: String, method: String, args: Array = []) -> bool:
	var b := behavior(n, bname)
	if b == null:
		return false
	return bool(b.callv(method, args))


func beh_val(n: Node, bname: String, method: String, args: Array = [], fallback: Variant = 0.0) -> Variant:
	var b := behavior(n, bname)
	if b == null:
		return fallback
	return b.callv(method, args)


func beh_get(n: Node, bname: String, prop: String, fallback: Variant = 0.0) -> Variant:
	var b := behavior(n, bname)
	if b == null:
		return fallback
	return b.get(prop)


func beh_set(n: Node, bname: String, prop: String, value: Variant) -> void:
	var b := behavior(n, bname)
	if b != null:
		b.set(prop, value)


# ------------------------------------------------------------------- ввод ---

var _keycodes: Dictionary = {}
var _keys_prev: Dictionary = {}
var _keys_now: Dictionary = {}


## Колесо мыши приходит событиями, а не состоянием — копим за кадр
var _wheel_acc: float = 0.0
var _wheel_now: float = 0.0

## Игровые часы: копят delta, поэтому замедление времени и пауза их
## касаются. Всё, что меряет «сколько прошло в игре», берёт время отсюда,
## а не с настенных часов.
var _clock: float = 0.0
var _scene_start: float = 0.0


func _input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null:
		if mb.pressed:
			if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
				_wheel_acc += 1.0
			elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_wheel_acc -= 1.0
		return
	if event is InputEventMouseMotion:
		_mouse_moved_acc = true
		return
	var k := event as InputEventKey
	if k != null and k.pressed and not k.echo:
		# Имя, а не код: в листе клавиша пишется словом, и сравнивать
		# «последнюю нажатую» надо с тем же самым словом.
		var name := OS.get_keycode_string(k.physical_keycode if k.keycode == KEY_NONE else k.keycode)
		if not name.is_empty():
			_last_key = name


## На сколько щелчков прокрутили в этом кадре: вверх положительно.
func wheel() -> float:
	return _wheel_now


func _process(delta: float) -> void:
	# process_priority = -100, поэтому снимок клавиш готов раньше листов событий.
	_keys_prev = _keys_now
	_keys_now = {}
	_wheel_now = _wheel_acc
	_wheel_acc = 0.0
	_mouse_prev = _mouse_now
	_mouse_now = {}
	for b in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
		if Input.is_mouse_button_pressed(b):
			_mouse_now[int(b)] = true
	_mouse_moved = _mouse_moved_acc
	_mouse_moved_acc = false
	_clock += delta
	_update_camera(delta)


func _keycode(name: String) -> int:
	if _keycodes.has(name):
		return _keycodes[name]
	var k := OS.find_keycode_from_string(name)
	if k == KEY_NONE:
		push_warning("GDevents: неизвестная клавиша «%s»" % name)
	_keycodes[name] = k
	return k


func key_pressed(name: String) -> bool:
	var k := _keycode(name)
	if k == KEY_NONE:
		return false
	var down := Input.is_key_pressed(k)
	if down:
		_keys_now[k] = true
	return down


## Нажатие именно в этом кадре — «Клавиша нажата (один раз)» в GDevelop.
func key_just_pressed(name: String) -> bool:
	var k := _keycode(name)
	if k == KEY_NONE:
		return false
	var down := Input.is_key_pressed(k)
	if down:
		_keys_now[k] = true
	return down and not _keys_prev.has(k)


## Отпускание именно в этом кадре.
func key_just_released(name: String) -> bool:
	var k := _keycode(name)
	if k == KEY_NONE:
		return false
	var down := Input.is_key_pressed(k)
	if down:
		_keys_now[k] = true
	return not down and _keys_prev.has(k)


## Нажата хоть какая-нибудь клавиша — удобно для заставок и меню.
func any_key_pressed() -> bool:
	return Input.is_anything_pressed()


func action_pressed(action: String) -> bool:
	return InputMap.has_action(action) and Input.is_action_pressed(action)


func action_just_pressed(action: String) -> bool:
	return InputMap.has_action(action) and Input.is_action_just_pressed(action)


func mouse_button(idx: int) -> bool:
	return Input.is_mouse_button_pressed(idx as MouseButton)


## Мышь в мировых координатах, с учётом камеры.
func mouse_world() -> Vector2:
	var vp := get_viewport()
	if vp == null:
		return Vector2.ZERO
	return vp.get_canvas_transform().affine_inverse() * vp.get_mouse_position()


# -------------------------------------------------------------- геометрия ---

## Найти Area2D в поддереве объекта. Корнём объекта может быть что угодно,
## а Area2D — вложенной нодой; искать только в корне значило бы требовать
## от пользователя одной-единственной структуры сцены.
func find_area(n: Node) -> Area2D:
	if not is_instance_valid(n):
		return null
	# Именно has_meta, а не get_meta с умолчанием: null как умолчание Godot
	# не отличает от «умолчания не передали» и ругается в консоль.
	if n.has_meta("__gde_area"):
		var cached: Variant = n.get_meta("__gde_area")
		if is_instance_valid(cached):
			return cached
	var found := _search_area(n)
	if found != null:
		n.set_meta("__gde_area", found)
	return found


func _search_area(n: Node) -> Area2D:
	if n is Area2D:
		return n as Area2D
	for c: Node in n.get_children():
		var r := _search_area(c)
		if r != null:
			return r
	return null


## Принадлежит ли нода поддереву объекта.
func _is_within(n: Node, root: Node) -> bool:
	var p := n
	while p != null:
		if p == root:
			return true
		p = p.get_parent()
	return false


func _find_shape(n: Node) -> Node:
	for c: Node in n.get_children():
		if c is CollisionShape2D and (c as CollisionShape2D).shape != null:
			return c
		if c is CollisionPolygon2D and (c as CollisionPolygon2D).polygon.size() > 0:
			return c
		var r := _find_shape(c)
		if r != null:
			return r
	return null


## Ограничивающий прямоугольник объекта в мировых координатах.
## Берётся из CollisionShape2D, иначе из спрайта, иначе — точка.
func aabb(n: Node) -> Rect2:
	var n2 := main(n)
	if n2 == null:
		return Rect2()
	var shape_node := _find_shape(n)
	if shape_node is CollisionShape2D:
		var cs := shape_node as CollisionShape2D
		var sh := cs.shape
		var r := sh.get_rect() if sh.has_method("get_rect") else Rect2(-Vector2.ONE, Vector2.ONE * 2.0)
		return Rect2(cs.global_position + r.position * n2.global_scale, r.size * n2.global_scale)
	if shape_node is CollisionPolygon2D:
		var cp := shape_node as CollisionPolygon2D
		var rp := Rect2(cp.polygon[0], Vector2.ZERO)
		for p: Vector2 in cp.polygon:
			rp = rp.expand(p)
		return Rect2(cp.global_position + rp.position, rp.size)
	if n is Sprite2D:
		var s := n as Sprite2D
		if s.texture != null:
			var sz := s.texture.get_size() * s.global_scale
			return Rect2(s.global_position - sz * 0.5, sz)
	if n is AnimatedSprite2D:
		var a := n as AnimatedSprite2D
		var fr := a.sprite_frames
		if fr != null and fr.has_animation(a.animation):
			var tex := fr.get_frame_texture(a.animation, a.frame)
			if tex != null:
				var sz2 := tex.get_size() * a.global_scale
				return Rect2(a.global_position - sz2 * 0.5, sz2)
	return Rect2(n2.global_position, Vector2.ZERO)


## Столкновение двух объектов.
##
## Если хотя бы у одного в поддереве есть Area2D — считаем через физику, точно.
## Сравниваем не с самими объектами, а с их поддеревьями: пересечённая
## область часто оказывается дочерней нодой, а не корнем объекта.
## Нет ни одной Area2D — падаем на AABB.
func overlaps(a: Node, b: Node) -> bool:
	if not is_instance_valid(a) or not is_instance_valid(b) or a == b:
		return false
	var area_a := find_area(a)
	var area_b := find_area(b)

	if area_a != null:
		for o: Node2D in area_a.get_overlapping_areas():
			if _is_within(o, b):
				return true
		for o: Node2D in area_a.get_overlapping_bodies():
			if _is_within(o, b):
				return true

	if area_b != null:
		for o: Node2D in area_b.get_overlapping_areas():
			if _is_within(o, a):
				return true
		for o: Node2D in area_b.get_overlapping_bodies():
			if _is_within(o, a):
				return true

	if area_a != null or area_b != null:
		return false
	return aabb(a).intersects(aabb(b))


func pos_of(n: Node) -> Vector2:
	var m := main(n)
	return m.global_position if m != null else Vector2.ZERO


func distance(a: Node, b: Node) -> float:
	return pos_of(a).distance_to(pos_of(b))


## Угол от a к b в градусах — GDevelop работает в градусах.
func angle_to(a: Node, b: Node) -> float:
	return rad_to_deg(pos_of(a).angle_to_point(pos_of(b)))


func is_visible(n: Node) -> bool:
	return is_instance_valid(n) and n is CanvasItem and (n as CanvasItem).is_visible_in_tree()


# ------------------------------------------------------------------ прочее ---

## Проиграть анимацию из события. Спрайт ищем по всему поддереву объекта:
## в живой сцене AnimatedSprite2D редко висит прямо на корне.
##
## Анимация, заказанная событием, главнее автоматической: поведение вроде
## «Платформера» каждый кадр ставит бег или прыжок и раньше перебивало
## событие уже на следующем кадре — «Двойной прыжок» просто не был виден.
## Теперь заказ события держится, пока его повторяют, и в любом случае —
## один полный проход анимации.
func play_animation(n: Node, anim: String) -> void:
	_play(n, anim, true)


## То же, но для поведений: уступает анимации, которую заказало событие.
func auto_animation(n: Node, anim: String) -> void:
	_play(n, anim, false)


func _play(n: Node, anim: String, from_event: bool) -> void:
	if not is_instance_valid(n) or anim.is_empty():
		return
	if n is AnimationPlayer:
		(n as AnimationPlayer).play(anim)
		return
	var a := _anim_node(n)
	if a == null:
		var ap := _player_node(n)
		if ap != null:
			ap.play(anim)
		else:
			_warn_once(n, "нет ноды с анимацией", "GDevents: у «%s» нет ноды с анимацией" % n.name)
		return
	if a.sprite_frames == null or not a.sprite_frames.has_animation(anim):
		_warn_once(a, "anim:" + anim, "GDevents: у «%s» нет анимации «%s». Есть: %s"
				% [n.name, anim, ", ".join(Array(a.sprite_frames.get_animation_names()) if a.sprite_frames != null else [])])
		return

	var now := _clock
	if from_event:
		var cur: Dictionary = a.get_meta("__gde_anim_order", {})
		var start := now
		if str(cur.get("anim", "")) == anim:
			start = float(cur.get("start", now))
		a.set_meta("__gde_anim_order", {"anim": anim, "last": now, "start": start,
				"cycle": _cycle_seconds(a, anim)})
	elif a.has_meta("__gde_anim_order"):
		var order: Dictionary = a.get_meta("__gde_anim_order")
		var held := now - float(order["last"]) < 0.06 \
				or now - float(order["start"]) < float(order["cycle"])
		if held:
			return
		a.remove_meta("__gde_anim_order")

	if a.animation != anim or not a.is_playing():
		a.play(anim)


## Длительность одного прохода анимации в секундах игрового времени.
func _cycle_seconds(a: AnimatedSprite2D, anim: String) -> float:
	var fr := a.sprite_frames
	var fps := fr.get_animation_speed(anim) * maxf(0.01, absf(a.speed_scale))
	if fps <= 0.0:
		return 0.0
	var units := 0.0
	for i in range(fr.get_frame_count(anim)):
		units += fr.get_frame_duration(anim, i)
	return units / fps


## Предупреждение один раз на пару «узел + причина». Раньше отсутствующая
## анимация ругалась каждый кадр прыжка, и консоль тонула в одной строке.
func _warn_once(n: Node, key: String, text: String) -> void:
	var seen: Dictionary = n.get_meta("__gde_warned", {})
	if seen.has(key):
		return
	seen[key] = true
	n.set_meta("__gde_warned", seen)
	push_warning(text)


func current_animation(n: Node) -> String:
	if not is_instance_valid(n):
		return ""
	var a := _anim_node(n)
	if a != null:
		return String(a.animation)
	var ap := _player_node(n)
	return String(ap.current_animation) if ap != null else ""


func _player_node(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n as AnimationPlayer
	for c: Node in n.get_children():
		var r := _player_node(c)
		if r != null:
			return r
	return null


## Физическое тело объекта. Корень сцены часто Node2D, а RigidBody2D или
## CharacterBody2D лежит внутри — искать надо по поддереву.
func body_of(n: Node) -> PhysicsBody2D:
	if not is_instance_valid(n):
		return null
	if n is PhysicsBody2D:
		return n as PhysicsBody2D
	for c: Node in n.get_children():
		var r := body_of(c)
		if r != null:
			return r
	return null


## Узел, на котором «живёт» объект.
##
## В GDevelop объект — одна сущность с одной позицией. В Godot сцена объекта
## часто выглядит иначе: корень — пустой Node2D, а двигается CharacterBody2D
## внутри него. Тогда «X объекта» обязан читать и писать позицию тела, иначе
## поведение двигает одно, а события смотрят на другое — и координаты вечно
## нулевые. Статические тела не в счёт: они не двигаются сами.
func main(n: Node) -> Node2D:
	if not is_instance_valid(n):
		return null
	if n is CollisionObject2D:
		return n as Node2D
	if n.has_meta("__gde_main"):
		var cached: Variant = n.get_meta("__gde_main")
		if is_instance_valid(cached):
			return cached
	var mover := _find_mover(n)
	var out: Node2D = mover if mover != null else n as Node2D
	n.set_meta("__gde_main", out)
	return out


## Кто в объекте двигается. По порядку:
##   1. тело (CharacterBody2D, RigidBody2D) с формой столкновения;
##   2. узел, на котором висят поведения: поведение двигает своего родителя;
##   3. иначе — корень.
## Тело без формы само по себе в расчёт не берётся: оно ни с чем не
## сталкивается и под гравитацией просто падает. Прими его за объект — и X()
## показывал бы координаты этого падения. Но если на нём висит поведение,
## значит, двигают именно его, и тогда оно главное.
func _find_mover(n: Node) -> Node2D:
	var body := _find_body(n)
	if body != null:
		return body
	var host := _behavior_host(n)
	return host if host != n else null


func _find_body(n: Node) -> Node2D:
	for c: Node in n.get_children():
		if (c is CharacterBody2D or c is RigidBody2D) and _has_shape(c):
			return c as Node2D
	for c: Node in n.get_children():
		var r := _find_body(c)
		if r != null:
			return r
	return null


## Ближайший к корню Node2D, у которого среди детей есть поведение.
func _behavior_host(root: Node) -> Node2D:
	var queue: Array[Node] = [root]
	while not queue.is_empty():
		var cur: Node = queue.pop_front()
		for c: Node in cur.get_children():
			if c is GdeBehavior and cur is Node2D:
				return cur as Node2D
		for c: Node in cur.get_children():
			queue.append(c)
	return null


func _has_shape(body: Node) -> bool:
	for c: Node in body.get_children():
		if c is CollisionShape2D and (c as CollisionShape2D).shape != null:
			return true
		if c is CollisionPolygon2D and (c as CollisionPolygon2D).polygon.size() > 2:
			return true
	return false


func count(ctx: GdePickContext, obj: String) -> float:
	var c := 0
	for n: Node in ctx.pick(obj):
		if is_instance_valid(n):
			c += 1
	return float(c)


func change_scene(path: String) -> void:
	get_tree().call_deferred("change_scene_to_file", path)


## Число в строку по-гдевелоповски: целое показывается как 5, а не 5.0.
func num_str(v: float) -> String:
	if is_equal_approx(v, roundf(v)):
		return str(int(roundf(v)))
	return str(v)


# -------------------------------------------------------------------- звук ---

var _sounds: Array[AudioStreamPlayer] = []


## Проиграть звук. Игрок создаётся на лету и сам себя убирает — для событий
## этого достаточно, а возиться с нодами в сцене не приходится.
func play_sound(path: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if not ResourceLoader.exists(path):
		push_warning("GDevents: звук не найден — %s" % path)
		return
	var stream: AudioStream = load(path)
	if stream == null:
		return
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = maxf(0.01, pitch)
	add_child(p)
	_sounds.append(p)
	p.finished.connect(func():
		_sounds.erase(p)
		p.queue_free())
	p.play()


func stop_sounds() -> void:
	for p: AudioStreamPlayer in _sounds.duplicate():
		if is_instance_valid(p):
			p.stop()
			p.queue_free()
	_sounds.clear()


# ------------------------------------------------------------------ камера ---

func _camera() -> Camera2D:
	var vp := get_viewport()
	return vp.get_camera_2d() if vp != null else null


func camera_center(n: Node) -> void:
	var cam := _camera()
	if cam != null and is_instance_valid(n) and n is Node2D:
		cam.global_position = (n as Node2D).global_position


func camera_move(x: float, y: float) -> void:
	var cam := _camera()
	if cam != null:
		cam.global_position = Vector2(x, y)


func camera_zoom(z: float) -> void:
	var cam := _camera()
	if cam != null and z > 0.0:
		cam.zoom = Vector2(z, z)


# ------------------------------------------------------------------- прочее ---

## Виден ли объект в пределах экрана.
func on_screen(n: Node) -> bool:
	if not is_instance_valid(n) or not (n is Node2D):
		return false
	var vp := get_viewport()
	if vp == null:
		return false
	var r := vp.get_visible_rect()
	var p := vp.get_canvas_transform() * (n as Node2D).global_position
	return r.has_point(p)


func set_opacity(n: Node, v: float) -> void:
	if is_instance_valid(n) and n is CanvasItem:
		var c := (n as CanvasItem).modulate
		c.a = clampf(v, 0.0, 1.0)
		(n as CanvasItem).modulate = c


func get_opacity(n: Node) -> float:
	if is_instance_valid(n) and n is CanvasItem:
		return (n as CanvasItem).modulate.a
	return 1.0


## Отразить спрайт объекта по горизонтали.
func set_flip_h(n: Node, flipped: bool) -> void:
	if not is_instance_valid(n):
		return
	for c: Node in _flippable(n):
		c.set("flip_h", flipped)


func _flippable(n: Node) -> Array[Node]:
	var out: Array[Node] = []
	if n is Sprite2D or n is AnimatedSprite2D:
		out.append(n)
	for c: Node in n.get_children():
		out.append_array(_flippable(c))
	return out


## Отражён ли объект по горизонтали. Смотрим на первый спрайт в поддереве:
## именно он и есть «лицо» объекта. Отрицательный масштаб по X тоже считается
## отражением — так объект можно развернуть и без флага спрайта.
func is_flipped_h(n: Node) -> bool:
	if not is_instance_valid(n):
		return false
	var m := main(n)
	if m != null and m.scale.x < 0.0:
		return true
	var list := _flippable(n)
	return not list.is_empty() and bool(list[0].get("flip_h"))


func set_flip_v(n: Node, flipped: bool) -> void:
	if not is_instance_valid(n):
		return
	for c: Node in _flippable(n):
		c.set("flip_v", flipped)


func is_flipped_v(n: Node) -> bool:
	if not is_instance_valid(n):
		return false
	var list := _flippable(n)
	return not list.is_empty() and bool(list[0].get("flip_v"))


## Куда смотрит объект: 1 — вправо, −1 — влево.
## Готовое число для «полететь в ту сторону, куда смотрит игрок».
func facing(n: Node) -> float:
	return -1.0 if is_flipped_h(n) else 1.0


## Поворот объекта в градусах. 0 — вправо, 90 — вниз.
func get_angle(n: Node) -> float:
	var m := main(n)
	return rad_to_deg(m.global_rotation) if m != null else 0.0


func get_scale_x(n: Node) -> float:
	var m := main(n)
	return m.scale.x if m != null else 1.0


func get_scale_y(n: Node) -> float:
	var m := main(n)
	return m.scale.y if m != null else 1.0


func get_z(n: Node) -> float:
	return float((n as CanvasItem).z_index) if is_instance_valid(n) and n is CanvasItem else 0.0


## Найти узел с текстом внутри объекта (Label, RichTextLabel) и задать текст.
func set_text(n: Node, text: String) -> void:
	if not is_instance_valid(n):
		return
	var t := _text_node(n)
	if t != null:
		t.set("text", text)
	else:
		push_warning("GDevents: у «%s» нет ноды с текстом" % n.name)


func get_text(n: Node) -> String:
	var t := _text_node(n) if is_instance_valid(n) else null
	return str(t.get("text")) if t != null else ""


func _text_node(n: Node) -> Node:
	if n is Label or n is RichTextLabel:
		return n
	for c: Node in n.get_children():
		var r := _text_node(c)
		if r != null:
			return r
	return null


func restart_scene() -> void:
	get_tree().call_deferred("reload_current_scene")


## Сдвинуть объект на расстояние под углом в градусах.
func move_at_angle(n: Node, angle_deg: float, distance: float) -> void:
	var o := main(n)
	if o != null:
		o.global_position += Vector2.RIGHT.rotated(deg_to_rad(angle_deg)) * distance


func look_at_point(n: Node, x: float, y: float) -> void:
	var o := main(n)
	if o != null:
		o.global_rotation = (Vector2(x, y) - o.global_position).angle()


func screen_size() -> Vector2:
	var vp := get_viewport()
	return vp.get_visible_rect().size if vp != null else Vector2.ZERO


# ------------------------------------------------------- выборка экземпляров ---
#
# Это сердце GDevelop: условия не только отвечают «да/нет», но и решают,
# с какими именно экземплярами будут работать следующие строки события.

## Оставить в выборке только ближайший к точке экземпляр.
func pick_nearest(ctx: GdePickContext, obj: String, x: float, y: float) -> bool:
	var target := Vector2(x, y)
	var best: Node = null
	var best_d := INF
	for n: Node in ctx.pick(obj):
		if not is_instance_valid(n):
			continue
		var d := pos_of(n).distance_squared_to(target)
		if d < best_d:
			best_d = d
			best = n
	ctx.set_pick(obj, [best] if best != null else [])
	return best != null


## Оставить только самый дальний от точки.
func pick_farthest(ctx: GdePickContext, obj: String, x: float, y: float) -> bool:
	var target := Vector2(x, y)
	var best: Node = null
	var best_d := -1.0
	for n: Node in ctx.pick(obj):
		if not is_instance_valid(n):
			continue
		var d := pos_of(n).distance_squared_to(target)
		if d > best_d:
			best_d = d
			best = n
	ctx.set_pick(obj, [best] if best != null else [])
	return best != null


## Оставить один случайный экземпляр.
func pick_random(ctx: GdePickContext, obj: String) -> bool:
	var alive: Array = []
	for n: Node in ctx.pick(obj):
		if is_instance_valid(n):
			alive.append(n)
	if alive.is_empty():
		ctx.set_pick(obj, [])
		return false
	ctx.set_pick(obj, [alive[randi() % alive.size()]])
	return true


## Сбросить выборку к полному списку — отменяет сужение, сделанное выше.
func pick_all(ctx: GdePickContext, obj: String) -> bool:
	var all := all_instances(obj)
	ctx.set_pick(obj, all)
	return not all.is_empty()


## Ближайший к другому объекту. Сужает оба списка: остаётся одна пара.
func pick_nearest_to(ctx: GdePickContext, obj: String, other: String) -> bool:
	var best: Node = null
	var best_other: Node = null
	var best_d := INF
	for a: Node in ctx.pick(obj):
		if not is_instance_valid(a):
			continue
		for b: Node in ctx.pick(other):
			if not is_instance_valid(b) or a == b:
				continue
			var d := pos_of(a).distance_squared_to(pos_of(b))
			if d < best_d:
				best_d = d
				best = a
				best_other = b
	if best == null:
		ctx.set_pick(obj, [])
		return false
	ctx.set_pick(obj, [best])
	if obj != other:
		ctx.set_pick(other, [best_other])
	return true


# ---------------------------------------------------------------- геометрия 2 ---

func in_rect(n: Node, x: float, y: float, w: float, h: float) -> bool:
	return Rect2(x, y, w, h).has_point(pos_of(n))


## Видит ли a объект b: луч между ними не упирается в третье тело.
func has_line_of_sight(a: Node, b: Node) -> bool:
	if not is_instance_valid(a) or not is_instance_valid(b):
		return false
	var a2 := a as Node2D
	if a2 == null:
		return false
	var space := a2.get_world_2d().direct_space_state
	var q := PhysicsRayQueryParameters2D.create(pos_of(a), pos_of(b))
	q.collide_with_areas = true
	q.exclude = _rids_of(a)
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		return true
	var col: Variant = hit.get("collider")
	return col is Node and _is_within(col as Node, b)


## RID всех физических тел внутри объекта — чтобы луч не цеплялся за себя.
func _rids_of(n: Node) -> Array[RID]:
	var out: Array[RID] = []
	if n is CollisionObject2D:
		out.append((n as CollisionObject2D).get_rid())
	for c: Node in n.get_children():
		out.append_array(_rids_of(c))
	return out


func clamp_to_rect(n: Node, x: float, y: float, w: float, h: float) -> void:
	var o := main(n)
	if o == null:
		return
	var half := aabb(n).size * 0.5
	o.global_position = Vector2(
			clampf(o.global_position.x, x + half.x, x + w - half.x),
			clampf(o.global_position.y, y + half.y, y + h - half.y))


## Плавно подвинуть к точке. distance — сколько пикселей за этот вызов.
func move_to(n: Node, x: float, y: float, distance: float) -> void:
	var o := main(n)
	if o != null:
		o.global_position = o.global_position.move_toward(Vector2(x, y), distance)


func move_to_node(n: Node, target: Node, distance: float) -> void:
	if is_instance_valid(target):
		var p := pos_of(target)
		move_to(n, p.x, p.y, distance)


func look_at_node(a: Node, b: Node) -> void:
	var o := main(a)
	if o != null and is_instance_valid(b):
		o.global_rotation = (pos_of(b) - o.global_position).angle()


func place_at(n: Node, target: Node, dx: float, dy: float) -> void:
	var o := main(n)
	if o != null and is_instance_valid(target):
		o.global_position = pos_of(target) + Vector2(dx, dy)


# ------------------------------------------------------------------- вид 2 ---

func set_color(n: Node, r: float, g: float, b: float) -> void:
	if is_instance_valid(n) and n is CanvasItem:
		var ci := n as CanvasItem
		var c := ci.modulate
		ci.modulate = Color(clampf(r, 0, 1), clampf(g, 0, 1), clampf(b, 0, 1), c.a)


func set_scale_xy(n: Node, sx: float, sy: float) -> void:
	var o := main(n)
	if o != null:
		o.scale = Vector2(sx, sy)


func _anim_node(n: Node) -> AnimatedSprite2D:
	if n is AnimatedSprite2D:
		return n as AnimatedSprite2D
	for c: Node in n.get_children():
		var r := _anim_node(c)
		if r != null:
			return r
	return null


func animation_finished(n: Node) -> bool:
	var a := _anim_node(n) if is_instance_valid(n) else null
	if a == null or a.sprite_frames == null:
		return false
	if a.sprite_frames.get_animation_loop(a.animation):
		return false
	return not a.is_playing()


func set_animation_speed(n: Node, scale: float) -> void:
	var a := _anim_node(n) if is_instance_valid(n) else null
	if a != null:
		a.speed_scale = scale


func pause_animation(n: Node, paused: bool) -> void:
	var a := _anim_node(n) if is_instance_valid(n) else null
	if a == null:
		return
	if paused:
		a.pause()
	else:
		a.play()


func animation_frame(n: Node) -> float:
	var a := _anim_node(n) if is_instance_valid(n) else null
	return float(a.frame) if a != null else 0.0


# ---------------------------------------------------------------- объекты 2 ---

## Создать объект в позиции другого — самый частый способ что-то породить.
func create_at(ctx: GdePickContext, obj: String, target: Node, dx: float, dy: float,
		parent: Node) -> Node:
	var p := pos_of(target)
	return create_object(ctx, obj, p.x + dx, p.y + dy, parent)


# ------------------------------------------------------------------ время ---

var _time_scale: float = 1.0


func set_time_scale(v: float) -> void:
	_time_scale = maxf(0.0, v)
	Engine.time_scale = _time_scale


func get_time_scale() -> float:
	return Engine.time_scale


func set_paused(v: bool) -> void:
	get_tree().paused = v


func is_paused() -> bool:
	return get_tree().paused


## Секунд с начала сцены в игровом времени. Раньше здесь были настенные
## часы с запуска движка — после перезапуска уровня отсчёт не сбрасывался.
func scene_time() -> float:
	return _clock - _scene_start


# ----------------------------------------------------- «каждые N» и «в начале» ---

## id раннера -> { индекс инструкции: накопленное время }
var _every: Dictionary = {}
## id раннера -> сколько кадров лист уже отработал
var _runner_frames: Dictionary = {}


## Первый проход листа — удобно для начальной расстановки.
func at_start(runner: Node) -> bool:
	return int(_runner_frames.get(runner.get_instance_id(), 0)) <= 1


## Срабатывает раз в seconds секунд. Каждому месту в листе нужен свой idx.
func every(runner: Node, idx: int, seconds: float) -> bool:
	var id := runner.get_instance_id()
	var t: Dictionary = _every.get(id, {})
	if not t.has(idx):
		t[idx] = 0.0
		_every[id] = t
		return false
	if float(t[idx]) >= maxf(0.001, seconds):
		t[idx] = float(t[idx]) - maxf(0.001, seconds)
		_every[id] = t
		return true
	return false


# ------------------------------------------------------------ сохранение ---

## Сохранить переменные сцены и глобальные в файл user://.
func save_vars(slot: String) -> void:
	var path := "user://%s.json" % slot.validate_filename()
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("GDevents: не сохраняется %s" % path)
		return
	f.store_string(JSON.stringify({"scene": _scene_vars, "global": _global_vars}, "  ", false))
	f.close()


## Загрузить переменные из файла. Молча ничего не делает, если файла нет.
func load_vars(slot: String) -> void:
	var path := "user://%s.json" % slot.validate_filename()
	if not FileAccess.file_exists(path):
		return
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if parsed is Dictionary:
		var d: Dictionary = parsed
		_scene_vars = d.get("scene", {})
		_global_vars = d.get("global", {})


func has_save(slot: String) -> bool:
	return FileAccess.file_exists("user://%s.json" % slot.validate_filename())


func delete_save(slot: String) -> void:
	var path := "user://%s.json" % slot.validate_filename()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


# ------------------------------------------------------------------ музыка ---

var _music: AudioStreamPlayer


## Фоновая музыка — один игрок на всю игру, зациклен.
func play_music(path: String, volume_db: float = 0.0) -> void:
	if not ResourceLoader.exists(path):
		push_warning("GDevents: музыка не найдена — %s" % path)
		return
	var stream: AudioStream = load(path)
	if stream == null:
		return
	if _music == null or not is_instance_valid(_music):
		_music = AudioStreamPlayer.new()
		add_child(_music)
	if _music.stream == stream and _music.playing:
		_music.volume_db = volume_db
		return
	_music.stream = stream
	_music.volume_db = volume_db
	_music.play()


func stop_music() -> void:
	if _music != null and is_instance_valid(_music):
		_music.stop()


func set_music_volume(volume_db: float) -> void:
	if _music != null and is_instance_valid(_music):
		_music.volume_db = volume_db


func music_playing() -> bool:
	return _music != null and is_instance_valid(_music) and _music.playing


# ------------------------------------------------------------------ камера 2 ---

var _shake_left: float = 0.0
var _shake_strength: float = 0.0
var _follow: Node = null
var _follow_smooth: float = 0.0


func shake_camera(strength: float, seconds: float) -> void:
	_shake_strength = maxf(_shake_strength, absf(strength))
	_shake_left = maxf(_shake_left, absf(seconds))


func camera_follow(n: Node, smoothing: float) -> void:
	_follow = n
	_follow_smooth = clampf(smoothing, 0.0, 0.99)


func camera_stop_follow() -> void:
	_follow = null


## Тряска и слежение крутятся здесь, чтобы работать независимо от листа событий.
func _update_camera(delta: float) -> void:
	var cam := _camera()
	if cam == null:
		return
	if _follow != null and is_instance_valid(_follow):
		var target := pos_of(_follow)
		if _follow_smooth <= 0.0:
			cam.global_position = target
		else:
			var t := 1.0 - pow(_follow_smooth, delta * 60.0)
			cam.global_position = cam.global_position.lerp(target, clampf(t, 0.0, 1.0))
	if _shake_left > 0.0:
		_shake_left = maxf(0.0, _shake_left - delta)
		var k := _shake_strength * (_shake_left if _shake_left < 1.0 else 1.0)
		cam.offset = Vector2(randf_range(-k, k), randf_range(-k, k))
		if is_zero_approx(_shake_left):
			cam.offset = Vector2.ZERO
			_shake_strength = 0.0


# ------------------------------------------------------------------ физика ---

## Импульс для RigidBody2D — это масса на скорость, а персонажу нужна сама
## скорость. Множитель подобран так, чтобы одинаковая «сила» в листе давала
## похожий на глаз толчок и ящику, и игроку.
const CHARACTER_IMPULSE := 10.0


func apply_impulse(n: Node, angle_deg: float, force: float) -> void:
	if not is_instance_valid(n):
		return
	var push := Vector2.RIGHT.rotated(deg_to_rad(angle_deg)) * force
	var body := body_of(n)
	if body is RigidBody2D:
		(body as RigidBody2D).apply_impulse(push)
	elif body is CharacterBody2D:
		# У персонажа скорость ведёт поведение (платформер, вид сверху) —
		# толчок добавляется к ней и гаснет так же, как гасится разбег.
		(body as CharacterBody2D).velocity += push * CHARACTER_IMPULSE
	else:
		_warn_once(n, "impulse", "GDevents: толкнуть можно только тело — внутри «%s» нет ни RigidBody2D, ни CharacterBody2D" % n.name)


# ------------------------------------------------------------------ строки ---

func str_get(path: String) -> String:
	return str(var_get(path, ""))


func gstr_get(path: String) -> String:
	return str(gvar_get(path, ""))


func str_len(s: String) -> float:
	return float(s.length())


## Кусок строки. Позиции по-человечески: первый символ — нулевой,
## длина за концом строки не ошибка, а просто «до конца».
func substring(s: String, from: float, count: float) -> String:
	var a := clampi(int(from), 0, s.length())
	var n := maxi(0, int(count))
	return s.substr(a, n)


func str_find(s: String, needle: String) -> float:
	return float(s.find(needle))


func str_contains(s: String, needle: String) -> bool:
	return s.contains(needle)


## Число с ведущими нулями: pad(7, 3) -> «007». Для счёта и таймеров на экране.
func pad_number(v: float, digits: float) -> String:
	var neg := v < 0.0
	var body := num_str(absf(v))
	var need := maxi(0, int(digits) - body.length())
	return ("-" if neg else "") + "0".repeat(need) + body


## Время в виде 1:05 — привычный формат для таймеров.
func time_text(seconds: float) -> String:
	var total := maxi(0, int(seconds))
	return "%d:%02d" % [total / 60, total % 60]


# ------------------------------------------------------------------ таймеры 2 ---
#
# Пауза таймера — отдельный набор имён: так «пауза» не теряется при
# перезапуске отсчёта и не требует второй переменной в листе.

var _timers_paused: Dictionary = {}


func timer_pause(runner: Node, name: String, paused: bool) -> void:
	var id := runner.get_instance_id()
	var p: Dictionary = _timers_paused.get(id, {})
	if paused:
		p[name] = true
	else:
		p.erase(name)
	_timers_paused[id] = p


func timer_paused(runner: Node, name: String) -> bool:
	return (_timers_paused.get(runner.get_instance_id(), {}) as Dictionary).has(name)


func timer_delete(runner: Node, name: String) -> void:
	var id := runner.get_instance_id()
	(_timers.get(id, {}) as Dictionary).erase(name)
	(_timers_paused.get(id, {}) as Dictionary).erase(name)


# ------------------------------------------------------------------- ввод 2 ---

var _last_key: String = ""
var _mouse_prev: Dictionary = {}
var _mouse_now: Dictionary = {}
var _mouse_moved: bool = false
var _mouse_moved_acc: bool = false


## Имя последней нажатой клавиши. Нужно экрану «нажмите клавишу для…».
func last_key() -> String:
	return _last_key


func mouse_released(button: float) -> bool:
	var b := int(button)
	return not _mouse_now.has(b) and _mouse_prev.has(b)


func mouse_moved() -> bool:
	return _mouse_moved


# ------------------------------------------------------------------ объекты 3 ---

## Есть ли в сцене хоть один экземпляр — в отличие от Count(), смотрит
## на всех живых, а не на отобранных.
func object_exists(obj: String) -> bool:
	for n: Node in all_instances(obj):
		if is_instance_valid(n):
			return true
	return false


func instance_count(obj: String) -> float:
	return float(all_instances(obj).size())


## Убрать вообще все экземпляры объекта. Для зачистки уровня и рестарта.
func delete_all(obj: String) -> void:
	for n: Node in all_instances(obj):
		if is_instance_valid(n):
			delete_object(n)


## Оттолкнуть объект от другого. Спутник урона: удар должен отбрасывать.
func knockback(n: Node, from: Node, force: float) -> void:
	var a := main(n)
	if a == null or not is_instance_valid(from):
		return
	var dir := (a.global_position - pos_of(from))
	if dir.length_squared() < 0.0001:
		dir = Vector2.RIGHT
	a.global_position += dir.normalized() * force


## Луч из объекта под углом. Истинно, только если первым на пути оказался
## именно b — стена между ними загораживает, как и должна.
##
## Проверка парная, поэтому выборку сужает сам движок событий: в списке
## останутся ровно те пары «кто смотрит» и «кого видно».
func ray_hits(a: Node, b: Node, angle_deg: float, length: float) -> bool:
	var o := main(a)
	if o == null or not is_instance_valid(b):
		return false
	var to := o.global_position + Vector2.RIGHT.rotated(deg_to_rad(angle_deg)) * length
	var q := PhysicsRayQueryParameters2D.create(o.global_position, to)
	q.collide_with_areas = true
	q.exclude = _rids_of(a)
	var hit := o.get_world_2d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		return false
	var col: Variant = hit.get("collider")
	return col is Node and _is_within(col as Node, b)


# ------------------------------------------------------------- плавность ---
#
# Твины GDevelop одним действием: «плавно переехать туда за столько-то».
# Руками это событие на три строки со своим счётчиком, и каждый раз заново.
# На объект живёт один твин: второй вызов отменяет первый, иначе два
# «плавно переместить» дерутся за одну позицию и объект дрожит.

var _tweens: Dictionary = {}


func _tween_for(n: Node) -> Tween:
	var id := n.get_instance_id()
	var old: Variant = _tweens.get(id)
	if old is Tween and (old as Tween).is_valid():
		(old as Tween).kill()
	var t := n.create_tween()
	t.set_trans(Tween.TRANS_SINE)
	t.set_ease(Tween.EASE_IN_OUT)
	_tweens[id] = t
	return t


func tween_move(n: Node, x: float, y: float, seconds: float) -> void:
	var o := main(n)
	if o == null:
		return
	_tween_for(o).tween_property(o, "global_position", Vector2(x, y), maxf(0.01, seconds))


func tween_move_by(n: Node, dx: float, dy: float, seconds: float) -> void:
	var o := main(n)
	if o != null:
		tween_move(n, o.global_position.x + dx, o.global_position.y + dy, seconds)


func tween_scale(n: Node, to: float, seconds: float) -> void:
	var o := main(n)
	if o != null:
		_tween_for(o).tween_property(o, "scale", Vector2(to, to), maxf(0.01, seconds))


func tween_rotate(n: Node, degrees: float, seconds: float) -> void:
	var o := main(n)
	if o != null:
		_tween_for(o).tween_property(o, "global_rotation_degrees", degrees, maxf(0.01, seconds))


func tween_opacity(n: Node, to: float, seconds: float) -> void:
	var ci := n as CanvasItem
	if ci == null or not is_instance_valid(n):
		return
	var c := ci.modulate
	_tween_for(ci).tween_property(ci, "modulate",
			Color(c.r, c.g, c.b, clampf(to, 0.0, 1.0)), maxf(0.01, seconds))


func tween_stop(n: Node) -> void:
	if not is_instance_valid(n):
		return
	for target: Node in [n, main(n)]:
		if target == null:
			continue
		var t: Variant = _tweens.get(target.get_instance_id())
		if t is Tween and (t as Tween).is_valid():
			(t as Tween).kill()


func tween_running(n: Node) -> bool:
	if not is_instance_valid(n):
		return false
	for target: Node in [n, main(n)]:
		if target == null:
			continue
		var t: Variant = _tweens.get(target.get_instance_id())
		if t is Tween and (t as Tween).is_valid() and (t as Tween).is_running():
			return true
	return false


## Мигание: объект N раз пропадает и появляется за заданное время.
## Отдельно от твина — им управляет своя петля, и гасить его не надо.
func blink(n: Node, seconds: float, times: float) -> void:
	var ci := n as CanvasItem
	if ci == null or not is_instance_valid(n):
		return
	var count := maxi(1, int(times))
	var step := maxf(0.02, seconds / float(count * 2))
	var t := ci.create_tween()
	for _i in range(count):
		t.tween_property(ci, "modulate:a", 0.0, step)
		t.tween_property(ci, "modulate:a", 1.0, step)


# -------------------------------------------------------------------- сцена 2 ---

func scene_name() -> String:
	var s := get_tree().current_scene
	return s.name if s != null else ""
