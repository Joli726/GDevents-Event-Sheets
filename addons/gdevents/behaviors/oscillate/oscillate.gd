## Поведение «Колебание».
##
## @behavior Oscillate
## @title Колебание
## @needs Sprite2D|AnimatedSprite2D Спрайт
## @description Колебание положения, поворота и размера разными волнами. Платформы, монеты, парящие враги.
## @icon oscillate
@tool
extends GdeBehavior

@export_group("Волна")
## Форма колебания — синус, треугольник или скачок.
@export_enum("Синус", "Пила", "Меандр") var waveform: int = 0
## Частота — колебаний в секунду.
@export_range(0.01, 10.0, 0.01) var frequency: float = 0.5
## Сдвиг фазы от 0 до 1, чтобы одинаковые объекты не качались синхронно.
@export_range(0.0, 1.0, 0.01) var phase: float = 0.0
## Колебание включено.
@export var running: bool = true

@export_group("Положение")
## Размах по положению, в пикселях.
@export_range(0.0, 1000.0, 1.0) var amplitude: float = 40.0
## Угол оси колебания в градусах: 0 — вбок, 90 — вверх-вниз.
@export_range(-180.0, 180.0, 1.0) var axis_angle: float = 90.0

@export_group("Поворот и размер")
## Размах покачивания, в градусах.
@export_range(0.0, 180.0, 1.0) var rotation_amplitude: float = 0.0
## Размах пульсации размера.
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
func recenter() -> void:
	var o := object as Node2D
	if o != null:
		_origin = o.global_position
		_base_rot = o.global_rotation_degrees
		_base_scale = o.scale
		_time = 0.0


## @action Сбросить фазу колебания _PARAM0_
func reset_phase() -> void:
	_time = 0.0


## @condition _PARAM0_ колеблется
func is_running() -> bool:
	return running


## @expression Текущее смещение от центра
func offset() -> float:
	return _wave(_time * frequency + phase) * amplitude


## @expression Значение волны от -1 до 1
func wave_value() -> float:
	return _wave(_time * frequency + phase)
