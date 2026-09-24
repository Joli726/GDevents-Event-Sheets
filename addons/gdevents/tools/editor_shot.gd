## Снимок панели редактора без запуска самого Godot-редактора:
##   godot --script res://addons/gdevents/tools/editor_shot.gd
##
## Фон и шрифты тут проектные, а не тема редактора, так что цвета
## приблизительные. Смысл — проверить раскладку: колонки, отступы,
## переносы длинных фраз.
extends SceneTree

const OUT := "user://gdevents_editor.png"

var _step: int = 0
var _panel: GdeEventSheetPanel


func _initialize() -> void:
	# У проекта вьюпорт 480×480 с растяжением — для снимка это надо снять,
	# иначе интерфейс уедет в квадратик.
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	root.content_scale_size = Vector2i(0, 0)
	DisplayServer.window_set_size(Vector2i(1500, 950))
	root.size = Vector2i(1500, 950)
	root.transparent_bg = false
	RenderingServer.set_default_clear_color(Color(0.16, 0.17, 0.19))

	var panel := GdeEventSheetPanel.new()
	panel.autosave_enabled = false
	root.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel = panel


func _process(_delta: float) -> bool:
	_step += 1
	if _step == 2:
		# Показываем тестовый лист: в нём есть и комментарии, и подсобытия —
		# по нему видна вся раскладка, а не один пустой прямоугольник.
		_panel.open_sheet("res://addons/gdevents/tests/selftest.gdes.json")
	if _step < 12:
		return false
	var img := root.get_texture().get_image()
	if img == null:
		print("не удалось получить кадр — нужен запуск без --headless")
		quit(1)
		return true
	img.save_png(OUT)
	print("снимок: %s (%dx%d)" % [OUT, img.get_width(), img.get_height()])
	quit(0)
	return true
