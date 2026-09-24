## Тест мышью: наведение и клики по кнопкам строк.
##   godot --headless res://addons/gdevents/tools/hover_test.tscn
##
## Остальные тесты зовут методы панели напрямую и не видят, что происходит
## под курсором. Так пропустили мигающие кнопки: навёлся на кнопку — строка
## решила, что курсор ушёл, спрятала кнопки, клик уходил в пустоту. Здесь
## мышь настоящая: события движения и нажатия идут через вьюпорт, как от руки.
extends Node

const SHEET := "res://addons/gdevents/tests/selftest.gdes.json"

var _panel: GdeEventSheetPanel
var _step: int = 0
var _fails: int = 0
var _checks: int = 0
var _item: GdeInstructionItem
var _before: int = 0
var _path: Array = []
var _kind: String = ""
var _events_before: int = 0
var _row_trash: Control
var _drag_path: Array = []
var _drag_first: String = ""
var _drag_second: String = ""
var _ev_first: String = ""
var _drag_from: Vector2
var _drag_to: Vector2
var _menu_near: Vector2
var _paste_path: Array = []
var _paste_before: int = 0
var _paste_id: String = ""
var _add_btn: Control
var _paste_btn: Button
var _act_paste: Button
var _stable: bool = true


func _ready() -> void:
	# Тест сверяет русские надписи — язык плагина здесь русский.
	GdeI18n.set_language("ru", false)
	# Растяжение проекта (1920×1080, canvas_items) пересчитывает координаты
	# событий. Для теста его выключаем: позиция события = позиция на экране.
	var root := get_tree().root
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.size = Vector2i(1500, 950)
	_panel = GdeEventSheetPanel.new()
	# Тест жмёт «удалить» — на диск ничего попасть не должно.
	_panel.autosave_enabled = false
	add_child(_panel)
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _process(_d: float) -> void:
	_step += 1
	match _step:
		3:
			_panel.open_sheet(SHEET)
		8:
			_ok(_panel.get_combined_minimum_size().x <= get_viewport().get_visible_rect().size.x,
					"панель влезает в окно 1500 px по ширине (минимум %d)"
					% int(_panel.get_combined_minimum_size().x))
			_item = _first_item_with_trash()
			_ok(_item != null, "в листе есть строка с кнопками")
			if _item == null:
				_report()
				return
			_path = _item.path.duplicate()
			_kind = _item.kind
			_before = _count()
			_ok(_item._tools.modulate.a < 0.01, "без наведения кнопки не видны")
			_move(_item.get_global_rect().get_center())
		10:
			_ok(_item._hovered and _item._tools.modulate.a > 0.99, "наведение на строку показывает кнопки")
			_move(_trash().get_global_rect().get_center())
		11, 12, 13, 14, 15:
			# Раньше именно здесь кнопки мигали: каждый кадр то есть, то нет.
			if not (_item._hovered and _item._tools.modulate.a > 0.99):
				_stable = false
		16:
			_ok(_stable, "курсор на кнопке — кнопки не исчезают")
			_ok(_trash().mouse_filter == Control.MOUSE_FILTER_STOP, "кнопка под курсором принимает клики")
			_click(_trash().get_global_rect().get_center())
		19:
			# После удаления строки перерисовываются, старая строка уже освобождена.
			_eq(_count(), _before - 1, "клик по корзине удалил строку")
			_move(Vector2(5, 940))
		22:
			var again := _first_item_with_trash()
			_ok(again != null and not again._hovered and again._tools.modulate.a < 0.01,
					"курсор ушёл — кнопки снова спрятаны")
			var last: Control = null
			if again != null:
				last = again._tools.get_child(again._tools.get_child_count() - 1) as Control
			_ok(last != null and last.mouse_filter == Control.MOUSE_FILTER_IGNORE,
					"спрятанные кнопки не ловят клики")
			# Кнопки самого события: дублировать, выключить, удалить.
			_events_before = (_panel.doc.data["events"] as Array).size()
			_row_trash = _find_row_trash(_panel)
			_ok(_row_trash != null, "у события есть кнопка удаления")
			if _row_trash == null:
				_report()
				return
			_move(_row_trash.get_global_rect().get_center())
		25:
			_ok(_row_trash.get_parent().modulate.a > 0.99, "курсор на кнопке события — она яркая, а не тусклая")
			_click(_row_trash.get_global_rect().get_center())
		28:
			_eq((_panel.doc.data["events"] as Array).size(), _events_before - 1,
					"клик по корзине события удалил событие")
			_start_instruction_drag()
		29, 30, 31, 32, 33, 34:
			_drag_step(_step - 29, 6)
		35:
			_release(_drag_to)
		38:
			var acts: Array = _panel.doc.instructions_of(_drag_path, "actions")
			_eq(str((acts[0] as Dictionary)["params"]), _drag_second,
					"действие перетащено мышью ниже соседнего")
			_eq(str((acts[1] as Dictionary)["params"]), _drag_first,
					"и соседнее поднялось на его место")
			_test_drop_follows_mark()
		40:
			_start_event_drag()
		41, 42, 43, 44, 45, 46:
			_drag_step(_step - 41, 6)
		47:
			_release(_drag_to)
		50:
			var evs: Array = _panel.doc.data["events"]
			_ok(JSON.stringify(evs[0]) != _ev_first, "событие перетащено мышью за ручку")
			# Правый клик по строке: меню должно открыться возле неё, а не в углу.
			# После переноса события пути сдвинулись — берём любую строку заново.
			var it := _first_item_with_trash()
			_menu_near = it.get_screen_position() + Vector2(20, 10)
			var ev := InputEventMouseButton.new()
			ev.position = it.get_global_rect().position + Vector2(20, 10)
			ev.global_position = ev.position
			ev.button_index = MOUSE_BUTTON_RIGHT
			ev.pressed = true
			get_viewport().push_input(ev)
		51:
			var m: PopupMenu = _panel._inst_menu
			_ok(m.visible and Vector2(m.position).distance_to(_menu_near) < 40.0,
					"правый клик открыл меню возле строки (меню в %s, клик в %s)" % [m.position, _menu_near])
			m.hide()
			# Узкое место для панели в редакторе с открытыми доками.
			_start_paste_test()
		55:
			_ok(_paste_btn != null and not _paste_btn.visible, "без наведения кнопки «Вставить» нет")
			_move(_add_btn.get_global_rect().get_center())
		57:
			_ok(_paste_btn.visible and _paste_btn.text == "Вставить условие",
					"наведение на «+ Условие» показало «Вставить условие»")
			_move(_paste_btn.get_global_rect().get_center())
		59:
			_ok(_paste_btn.visible, "курсор перешёл на «Вставить» — кнопка не пропала")
			_click(_paste_btn.get_global_rect().get_center())
		62:
			var conds: Array = _panel.doc.instructions_of(_paste_path, "conditions")
			_eq(conds.size(), _paste_before + 1, "клик вставил условие в это событие")
			_eq(str((conds[conds.size() - 1] as Dictionary)["id"]), _paste_id,
					"вставлено именно скопированное")
			# Скопировано условие — у «+ Действие» вставки нет: туда оно не подходит.
			var act_add := _add_button(_panel, _paste_path, "actions")
			_act_paste = _paste_button(_panel, _paste_path, "actions")
			_move(act_add.get_global_rect().get_center())
		64:
			_ok(_act_paste != null and not _act_paste.visible,
					"у «+ Действие» вставки нет — в буфере условие")
			_move(Vector2(5, 900))
			get_tree().root.size = Vector2i(1000, 700)
		66:
			_ok(_panel.get_combined_minimum_size().x <= 1000.0,
					"и в узком окне 1000 px панель не вылезает за край (минимум %d)"
					% int(_panel.get_combined_minimum_size().x))
			get_tree().root.size = Vector2i(1500, 950)
		70:
			_start_inline_test()
		72:
			_ok(_panel._inline != null and _panel._inline.visible,
					"щелчок по значению открыл правку на месте")
			_panel._close_inline()
			_panel.select_event([0])
			# Щелчок мимо значения — по началу фразы — выделяет строку, как раньше.
			if _inline_item != null:
				_click(_inline_item._text.get_global_rect().position + Vector2(3, 8))
		75:
			_ok(_inline_item != null and _panel.is_instruction_selected(_inline_item.path, _inline_item.kind, _inline_item.index)
					and _panel._inline == null, "щелчок мимо значения выделяет строку, правка не открывается")
			_report()


