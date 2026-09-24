## Поведение «Выстрел».
##
## @behavior Shoot
## @title Выстрел
## @title.en Shoot
## @description Стрельба с разбросом, дробью, очередями, магазином и перезарядкой. Если у пули нет своего движения — выдаёт его сама.
## @description.en Shooting with spread, pellets, bursts, a magazine and reloading. If a bullet has no movement of its own, it gives it one.
## @icon action
@tool
extends GdeBehavior

## Выстрелил. Передаётся созданный снаряд.
signal fired(bullet: Node)
## Магазин опустел.
signal ammo_empty
## Перезарядка закончена.
signal reloaded

## Скрипт движения, который выдаётся пуле, если у неё своего нет. Путь, а не
## preload: своя копия «Прямолинейного движения» в res://behaviors должна
## работать и здесь.
const LINEAR_MOVE := "res://addons/gdevents/behaviors/linear_move/linear_move.gd"

const PRESETS: Array[Dictionary] = [
	{},
	# Пистолет — одиночные, точные.
	{
		"fire_rate": 0.30, "pellets": 1, "spread": 0.0,
		"burst_count": 1, "burst_delay": 0.0,
		"bullet_speed": 520.0, "recoil": 0.0,
		"magazine": 0, "reload_time": 0.0,
	},
	# Дробовик — сноп дроби, редко и с отдачей.
	{
		"fire_rate": 0.85, "pellets": 7, "spread": 22.0,
		"burst_count": 1, "burst_delay": 0.0,
		"bullet_speed": 460.0, "recoil": 180.0,
		"magazine": 6, "reload_time": 1.2,
	},
	# Пулемёт — часто и неточно.
	{
		"fire_rate": 0.08, "pellets": 1, "spread": 7.0,
		"burst_count": 1, "burst_delay": 0.0,
		"bullet_speed": 620.0, "recoil": 12.0,
		"magazine": 40, "reload_time": 1.8,
	},
	# Очередь — три патрона подряд.
	{
		"fire_rate": 0.55, "pellets": 1, "spread": 2.5,
		"burst_count": 3, "burst_delay": 0.07,
		"bullet_speed": 600.0, "recoil": 25.0,
		"magazine": 30, "reload_time": 1.5,
	},
]

## @group.en Preset
@export_group("Пресет")
## Готовый набор настроек. Применяется галочкой ниже.
## @en A ready-made set of settings. Applied with the checkbox below.
## @options.en Custom, Pistol, Shotgun, Machine gun, Burst
@export_enum("Свои настройки", "Пистолет", "Дробовик", "Пулемёт", "Очередь")
var preset: int = 1
## Поставьте галочку, чтобы записать пресет в настройки. Сама снимается.
## @en Check the box to write the preset into the settings. It unchecks itself.
## @internal
@export var apply_preset: bool = false:
	set(v):
		apply_preset = false
		if v and preset > 0 and preset < PRESETS.size():
			apply_values(PRESETS[preset])

## @group.en Projectile
@export_group("Снаряд")
## Сцена снаряда. Без неё стрельба не работает.
## @en Projectile scene. Shooting does not work without it.
@export var bullet_scene: PackedScene
## Скорость снаряда, пикселей в секунду.
## @en Projectile speed, pixels per second.
@export_range(0.0, 3000.0, 10.0) var bullet_speed: float = 520.0
## Время жизни снаряда, секунд.
## @en Projectile lifetime, seconds.
@export_range(0.0, 30.0, 0.1) var bullet_lifetime: float = 3.0
## Выдавать снаряду движение, если у него нет поведения «Прямолинейное движение».
## @en Give the projectile movement if it has no “Linear movement” behavior.
@export var auto_move: bool = true
## Прибавлять снаряду скорость стрелка.
## @en Add the shooter's velocity to the projectile.
@export_range(0.0, 1.0, 0.05) var inherit_velocity: float = 0.0

