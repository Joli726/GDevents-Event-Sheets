## Поведение «Колебание».
##
## @behavior Oscillate
## @title Колебание
## @title.en Oscillation
## @needs Sprite2D|AnimatedSprite2D Спрайт
## @needs.en Sprite2D|AnimatedSprite2D Sprite
## @description Колебание положения, поворота и размера разными волнами. Платформы, монеты, парящие враги.
## @description.en Oscillation of position, rotation and size with different waves. Platforms, coins, hovering enemies.
## @icon oscillate
@tool
extends GdeBehavior

## @group.en Wave
@export_group("Волна")
## Форма колебания — синус, треугольник или скачок.
## @en Waveform — sine, triangle or step.
## @options.en Sine, Sawtooth, Square
@export_enum("Синус", "Пила", "Меандр") var waveform: int = 0
## Частота — колебаний в секунду.
## @en Frequency — oscillations per second.
@export_range(0.01, 10.0, 0.01) var frequency: float = 0.5
## Сдвиг фазы от 0 до 1, чтобы одинаковые объекты не качались синхронно.
## @en Phase shift from 0 to 1, so identical objects do not sway in sync.
@export_range(0.0, 1.0, 0.01) var phase: float = 0.0
## Колебание включено.
## @en Oscillation is on.
@export var running: bool = true

## @group.en Position
@export_group("Положение")
## Размах по положению, в пикселях.
## @en Position amplitude, in pixels.
@export_range(0.0, 1000.0, 1.0) var amplitude: float = 40.0
## Угол оси колебания в градусах: 0 — вбок, 90 — вверх-вниз.
## @en Angle of the oscillation axis in degrees: 0 — sideways, 90 — up and down.
@export_range(-180.0, 180.0, 1.0) var axis_angle: float = 90.0

## @group.en Rotation and size
@export_group("Поворот и размер")
## Размах покачивания, в градусах.
## @en Swaying amplitude, in degrees.
@export_range(0.0, 180.0, 1.0) var rotation_amplitude: float = 0.0
## Размах пульсации размера.
## @en Size pulsation amplitude.
@export_range(0.0, 2.0, 0.05) var scale_amplitude: float = 0.0

var _time: float = 0.0
var _origin: Vector2 = Vector2.ZERO
var _base_rot: float = 0.0
var _base_scale: Vector2 = Vector2.ONE
var _ready_done: bool = false


func _process(delta: float) -> void:
	var o := object as Node2D
	if o == null:
		return
	if not _ready_done:
		_origin = o.global_position
		_base_rot = o.global_rotation_degrees
		_base_scale = o.scale
		_ready_done = true
	if not running:
		return

	_time += delta
	var w := _wave(_time * frequency + phase)

	if amplitude > 0.0:
		o.global_position = _origin \
				+ Vector2.RIGHT.rotated(deg_to_rad(axis_angle)) * (w * amplitude)
	if rotation_amplitude > 0.0:
		o.global_rotation_degrees = _base_rot + w * rotation_amplitude
	if scale_amplitude > 0.0:
		o.scale = _base_scale * (1.0 + w * scale_amplitude)


## Значение волны от -1 до 1. t в оборотах, а не в радианах.
func _wave(t: float) -> float:
	match waveform:
		1:
			# Пила: ровный ход туда и обратно.
			var f := fposmod(t, 1.0)
			return (f * 4.0 - 1.0) if f < 0.5 else (3.0 - f * 4.0)
		2:
			return 1.0 if fposmod(t, 1.0) < 0.5 else -1.0
		_:
			return sin(t * TAU)


## @action Запомнить текущую точку _PARAM0_ как центр колебания
## @action.en Remember the current point of _PARAM0_ as the oscillation center
func recenter() -> void:
	var o := object as Node2D
	if o != null:
		_origin = o.global_position
		_base_rot = o.global_rotation_degrees
		_base_scale = o.scale
		_time = 0.0


## @action Сбросить фазу колебания _PARAM0_
## @action.en Reset the oscillation phase of _PARAM0_
func reset_phase() -> void:
	_time = 0.0


## @condition _PARAM0_ колеблется
## @condition.en _PARAM0_ is oscillating
func is_running() -> bool:
	return running


## @expression Текущее смещение от центра
## @expression.en Current offset from the center
func offset() -> float:
	return _wave(_time * frequency + phase) * amplitude


## @expression Значение волны от -1 до 1
## @expression.en Wave value from -1 to 1
func wave_value() -> float:
	return _wave(_time * frequency + phase)
