## Поведение «Шаг по сетке».
##
## @behavior GridStep
## @title Шаг по сетке
## @title.en Grid step
## @needs Sprite2D|AnimatedSprite2D Спрайт
## @needs.en Sprite2D|AnimatedSprite2D Sprite
## @description Движение клетками: головоломки, рогалики, сокобан. Стены останавливают, объекты с этим же поведением занимают клетки, а «толкаемые» сдвигаются на клетку дальше.
## @description.en Movement by cells: puzzles, roguelikes, sokoban. Walls stop it, objects with the same behavior occupy cells, and "pushable" ones move one cell further.
## @icon grid
@tool
extends GdeBehavior

## Шагнул в соседнюю клетку.
signal stepped
## Упёрся: клетка занята.
signal bumped
## Сдвинул толкаемый объект.
signal pushed(other: Node)

const GROUP := "__gde_grid"
const DIRS: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]

## @group.en Grid
@export_group("Сетка")
## Размер клетки, пикселей.
## @en Cell size, pixels.
@export_range(1.0, 512.0, 1.0) var cell_size: float = 32.0
## Встать в центр клетки при старте.
## @en Snap to the center of a cell at the start.
@export var snap_on_start: bool = true
## Занимает клетку: другие объекты с «Шагом по сетке» в неё не войдут.
## @en Occupies its cell: other objects with "Grid step" cannot enter it.
@export var solid: bool = true
## Толкаемый — как ящик в сокобане: его можно сдвинуть, если за ним свободно.
## @en Pushable — like a sokoban crate: it can be moved if the cell behind it is free.
@export var pushable: bool = false
## Может толкать толкаемые объекты.
## @en Can push pushable objects.
@export var can_push: bool = true

## @group.en Movement
@export_group("Движение")
## Время одного шага, секунд. 0 — мгновенно.
## @en Time of one step, seconds. 0 — instant.
@export_range(0.0, 2.0, 0.01) var step_time: float = 0.12
## Управление стрелками — автоматически, без событий.
## @en Arrow keys controls — automatic, without events.
@export var default_controls: bool = false
## Повтор шага при удержании клавиши, секунд. 0 — один шаг на нажатие.
## @en Step repeat while a key is held, seconds. 0 — one step per press.
@export_range(0.0, 2.0, 0.01) var hold_repeat: float = 0.18
## Поворачивать объект в сторону шага.
## @en Rotate the object toward the step.
@export var rotate_object: bool = false
## Отражение спрайта по направлению шага.
## @en Flip the sprite toward the step direction.
@export var flip_sprite: bool = false

var _cell: Vector2i = Vector2i.ZERO
var _from: Vector2 = Vector2.ZERO
var _to: Vector2 = Vector2.ZERO
var _t: float = 1.0
var _started: bool = false
var _steps: int = 0
var _queued: int = -1
var _hold: float = 0.0
var _step_frame: int = -100
var _bump_frame: int = -100
var _facing: int = 0


func _ready() -> void:
	super()
	if not Engine.is_editor_hint():
		add_to_group(GROUP)


func _physics_process(delta: float) -> void:
	var o := object as Node2D
	if o == null:
		return
	if not _started:
		_started = true
		_cell = Vector2i((o.global_position / cell_size).floor())
		if snap_on_start:
			o.global_position = _center(_cell)
		_to = o.global_position
	if default_controls:
		_read_keys(delta)
	if _t < 1.0:
		_t = minf(1.0, _t + delta / maxf(step_time, 0.0001))
		o.global_position = _from.lerp(_to, _smooth(_t))
	elif _queued >= 0:
		var d := _queued
		_queued = -1
		step(float(d))


func _read_keys(delta: float) -> void:
	var dir := -1
	for pair: Array in [["ui_right", 0], ["ui_down", 1], ["ui_left", 2], ["ui_up", 3]]:
		if Input.is_action_just_pressed(pair[0]):
			dir = pair[1]
			_hold = hold_repeat
			break
		if hold_repeat > 0.0 and Input.is_action_pressed(pair[0]):
			_hold -= delta
			if _hold <= 0.0:
				dir = pair[1]
				_hold = hold_repeat
			break
	if dir >= 0:
		_queued = dir


static func _smooth(t: float) -> float:
	return t * t * (3.0 - 2.0 * t)


func _center(c: Vector2i) -> Vector2:
	return (Vector2(c) + Vector2(0.5, 0.5)) * cell_size


## Клетка, которую объект занимает или в которую уже идёт.
func occupied_cell() -> Vector2i:
	return _cell


func _mover_at(c: Vector2i) -> Node:
	for b: Node in get_tree().get_nodes_in_group(GROUP):
		if b != self and b.get("solid") and b.call("occupied_cell") == c:
			return b
	return null


## Стена — неподвижное тело или слой тайлов в центре клетки.
func _wall_at(c: Vector2i) -> bool:
	var o := object as Node2D
	var q := PhysicsPointQueryParameters2D.new()
	q.position = _center(c)
	q.collide_with_areas = false
	var body := Gde.body_of(o)
	q.collision_mask = body.collision_mask if body != null else 1
	if body != null:
		q.exclude = [body.get_rid()]
	for hit: Dictionary in o.get_world_2d().direct_space_state.intersect_point(q, 8):
		var col: Variant = hit.get("collider")
		if col is StaticBody2D or (col is Object and ((col as Object).is_class("TileMapLayer") \
				or (col as Object).is_class("TileMap"))):
			return true
	return false


