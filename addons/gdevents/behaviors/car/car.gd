## Поведение «Машина».
##
## @behavior Car
## @title Машина (вид сверху)
## @title.en Car (top-down)
## @target CharacterBody2D
## @needs CollisionShape2D Форма
## @needs.en CollisionShape2D Shape
## @needs Sprite2D|AnimatedSprite2D Спрайт
## @needs.en Sprite2D|AnimatedSprite2D Sprite
## @description Машина для вида сверху: газ, тормоз, задний ход, руль, занос и ручник. Спрайт машины должен смотреть вправо. Управление стрелками и пробелом — без событий.
## @description.en A car for top-down games: throttle, brake, reverse, steering, drifting and a handbrake. The car sprite must face right. Arrow keys and space controls — without events.
## @icon car
@tool
extends GdeBehavior

## Машину начало заносить.
signal drift_started
## Занос кончился.
signal drift_ended
## Врезалась во что-то на скорости.
signal crashed(speed: float)

const PRESETS: Array[Dictionary] = [
	{},
	# Аркада — цепкая, послушная, почти без заноса.
	{"max_speed": 420.0, "acceleration": 500.0, "braking": 900.0, "reverse_speed": 160.0,
		"friction": 200.0, "turn_speed": 200.0, "grip": 0.35, "drift_grip": 0.06},
	# Дрифт — легко срывается в занос и долго скользит боком.
	{"max_speed": 460.0, "acceleration": 450.0, "braking": 700.0, "reverse_speed": 150.0,
		"friction": 120.0, "turn_speed": 220.0, "grip": 0.08, "drift_grip": 0.02},
	# Грузовик — тяжёлый и неповоротливый.
	{"max_speed": 260.0, "acceleration": 180.0, "braking": 500.0, "reverse_speed": 100.0,
		"friction": 150.0, "turn_speed": 90.0, "grip": 0.5, "drift_grip": 0.1},
	# Картинг — резвый старт и острый руль.
	{"max_speed": 340.0, "acceleration": 900.0, "braking": 1200.0, "reverse_speed": 140.0,
		"friction": 300.0, "turn_speed": 280.0, "grip": 0.6, "drift_grip": 0.08},
]

## @group.en Preset
@export_group("Пресет")
## Готовый набор настроек. Сам по себе ничего не меняет — нажмите галочку ниже.
## @en A ready-made set of settings. It changes nothing by itself — press the checkbox below.
## @options.en Custom, Arcade, Drift, Truck, Kart
@export_enum("Свои настройки", "Аркада", "Дрифт", "Грузовик", "Картинг")
var preset: int = 1
## Поставьте галочку, чтобы записать выбранный пресет в настройки ниже.
## Галочка тут же снимается: это кнопка, а не переключатель.
## @en Check the box to write the selected preset into the settings below. The box unchecks itself right away: it is a button, not a switch.
## @internal
@export var apply_preset: bool = false:
	set(v):
		apply_preset = false
		if v and preset > 0 and preset < PRESETS.size():
			apply_values(PRESETS[preset])

## @group.en Engine
@export_group("Двигатель")
## Максимальная скорость вперёд, пикселей в секунду.
## @en Maximum forward speed, pixels per second.
@export_range(0.0, 3000.0, 5.0) var max_speed: float = 420.0
## Разгон, пикселей в секунду за секунду.
## @en Acceleration, pixels per second per second.
@export_range(0.0, 10000.0, 10.0) var acceleration: float = 500.0
## Торможение, пикселей в секунду за секунду.
## @en Braking, pixels per second per second.
@export_range(0.0, 10000.0, 10.0) var braking: float = 900.0
## Скорость заднего хода.
## @en Reverse speed.
@export_range(0.0, 3000.0, 5.0) var reverse_speed: float = 160.0
## Сопротивление качению — как быстро машина катится до остановки без газа.
## @en Rolling resistance — how fast the car rolls to a stop without throttle.
@export_range(0.0, 5000.0, 10.0) var friction: float = 200.0