## @group.en Firing
@export_group("Стрельба")
## Темп стрельбы — секунд между выстрелами.
## @en Fire rate — seconds between shots.
@export_range(0.02, 5.0, 0.01) var fire_rate: float = 0.30
## Дробь — сколько снарядов за один выстрел.
## @en Pellets — how many projectiles per shot.
@export_range(1, 30, 1) var pellets: int = 1
## Разброс, в градусах.
## @en Spread, in degrees.
@export_range(0.0, 180.0, 0.5) var spread: float = 0.0
## Очередь — выстрелов по одному нажатию.
## @en Burst — shots per press.
@export_range(1, 10, 1) var burst_count: int = 1
## Пауза между выстрелами очереди, секунд.
## @en Pause between burst shots, seconds.
@export_range(0.0, 1.0, 0.01) var burst_delay: float = 0.07

## @group.en Direction
@export_group("Направление")
## Вылет вперёд — смещение точки выстрела от центра.
## @en Muzzle forward — offset of the shot point from the center.
@export_range(-200.0, 200.0, 1.0) var offset_forward: float = 16.0
## Вылет вбок — смещение точки выстрела вбок.
## @en Muzzle side — sideways offset of the shot point.
@export_range(-200.0, 200.0, 1.0) var offset_side: float = 0.0
## Направление стрельбы — угол относительно поворота объекта, в градусах.
## @en Firing direction — angle relative to the object's rotation, in degrees.
@export_range(-180.0, 180.0, 1.0) var direction_deg: float = 0.0
## Стрелять туда, куда смотрит спрайт. В платформере персонаж не
## поворачивается, а отражается — без этого «Выстрелить» било бы всегда вправо.
## @en Shoot where the sprite faces. In a platformer the character does not rotate but flips — without this “Shoot” would always fire to the right.
@export var aim_by_flip: bool = true

## @group.en Ammo
@export_group("Боезапас")
## Патронов в магазине. 0 — без перезарядки.
## @en Rounds in the magazine. 0 — no reloading.
@export_range(0, 200, 1) var magazine: int = 0
## Время перезарядки, секунд.
## @en Reload time, seconds.
@export_range(0.0, 10.0, 0.1) var reload_time: float = 1.2
## Перезарядка автоматически, как только магазин опустел.
## @en Reload automatically as soon as the magazine is empty.
@export var auto_reload: bool = true

## @group.en Recoil
@export_group("Отдача")
## Отдача — толчок стрелка назад при выстреле.
## @en Recoil — pushes the shooter back on a shot.
@export_range(0.0, 1000.0, 5.0) var recoil: float = 0.0

## @group.en Sound
@export_group("Звук")
## Звук выстрела — путь к файлу.
## @en Shot sound — a path to the file.
@export var shot_sound: String = ""
## Громкость выстрела, в децибелах. 0 — как в файле.
## @en Shot volume, in decibels. 0 — as in the file.
@export_range(-40.0, 12.0, 0.5) var shot_volume_db: float = 0.0

## @group.en Controls
@export_group("Управление")
## Стрельба без событий — объект палит сам.
## @en Shooting without events — the object fires by itself.
@export var auto_fire: bool = false

var _cooldown: float = 0.0
var _ammo: int = -1
var _reload_left: float = 0.0
var _burst_left: int = 0
var _burst_timer: float = 0.0
var _burst_angle: float = 0.0
var _fire_frame: int = -10


## Магазин заполняется при первом обращении, а не в _ready: так он учитывает
## значение magazine, даже если его поменяли действием до первого выстрела.
func _ensure_ammo() -> void:
	if _ammo < 0 and magazine > 0:
		_ammo = magazine


func _process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	_ensure_ammo()

	if _reload_left > 0.0:
		_reload_left = maxf(0.0, _reload_left - delta)
		if is_zero_approx(_reload_left):
			_ammo = magazine
			reloaded.emit()

	# Очередь доигрывается сама, независимо от того, держат ли кнопку.
	if _burst_left > 0:
		_burst_timer = maxf(0.0, _burst_timer - delta)
		if is_zero_approx(_burst_timer):
			_burst_left -= 1
			_spawn_volley(_burst_angle)
			_burst_timer = burst_delay

	if auto_fire:
		fire()


