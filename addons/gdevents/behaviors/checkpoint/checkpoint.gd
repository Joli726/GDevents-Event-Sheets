## Поведение «Контрольная точка».
##
## @behavior Checkpoint
## @title Контрольная точка
## @title.en Checkpoint
## @needs Sprite2D|AnimatedSprite2D Спрайт
## @needs.en Sprite2D|AnimatedSprite2D Sprite
## @description Касание запоминает место возрождения. После смерти («Здоровье» кончилось) игрок появляется у последней задетой точки — с полным здоровьем и короткой неуязвимостью. Запоминается и после перезапуска сцены.
## @description.en A touch remembers the respawn point. After death (its "Health" ran out) the player appears at the last touched point — with full health and a short invulnerability. It is remembered after a scene restart too.
## @icon checkpoint
@tool
extends GdeBehavior

## Точка стала текущей.
signal activated
## Игрок появился у этой точки.
signal respawned(player: Node)

const GROUP := "__gde_checkpoint"

## Точки, запомненные до перезапуска сцены, лежат в метаданных автозагрузки
## Gde: «сцена|игрок» -> место. Она переживает смену сцены, а статическая
## переменная скрипта держала бы классы рантайма до самого выхода.
const SAVED_META := "__gde_checkpoints"

## @group.en Player
@export_group("Игрок")
## Игрок — имя объекта из листа событий, например Player.
## @en Player — the name of an object from the event sheet, e.g. Player.
@export var player_object: String = "Player"
## Стартовая точка — текущая с самого начала, ещё до касания.
## @en Start point — current from the very beginning, before any touch.
@export var is_start: bool = false
## Становиться текущей при касании.
## @en Become current on touch.
@export var activate_on_touch: bool = true

## @group.en Respawn
@export_group("Возрождение")
## Возрождать игрока здесь, когда его «Здоровье» кончилось.
## @en Respawn the player here when its "Health" runs out.
@export var respawn_on_death: bool = true
## Через сколько секунд после смерти появиться.
## @en How many seconds after death to appear.
@export_range(0.0, 30.0, 0.1) var respawn_delay: float = 0.8
## Неуязвимость после появления, секунд.
## @en Invulnerability after appearing, seconds.
@export_range(0.0, 30.0, 0.1) var invulnerable_after: float = 1.0
## Создать игрока заново, если его удалили при смерти.
## @en Create the player again if it was deleted on death.
@export var recreate_if_deleted: bool = true
## Помнить точку после перезапуска сцены: игрок начнёт с неё.
## @en Remember the point after a scene restart: the player starts from it.
@export var remember_after_restart: bool = true
## Сдвиг места появления по X от точки, пикселей.
## @en Offset of the spawn place along X from the point, pixels.
@export_range(-1000.0, 1000.0, 1.0) var offset_x: float = 0.0
## Сдвиг места появления по Y от точки, пикселей. Минус — выше.
## @en Offset of the spawn place along Y from the point, pixels. Minus — higher.
@export_range(-1000.0, 1000.0, 1.0) var offset_y: float = 0.0

## @group.en Look
@export_group("Вид")
## Анимация неактивной точки, например опущенный флаг. Пусто — не менять.
## @en Animation of an inactive point, e.g. a lowered flag. Empty — do not change.
@export var inactive_animation: String = ""
## Анимация текущей точки, например поднятый флаг.
## @en Animation of the current point, e.g. a raised flag.
@export var active_animation: String = ""

var _active: bool = false
var _started: bool = false
var _activate_frame: int = -100
var _watched: Dictionary = {}
var _respawn_left: float = -1.0
var _respawns: int = 0


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
		_restore_saved(o)
		if is_start and _current() == null:
			_make_active(false)
		_show()

	if activate_on_touch and not _active:
		for n: Node in Gde.all_instances(player_object):
			if Gde.overlaps(n, o):
				activate()
				break

	if _active and respawn_on_death:
		_watch_health()
		if _respawn_left >= 0.0:
			_respawn_left -= delta
			if _respawn_left <= 0.0:
				_respawn_left = -1.0
				respawn_player()


func _key() -> String:
	var scene := get_tree().current_scene
	return "%s|%s" % [scene.scene_file_path if scene != null else "", player_object]


func _spawn_point() -> Vector2:
	var o := object as Node2D
	return o.global_position + Vector2(offset_x, offset_y) if o != null else Vector2.ZERO


