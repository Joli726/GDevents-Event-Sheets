## Поведение «Поиск пути».
##
## @behavior Pathfinder
## @title Поиск пути
## @title.en Pathfinding
## @needs Sprite2D|AnimatedSprite2D Спрайт
## @needs.en Sprite2D|AnimatedSprite2D Sprite
## @description Идёт к цели в обход стен, а не упирается в них. Для вида сверху: уровень сам размечается на клетки, путь ищется по A* и сглаживается.
## @description.en Walks to the target around walls instead of bumping into them. For top-down games: the level is split into cells by itself, the path is found with A* and smoothed.
## @icon pathfinder
@tool
extends GdeBehavior

## Путь найден и объект пошёл по нему.
signal path_found
## До цели не добраться: всё загорожено.
signal path_failed
## Дошёл до цели.
signal arrived

## @group.en Target
@export_group("Цель")
## Цель — имя объекта из листа событий, например Player. Пусто — идти в точку из действия.
## @en Target — the name of an object from the event sheet, e.g. Player. Empty — go to the point from the action.
@export var target_object: String = ""
## Дистанция остановки — на каком расстоянии от цели остановиться.
## @en Stop distance — how far from the target to stop.
@export_range(0.0, 500.0, 1.0) var stop_distance: float = 8.0
## Пересчёт пути — как часто искать путь к движущейся цели заново, секунд.
## @en Repath interval — how often to look for a new path to a moving target, seconds.
@export_range(0.05, 10.0, 0.05) var repath_interval: float = 0.5
## Движение к цели включено.
## @en Moving to the target is on.
@export var running: bool = true

## @group.en Movement
@export_group("Движение")
## Скорость, пикселей в секунду.
## @en Speed, pixels per second.
@export_range(0.0, 2000.0, 5.0) var speed: float = 120.0
## Поворот по направлению движения.
## @en Turn toward the movement direction.
@export var rotate_object: bool = false
## Отражение спрайта по направлению движения.
## @en Flip the sprite — toward the movement direction.
@export var flip_sprite: bool = false

## @group.en Grid
@export_group("Сетка")
## Размер клетки, пикселей. Меньше — точнее путь в узких проходах, но дольше поиск.
## @en Cell size, pixels. Smaller — a more precise path in narrow passages, but a longer search.
@export_range(4.0, 128.0, 1.0) var cell_size: float = 16.0
## Радиус объекта — насколько держаться от стен. 0 — половина клетки.
## @en Object radius — how far to keep from walls. 0 — half a cell.
@export_range(0.0, 256.0, 1.0) var agent_radius: float = 0.0
## Запас поиска вокруг объекта и цели, в клетках — насколько далеко можно уйти в обход.
## @en Search margin, in cells — how far a detour around the object and the target may go.
@export_range(1, 200, 1) var search_margin: int = 12
## Ходить по диагонали.
## @en Walk diagonally.
@export var diagonals: bool = true
## Если цель недостижима — подойти как можно ближе.
## @en If the target is unreachable, come as close as possible.
@export var partial_path: bool = true
## Показывать путь линией — для отладки.
## @en Show the path as a line — for debugging.
@export var show_path: bool = false

var _path: PackedVector2Array = PackedVector2Array()
var _next: int = 0
var _goal: Vector2 = Vector2.ZERO
var _has_goal: bool = false
var _repath_left: float = 0.0
var _arrived: bool = false
var _failed: bool = false
var _arrive_frame: int = -100
## Клетка -> загорожена ли. Стены неподвижны, поэтому разметка копится.
var _solid: Dictionary = {}
var _line: Line2D = null
var _probe: CircleShape2D = null


func _physics_process(delta: float) -> void:
	var o := object as Node2D
	if o == null:
		return
	var goal: Variant = _current_goal() if running else null
	if goal == null:
		_stop_body(o)
		_update_line()
		return
	var g: Vector2 = goal
	if o.global_position.distance_to(g) <= stop_distance:
		if not _arrived:
			_arrived = true
			_arrive_frame = Engine.get_physics_frames()
			arrived.emit()
		_path = PackedVector2Array()
		_stop_body(o)
		_update_line()
		return
	_arrived = false
	# Путь пересчитывается не чаще раза в repath_interval — и только если
	# его нет, он кончился или цель ушла больше чем на полклетки.
	_repath_left -= delta
	if _repath_left <= 0.0 and (_next >= _path.size() or g.distance_to(_goal) > cell_size * 0.5):
		_find_path(o, g)
		_repath_left = repath_interval
	_move(o, delta)
	_update_line()


func _current_goal() -> Variant:
	if not target_object.is_empty():
		var best: Node2D = null
		var best_d := INF
		for n: Node in Gde.all_instances(target_object):
			var t := Gde.main(n)
			if t == null or t == object:
				continue
			var d := t.global_position.distance_squared_to((object as Node2D).global_position)
			if d < best_d:
				best_d = d
				best = t
		return best.global_position if best != null else null
	return _goal if _has_goal else null


