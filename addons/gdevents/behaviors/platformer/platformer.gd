## Поведение «Персонаж платформера».
##
## @behavior Platformer
## @title Персонаж платформера
## @title.en Platformer character
## @target CharacterBody2D
## @needs CollisionShape2D Форма
## @needs.en CollisionShape2D Shape
## @needs AnimatedSprite2D|Sprite2D Спрайт
## @needs.en AnimatedSprite2D|Sprite2D Sprite
## @description Платформер с характером: койот-тайм, буфер прыжка, переменная высота, двойной прыжок, скольжение по стенам и прыжок от них. Нужен CharacterBody2D с формой столкновения.
## @description.en A platformer with character: coyote time, jump buffer, variable height, double jump, wall sliding and wall jumps. Needs a CharacterBody2D with a collision shape.
## @icon platformer
@tool
extends GdeBehavior

## Прыгнул. Номер: 1 — с земли, 2 и дальше — в воздухе.
signal jumped(jump_index: int)
## Коснулся земли после полёта.
signal landed
## Оттолкнулся от стены.
signal wall_jumped
## Схватился за лестницу.
signal climb_started
## Слез с лестницы.
signal climb_ended
## Спрыгнул вниз сквозь одностороннюю платформу.
signal dropped_down

const PRESETS: Array[Dictionary] = [
	{},
	# Классический — ощущение старых платформеров.
	{
		"max_speed": 250.0, "acceleration": 1600.0, "deceleration": 1900.0,
		"turn_boost": 2.0, "air_control": 0.75,
		"jump_force": 430.0, "max_jumps": 1, "coyote_time": 0.10,
		"jump_buffer_time": 0.12, "variable_height": true, "jump_cut": 0.45,
		"gravity": 1300.0, "fall_gravity_factor": 1.4, "max_fall_speed": 900.0,
	},
	# Ледяной — долго разгоняется и почти не тормозит.
	{
		"max_speed": 260.0, "acceleration": 600.0, "deceleration": 220.0,
		"turn_boost": 1.2, "air_control": 0.95,
		"jump_force": 420.0, "max_jumps": 1, "coyote_time": 0.08,
		"jump_buffer_time": 0.12, "variable_height": true, "jump_cut": 0.5,
		"gravity": 1300.0, "fall_gravity_factor": 1.3, "max_fall_speed": 900.0,
	},
	# Луна — низкая гравитация, долгий зависон, двойной прыжок.
	{
		"max_speed": 210.0, "acceleration": 900.0, "deceleration": 900.0,
		"turn_boost": 1.5, "air_control": 1.0,
		"jump_force": 300.0, "max_jumps": 2, "coyote_time": 0.14,
		"jump_buffer_time": 0.15, "variable_height": true, "jump_cut": 0.6,
		"gravity": 420.0, "fall_gravity_factor": 1.0, "max_fall_speed": 400.0,
	},
	# Отзывчивый — резкий старт и стоп, тяжёлое падение.
	{
		"max_speed": 280.0, "acceleration": 6000.0, "deceleration": 6000.0,
		"turn_boost": 1.0, "air_control": 0.9,
		"jump_force": 450.0, "max_jumps": 1, "coyote_time": 0.06,
		"jump_buffer_time": 0.08, "variable_height": true, "jump_cut": 0.35,
		"gravity": 1500.0, "fall_gravity_factor": 1.9, "max_fall_speed": 1100.0,
	},
]

## @group.en Preset
@export_group("Пресет")
## Готовый набор настроек. Сам по себе ничего не меняет — нажмите галочку ниже.
## @en A ready-made set of settings. It changes nothing by itself — press the checkbox below.
## @options.en Custom, Classic, Icy, Moon, Responsive
@export_enum("Свои настройки", "Классический", "Ледяной", "Луна", "Отзывчивый")
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