var _inline_item: GdeInstructionItem = null


## Первое значение в строке с параметрами: считаем ширину текста до него
## шрифтом строки и щёлкаем точно по нему — как рукой.
func _start_inline_test() -> void:
	_inline_item = null
	for it: GdeInstructionItem in _all_items(_panel):
		var inst: Dictionary = _panel.doc.instructions_of(it.path, it.kind)[it.index]
		var params: Array = inst.get("params", [])
		var def: Variant = _panel.instruction_def(it.kind, str(inst.get("id", "")))
		if params.is_empty() or not (def is Dictionary) or str(params[0]).is_empty():
			continue
		var sentence := str((def as Dictionary).get("sentence", ""))
		var at := sentence.find("_PARAM0_")
		if at < 0 or sentence.substr(0, at).contains("_PARAM"):
			continue
		_inline_item = it
		var font := it._text.get_theme_font("normal_font")
		var fsize := it._text.get_theme_font_size("normal_font_size")
		var prefix := sentence.substr(0, at)
		var w := font.get_string_size(prefix, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x
		var r := it._text.get_global_rect()
		_panel._inline = null
		_click(r.position + Vector2(w + 4.0, float(fsize) * 0.7))
		return
	_ok(false, "нашлась строка со значением для щелчка")


func _all_items(n: Node) -> Array:
	var out: Array = []
	if n is GdeInstructionItem:
		out.append(n)
	for c: Node in n.get_children():
		out.append_array(_all_items(c))
	return out


func _first_item_with_trash() -> GdeInstructionItem:
	return _find_item(_panel)


func _find_item(n: Node) -> GdeInstructionItem:
	if n is GdeInstructionItem:
		return n as GdeInstructionItem
	for c: Node in n.get_children():
		var r := _find_item(c)
		if r != null:
			return r
	return null


# ---------------------------------------------------------- перетаскивание ---

## Берём первое действие события, у которого их хотя бы три, и тащим его
## на третье: оно должно встать между вторым и третьим.
##
## Бросаем в ВЕРХНЮЮ половину через одну строку, а не в нижнюю соседней —
## не случайно. В безголовом режиме Godot считает координату внутри цели по
## настоящему курсору, а он там всегда в (0, 0): «какая половина» мышью здесь
## не проверяется. Цель и сам перенос — проверяются; выбор половины и то,
## что бросок ложится по линии-подсказке, проверяет _test_drop_follows_mark().
func _start_instruction_drag() -> void:
	var evs: Array = _panel.doc.data["events"]
	for i in range(evs.size()):
		if ((evs[i] as Dictionary).get("actions", []) as Array).size() >= 3:
			_drag_path = [i]
			break
	var acts: Array = _panel.doc.instructions_of(_drag_path, "actions")
	_drag_first = str((acts[0] as Dictionary)["params"])
	_drag_second = str((acts[1] as Dictionary)["params"])
	var a := _item_at(_panel, _drag_path, "actions", 0)
	var c := _item_at(_panel, _drag_path, "actions", 2)
	var rc := c.get_global_rect()
	_drag_from = a.get_global_rect().get_center()
	_drag_to = Vector2(rc.get_center().x, rc.position.y + rc.size.y * 0.2)
	_press(_drag_from)


## Первое событие тащим за ручку в верхнюю часть третьего — встанет перед ним.
func _start_event_drag() -> void:
	var evs: Array = _panel.doc.data["events"]
	_ev_first = JSON.stringify(evs[0])
	var grip := _grip_at(_panel, [0])
	var card := _card_at(_panel, [2])
	var rc := card.get_global_rect()
	_drag_from = grip.get_global_rect().get_center()
	_drag_to = Vector2(rc.get_center().x, rc.position.y + rc.size.y * 0.1)
	_press(_drag_from)


## Бросок ложится туда, где горела линия-подсказка, даже если координата
## в момент отпускания указывает в другую половину строки.
func _test_drop_follows_mark() -> void:
	var list: Array = _panel.doc.instructions_of(_drag_path, "actions")
	var first := str((list[0] as Dictionary)["params"])
	var second := str((list[1] as Dictionary)["params"])
	var b := _item_at(_panel, _drag_path, "actions", 1) as GdeInstructionItem
	var data := {"type": GdeInstructionItem.DRAG_TYPE, "kind": "actions",
			"path": _drag_path.duplicate(), "index": 0, "data": list[0]}
	_ok(b._can_drop_data(Vector2(5, b.size.y * 0.8), data) and b._drop_mark == 1,
			"над нижней половиной строки горит линия «встанет ниже»")
	b._drop_data(Vector2(5, -500), data)
	var after: Array = _panel.doc.instructions_of(_drag_path, "actions")
	_ok(str((after[0] as Dictionary)["params"]) == second
			and str((after[1] as Dictionary)["params"]) == first,
			"бросок лёг по линии-подсказке, а не по координате отпускания")


## Промежуточные шаги: Godot начинает перетаскивание, только увидев движение
## с зажатой кнопкой, — одним прыжком мышь не «тянут».
func _drag_step(i: int, total: int) -> void:
	var at := _drag_from.lerp(_drag_to, float(i + 1) / float(total))
	var ev := InputEventMouseMotion.new()
	ev.position = at
	ev.global_position = at
	ev.button_mask = MOUSE_BUTTON_MASK_LEFT
	ev.relative = (_drag_to - _drag_from) / float(total)
	get_viewport().push_input(ev)


func _press(at: Vector2) -> void:
	_move(at)
	var ev := InputEventMouseButton.new()
	ev.position = at
	ev.global_position = at
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	get_viewport().push_input(ev)


func _release(at: Vector2) -> void:
	var ev := InputEventMouseButton.new()
	ev.position = at
	ev.global_position = at
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = false
	get_viewport().push_input(ev)


func _item_at(n: Node, path: Array, kind: String, index: int) -> Control:
	if n is GdeInstructionItem:
		var it := n as GdeInstructionItem
		if it.path == path and it.kind == kind and it.index == index:
			return it
	for c: Node in n.get_children():
		var r := _item_at(c, path, kind, index)
		if r != null:
			return r
	return null


func _grip_at(n: Node, path: Array) -> Control:
	if n is GdeEventGrip and (n as GdeEventGrip).path == path:
		return n as Control
	for c: Node in n.get_children():
		var r := _grip_at(c, path)
		if r != null:
			return r
	return null


func _card_at(n: Node, path: Array) -> Control:
	if n is GdeEventCard and (n as GdeEventCard).path == path:
		return n as Control
	for c: Node in n.get_children():
		var r := _card_at(c, path)
		if r != null:
			return r
	return null


# -------------------------------------------------------------- вставка ---

## Копируем условие из одного события и готовимся вставить его в другое
## событие, у которого есть колонка условий.
func _start_paste_test() -> void:
	var evs: Array = _panel.doc.data["events"]
	var src: Array = []
	for i in range(evs.size()):
		var e: Dictionary = evs[i]
		if str(e.get("type", "standard")) != "standard":
			continue
		if src.is_empty() and not (e.get("conditions", []) as Array).is_empty():
			src = [i]
		elif not src.is_empty():
			_paste_path = [i]
			break
	_panel.copy_instruction(src, "conditions", 0)
	_paste_id = str((_panel.doc.instructions_of(src, "conditions")[0] as Dictionary)["id"])
	_paste_before = _panel.doc.instructions_of(_paste_path, "conditions").size()
	_add_btn = _add_button(_panel, _paste_path, "conditions")
	_paste_btn = _paste_button(_panel, _paste_path, "conditions")


func _add_button(n: Node, path: Array, kind: String) -> Control:
	var paste := _paste_button(n, path, kind)
	return paste.get_parent().get_child(0) as Control if paste != null else null


## Кнопка «Вставить» нужной колонки нужного события.
func _paste_button(n: Node, path: Array, kind: String) -> Button:
	if n is GdeEventRow and (n as GdeEventRow).path == path:
		return _find_paste(n, kind, path)
	for c: Node in n.get_children():
		var r := _paste_button(c, path, kind)
		if r != null:
			return r
	return null


func _find_paste(n: Node, kind: String, path: Array) -> Button:
	for c: Node in n.get_children():
		# Не спускаемся в подсобытия: у них свои кнопки.
		if c is GdeEventRow and (c as GdeEventRow).path != path:
			continue
		if c is Button and c.has_meta("gde_paste_kind") and str(c.get_meta("gde_paste_kind")) == kind:
			return c as Button
		var r := _find_paste(c, kind, path)
		if r != null:
			return r
	return null


## Корзина первого события верхнего уровня — последняя кнопка его ряда.
func _find_row_trash(n: Node) -> Control:
	for c: Node in n.get_children():
		if c is GdeEventRow and (c as GdeEventRow).path.size() == 1:
			var tools: HBoxContainer = (c as GdeEventRow)._tools
			return tools.get_child(tools.get_child_count() - 1) as Control
		var r := _find_row_trash(c)
		if r != null:
			return r
	return null


func _trash() -> Control:
	return _item._tools.get_child(_item._tools.get_child_count() - 1) as Control


func _count() -> int:
	return _panel.doc.instructions_of(_path, _kind).size()


func _move(at: Vector2) -> void:
	var ev := InputEventMouseMotion.new()
	ev.position = at
	ev.global_position = at
	get_viewport().push_input(ev)


func _click(at: Vector2) -> void:
	for pressed: bool in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.position = at
		ev.global_position = at
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = pressed
		get_viewport().push_input(ev)


func _ok(cond: bool, what: String) -> void:
	_checks += 1
	if cond:
		print("  ✓ %s" % what)
	else:
		_fails += 1
		print("  ✗ %s" % what)


func _eq(got: Variant, want: Variant, what: String) -> void:
	_ok(str(got) == str(want), "%s (ожидалось %s, получено %s)" % [what, want, got] \
			if str(got) != str(want) else what)


func _report() -> void:
	print("—— проверок: %d, провалено: %d" % [_checks, _fails])
	get_tree().quit(1 if _fails > 0 else 0)