func _move(o: Node2D, delta: float) -> void:
	if _next >= _path.size():
		_stop_body(o)
		return
	var at := o.global_position
	var step := speed * delta
	var to := _path[_next] - at
	while to.length() <= maxf(step, 1.0) and _next < _path.size() - 1:
		_next += 1
		to = _path[_next] - at
	if to.length() <= maxf(step, 1.0):
		# Последняя точка пути: встать ровно на неё.
		_next = _path.size()
	var vel := to.normalized() * speed if to.length() > 0.5 else Vector2.ZERO
	var body := o as CharacterBody2D
	if body != null:
		body.velocity = vel if to.length() > step else to / maxf(delta, 0.0001)
		body.move_and_slide()
	else:
		o.global_position = at + to.limit_length(step)
	if vel.length() > 1.0:
		if rotate_object:
			o.global_rotation = vel.angle()
		if flip_sprite and absf(vel.x) > 1.0:
			Gde.set_flip_h(o, vel.x < 0.0)


func _stop_body(o: Node2D) -> void:
	var body := o as CharacterBody2D
	if body != null:
		body.velocity = Vector2.ZERO


# ----------------------------------------------------------------- поиск ---

func _find_path(o: Node2D, goal: Vector2) -> void:
	var from := _cell(o.global_position)
	var to := _cell(goal)
	var lo := Vector2i(mini(from.x, to.x), mini(from.y, to.y)) - Vector2i.ONE * search_margin
	var hi := Vector2i(maxi(from.x, to.x), maxi(from.y, to.y)) + Vector2i.ONE * search_margin
	var grid := AStarGrid2D.new()
	grid.region = Rect2i(lo, hi - lo + Vector2i.ONE)
	grid.cell_size = Vector2.ONE * cell_size
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES if diagonals \
			else AStarGrid2D.DIAGONAL_MODE_NEVER
	grid.update()
	var exclude := _exclude(o)
	for x in range(lo.x, hi.x + 1):
		for y in range(lo.y, hi.y + 1):
			var c := Vector2i(x, y)
			if c != from and _is_solid(o, c, exclude):
				grid.set_point_solid(c, true)
	# Цель в стене (её тело больше клетки) — ищем ближайшую свободную рядом.
	if grid.is_point_solid(to):
		to = _free_near(grid, to)
	var cells := grid.get_id_path(from, to, partial_path)
	_goal = goal
	_next = 0
	if cells.is_empty() or (not partial_path and cells[cells.size() - 1] != to):
		_path = PackedVector2Array()
		if not _failed:
			_failed = true
			path_failed.emit()
		return
	var pts := PackedVector2Array()
	pts.append(o.global_position)
	for i in range(1, cells.size()):
		pts.append(_center(cells[i]))
	# Последняя точка — сама цель, если до неё добрались.
	if cells[cells.size() - 1] == to:
		pts[pts.size() - 1] = goal
	_path = _smooth(o, pts, exclude)
	_next = 1 if _path.size() > 1 else 0
	var was_failed := _failed
	_failed = cells[cells.size() - 1] != to
	if _failed and not was_failed:
		path_failed.emit()
	elif not _failed:
		path_found.emit()


func _cell(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / cell_size), floori(p.y / cell_size))


func _center(c: Vector2i) -> Vector2:
	return (Vector2(c) + Vector2(0.5, 0.5)) * cell_size


func _radius() -> float:
	return agent_radius if agent_radius > 0.0 else cell_size * 0.5


## Загорожена ли клетка неподвижной стеной (тело или слой тайлов).
## Движущиеся тела — персонажи, ящики — препятствием не считаются:
## их разметка устарела бы через кадр.
func _is_solid(o: Node2D, c: Vector2i, exclude: Array[RID]) -> bool:
	if _solid.has(c):
		return _solid[c]
	# Одна фигура на все клетки: их сотни за поиск.
	if _probe == null:
		_probe = CircleShape2D.new()
	_probe.radius = maxf(1.0, _radius() - 0.5)
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = _probe
	q.transform = Transform2D(0.0, _center(c))
	q.collision_mask = _mask(o)
	q.exclude = exclude
	q.collide_with_areas = false
	var solid := false
	for hit: Dictionary in o.get_world_2d().direct_space_state.intersect_shape(q, 8):
		var col: Variant = hit.get("collider")
		if col is StaticBody2D or (col is Object and ((col as Object).is_class("TileMapLayer") \
				or (col as Object).is_class("TileMap"))):
			solid = true
			break
	_solid[c] = solid
	return solid


func _free_near(grid: AStarGrid2D, c: Vector2i) -> Vector2i:
	for r in range(1, 6):
		for dx in range(-r, r + 1):
			for dy in range(-r, r + 1):
				var n := c + Vector2i(dx, dy)
				if grid.is_in_boundsv(n) and not grid.is_point_solid(n):
					return n
	return c