## @group.en Running
@export_group("Бег")
## Максимальная скорость бега, пикселей в секунду.
## @en Maximum running speed, pixels per second.
@export_range(0.0, 2000.0, 1.0) var max_speed: float = 250.0
## Разгон — как быстро набирается скорость.
## @en Acceleration — how fast the speed builds up.
@export_range(0.0, 20000.0, 10.0) var acceleration: float = 1600.0
## Торможение — как быстро гасится скорость без ввода.
## @en Deceleration — how fast the speed dies down without input.
@export_range(0.0, 20000.0, 10.0) var deceleration: float = 1900.0
## Ускорение разворота — во сколько раз быстрее смена направления.
## @en Turn boost — how many times faster a change of direction is.
@export_range(1.0, 5.0, 0.1) var turn_boost: float = 2.0
## Управление в воздухе, доля от земного: 1 — как на земле, 0 — никакого.
## @en Air control, share of the ground one: 1 — as on the ground, 0 — none.
@export_range(0.0, 1.0, 0.05) var air_control: float = 0.75

## @group.en Jump
@export_group("Прыжок")
## Сила прыжка, пикселей в секунду.
## @en Jump force, pixels per second.
@export_range(0.0, 2000.0, 5.0) var jump_force: float = 430.0
## Число прыжков без касания земли. 2 — двойной прыжок.
## @en Number of jumps without touching the ground. 2 — double jump.
@export_range(1, 5, 1) var max_jumps: int = 1
## Сила прыжков в воздухе, доля от обычной.
## @en Force of jumps in the air, share of a normal one.
@export_range(0.1, 1.5, 0.05) var air_jump_factor: float = 0.9
## Койот-тайм — сколько секунд после схода с края ещё можно прыгнуть.
## @en Coyote time — how many seconds after leaving an edge a jump is still possible.
@export_range(0.0, 0.5, 0.01) var coyote_time: float = 0.10
## Буфер прыжка — сколько секунд нажатие ждёт приземления.
## @en Jump buffer — how many seconds a press waits for landing.
@export_range(0.0, 0.5, 0.01) var jump_buffer_time: float = 0.12
## Переменная высота прыжка — отпустил кнопку, прыжок оборвался.
## @en Variable jump height — release the button and the jump is cut.
@export var variable_height: bool = true
## Обрыв прыжка — во сколько раз гасится подъём при отпускании.
## @en Jump cut — how many times the rise is reduced on release.
@export_range(0.0, 1.0, 0.05) var jump_cut: float = 0.45

## @group.en Gravity
@export_group("Гравитация")
## Сила тяжести, пикселей в секунду за секунду.
## @en Gravity strength, pixels per second per second.
@export_range(0.0, 5000.0, 10.0) var gravity: float = 1300.0
## Тяжесть падения — во сколько раз оно тяжелее подъёма.
## @en Fall weight — how many times heavier a fall is than a rise.
@export_range(0.5, 4.0, 0.1) var fall_gravity_factor: float = 1.4
## Предел скорости падения.
## @en Maximum fall speed.
@export_range(0.0, 3000.0, 10.0) var max_fall_speed: float = 900.0

## @group.en Walls
@export_group("Стены")
## Скольжение по стене вместо падения.
## @en Slide down a wall instead of falling.
@export var wall_slide: bool = false
## Скорость сползания по стене.
## @en Wall slide speed.
@export_range(0.0, 500.0, 5.0) var wall_slide_speed: float = 60.0
## Прыжок от стены в противоположную сторону.
## @en Jump off a wall in the opposite direction.
@export var wall_jump: bool = false
## Толчок от стены по горизонтали.
## @en Horizontal push off the wall.
@export_range(0.0, 1000.0, 10.0) var wall_jump_push: float = 260.0
## Сила прыжка от стены вверх, доля от обычной.
## @en Upward force of a wall jump, share of a normal one.
@export_range(0.1, 2.0, 0.05) var wall_jump_up: float = 1.0
## Блокировка ввода после прыжка от стены, секунд.
## @en Input lock after a wall jump, seconds.
@export_range(0.0, 0.5, 0.01) var wall_jump_lock: float = 0.12

## @group.en Ladders and platforms
@export_group("Лестницы и платформы")
## Лазать по лестницам — зонам с поведением «Лестница»: вверх и вниз стрелками, прыжок — соскочить.
## @en Climb ladders — zones with the "Ladder" behavior: up and down with the arrow keys, jump to get off.
@export var climb_ladders: bool = true
## Скорость лазанья, пикселей в секунду.
## @en Climbing speed, pixels per second.
@export_range(0.0, 2000.0, 5.0) var climb_speed: float = 120.0
## Скорость вбок на лестнице, доля от бега. 0 — только вверх и вниз.
## @en Sideways speed on a ladder, share of running. 0 — only up and down.
@export_range(0.0, 1.0, 0.05) var ladder_side_speed: float = 0.4
## Спрыгивание вниз — сквозь односторонние платформы: «вниз» и прыжок.
## @en Drop down through one-way platforms: "down" and jump.
@export var drop_through: bool = true

