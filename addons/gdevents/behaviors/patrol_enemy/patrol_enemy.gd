## Поведение «Патрульный враг».
##
## @behavior PatrolEnemy
## @title Патрульный враг
## @title.en Patrolling enemy
## @target CharacterBody2D
## @needs CollisionShape2D Форма
## @needs.en CollisionShape2D Shape
## @needs AnimatedSprite2D|Sprite2D Спрайт
## @needs.en AnimatedSprite2D|Sprite2D Sprite
## @description Готовый враг платформера без единого события: ходит по платформе, разворачивается у края и у стены, замечает игрока лучом, гонится, теряет и возвращается на свой участок.
## @description.en A ready-made platformer enemy without a single event: walks along a platform, turns at edges and walls, spots the player with a ray, chases, loses and returns to its beat.
## @icon patrol
@tool
extends GdeBehavior

## Заметил цель.
signal spotted
## Потерял цель.
signal lost
## Развернулся у края, у стены или на границе участка.
signal turned

enum State { PATROL, TURN_PAUSE, CHASE, SEARCH, RETURN }

## @group.en Patrol
@export_group("Патруль")
## Скорость патруля, пикселей в секунду.
## @en Patrol speed, pixels per second.
@export_range(0.0, 1000.0, 5.0) var walk_speed: float = 60.0
## В какую сторону идти сначала.
## @en Which way to walk first.
## @options.en Right, Left
@export_enum("Вправо", "Влево") var start_direction: int = 0
## Разворот у края платформы — не падать вниз.
## @en Turn at the platform edge — do not fall off.
@export var turn_at_edges: bool = true
## Разворот, упёршись в стену.
## @en Turn when bumping into a wall.
@export var turn_at_walls: bool = true
## Участок патруля — на сколько пикселей можно отойти от места старта. 0 — без предела.
## @en Patrol beat — how many pixels it may walk away from the start. 0 — no limit.
@export_range(0.0, 5000.0, 10.0) var patrol_range: float = 0.0
## Пауза при развороте, секунд.
## @en Pause when turning, seconds.
@export_range(0.0, 5.0, 0.05) var turn_pause: float = 0.3
## Патруль включён.
## @en The patrol is on.
@export var running: bool = true

## @group.en Vision
@export_group("Зрение")
## Цель — имя объекта из листа событий, например Player.
## @en Target — the name of an object from the event sheet, e.g. Player.
@export var target_object: String = "Player"
## Дальность взгляда, пикселей.
## @en Sight range, pixels.
@export_range(0.0, 3000.0, 10.0) var sight_range: float = 220.0
## Высота взгляда — насколько выше или ниже себя замечает цель.
## @en Sight height — how far above or below itself it notices the target.
@export_range(0.0, 1000.0, 5.0) var sight_height: float = 60.0
## Замечает и за спиной, а не только впереди.
## @en Notices behind its back too, not only in front.
@export var sees_behind: bool = false
## Стены загораживают взгляд.
## @en Walls block the view.
@export var walls_block_sight: bool = true

## @group.en Chase
@export_group("Погоня")
## Гнаться за замеченной целью.
## @en Chase a spotted target.
@export var chase: bool = true
## Скорость погони, пикселей в секунду.
## @en Chase speed, pixels per second.
@export_range(0.0, 2000.0, 5.0) var chase_speed: float = 130.0
## Сколько секунд искать цель, пропавшую из виду, прежде чем сдаться.
## @en How many seconds to search for a target out of sight before giving up.
@export_range(0.0, 30.0, 0.1) var lose_time: float = 1.5
## Не прыгать с края в погоне — остановиться и ждать.
## @en Do not jump off an edge while chasing — stop and wait.
@export var stop_at_edges: bool = true
## Потеряв цель, вернуться на свой участок.
## @en After losing the target, return to its beat.
@export var return_home: bool = true

## @group.en Gravity
@export_group("Гравитация")
## Сила тяжести, пикселей в секунду за секунду.
## @en Gravity strength, pixels per second per second.
@export_range(0.0, 5000.0, 10.0) var gravity: float = 1300.0
## Предел скорости падения.
## @en Maximum fall speed.
@export_range(0.0, 3000.0, 10.0) var max_fall_speed: float = 900.0