## @group.en Handling
@export_group("Управляемость")
## Скорость поворота руля, градусов в секунду на полном ходу.
## @en Steering speed, degrees per second at full speed.
@export_range(0.0, 1000.0, 5.0) var turn_speed: float = 200.0
## Сцепление — насколько быстро гасится скольжение вбок. 1 — как по рельсам, меньше — больше заноса.
## @en Grip — how fast sideways sliding dies down. 1 — like on rails, less — more drifting.
@export_range(0.0, 1.0, 0.01) var grip: float = 0.35
## Сцепление на ручнике — меньше, чем обычное, чтобы машину заносило.
## @en Grip on the handbrake — lower than normal so the car slides.
@export_range(0.0, 1.0, 0.01) var drift_grip: float = 0.06
## Торможение ручником, пикселей в секунду за секунду.
## @en Handbrake braking, pixels per second per second.
@export_range(0.0, 10000.0, 10.0) var handbrake_force: float = 300.0
## С какой скорости скольжения вбок считать, что машину заносит.
## @en Drift threshold — from what sideways sliding speed the car counts as drifting.
@export_range(0.0, 1000.0, 5.0) var drift_threshold: float = 70.0

## @group.en Controls
@export_group("Управление")
## Управление стрелками и пробелом — автоматически, без событий: вверх — газ, вниз — тормоз и задний ход, пробел — ручник.
## @en Arrow keys and space controls — automatic, without events: up — throttle, down — brake and reverse, space — handbrake.
@export var default_controls: bool = true
## Сила удара о стену, с которой срабатывает «врезалась».
## @en Impact speed at which "crashed" fires.
@export_range(0.0, 3000.0, 10.0) var crash_speed: float = 150.0

var _heading: float = 0.0
var _started: bool = false
var _throttle: float = 0.0
var _steer: float = 0.0
var _handbrake: bool = false
var _drifting: bool = false
var _crash_frame: int = -100


func _physics_process(delta: float) -> void:
	var body := object as CharacterBody2D
	if body == null:
		return
	if not _started:
		_started = true
		_heading = body.global_rotation
		# Вид сверху: пола нет, скольжение по стенам одинаковое во все стороны.
		body.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING

	var throttle := _throttle
	var steer := _steer
	var hand := _handbrake
	if default_controls:
		throttle += Input.get_axis("ui_down", "ui_up")
		steer += Input.get_axis("ui_left", "ui_right")
		hand = hand or Input.is_key_pressed(KEY_SPACE)
	throttle = clampf(throttle, -1.0, 1.0)
	steer = clampf(steer, -1.0, 1.0)
	_throttle = 0.0
	_steer = 0.0
	_handbrake = false

	# Сначала руль: он работает только на ходу и сильнее на скорости,
	# назад — наоборот.
	var fs0 := body.velocity.dot(Vector2.RIGHT.rotated(_heading))
	var turn_factor := clampf(absf(fs0) / maxf(1.0, max_speed * 0.3), 0.0, 1.0) * signf(fs0)
	_heading += deg_to_rad(turn_speed) * steer * turn_factor * delta

	# Скорость раскладывается уже по новому курсу: то, что не успело
	# повернуть вслед за кузовом, — скольжение вбок. Из него и занос.
	var fwd := Vector2.RIGHT.rotated(_heading)
	var side := Vector2(-fwd.y, fwd.x)
	var fs := body.velocity.dot(fwd)
	var ls := body.velocity.dot(side)

	if throttle > 0.0:
		fs = move_toward(fs, max_speed, acceleration * throttle * delta) if fs >= 0.0 \
				else move_toward(fs, 0.0, braking * delta)
	elif throttle < 0.0:
		fs = move_toward(fs, 0.0, braking * -throttle * delta) if fs > 1.0 \
				else move_toward(fs, -reverse_speed, acceleration * -throttle * delta)
	else:
		fs = move_toward(fs, 0.0, friction * delta)
	if hand:
		fs = move_toward(fs, 0.0, handbrake_force * delta)

	# Сцепление гасит скольжение вбок; на ручнике — слабее.
	var g := drift_grip if hand else grip
	ls *= pow(1.0 - clampf(g, 0.0, 1.0), delta * 60.0)
	body.velocity = fwd * fs + side * ls
	body.move_and_slide()
	body.global_rotation = _heading

	# Удар: движок в режиме «вид сверху» оставляет скорость как была, и
	# машина давила бы в стену на полном ходу. Гасим то, что шло в стену, —
	# это и есть сила удара.
	var impact := 0.0
	for i in body.get_slide_collision_count():
		var n := body.get_slide_collision(i).get_normal()
		var into := body.velocity.dot(n)
		if into < 0.0:
			body.velocity -= n * into
			impact = maxf(impact, -into)
	if impact >= crash_speed:
		_crash_frame = Engine.get_physics_frames()
		crashed.emit(impact)

	var drifting := absf(ls) >= drift_threshold
	if drifting != _drifting:
		_drifting = drifting
		if drifting:
			drift_started.emit()
		else:
			drift_ended.emit()