## @group.en Look
@export_group("Вид")
## Отражение спрайта по направлению движения.
## @en Flip the sprite — toward the movement direction.
@export var flip_sprite: bool = true
## Автоматические анимации по состоянию. Имена ниже должны совпадать с AnimatedSprite2D.
## @en Automatic animations by state. The names below must match the AnimatedSprite2D.
@export var animate: bool = false
## Анимация покоя — имя из AnimatedSprite2D.
## @en Idle animation — a name from AnimatedSprite2D.
@export var idle_animation: String = "Idle"
## Анимация бега — имя из AnimatedSprite2D.
## @en Run animation — a name from AnimatedSprite2D.
@export var run_animation: String = "Run"
## Анимация подъёма в прыжке.
## @en Animation of rising in a jump.
@export var jump_animation: String = "Jump"
## Анимация падения.
## @en Fall animation.
@export var fall_animation: String = "Fall"
## Анимация прыжка в воздухе (второго и дальше). Пусто — та же, что у обычного.
## @en Animation of a jump in the air (the second and later). Empty — the same as a normal one.
@export var double_jump_animation: String = ""
## Анимация скольжения по стене. Пусто — анимация падения.
## @en Wall slide animation. Empty — the fall animation.
@export var wall_slide_animation: String = ""
## Анимация лазанья по лестнице. Пусто — анимация покоя.
## @en Ladder climbing animation. Empty — the idle animation.
@export var climb_animation: String = ""

## @group.en Controls
@export_group("Управление")
## Управление стрелками и пробелом — автоматически, без событий.
## @en Arrow keys and space controls — automatic, without events.
@export var default_controls: bool = true

var _dir: float = 0.0
var _jump_buffer: float = 0.0
var _coyote: float = 0.0
var _jumps_used: int = 0
var _jump_released: bool = false
var _wall_lock: float = 0.0
var _wall_sliding: bool = false
var _was_on_floor: bool = false
var _jump_frame: int = -10
var _land_frame: int = -10
var _climb_dir: float = 0.0
var _climbing: bool = false
var _ladder: Node = null
var _leave_ladder: bool = false
var _drop_wanted: bool = false
var _drop_frame: int = -10
## Тела односторонних платформ, сквозь которые сейчас спрыгиваем -> сколько ещё секунд.
var _dropping: Dictionary = {}


func _physics_process(delta: float) -> void:
	var body := object as CharacterBody2D
	if body == null:
		return

	var dir := _dir
	var vert := _climb_dir
	if default_controls:
		dir += Input.get_axis("ui_left", "ui_right")
		vert += Input.get_axis("ui_up", "ui_down")
		if Input.is_action_just_pressed("ui_accept"):
			if drop_through and Input.is_action_pressed("ui_down"):
				_drop_wanted = true
			else:
				_jump_buffer = jump_buffer_time
		if Input.is_action_just_released("ui_accept"):
			_jump_released = true
	dir = clampf(dir, -1.0, 1.0)
	vert = clampf(vert, -1.0, 1.0)
	_dir = 0.0
	_climb_dir = 0.0
	_forget_drops(body, delta)

	var on_ground := body.is_on_floor()
	if _drop_wanted:
		_drop_wanted = false
		var ow := _one_way_floor(body)
		if on_ground and ow != null:
			_drop(body, ow)
			on_ground = false
		else:
			# Под ногами не односторонняя платформа — это обычный прыжок.
			_jump_buffer = jump_buffer_time

	if climb_ladders and _update_climbing(body, on_ground, vert):
		_climb(body, dir, vert, delta)
		return
	_wall_lock = maxf(0.0, _wall_lock - delta)
	_jump_buffer = maxf(0.0, _jump_buffer - delta)

	if on_ground:
		_coyote = coyote_time
		if not _was_on_floor:
			_jumps_used = 0
			_land_frame = Engine.get_physics_frames()
			landed.emit()
	else:
		_coyote = maxf(0.0, _coyote - delta)

	# Скольжение по стене считаем до прыжка — от него зависит его тип.
	_wall_sliding = wall_slide and not on_ground and body.is_on_wall_only() \
			and body.velocity.y > 0.0
	if _wall_sliding:
		body.velocity.y = minf(body.velocity.y, wall_slide_speed)

	_try_jump(body)

	# Горизонталь. Сразу после прыжка от стены ввод игнорируется,
	# иначе игрок прилипает обратно к стене.
	if _wall_lock <= 0.0:
		var accel := acceleration if on_ground else acceleration * air_control
		var decel := deceleration if on_ground else deceleration * air_control
		if is_zero_approx(dir):
			body.velocity.x = move_toward(body.velocity.x, 0.0, decel * delta)
		else:
			var rate := accel
			if not is_zero_approx(body.velocity.x) and signf(dir) != signf(body.velocity.x):
				rate *= turn_boost
			body.velocity.x = move_toward(body.velocity.x, dir * max_speed, rate * delta)

	# Обрыв прыжка при отпускании кнопки.
	if variable_height and _jump_released and body.velocity.y < 0.0:
		body.velocity.y *= jump_cut
	_jump_released = false

	if not on_ground:
		var g := gravity
		if body.velocity.y > 0.0:
			g *= fall_gravity_factor
		body.velocity.y = minf(body.velocity.y + g * delta, max_fall_speed)

	_was_on_floor = on_ground
	body.move_and_slide()
	_update_look(body, on_ground)