## Срезать углы: из каждой точки идём сразу к самой дальней, до которой
## объект доходит по прямой, не задев стену. Иначе путь по клеткам шёл бы
## лесенкой.
func _smooth(o: Node2D, pts: PackedVector2Array, exclude: Array[RID]) -> PackedVector2Array:
	if pts.size() <= 2:
		return pts
	var out := PackedVector2Array([pts[0]])
	var i := 0
	while i < pts.size() - 1:
		var j := pts.size() - 1
		while j > i + 1 and not _clear(o, pts[i], pts[j], exclude):
			j -= 1
		out.append(pts[j])
		i = j
	return out


func _clear(o: Node2D, a: Vector2, b: Vector2, exclude: Array[RID]) -> bool:
	var shape := CircleShape2D.new()
	shape.radius = maxf(1.0, _radius() - 1.0)
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = shape
	q.transform = Transform2D(0.0, a)
	q.motion = b - a
	q.collision_mask = _mask(o)
	q.exclude = exclude
	var r := o.get_world_2d().direct_space_state.cast_motion(q)
	return r.size() > 0 and r[0] >= 1.0


## Во что упирается сам объект — то и стена. Без тела — первый слой.
func _mask(o: Node2D) -> int:
	var body := Gde.body_of(o)
	return body.collision_mask if body != null else 1


func _exclude(o: Node2D) -> Array[RID]:
	var out: Array[RID] = []
	_collect_rids(o, out)
	return out


func _collect_rids(n: Node, out: Array[RID]) -> void:
	if n is CollisionObject2D:
		out.append((n as CollisionObject2D).get_rid())
	for c: Node in n.get_children():
		_collect_rids(c, out)


func _update_line() -> void:
	if not show_path:
		if _line != null:
			_line.queue_free()
			_line = null
		return
	if _line == null:
		_line = Line2D.new()
		_line.width = 2.0
		_line.default_color = Color(1.0, 0.8, 0.2, 0.8)
		_line.top_level = true
		add_child(_line)
	var o := object as Node2D
	var pts := PackedVector2Array()
	if o != null and not _path.is_empty():
		pts.append(o.global_position)
		for i in range(_next, _path.size()):
			pts.append(_path[i])
	_line.points = pts


## @action Отправить _PARAM0_ в точку _PARAM1_ ; _PARAM2_
## @action.en Send _PARAM0_ to point _PARAM1_ ; _PARAM2_
## @param x X
## @param y Y
func go_to(x: float, y: float) -> void:
	target_object = ""
	_goal = Vector2(x, y)
	_has_goal = true
	_path = PackedVector2Array()
	_repath_left = 0.0
	_arrived = false
	running = true


## @action Вести _PARAM0_ к объекту _PARAM1_
## @action.en Lead _PARAM0_ to object _PARAM1_
## @param name Имя объекта
## @param.en name Object name
func go_to_object(name: String) -> void:
	target_object = name
	_path = PackedVector2Array()
	_repath_left = 0.0
	_arrived = false
	running = true


## @action Остановить _PARAM0_
## @action.en Stop _PARAM0_
func stop() -> void:
	running = false
	_has_goal = false
	_path = PackedVector2Array()


## Нужно, если стены передвинули или создали: разметка уровня забывается и строится заново.
## @en Needed if walls were moved or created: the level layout is forgotten and built again.
## @action Пересчитать путь _PARAM0_ заново
## @action.en Recompute the path of _PARAM0_ from scratch
func recompute() -> void:
	_solid.clear()
	_repath_left = 0.0
	_path = PackedVector2Array()


## @condition _PARAM0_ идёт по пути
## @condition.en _PARAM0_ is following a path
func is_moving() -> bool:
	return running and not _path.is_empty() and _next < _path.size() and not _arrived


## @condition _PARAM0_ дошёл до цели
## @condition.en _PARAM0_ reached the target
func has_arrived() -> bool:
	return _arrived


## @condition _PARAM0_ только что дошёл до цели
## @condition.en _PARAM0_ has just reached the target
func just_arrived() -> bool:
	return Engine.get_physics_frames() - _arrive_frame <= RECENT_FRAMES


## @condition До цели _PARAM0_ не добраться
## @condition.en _PARAM0_ cannot reach the target
func no_path() -> bool:
	return _failed


## @expression Длина оставшегося пути, пикселей
## @expression.en Length of the remaining path, pixels
func path_length() -> float:
	var o := object as Node2D
	if o == null or _path.is_empty() or _next >= _path.size():
		return 0.0
	var total := o.global_position.distance_to(_path[_next])
	for i in range(_next, _path.size() - 1):
		total += _path[i].distance_to(_path[i + 1])
	return total


## @expression Сколько точек пути осталось
## @expression.en How many path points are left
func points_left() -> float:
	return float(maxi(0, _path.size() - _next))


## @expression X следующей точки пути
## @expression.en X of the next path point
func next_x() -> float:
	return _path[_next].x if _next < _path.size() else 0.0


## @expression Y следующей точки пути
## @expression.en Y of the next path point
func next_y() -> float:
	return _path[_next].y if _next < _path.size() else 0.0