## @action Выстрелить из _PARAM0_
## @action.en Shoot from _PARAM0_
func fire() -> void:
	fire_at_angle(forward_angle())


## Угол «вперёд» с учётом поворота объекта и того, куда смотрит спрайт.
func forward_angle() -> float:
	var o := object as Node2D
	if o == null:
		return direction_deg
	var a := rad_to_deg(o.global_rotation) + direction_deg
	if aim_by_flip and Gde.is_flipped_h(o):
		a = 180.0 - a
	return a


## @action Выстрелить из _PARAM0_ под углом _PARAM1_ градусов
## @action.en Shoot from _PARAM0_ at an angle of _PARAM1_ degrees
## @param angle_deg Угол, градусов
## @param.en angle_deg Angle, degrees
func fire_at_angle(angle_deg: float) -> void:
	if not can_fire():
		return
	if bullet_scene == null:
		push_warning(GdeI18n.t("Shoot: у «%s» не задана сцена снаряда") % name)
		return

	_cooldown = fire_rate
	_fire_frame = Engine.get_process_frames()
	_burst_angle = angle_deg
	_spawn_volley(angle_deg)
	if burst_count > 1:
		_burst_left = burst_count - 1
		_burst_timer = burst_delay


## @action Выстрелить из _PARAM0_ в ближайший объект _PARAM1_
## @action.en Shoot from _PARAM0_ at the nearest object _PARAM1_
## @param target_name Имя объекта
## @param.en target_name Object name
func fire_at_object(target_name: String) -> void:
	var o := object as Node2D
	if o == null:
		return
	var best: Node2D = null
	var best_d := INF
	for n: Node in Gde.all_instances(target_name):
		var n2 := n as Node2D
		if n2 == null or n2 == o:
			continue
		var d := o.global_position.distance_squared_to(n2.global_position)
		if d < best_d:
			best_d = d
			best = n2
	if best == null:
		return
	fire_at_angle(rad_to_deg((best.global_position - o.global_position).angle()))


## Один залп: pellets снарядов с разбросом вокруг заданного угла.
func _spawn_volley(angle_deg: float) -> void:
	var o := object as Node2D
	if o == null or bullet_scene == null:
		return

	if magazine > 0:
		if _ammo <= 0:
			return
		_ammo -= 1
		if _ammo == 0:
			ammo_empty.emit()
			if auto_reload:
				start_reload()

	var count := maxi(1, pellets)
	for i in range(count):
		var a := angle_deg
		if spread > 0.0:
			# Один снаряд — случайно внутри конуса; несколько — ровно по вееру.
			if count == 1:
				a += randf_range(-spread * 0.5, spread * 0.5)
			else:
				a += -spread * 0.5 + spread * (float(i) / float(count - 1))
		_spawn_one(o, a)

	if recoil > 0.0:
		var back := Vector2.RIGHT.rotated(deg_to_rad(angle_deg)) * -recoil
		var body := o as CharacterBody2D
		if body != null:
			body.velocity += back
		else:
			o.global_position += back * 0.02

	if not shot_sound.is_empty():
		Gde.play_sound(shot_sound, shot_volume_db)