# ---------------------------------------------------------- лестницы ---

## Решить, лезем ли. true — этот кадр персонаж на лестнице.
func _update_climbing(body: CharacterBody2D, on_ground: bool, vert: float) -> bool:
	var ladder := _ladder_at(body)
	if _climbing and (ladder == null or _leave_ladder):
		_set_climbing(body, false, null)
	elif _climbing and ladder != _ladder:
		# Перелез на соседнюю лестницу.
		if is_instance_valid(_ladder):
			_ladder.call("_climber", body, false)
		_ladder = ladder
		_ladder.call("_climber", body, true)
	elif not _climbing and ladder != null and absf(vert) > 0.5:
		# Стоя на полу, вниз не полезешь — разве что сквозь одностороннюю платформу.
		if not (on_ground and vert > 0.0 and _one_way_floor(body) == null):
			_set_climbing(body, true, ladder)
	_leave_ladder = false
	return _climbing


func _ladder_at(body: CharacterBody2D) -> Node:
	for n: Node in get_tree().get_nodes_in_group("__gde_ladder"):
		if n.call("contains", body.global_position):
			return n
	return null


func _set_climbing(body: CharacterBody2D, on: bool, ladder: Node) -> void:
	if on == _climbing:
		return
	_climbing = on
	if is_instance_valid(_ladder):
		_ladder.call("_climber", body, false)
	_ladder = ladder
	if on:
		_ladder.call("_climber", body, true)
		body.velocity = Vector2.ZERO
		_jumps_used = 0
		climb_started.emit()
	else:
		climb_ended.emit()


func _climb(body: CharacterBody2D, dir: float, vert: float, delta: float) -> void:
	var own: float = float(_ladder.get("climb_speed"))
	var sp := own if own > 0.0 else climb_speed
	body.velocity.y = vert * sp
	body.velocity.x = dir * max_speed * ladder_side_speed
	if bool(_ladder.get("snap_to_center")) and is_zero_approx(dir):
		var cx := (_ladder.call("zone") as Rect2).get_center().x
		body.velocity.x = clampf((cx - body.global_position.x) / maxf(delta, 0.0001), -sp, sp)
	if body.is_on_floor() and vert > 0.0:
		var ow := _one_way_floor(body)
		if ow != null:
			_drop(body, ow)
		else:
			# Долез до пола — стоим.
			_set_climbing(body, false, null)
	# С лестницы спрыгивают, как с земли.
	_coyote = maxf(coyote_time, delta * 2.0)
	_jumps_used = 0
	var before := _jump_frame
	_try_jump(body)
	if _jump_frame != before:
		_set_climbing(body, false, null)
	body.move_and_slide()
	_was_on_floor = body.is_on_floor()
	if animate and _climbing:
		Gde.auto_animation(body, climb_animation if not climb_animation.is_empty() else idle_animation)
	elif not _climbing:
		_update_look(body, body.is_on_floor())


