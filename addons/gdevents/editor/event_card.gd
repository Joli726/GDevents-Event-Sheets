## Карточка события — она же приёмник перетаскивания самих событий.
##
## Куда встанет брошенное событие, видно по подсветке:
##   верхняя четверть  — выше этого,
##   нижняя четверть   — ниже этого,
##   середина          — подсобытием внутрь.
## Это те же три исхода, что даёт меню «Выше / Ниже / Вложить», только
## одним движением и с показом результата заранее.
@tool
class_name GdeEventCard
extends PanelContainer

const DRAG_TYPE := "gde_event"

enum Where { NONE, BEFORE, AFTER, INSIDE }

var panel: Control
var path: Array = []

var _where: int = Where.NONE
var _accent: Color = Color(1, 0.78, 0.42)
var _selected: bool = false
var _has_errors: bool = false
## Карточка комментария: своя окраска, и бросить событие «внутрь» нельзя.
var comment: bool = false

const ERROR_COLOR := Color(0.93, 0.36, 0.36)


func setup(p: Control, event_path: Array, accent: Color, selected: bool) -> void:
	panel = p
	path = event_path
	_accent = accent
	_selected = selected
	mouse_filter = Control.MOUSE_FILTER_PASS
	add_theme_stylebox_override("panel", _style())
	draw.connect(_draw_marker)


func set_selected(v: bool) -> void:
	if _selected == v:
		return
	_selected = v
	add_theme_stylebox_override("panel", _style())


## Ошибки сборки этого события: красная рамка и текст в подсказке.
func set_errors(errors: Array[String]) -> void:
	_has_errors = not errors.is_empty()
	if _has_errors:
		tooltip_text = "Это событие не соберётся:\n• " + "\n• ".join(errors)
	add_theme_stylebox_override("panel", _style())


func _style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	if comment:
		sb.bg_color = Color(0.85, 0.75, 0.35, 0.16)
		sb.border_color = Color(_accent.r, _accent.g, _accent.b, 0.55) if _selected \
				else Color(0.85, 0.75, 0.35, 0.5)
		sb.border_width_left = 3
		sb.border_width_top = 1 if _selected else 0
		sb.border_width_right = 1 if _selected else 0
		sb.border_width_bottom = 1 if _selected else 0
		sb.content_margin_left = 8
		sb.content_margin_right = 8
		sb.content_margin_top = 4
		sb.content_margin_bottom = 4
		sb.set_corner_radius_all(4)
		return sb
	sb.bg_color = Color(1, 1, 1, 0.04)
	if _has_errors:
		sb.bg_color = Color(ERROR_COLOR.r, ERROR_COLOR.g, ERROR_COLOR.b, 0.07)
		sb.border_color = Color(ERROR_COLOR.r, ERROR_COLOR.g, ERROR_COLOR.b, 0.8)
	elif _selected:
		sb.border_color = Color(_accent.r, _accent.g, _accent.b, 0.55)
	else:
		sb.border_color = Color(1, 1, 1, 0.09)
	sb.set_border_width_all(1)
	sb.content_margin_left = 2
	sb.content_margin_right = 6
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	sb.set_corner_radius_all(4)
	return sb


func _draw_marker() -> void:
	var c := Color(_accent.r, _accent.g, _accent.b, 0.9)
	match _where:
		Where.BEFORE:
			draw_rect(Rect2(0, 0, size.x, 3), c, true)
		Where.AFTER:
			draw_rect(Rect2(0, size.y - 3, size.x, 3), c, true)
		Where.INSIDE:
			draw_rect(Rect2(Vector2.ZERO, size), Color(c.r, c.g, c.b, 0.12), true)
			draw_rect(Rect2(Vector2.ZERO, size), c, false, 2.0)


func _can_drop_data(at: Vector2, data: Variant) -> bool:
	if not (data is Dictionary) or str((data as Dictionary).get("type", "")) != DRAG_TYPE:
		return false
	var from: Array = (data as Dictionary).get("path", [])
	# Внутрь самого себя событие не переносится: получилось бы кольцо.
	if GdeSheetDocument.is_inside(path, from):
		return false
	var w := Where.BEFORE
	if comment:
		# У комментария нет подсобытий: только выше или ниже.
		w = Where.AFTER if at.y > size.y * 0.5 else Where.BEFORE
	elif at.y > size.y * 0.75:
		w = Where.AFTER
	elif at.y > size.y * 0.25:
		w = Where.INSIDE
	if w != _where:
		_where = w
		queue_redraw()
	return true


func _drop_data(_at: Vector2, data: Variant) -> void:
	var w := _where
	_where = Where.NONE
	queue_redraw()
	panel.drop_event(data as Dictionary, path, w)


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and _where != Where.NONE:
		_where = Where.NONE
		queue_redraw()
