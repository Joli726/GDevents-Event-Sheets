## Снимки диалогов редактора без запуска самого Godot-редактора:
##   godot res://addons/gdevents/tools/dialog_shot.tscn
##
## Кладёт в user://: gde_panel.png, gde_objects.png, gde_bullet.png,
## gde_picker.png, gde_toggles.png, gde_panel_narrow.png, gde_behavior.png
## (настройки «Выстрела» у Player) и gde_code.png (его код). Нужно, чтобы ловить перекос вёрстки окон,
## не открывая редактор.
##
## Запускается сценой, а не через --script: без автозагрузки Gde скрипты
## поведений не компилируются, и окно объектов показало бы неправду.
extends Node

var _step: int = 0
var _panel: GdeEventSheetPanel
var _root: Window


func _ready() -> void:
	_root = get_tree().root
	# Встроенные подокна рисуются внутрь корневого вьюпорта — только так
	# диалог попадёт в снимок.
	_root.gui_embed_subwindows = true
	_root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	_root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	_root.content_scale_size = Vector2i(0, 0)
	DisplayServer.window_set_size(Vector2i(1500, 950))
	_root.size = Vector2i(1500, 950)
	RenderingServer.set_default_clear_color(Color(0.16, 0.17, 0.19))

	_panel = GdeEventSheetPanel.new()
	_panel.autosave_enabled = false
	add_child(_panel)
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.size = Vector2(1500, 950)


func _process(_delta: float) -> void:
	_step += 1
	match _step:
		12:
			_save("gde_panel.png")
		14:
			_panel._objects.open_for(_panel.doc, _panel.registry)
		26:
			_save("gde_objects.png")
		28:
			_select_object("Bullet")
		40:
			_save("gde_bullet.png")
			_panel._objects.hide()
		44:
			# Добавление: щелчок по действию — справа его настройки.
			_panel._picker.open_add(_panel.registry, _panel.doc, "actions", "Player")
		48:
			_panel._picker._select_id("object.x")
			var ed: GdeParamEditor = _panel._picker._editor
			(ed._editors[2] as LineEdit).text = "Plaer.X() + 5"
			ed._refresh_preview()
		60:
			_save("gde_picker.png")
			_panel._picker.hide()
		64:
			# Правка условия без параметров с тумблером «НЕ».
			_panel.edit_instruction([0], "conditions", 1)
		86:
			_save("gde_toggles.png")
			_panel._picker.hide()
		88:
			# Скопировали условие — навели на «+ Условие» другого события.
			_panel.copy_instruction([0], "conditions", 0)
			var paste := _find_paste(_panel, [3])
			if paste != null:
				var add := paste.get_parent().get_child(0) as Control
				var ev := InputEventMouseMotion.new()
				ev.position = add.get_global_rect().get_center()
				ev.global_position = ev.position
				get_viewport().push_input(ev)
		92:
			_save("gde_paste.png")
			# Узкая центральная часть редактора — как при открытых доках.
			DisplayServer.window_set_size(Vector2i(1000, 700))
			_root.size = Vector2i(1000, 700)
		100:
			_save("gde_panel_narrow.png")
			DisplayServer.window_set_size(Vector2i(1500, 950))
			_root.size = Vector2i(1500, 950)
		104:
			_panel._objects.open_for(_panel.doc, _panel.registry)
		106:
			_select_object("Player")
			_panel._objects._select_behavior("Shoot")
		118:
			_save("gde_behavior.png")
			_panel._objects._beh_panel._tabs.current_tab = 1
			_panel._objects._beh_panel.code._on_jump(0)
		126:
			_save("gde_code.png")
			get_tree().quit()


func _find_paste(n: Node, path: Array) -> Button:
	if n is Button and n.has_meta("gde_paste_kind") and str(n.get_meta("gde_paste_kind")) == "conditions":
		var row := n.get_parent()
		while row != null and not (row is GdeEventRow):
			row = row.get_parent()
		if row != null and (row as GdeEventRow).path == path:
			return n as Button
	for c: Node in n.get_children():
		var r := _find_paste(c, path)
		if r != null:
			return r
	return null


func _select_object(obj: String) -> void:
	var objs: Array = _panel.doc.objects()
	for i in range(objs.size()):
		if str((objs[i] as Dictionary).get("name", "")) == obj:
			_panel._objects._list.select(i)
			_panel._objects._on_object_selected(i)
			return


func _save(name: String) -> void:
	var img := _root.get_texture().get_image()
	if img == null:
		print("нет кадра — нужен запуск без --headless")
		return
	img.save_png("user://" + name)
	print("снимок: user://%s (%dx%d)" % [name, img.get_width(), img.get_height()])