# ------------------------------------------- односторонние платформы ---

## Односторонняя платформа под ногами: её тело или слой тайлов, иначе null.
func _one_way_floor(body: CharacterBody2D) -> Object:
	for i in body.get_slide_collision_count():
		var c := body.get_slide_collision(i)
		if c.get_normal().dot(body.up_direction) < 0.7:
			continue
		var sh: Object = c.get_collider_shape()
		if (sh is CollisionShape2D and (sh as CollisionShape2D).one_way_collision) \
				or (sh is CollisionPolygon2D and (sh as CollisionPolygon2D).one_way_collision):
			return c.get_collider()
		var col: Object = c.get_collider()
		if col != null and col.is_class("TileMapLayer"):
			# У тайлов односторонность своя у каждого — пробуем: сплошной
			# тайл просто вытолкнет персонажа обратно наверх.
			return col
	return null


func _drop(body: CharacterBody2D, platform: Object) -> void:
	if platform is PhysicsBody2D:
		body.add_collision_exception_with(platform as PhysicsBody2D)
		_dropping[platform] = 0.3
	else:
		body.global_position += -body.up_direction * 3.0
	body.velocity.y = maxf(body.velocity.y, 60.0)
	_coyote = 0.0
	_drop_frame = Engine.get_physics_frames()
	dropped_down.emit()


func _forget_drops(body: CharacterBody2D, delta: float) -> void:
	for p: Variant in _dropping.keys():
		_dropping[p] = float(_dropping[p]) - delta
		if float(_dropping[p]) <= 0.0:
			if is_instance_valid(p):
				body.remove_collision_exception_with(p as PhysicsBody2D)
			_dropping.erase(p)


func _try_jump(body: CharacterBody2D) -> void:
	if _jump_buffer <= 0.0:
		return
	var done := false
	if wall_jump and _wall_sliding:
		var n := body.get_wall_normal()
		body.velocity.x = n.x * wall_jump_push
		body.velocity.y = -jump_force * wall_jump_up
		_wall_lock = wall_jump_lock
		wall_jumped.emit()
		done = true
	# С пола прыгают всегда; койот-тайм лишь продлевает это за край.
	# Раньше при койот-тайме 0 с пола было не прыгнуть вовсе.
	elif (_coyote > 0.0 or body.is_on_floor()) and _jumps_used == 0:
		_jumps_used = 1
		body.velocity.y = -jump_force
		jumped.emit(1)
		done = true
	elif _jumps_used > 0 and _jumps_used < max_jumps:
		_jumps_used += 1
		body.velocity.y = -jump_force * air_jump_factor
		jumped.emit(_jumps_used)
		done = true
	if done:
		_jump_buffer = 0.0
		_coyote = 0.0
		_jump_released = false
		_jump_frame = Engine.get_physics_frames()


func _update_look(body: CharacterBody2D, on_ground: bool) -> void:
	if flip_sprite and absf(body.velocity.x) > 1.0:
		Gde.set_flip_h(body, body.velocity.x < 0.0)
	if not animate:
		return
	var anim := idle_animation
	if not on_ground:
		if _wall_sliding and not wall_slide_animation.is_empty():
			anim = wall_slide_animation
		elif body.velocity.y < 0.0:
			anim = double_jump_animation 					if _jumps_used > 1 and not double_jump_animation.is_empty() 					else jump_animation
		else:
			anim = fall_animation
	elif absf(body.velocity.x) > 10.0:
		anim = run_animation
	# auto_animation уступает анимации, которую заказало событие: иначе
	# поведение перебивало бы её на следующем же кадре.
	Gde.auto_animation(body, anim)


## @action Идти влево: _PARAM0_
## @action.en Walk left: _PARAM0_
func simulate_left() -> void:
	_dir -= 1.0


## @action Идти вправо: _PARAM0_
## @action.en Walk right: _PARAM0_
func simulate_right() -> void:
	_dir += 1.0


## @action Прыгнуть: _PARAM0_
## @action.en Jump: _PARAM0_
func simulate_jump() -> void:
	_jump_buffer = maxf(jump_buffer_time, 0.02)


## @action Лезть вверх по лестнице: _PARAM0_
## @action.en Climb up the ladder: _PARAM0_
func simulate_up() -> void:
	_climb_dir -= 1.0