func _spawn_one(o: Node2D, angle_deg: float) -> void:
	var dir := Vector2.RIGHT.rotated(deg_to_rad(angle_deg))
	var side := Vector2(-dir.y, dir.x)
	var b := bullet_scene.instantiate()
	# Снаряд — житель уровня, а не стрелка. Если положить его рядом со стрелком,
	# он окажется внутри сцены игрока: поедет вместе с ней и исчезнет, когда
	# игрока удалят.
	var level := get_tree().current_scene if get_tree() != null else null
	if level == null or level == o or not level.is_ancestor_of(o):
		level = o.get_parent()
	level.add_child(b)

	if b is Node2D:
		var b2 := b as Node2D
		b2.global_position = o.global_position + dir * offset_forward + side * offset_side
		b2.global_rotation = deg_to_rad(angle_deg)

	var speed := bullet_speed
	if inherit_velocity > 0.0:
		var body := o as CharacterBody2D
		if body != null:
			speed += body.velocity.dot(dir) * inherit_velocity

	# Самонаводящийся снаряд летит сам: прямолинейный полёт поверх него
	# увёл бы ракету мимо цели. Направление ему задаёт поворот, поставленный выше.
	var homing: Node = Gde.behavior(b, "Homing", true)
	if homing != null:
		homing.call("launch", angle_deg)
		fired.emit(b)
		return

	var mv: Node = Gde.behavior(b, "LinearMove", true)
	var created := false
	if mv == null and auto_move:
		mv = _give_movement(b)
		created = true
	if mv != null:
		mv.set("angle", angle_deg)
		mv.set("speed", speed)
		if created:
			mv.set("lifetime", bullet_lifetime)
	else:
		push_warning(GdeI18n.t("Shoot: у снаряда «%s» нет LinearMove, а auto_move выключен — он не полетит") % b.name)

	fired.emit(b)


## Выдать снаряду прямолинейное движение, если своего нет.
func _give_movement(b: Node) -> Node:
	var n := Node.new()
	n.name = "LinearMove"
	n.set_script(GdeBehavior.resolve(LINEAR_MOVE))
	b.add_child(n)
	return n


## @action Выстрелить из _PARAM0_ туда, куда он смотрит, со сдвигом _PARAM1_ градусов
## @action.en Shoot from _PARAM0_ where it faces, shifted by _PARAM1_ degrees
## @param extra_deg Сдвиг, градусов
## @param.en extra_deg Shift, degrees
func fire_forward(extra_deg: float) -> void:
	var a := forward_angle()
	# Сдвиг «вверх» у смотрящего влево — тоже вверх, а не вниз.
	var o := object as Node2D
	if aim_by_flip and o != null and Gde.is_flipped_h(o):
		a -= extra_deg
	else:
		a += extra_deg
	fire_at_angle(a)


## @action Перезарядить _PARAM0_
## @action.en Reload _PARAM0_
func start_reload() -> void:
	if magazine <= 0 or _reload_left > 0.0 or _ammo == magazine:
		return
	_reload_left = maxf(reload_time, 0.01)


## @action Добавить _PARAM0_ патронов: _PARAM1_
## @action.en Add ammo to _PARAM0_: _PARAM1_
## @param amount Патронов
## @param.en amount Rounds
func add_ammo(amount: float) -> void:
	if magazine <= 0:
		return
	_ammo = clampi(_ammo + int(amount), 0, magazine)


## @condition _PARAM0_ может стрелять
## @condition.en _PARAM0_ can shoot
func can_fire() -> bool:
	_ensure_ammo()
	if _cooldown > 0.0 or _reload_left > 0.0:
		return false
	return magazine <= 0 or _ammo > 0


## @condition _PARAM0_ перезаряжается
## @condition.en _PARAM0_ is reloading
func is_reloading() -> bool:
	return _reload_left > 0.0


## @condition У _PARAM0_ кончились патроны
## @condition.en _PARAM0_ is out of ammo
func is_empty() -> bool:
	return magazine > 0 and _ammo <= 0


## @condition _PARAM0_ только что выстрелил
## @condition.en _PARAM0_ has just fired
func just_fired() -> bool:
	return Engine.get_process_frames() - _fire_frame <= RECENT_FRAMES


## @expression Угол, куда сейчас стреляет объект
## @expression.en The angle the object is firing at now
func aim_angle() -> float:
	return forward_angle()


## @expression Секунд до следующего выстрела
## @expression.en Seconds until the next shot
func cooldown_left() -> float:
	return _cooldown


## @expression Патронов в магазине
## @expression.en Rounds in the magazine
func ammo() -> float:
	return float(maxi(0, _ammo))


## @expression Доля патронов от 0 до 1
## @expression.en Ammo share from 0 to 1
func ammo_fraction() -> float:
	return float(_ammo) / float(magazine) if magazine > 0 else 1.0


## @expression Секунд до конца перезарядки
## @expression.en Seconds until the reload ends
func reload_left() -> float:
	return _reload_left