## После перезапуска сцены: эта ли точка была текущей — тогда игрок с неё и начнёт.
func _restore_saved(o: Node2D) -> void:
	var saved: Dictionary = Gde.get_meta(SAVED_META, {})
	if not remember_after_restart or not saved.has(_key()):
		return
	var at: Vector2 = saved[_key()]
	if at.distance_to(o.global_position) > 1.0:
		return
	_active = true
	for n: Node in Gde.all_instances(player_object):
		_place(n)


func _current() -> Node:
	for c: Node in get_tree().get_nodes_in_group(GROUP):
		if c.get("player_object") == player_object and bool(c.get("_active")):
			return c
	return null


func _make_active(notify: bool) -> void:
	for c: Node in get_tree().get_nodes_in_group(GROUP):
		if c != self and c.get("player_object") == player_object and bool(c.get("_active")):
			c.call("_deactivate")
	_active = true
	var o := object as Node2D
	if o != null:
		var saved: Dictionary = Gde.get_meta(SAVED_META, {})
		saved[_key()] = o.global_position
		Gde.set_meta(SAVED_META, saved)
	_show()
	if notify:
		_activate_frame = Engine.get_physics_frames()
		activated.emit()


func _deactivate() -> void:
	_active = false
	_respawn_left = -1.0
	_show()


func _show() -> void:
	var anim := active_animation if _active else inactive_animation
	if not anim.is_empty():
		Gde.auto_animation(object, anim)


## Следить за «Здоровьем» каждого игрока: игроков могли создать заново.
func _watch_health() -> void:
	for n: Node in Gde.all_instances(player_object):
		var h := Gde.behavior(n, "Health", true)
		if h == null or _watched.has(h):
			continue
		_watched[h] = true
		h.connect("died", _on_player_died)


func _on_player_died() -> void:
	if _active and respawn_on_death and _respawn_left < 0.0:
		_respawn_left = respawn_delay


func _place(n: Node) -> void:
	var m := Gde.main(n)
	if m == null:
		return
	m.global_position = _spawn_point()
	var body := Gde.body_of(n)
	if body is CharacterBody2D:
		(body as CharacterBody2D).velocity = Vector2.ZERO
	elif body is RigidBody2D:
		(body as RigidBody2D).linear_velocity = Vector2.ZERO


## @action Сделать _PARAM0_ текущей точкой возрождения
## @action.en Make _PARAM0_ the current respawn point
func activate() -> void:
	if not _active:
		_make_active(true)


## Игрок переносится к текущей точке — этой или последней задетой.
## @en The player is moved to the current point — this one or the last touched one.
## @action Возродить игрока у текущей точки (через _PARAM0_)
## @action.en Respawn the player at the current point (via _PARAM0_)
func respawn_player() -> void:
	var cur := _current()
	if cur != null and cur != self:
		cur.call("respawn_player")
		return
	# Удалённый при смерти игрок ещё может висеть в дереве до конца кадра.
	var players: Array = []
	for n0: Node in Gde.all_instances(player_object):
		if is_instance_valid(n0) and not n0.is_queued_for_deletion():
			players.append(n0)
	if players.is_empty() and recreate_if_deleted and Gde.is_object(player_object):
		var level := get_tree().current_scene
		if level == null:
			level = (object as Node).get_parent()
		var p := _spawn_point()
		var n := Gde.create_object(null, player_object, p.x, p.y, level)
		if n != null:
			players = [n]
	for n: Node in players:
		_place(n)
		var h := Gde.behavior(n, "Health", true)
		if h != null:
			h.call("restore")
			if invulnerable_after > 0.0:
				h.call("make_invulnerable", invulnerable_after)
		_respawns += 1
		respawned.emit(n)


## @condition _PARAM0_ — текущая точка возрождения
## @condition.en _PARAM0_ is the current respawn point
func is_active() -> bool:
	return _active


## @condition _PARAM0_ только что стала текущей
## @condition.en _PARAM0_ has just become current
func just_activated() -> bool:
	return Engine.get_physics_frames() - _activate_frame <= RECENT_FRAMES


## @expression Сколько раз игрок появлялся у этой точки
## @expression.en How many times the player appeared at this point
func respawn_count() -> float:
	return float(_respawns)