## @action Газ: _PARAM0_
## @action.en Throttle: _PARAM0_
func gas() -> void:
	_throttle += 1.0


## Тормоз на ходу, задний ход — если машина стоит.
## @en Brakes while moving, reverses when the car stands still.
## @action Тормоз и задний ход: _PARAM0_
## @action.en Brake and reverse: _PARAM0_
func brake() -> void:
	_throttle -= 1.0


## @action Руль влево: _PARAM0_
## @action.en Steer left: _PARAM0_
func steer_left() -> void:
	_steer -= 1.0


## @action Руль вправо: _PARAM0_
## @action.en Steer right: _PARAM0_
func steer_right() -> void:
	_steer += 1.0


## @action Ручник: _PARAM0_
## @action.en Handbrake: _PARAM0_
func handbrake() -> void:
	_handbrake = true


## @action Остановить _PARAM0_ на месте
## @action.en Stop _PARAM0_ on the spot
func stop() -> void:
	var body := object as CharacterBody2D
	if body != null:
		body.velocity = Vector2.ZERO


## @action Повернуть _PARAM0_ на угол _PARAM1_ градусов
## @action.en Turn _PARAM0_ to an angle of _PARAM1_ degrees
## @param angle_deg Угол, градусов
## @param.en angle_deg Angle, degrees
func set_heading(angle_deg: float) -> void:
	_heading = deg_to_rad(angle_deg)
	_started = true
	var body := object as Node2D
	if body != null:
		body.global_rotation = _heading


## @condition _PARAM0_ заносит
## @condition.en _PARAM0_ is drifting
func is_drifting() -> bool:
	return _drifting


## @condition _PARAM0_ едет задним ходом
## @condition.en _PARAM0_ is reversing
func is_reversing() -> bool:
	return forward_speed() < -1.0


## @condition _PARAM0_ едет
## @condition.en _PARAM0_ is moving
func is_moving() -> bool:
	var body := object as CharacterBody2D
	return body != null and body.velocity.length() > 5.0


## @condition _PARAM0_ только что врезалась
## @condition.en _PARAM0_ has just crashed
func just_crashed() -> bool:
	return Engine.get_physics_frames() - _crash_frame <= RECENT_FRAMES


## @expression Скорость вперёд, отрицательная — задний ход
## @expression.en Forward speed, negative — reversing
func forward_speed() -> float:
	var body := object as CharacterBody2D
	if body == null:
		return 0.0
	return body.velocity.dot(Vector2.RIGHT.rotated(_heading))


## @expression Скорость скольжения вбок
## @expression.en Sideways sliding speed
func drift_speed() -> float:
	var body := object as CharacterBody2D
	if body == null:
		return 0.0
	var fwd := Vector2.RIGHT.rotated(_heading)
	return absf(body.velocity.dot(Vector2(-fwd.y, fwd.x)))


## @expression Курс в градусах
## @expression.en Heading in degrees
func heading() -> float:
	return rad_to_deg(_heading)