## @action Лезть вниз по лестнице: _PARAM0_
## @action.en Climb down the ladder: _PARAM0_
func simulate_down() -> void:
	_climb_dir += 1.0


## @action Слезть с лестницы: _PARAM0_
## @action.en Get off the ladder: _PARAM0_
func leave_ladder() -> void:
	_leave_ladder = true


## Сквозь одностороннюю платформу под ногами. На обычном полу — просто прыжок.
## @en Through the one-way platform underfoot. On a normal floor — just a jump.
## @action Спрыгнуть вниз: _PARAM0_
## @action.en Drop down: _PARAM0_
func simulate_drop() -> void:
	_drop_wanted = true


## @action Оборвать прыжок _PARAM0_ (как отпускание кнопки)
## @action.en Cut the jump of _PARAM0_ (like releasing the button)
func release_jump() -> void:
	_jump_released = true


## @action Подбросить _PARAM0_ с силой _PARAM1_
## @action.en Bounce _PARAM0_ with force _PARAM1_
## @param force Сила
## @param.en force Force
func bounce(force: float) -> void:
	var body := object as CharacterBody2D
	if body != null:
		body.velocity.y = -absf(force)
		_jumps_used = 0


## @action Остановить _PARAM0_
## @action.en Stop _PARAM0_
func stop() -> void:
	var body := object as CharacterBody2D
	if body != null:
		body.velocity.x = 0.0


## @condition _PARAM0_ стоит на земле
## @condition.en _PARAM0_ is on the floor
func on_floor() -> bool:
	var body := object as CharacterBody2D
	return body != null and body.is_on_floor()


## @condition _PARAM0_ падает
## @condition.en _PARAM0_ is falling
func is_falling() -> bool:
	var body := object as CharacterBody2D
	return body != null and body.velocity.y > 1.0 and not body.is_on_floor()


## @condition _PARAM0_ прыгает вверх
## @condition.en _PARAM0_ is jumping up
func is_jumping() -> bool:
	var body := object as CharacterBody2D
	return body != null and body.velocity.y < -1.0


## @condition _PARAM0_ движется
## @condition.en _PARAM0_ is moving
func is_moving() -> bool:
	var body := object as CharacterBody2D
	return body != null and absf(body.velocity.x) > 1.0


## @condition _PARAM0_ скользит по стене
## @condition.en _PARAM0_ is sliding down a wall
func is_wall_sliding() -> bool:
	return _wall_sliding


## @condition _PARAM0_ только что прыгнул
## @condition.en _PARAM0_ has just jumped
func just_jumped() -> bool:
	return Engine.get_physics_frames() - _jump_frame <= RECENT_FRAMES


## @condition _PARAM0_ только что приземлился
## @condition.en _PARAM0_ has just landed
func just_landed() -> bool:
	return Engine.get_physics_frames() - _land_frame <= RECENT_FRAMES


## @condition _PARAM0_ лезет по лестнице
## @condition.en _PARAM0_ is climbing a ladder
func is_climbing() -> bool:
	return _climbing


## @condition _PARAM0_ у лестницы — может за неё схватиться
## @condition.en _PARAM0_ is at a ladder — can grab it
func at_ladder() -> bool:
	var body := object as CharacterBody2D
	return body != null and _ladder_at(body) != null


## @condition _PARAM0_ только что спрыгнул вниз сквозь платформу
## @condition.en _PARAM0_ has just dropped down through a platform
func just_dropped() -> bool:
	return Engine.get_physics_frames() - _drop_frame <= RECENT_FRAMES


## @condition _PARAM0_ может прыгнуть прямо сейчас
## @condition.en _PARAM0_ can jump right now
func can_jump() -> bool:
	return _coyote > 0.0 or _jumps_used < max_jumps or (_wall_sliding and wall_jump)


## @expression Скорость по горизонтали
## @expression.en Horizontal speed
func speed_x() -> float:
	var body := object as CharacterBody2D
	return body.velocity.x if body != null else 0.0


## @expression Скорость по вертикали
## @expression.en Vertical speed
func speed_y() -> float:
	var body := object as CharacterBody2D
	return body.velocity.y if body != null else 0.0


## @expression Сколько прыжков осталось
## @expression.en How many jumps are left
func jumps_left() -> float:
	return float(maxi(0, max_jumps - _jumps_used))
