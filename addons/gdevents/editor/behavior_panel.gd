## Выбранное поведение объекта целиком: что это, где висит в сцене и его
## настройки. Правая половина вкладки «Поведения» в окне объектов.
@tool
class_name GdeBehaviorPanel
extends VBoxContainer

## Для строки сообщений окна объектов.
signal message(text: String, is_error: bool)

var settings: GdeBehaviorSettings
var scene_path: String = ""
var behavior: String = ""

var _head: Control
var _icon: TextureRect
var _title: Label
var _where: Label
var _about: Label
var _tabs: TabContainer
var _empty: Label


func _init() -> void:
	add_theme_constant_override("separation", 6)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	_empty = Label.new()
	_empty.modulate = Color(1, 1, 1, 0.45)
	_empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_empty)

	var head := VBoxContainer.new()
	head.add_theme_constant_override("separation", 2)
	add_child(head)
	_head = head

	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 8)
	head.add_child(line)
	_icon = TextureRect.new()
	_icon.custom_minimum_size = Vector2(22, 22)
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	line.add_child(_icon)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 16)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.clip_text = true
	line.add_child(_title)
	# На каком узле висит — важно: в живой сцене поведение редко лежит на корне.
	_where = Label.new()
	_where.add_theme_font_size_override("font_size", 10)
	_where.modulate = Color(1, 1, 1, 0.4)
	_where.clip_text = true
	_where.custom_minimum_size = Vector2(120, 0)
	_where.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	line.add_child(_where)

	_about = Label.new()
	_about.modulate = Color(1, 1, 1, 0.6)
	_about.add_theme_font_size_override("font_size", 12)
	_about.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_about.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_about)

	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_tabs)

	settings = GdeBehaviorSettings.new()
	settings.name = "Настройки"
	settings.saved.connect(func(err: String) -> void:
		if err.is_empty():
			message.emit("Настройки «%s» сохранены в %s" % [_title.text, scene_path.get_file()], false)
		else:
			message.emit(err, true))
	_tabs.add_child(settings)

	show_empty("")


func show_behavior(scene: String, bname: String, reg: GdeRegistry, object_names: Array = [],
		node_path: String = "") -> void:
	scene_path = scene
	behavior = bname
	_set_body_visible(true)
	var b: Variant = reg.behaviors.get(bname) if reg != null else null
	if b != null:
		var d: Dictionary = b
		_icon.texture = GdeIcons.get_icon(str(d.get("icon", "behavior")))
		_title.text = str(d.get("title", bname))
		_about.text = str(d.get("description", ""))
	else:
		_icon.texture = GdeIcons.get_icon("behavior")
		_title.text = bname
		_about.text = "Скрипт этого поведения не найден в проекте."
	_about.visible = not _about.text.is_empty()
	_where.text = node_path
	_where.tooltip_text = "Узел поведения в сцене объекта: %s" % node_path
	settings.show_behavior(scene, bname, reg, object_names)


func show_empty(text: String) -> void:
	if settings != null and settings.has_pending():
		settings.flush()
	scene_path = ""
	behavior = ""
	_empty.text = text
	_set_body_visible(false)


func _set_body_visible(on: bool) -> void:
	_empty.visible = not on
	_head.visible = on
	_tabs.visible = on