## @group.en Look
@export_group("Вид")
## Отражение спрайта по направлению движения.
## @en Flip the sprite toward the movement direction.
@export var flip_sprite: bool = true
## Автоматические анимации по состоянию. Имена ниже должны совпадать с AnimatedSprite2D.
## @en Automatic animations by state. The names below must match the AnimatedSprite2D.
@export var animate: bool = false
## Анимация ходьбы — имя из AnimatedSprite2D.
## @en Walk animation — a name from AnimatedSprite2D.
@export var walk_animation: String = "Run"
## Анимация покоя — во время паузы и ожидания.
## @en Idle animation — during pauses and waiting.
@export var idle_animation: String = "Idle"
## Анимация погони. Пусто — анимация ходьбы.
## @en Chase animation. Empty — the walk animation.
@export var chase_animation: String = ""

var _state: State = State.PATROL
var _dir: float = 1.0
var _home_x: float = 0.0
var _has_home: bool = false
var _pause_left: float = 0.0
var _unseen: float = 0.0
var _last_seen_x: float = 0.0
var _target: Node2D = null
var _spot_frame: int = -100
var _turn_frame: int = -100
var _flip_dir: float = 0.0


func _physics_process(delta: float) -> void:
	var body := object as CharacterBody2D
	if body == null:
		return
	if not _has_home:
		_home_x = body.global_position.x
		_dir = -1.0 if start_direction == 1 else 1.0
		_has_home = true

	var on_floor := body.is_on_floor()
	_look(body)
	var want := 0.0
	if running:
		want = _think(body, on_floor, delta)
	body.velocity.x = want
	if not on_floor:
		body.velocity.y = minf(body.velocity.y + gravity * delta, max_fall_speed)
	body.move_and_slide()
	_update_look(body, want)


## Скорость по горизонтали, которую хочет состояние.
func _think(body: CharacterBody2D, on_floor: bool, delta: float) -> float:
	match _state:
		State.TURN_PAUSE:
			_pause_left -= delta
			if _pause_left <= 0.0:
				_state = State.PATROL
			return 0.0
		State.CHASE, State.SEARCH:
			if _target != null:
				_last_seen_x = _target.global_position.x
				_unseen = 0.0
				_state = State.CHASE
			else:
				_unseen += delta
				_state = State.SEARCH
				if _unseen >= lose_time:
					lost.emit()
					_state = State.RETURN if return_home else State.PATROL
					return 0.0
			var dx := _last_seen_x - body.global_position.x
			if absf(dx) < 4.0:
				return 0.0
			_dir = signf(dx)
			if stop_at_edges and on_floor and _edge_ahead(body):
				return 0.0
			return _dir * chase_speed
		State.RETURN:
			var hx := _home_x - body.global_position.x
			if absf(hx) < 4.0:
				_state = State.PATROL
				return 0.0
			_dir = signf(hx)
			if _blocked(body, on_floor):
				_state = State.PATROL
				return 0.0
			return _dir * walk_speed
	# Патруль.
	var away := (body.global_position.x - _home_x) * _dir
	if (patrol_range > 0.0 and away >= patrol_range) or _blocked(body, on_floor):
		_turn()
		return 0.0
	return _dir * walk_speed


## Край или стена впереди.
func _blocked(body: CharacterBody2D, on_floor: bool) -> bool:
	if turn_at_walls and body.is_on_wall() and signf(body.get_wall_normal().x) == -_dir:
		return true
	return turn_at_edges and on_floor and _edge_ahead(body)


## Луч вниз чуть впереди ног: пусто — там обрыв.
func _edge_ahead(body: CharacterBody2D) -> bool:
	var r := Gde.aabb(body)
	if r.size == Vector2.ZERO:
		return false
	var x := r.end.x + 2.0 if _dir > 0.0 else r.position.x - 2.0
	var q := PhysicsRayQueryParameters2D.create(Vector2(x, r.get_center().y), Vector2(x, r.end.y + 10.0))
	q.collision_mask = body.collision_mask
	q.exclude = [body.get_rid()]
	return body.get_world_2d().direct_space_state.intersect_ray(q).is_empty()


func _turn() -> void:
	_dir = -_dir
	_turn_frame = Engine.get_physics_frames()
	turned.emit()
	if turn_pause > 0.0:
		_pause_left = turn_pause
		_state = State.TURN_PAUSE