## Можно ли войти в клетку: толкаемого соседа, если можно, двигаем.
func _enter(c: Vector2i, d: Vector2i, dry_run: bool) -> bool:
	if _wall_at(c):
		return false
	var other := _mover_at(c)
	if other == null:
		return true
	if not can_push or not other.get("pushable"):
		return false
	var beyond := c + d
	if dry_run:
		return not other.call("_wall_at", beyond) and other.call("_mover_at", beyond) == null
	if other.call("_move_to", beyond, d, true):
		pushed.emit(other)
		return true
	return false


## Сдвинуть на клетку; толкаемого — только если за ним свободно.
func _move_to(c: Vector2i, d: Vector2i, by_push: bool) -> bool:
	if by_push and (_wall_at(c) or _mover_at(c) != null):
		return false
	var o := object as Node2D
	if o == null:
		return false
	_cell = c
	_from = o.global_position
	_to = _center(c)
	_t = 0.0 if step_time > 0.0 else 1.0
	if _t >= 1.0:
		o.global_position = _to
	_steps += 1
	_step_frame = Engine.get_physics_frames()
	stepped.emit()
	_face(o, d)
	return true


func _face(o: Node2D, d: Vector2i) -> void:
	_facing = DIRS.find(d)
	if rotate_object:
		o.global_rotation = Vector2(d).angle()
	if flip_sprite and d.x != 0:
		Gde.set_flip_h(o, d.x < 0)


## 0 — вправо, 1 — вниз, 2 — влево, 3 — вверх.
## @en 0 — right, 1 — down, 2 — left, 3 — up.
## @action Шагнуть _PARAM0_ в сторону _PARAM1_ (0 вправо, 1 вниз, 2 влево, 3 вверх)
## @action.en Step _PARAM0_ toward _PARAM1_ (0 right, 1 down, 2 left, 3 up)
## @param direction Направление
## @param.en direction Direction
func step(direction: float) -> void:
	var o := object as Node2D
	if o == null:
		return
	var i := posmod(int(direction), 4)
	if _t < 1.0:
		# Идёт шаг — запомним следующий, как буфер прыжка в платформере.
		_queued = i
		return
	var d := DIRS[i]
	var c := _cell + d
	if not _enter(c, d, false):
		_face(o, d)
		_bump_frame = Engine.get_physics_frames()
		bumped.emit()
		return
	_move_to(c, d, false)


## @action Шагнуть _PARAM0_ вправо
## @action.en Step _PARAM0_ right
func step_right() -> void:
	step(0.0)


## @action Шагнуть _PARAM0_ вниз
## @action.en Step _PARAM0_ down
func step_down() -> void:
	step(1.0)


## @action Шагнуть _PARAM0_ влево
## @action.en Step _PARAM0_ left
func step_left() -> void:
	step(2.0)


## @action Шагнуть _PARAM0_ вверх
## @action.en Step _PARAM0_ up
func step_up() -> void:
	step(3.0)


## @action Поставить _PARAM0_ в клетку _PARAM1_ ; _PARAM2_
## @action.en Put _PARAM0_ into cell _PARAM1_ ; _PARAM2_
## @param cx Клетка по X
## @param.en cx Cell X
## @param cy Клетка по Y
## @param.en cy Cell Y
func teleport(cx: float, cy: float) -> void:
	var o := object as Node2D
	if o == null:
		return
	_started = true
	_cell = Vector2i(int(cx), int(cy))
	_t = 1.0
	_queued = -1
	o.global_position = _center(_cell)
	_to = o.global_position


## @condition _PARAM0_ шагает
## @condition.en _PARAM0_ is stepping
func is_stepping() -> bool:
	return _t < 1.0


## @condition _PARAM0_ может шагнуть в сторону _PARAM1_ (0 вправо, 1 вниз, 2 влево, 3 вверх)
## @condition.en _PARAM0_ can step toward _PARAM1_ (0 right, 1 down, 2 left, 3 up)
## @param direction Направление
## @param.en direction Direction
func can_step(direction: float) -> bool:
	var d := DIRS[posmod(int(direction), 4)]
	return _enter(_cell + d, d, true)


## @condition _PARAM0_ только что шагнул
## @condition.en _PARAM0_ has just stepped
func just_stepped() -> bool:
	return Engine.get_physics_frames() - _step_frame <= RECENT_FRAMES


## @condition _PARAM0_ только что упёрся
## @condition.en _PARAM0_ has just bumped into something
func just_bumped() -> bool:
	return Engine.get_physics_frames() - _bump_frame <= RECENT_FRAMES


## @expression Клетка по X
## @expression.en Cell X
func cell_x() -> float:
	return float(_cell.x)


## @expression Клетка по Y
## @expression.en Cell Y
func cell_y() -> float:
	return float(_cell.y)


## @expression Сколько шагов сделано
## @expression.en How many steps were taken
func steps_taken() -> float:
	return float(_steps)


## @expression Куда смотрит: 0 вправо, 1 вниз, 2 влево, 3 вверх
## @expression.en Where it faces: 0 right, 1 down, 2 left, 3 up
func facing() -> float:
	return float(_facing)
