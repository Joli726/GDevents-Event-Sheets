## Всплывающий текст: «−3», «+1 монета». Подскакивает, взлетает и тает сам.
class_name GdeFloatText
extends Node2D

var lifetime: float = 0.9
## Пикселей в секунду вверх.
var rise: float = 45.0

var _age: float = 0.0
var _label: Label = null


static func make(text: String, color: Color, font_size: int) -> GdeFloatText:
	var f := GdeFloatText.new()
	f.z_index = 200
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	# Обводка — чтобы читалось на любом фоне.
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", maxi(2, int(font_size / 4.0)))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	f.add_child(l)
	f._label = l
	return f


func _process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		queue_free()
		return
	position.y -= rise * delta * (1.0 - _age / lifetime * 0.6)
	var k := _age / lifetime
	# В начале — короткий подскок размера, в конце — тает.
	var pop := 1.0 + 0.35 * maxf(0.0, 1.0 - _age / 0.12)
	scale = Vector2.ONE * pop
	modulate.a = clampf(2.0 - 2.0 * k, 0.0, 1.0)
	if _label != null:
		_label.position = -_label.size * 0.5