## Ищет цель глазами; замеченная переводит в погоню.
func _look(body: CharacterBody2D) -> void:
	_target = null
	if target_object.is_empty() or sight_range <= 0.0:
		return
	var chasing := _state == State.CHASE or _state == State.SEARCH
	for n: Node in Gde.all_instances(target_object):
		var t := Gde.main(n)
		if t == null or t == body:
			continue
		var to := t.global_position - body.global_position
		if to.length() > sight_range or absf(to.y) > sight_height:
			continue
		# В погоне цель видна и за спиной: иначе враг терял бы её при каждом развороте.
		if not sees_behind and not chasing and signf(to.x) != _dir and absf(to.x) > 1.0:
			continue
		if walls_block_sight and not Gde.has_line_of_sight(body, n):
			continue
		_target = t
		break
	if _target != null and chase and not chasing:
		_state = State.CHASE
		_spot_frame = Engine.get_physics_frames()
		spotted.emit()


func _update_look(body: CharacterBody2D, want: float) -> void:
	if flip_sprite and _dir != _flip_dir:
		_flip_dir = _dir
		Gde.set_flip_h(body, _dir < 0.0)
	if not animate:
		return
	var anim := idle_animation
	if absf(want) > 1.0:
		anim = chase_animation if _state == State.CHASE and not chase_animation.is_empty() else walk_animation
	Gde.auto_animation(body, anim)


## @action Развернуть _PARAM0_
## @action.en Turn _PARAM0_ around
func turn_around() -> void:
	_turn()


## @action Задать цель для _PARAM0_: объект _PARAM1_
## @action.en Set the target of _PARAM0_: object _PARAM1_
## @param name Имя объекта
## @param.en name Object name
func set_target(name: String) -> void:
	target_object = name


## @action Сделать место _PARAM0_ центром участка патруля
## @action.en Make the current place of _PARAM0_ the center of its patrol beat
func set_home_here() -> void:
	var body := object as Node2D
	if body != null:
		_home_x = body.global_position.x
		_has_home = true


## Прекратить погоню и поиск.
## @en Stop chasing and searching.
## @action Вернуть _PARAM0_ к патрулю
## @action.en Send _PARAM0_ back to patrolling
func back_to_patrol() -> void:
	_state = State.RETURN if return_home else State.PATROL


## @condition _PARAM0_ гонится за целью
## @condition.en _PARAM0_ is chasing the target
func is_chasing() -> bool:
	return _state == State.CHASE


## @condition _PARAM0_ ищет пропавшую цель
## @condition.en _PARAM0_ is searching for a lost target
func is_searching() -> bool:
	return _state == State.SEARCH


## @condition _PARAM0_ патрулирует
## @condition.en _PARAM0_ is patrolling
func is_patrolling() -> bool:
	return _state == State.PATROL or _state == State.TURN_PAUSE


## @condition _PARAM0_ возвращается на свой участок
## @condition.en _PARAM0_ is returning to its beat
func is_returning() -> bool:
	return _state == State.RETURN


## @condition _PARAM0_ видит цель
## @condition.en _PARAM0_ sees the target
func sees_target() -> bool:
	return _target != null


## @condition _PARAM0_ только что заметил цель
## @condition.en _PARAM0_ has just spotted the target
func just_spotted() -> bool:
	return Engine.get_physics_frames() - _spot_frame <= RECENT_FRAMES


## @condition _PARAM0_ только что развернулся
## @condition.en _PARAM0_ has just turned around
func just_turned() -> bool:
	return Engine.get_physics_frames() - _turn_frame <= RECENT_FRAMES


## @expression Направление: 1 вправо, -1 влево
## @expression.en Direction: 1 right, -1 left
func direction() -> float:
	return _dir


## @expression Расстояние до замеченной цели, -1 — не видит
## @expression.en Distance to the spotted target, -1 — does not see it
func distance_to_target() -> float:
	var body := object as Node2D
	if body == null or _target == null:
		return -1.0
	return body.global_position.distance_to(_target.global_position)


## @expression Состояние текстом: patrol, chase, search или return
## @expression.en State as text: patrol, chase, search or return
func state_name() -> String:
	match _state:
		State.CHASE:
			return "chase"
		State.SEARCH:
			return "search"
		State.RETURN:
			return "return"
	return "patrol"
