## Выбранное поведение объекта целиком: что это, где висит в сцене и его
## настройки. Правая половина вкладки «Поведения» в окне объектов.
@tool
class_name GdeBehaviorPanel
extends VBoxContainer

## Для строки сообщений окна объектов.
signal message(text: String, is_error: bool)
## Пользователь ушёл в редактор скриптов — окну объектов пора закрыться.
signal left_for_editor
## Кнопки своей копии — их выполняет окно объектов: там подтверждение
## и обновление всего списка.
signal copy_requested(bname: String)
signal reset_requested(bname: String)
signal derive_requested(bname: String)
signal remember_requested(bname: String)
signal restore_requested(bname: String, version_path: String, version_title: String)
signal accept_builtin_requested(bname: String)

var settings: GdeBehaviorSettings
var code: GdeBehaviorCode
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
	_about.custom_minimum_size = Vector2(360, 0)
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

	code = GdeBehaviorCode.new()
	code.name = "Код"
	code.opened_in_editor.connect(func() -> void: left_for_editor.emit())
	code.copy_requested.connect(func() -> void: copy_requested.emit(behavior))
	code.reset_requested.connect(func() -> void: reset_requested.emit(behavior))
	code.derive_requested.connect(func() -> void: derive_requested.emit(behavior))
	code.remember_requested.connect(func() -> void: remember_requested.emit(behavior))
	code.restore_requested.connect(func(p: String, t: String) -> void: restore_requested.emit(behavior, p, t))
	code.accept_builtin_requested.connect(func() -> void: accept_builtin_requested.emit(behavior))
	_tabs.add_child(code)

	show_empty("")


func show_behavior(scene: String, bname: String, reg: GdeRegistry, object_names: Array = [],
		node_path: String = "", script_path: String = "") -> void:
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
	var entry: Dictionary = b if b != null else {}
	# Код — того скрипта, что реально стоит на объекте.
	code.show_script(script_path if not script_path.is_empty() else str(entry.get("path", "")), entry)
	settings.show_behavior(scene, bname, reg, object_names)


func show_code_tab() -> void:
	_tabs.current_tab = 1


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
