## Поведение «Состояния».
##
## @behavior StateMachine
## @title Состояния
## @title.en States
## @description «Патруль / погоня / атака / оглушён»: одно текущее состояние, время в нём, «только что вошёл» и «только что вышел», переход на время («оглушён на 2 секунды, потом обратно»). Сильно разгружает листы врагов: события пишутся для каждого состояния отдельно.
## @description.en "Patrol / chase / attack / stunned": one current state, the time in it, "has just entered" and "has just left", a timed transition ("stunned for 2 seconds, then back"). It greatly unloads enemy sheets: events are written for each state separately.
## @icon states
@tool
extends GdeBehavior

## Состояние сменилось.
signal state_changed(from: String, to: String)

## Состояния через запятую — для подсказки и проверки. Пусто — любые.
## @en States separated by commas — for hints and checks. Empty — any.
@export var states: String = "idle, patrol, chase, attack, stunned"
## Начальное состояние.
## @en Initial state.
@export var initial_state: String = "idle"
## Играть анимацию с именем состояния, если такая есть в спрайте.
## @en Play the animation named after the state, if the sprite has one.
@export var state_animations: bool = false

var _state: String = ""
var _previous: String = ""
var _time: float = 0.0
var _started: bool = false
var _enter_frame: int = -100
var _leave_frame: int = -100
var _left: String = ""
var _timeout: float = -1.0
var _then: String = ""


func _process(delta: float) -> void:
	if not _started:
		_start()
	_time += delta
	if _timeout >= 0.0:
		_timeout -= delta
		if _timeout <= 0.0:
			_timeout = -1.0
			_go(_then if not _then.is_empty() else _previous)
	if state_animations:
		_animate()


func _start() -> void:
	_started = true
	_state = initial_state.strip_edges()
	_enter_frame = Engine.get_process_frames()


func _go(to: String) -> void:
	if not _started:
		_start()
	to = to.strip_edges()
	if to == _state:
		return
	var known := _known()
	if not known.is_empty() and not known.has(to):
		push_warning(GdeI18n.t("Состояния: у «%s» нет состояния «%s». Есть: %s") % [(object as Node).name, to, ", ".join(known)])
	_previous = _state
	_left = _state
	_state = to
	_time = 0.0
	_enter_frame = Engine.get_process_frames()
	_leave_frame = _enter_frame
	state_changed.emit(_previous, _state)
	if state_animations:
		_animate()


func _known() -> PackedStringArray:
	var out := PackedStringArray()
	for s: String in states.split(",", false):
		if not s.strip_edges().is_empty():
			out.append(s.strip_edges())
	return out


func _animate() -> void:
	var a := _sprite(object)
	if a != null and a.sprite_frames != null and a.sprite_frames.has_animation(_state):
		Gde.auto_animation(object, _state)


func _sprite(n: Node) -> AnimatedSprite2D:
	if n is AnimatedSprite2D:
		return n as AnimatedSprite2D
	for c: Node in n.get_children():
		var r := _sprite(c)
		if r != null:
			return r
	return null


## @action Перевести _PARAM0_ в состояние _PARAM1_
## @action.en Switch _PARAM0_ to state _PARAM1_
## @param name Состояние
## @param.en name State
func set_state(name: String) -> void:
	_timeout = -1.0
	_go(name)


## Потом — в состояние из третьего поля, а пустое — обратно в прежнее.
## @en Then into the state from the third field, and an empty one means back to the previous.
## @action Перевести _PARAM0_ в состояние _PARAM1_ на _PARAM2_ секунд, потом в _PARAM3_
## @action.en Switch _PARAM0_ to state _PARAM1_ for _PARAM2_ seconds, then to _PARAM3_
## @param name Состояние
## @param.en name State
## @param seconds Секунд
## @param.en seconds Seconds
## @param then Потом
## @param.en then Then
func set_state_for(name: String, seconds: float, then: String) -> void:
	var back := _state
	_go(name)
	_then = then if not then.strip_edges().is_empty() else back
	_timeout = maxf(0.0, seconds)


## @action Вернуть _PARAM0_ в прежнее состояние
## @action.en Return _PARAM0_ to the previous state
func back() -> void:
	_timeout = -1.0
	if not _previous.is_empty():
		_go(_previous)


## @condition _PARAM0_ в состоянии _PARAM1_
## @condition.en _PARAM0_ is in state _PARAM1_
## @param name Состояние
## @param.en name State
func is_state(name: String) -> bool:
	if not _started:
		_start()
	return _state == name.strip_edges()


## @condition _PARAM0_ только что вошёл в состояние _PARAM1_
## @condition.en _PARAM0_ has just entered state _PARAM1_
## @param name Состояние
## @param.en name State
func just_entered(name: String) -> bool:
	return is_state(name) and Engine.get_process_frames() - _enter_frame <= RECENT_FRAMES


## @condition _PARAM0_ только что вышел из состояния _PARAM1_
## @condition.en _PARAM0_ has just left state _PARAM1_
## @param name Состояние
## @param.en name State
func just_left(name: String) -> bool:
	return _left == name.strip_edges() and Engine.get_process_frames() - _leave_frame <= RECENT_FRAMES


## @condition _PARAM0_ в текущем состоянии дольше _PARAM1_ секунд
## @condition.en _PARAM0_ has been in the current state longer than _PARAM1_ seconds
## @param seconds Секунд
## @param.en seconds Seconds
func longer_than(seconds: float) -> bool:
	return _time > seconds


## @expression Текущее состояние
## @expression.en Current state
func state() -> String:
	if not _started:
		_start()
	return _state


## @expression Прежнее состояние
## @expression.en Previous state
func previous_state() -> String:
	return _previous


## @expression Сколько секунд в текущем состоянии
## @expression.en How many seconds in the current state
func time_in_state() -> float:
	return _time
