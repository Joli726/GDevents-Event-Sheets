## Поведение «Диалог».
##
## @behavior Dialogue
## @title Диалог
## @title.en Dialogue
## @description Облачко над персонажем: текст печатается по буквам, реплики идут очередью, Enter или щелчок — дальше, а вопрос предлагает ответы на выбор. Несколько реплик сразу — через «|»: «Привет!|Как дела?».
## @description.en A speech bubble above a character: the text is typed letter by letter, lines go in a queue, Enter or a click moves on, and a question offers answers to choose from. Several lines at once — with "|": "Hi!|How are you?".
## @icon dialogue
@tool
extends GdeBehavior

## Началась реплика.
signal line_started(text: String)
## Реплика допечатана.
signal line_typed
## Выбран ответ: номер с нуля и текст.
signal choice_made(index: int, text: String)
## Очередь кончилась, облачко закрылось.
signal finished

## @group.en Text
@export_group("Текст")
## Скорость печати, букв в секунду. 0 — сразу целиком.
## @en Typing speed, letters per second. 0 — all at once.
@export_range(0.0, 500.0, 1.0) var letters_per_second: float = 40.0
## Автопродолжение — через сколько секунд после допечатки идти дальше. 0 — ждать Enter или щелчка.
## @en Auto-advance — how many seconds after typing to move on. 0 — wait for Enter or a click.
@export_range(0.0, 30.0, 0.1) var auto_advance: float = 0.0
## Клавиша «дальше», например Enter или E.
## @en The "next" key, e.g. Enter or E.
@export var advance_key: String = "Enter"
## Щелчок мышью тоже продолжает.
## @en A mouse click moves on too.
@export var click_to_advance: bool = true
## Имя говорящего над текстом. Пусто — без имени.
## @en The speaker's name above the text. Empty — no name.
@export var speaker_name: String = ""
## Звук каждой буквы — путь к файлу. Пусто — тихо.
## @en The sound of each letter — a file path. Empty — silent.
@export_file("*.wav", "*.ogg", "*.mp3") var letter_sound: String = ""
## Ставить игру на паузу, пока идёт разговор.
## @en Pause the game — while the conversation goes on.
@export var pause_game: bool = false

## @group.en Bubble
@export_group("Облачко")
## Внизу экрана, как в ролевых играх, а не над персонажем.
## @en At the bottom of the screen, as in role-playing games, instead of above the character.
@export var on_screen: bool = false
## Наибольшая ширина облачка, пикселей.
## @en Maximum bubble width, pixels.
@export_range(40.0, 2000.0, 1.0) var max_width: float = 220.0
## Размер шрифта.
## @en Font size.
@export_range(6, 96, 1) var font_size: int = 14
## Подъём облачка над объектом, пикселей.
## @en How high the bubble floats above the object, pixels.
@export_range(0.0, 500.0, 1.0) var lift: float = 8.0
## Цвет облачка.
## @en Bubble color.
@export var bubble_color: Color = Color(1.0, 1.0, 1.0, 0.95)
## Цвет текста.
## @en Text color.
@export var text_color: Color = Color(0.1, 0.1, 0.12)
## Цвет выбранного ответа.
## @en Color of the selected answer.
@export var choice_color: Color = Color(0.85, 0.35, 0.1)

var _queue: Array = []
var _text: String = ""
var _choices: PackedStringArray = PackedStringArray()
var _shown: float = 0.0
var _open: bool = false
var _wait: float = 0.0
var _selected: int = 0
var _chosen: int = -1
var _chosen_text: String = ""
var _choice_frame: int = -100
var _finish_frame: int = -100
var _key_was: bool = true
var _mouse_was: bool = true
var _up_was: bool = true
var _down_was: bool = true
var _last_letters: int = 0

var _root: Node = null
var _panel: PanelContainer = null
var _name_label: Label = null
var _label: Label = null
var _choice_box: VBoxContainer = null
var _tail: Polygon2D = null


func _ready() -> void:
	super()
	if not Engine.is_editor_hint():
		# Разговор идёт и на паузе, которую он сам поставил.
		process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	var o := object as Node2D
	if o == null:
		return
	if not _open:
		_edges()
		return
	if _root == null:
		_build()
	var total := _text.length()
	if _shown < total:
		_shown = float(total) if letters_per_second <= 0.0 else minf(total, _shown + letters_per_second * delta)
		_label.visible_characters = int(_shown)
		if int(_shown) != _last_letters:
			_last_letters = int(_shown)
			if not letter_sound.is_empty() and _last_letters % 2 == 1:
				Gde.play_sound(letter_sound, -6.0, randf_range(0.95, 1.05))
		if _shown >= total:
			_on_typed()
	elif _choices.is_empty() and auto_advance > 0.0:
		_wait -= delta
		if _wait <= 0.0:
			advance()
	_read_input()
	_layout(o)


func _edges() -> void:
	_key_was = _key_down()
	_mouse_was = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	_up_was = Input.is_action_pressed("ui_up")
	_down_was = Input.is_action_pressed("ui_down")


func _key_down() -> bool:
	if advance_key.is_empty():
		return false
	var k := OS.find_keycode_from_string(advance_key)
	return k != KEY_NONE and Input.is_key_pressed(k)


## Нажатия ловим сами: на паузе автозагрузка Gde стоит вместе с игрой.
func _read_input() -> void:
	var key := _key_down()
	var mouse := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var up := Input.is_action_pressed("ui_up")
	var down := Input.is_action_pressed("ui_down")
	var next := (key and not _key_was) or (click_to_advance and mouse and not _mouse_was and _choices.is_empty())
	if not _choices.is_empty() and _shown >= _text.length():
		if up and not _up_was:
			_select(_selected - 1)
		if down and not _down_was:
			_select(_selected + 1)
	_key_was = key
	_mouse_was = mouse
	_up_was = up
	_down_was = down
	if next:
		if not _choices.is_empty() and _shown >= _text.length():
			choose(float(_selected))
		else:
			advance()


func _on_typed() -> void:
	_wait = auto_advance
	line_typed.emit()
	if not _choices.is_empty():
		_show_choices()


func _build() -> void:
	var holder: Node
	if on_screen:
		var layer := CanvasLayer.new()
		layer.layer = 20
		add_child(layer)
		holder = layer
	else:
		var n2 := Node2D.new()
		n2.top_level = true
		n2.z_index = 100
		add_child(n2)
		holder = n2
		_tail = Polygon2D.new()
		_tail.polygon = PackedVector2Array([Vector2(-7, 0), Vector2(7, 0), Vector2(0, 9)])
		n2.add_child(_tail)
	_root = holder
	_panel = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	_panel.add_theme_stylebox_override("panel", sb)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(_panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	_panel.add_child(vb)
	_name_label = Label.new()
	vb.add_child(_name_label)
	_label = Label.new()
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(_label)
	_choice_box = VBoxContainer.new()
	vb.add_child(_choice_box)
	_style()


func _style() -> void:
	(_panel.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = bubble_color
	if _tail != null:
		_tail.color = bubble_color
	for l: Label in [_name_label, _label]:
		l.add_theme_font_size_override("font_size", font_size)
		l.add_theme_color_override("font_color", text_color)
	_name_label.text = speaker_name
	_name_label.visible = not speaker_name.is_empty()
	_name_label.add_theme_color_override("font_color", choice_color)


func _show_line(text: String) -> void:
	# «Вопрос? [Да|Нет]» — вопрос с ответами.
	_choices = PackedStringArray()
	var t := text
	var b := text.rfind("[")
	if b >= 0 and text.ends_with("]"):
		for c: String in text.substr(b + 1, text.length() - b - 2).split("|", false):
			if not c.strip_edges().is_empty():
				_choices.append(c.strip_edges())
		t = text.substr(0, b).strip_edges()
	_text = t
	_shown = 0.0
	_last_letters = 0
	_selected = 0
	if _root == null:
		_build()
	_style()
	_label.text = _text
	_label.visible_characters = 0
	for c: Node in _choice_box.get_children():
		c.queue_free()
	_choice_box.visible = false
	_root.set("visible", true)
	line_started.emit(_text)
	if letters_per_second <= 0.0 or _text.is_empty():
		_shown = float(_text.length())
		_label.visible_characters = -1
		_on_typed()


func _show_choices() -> void:
	for c: Node in _choice_box.get_children():
		c.queue_free()
	for i in _choices.size():
		var btn := Button.new()
		btn.text = _choices[i]
		btn.flat = true
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_font_size_override("font_size", font_size)
		btn.focus_mode = Control.FOCUS_NONE
		btn.pressed.connect(func() -> void: choose(float(i)))
		btn.mouse_entered.connect(func() -> void: _select(i))
		_choice_box.add_child(btn)
	_choice_box.visible = true
	_select(0)


func _select(i: int) -> void:
	if _choices.is_empty():
		return
	_selected = posmod(i, _choices.size())
	var k := 0
	for c: Node in _choice_box.get_children():
		if c is Button and not c.is_queued_for_deletion():
			var mark := "▸ " if k == _selected else "   "
			(c as Button).text = mark + _choices[k]
			var col := choice_color if k == _selected else text_color
			for s: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
				(c as Button).add_theme_color_override(s, col)
			k += 1


func _layout(o: Node2D) -> void:
	var w := max_width
	_label.custom_minimum_size.x = 0.0
	var natural := _label.get_theme_font("font").get_string_size(_text, HORIZONTAL_ALIGNMENT_LEFT, -1,
			font_size).x + 22.0
	for c: String in _choices:
		natural = maxf(natural, _label.get_theme_font("font").get_string_size("▸ " + c, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + 40.0)
	w = clampf(natural, 60.0, max_width)
	_label.custom_minimum_size.x = w - 20.0
	_panel.size = Vector2(w, 0)
	_panel.reset_size()
	var size := _panel.get_combined_minimum_size()
	size.x = maxf(size.x, w)
	_panel.size = size
	if on_screen:
		var vp := o.get_viewport_rect().size
		_panel.position = Vector2((vp.x - size.x) * 0.5, vp.y - size.y - 24.0)
		return
	var r := Gde.aabb(o)
	var top := Vector2(r.get_center().x, r.position.y) if r.size != Vector2.ZERO else o.global_position
	(_root as Node2D).global_position = top - Vector2(0, lift + 9.0)
	_panel.position = Vector2(-size.x * 0.5, -size.y)
	if _tail != null:
		_tail.position = Vector2.ZERO


func _close() -> void:
	_open = false
	_text = ""
	_choices = PackedStringArray()
	if _root != null:
		_root.set("visible", false)
	if pause_game:
		get_tree().paused = false
	_finish_frame = Engine.get_process_frames()
	finished.emit()


## Несколько реплик сразу — через «|». Вопрос с ответами: «Идём? [Да|Нет]».
## @en Several lines at once — with "|". A question with answers: "Shall we go? [Yes|No]".
## @action _PARAM0_ говорит: _PARAM1_
## @action.en _PARAM0_ says: _PARAM1_
## @param text Текст
## @param.en text Text
func say(text: String) -> void:
	for line: String in _split(text):
		_queue.append(line)
	if not _open:
		_open = true
		_edges()
		if pause_game:
			get_tree().paused = true
		advance()


## Ответы через «|».
## @en Answers separated by "|".
## @action _PARAM0_ спрашивает: _PARAM1_, ответы: _PARAM2_
## @action.en _PARAM0_ asks: _PARAM1_, answers: _PARAM2_
## @param question Вопрос
## @param.en question Question
## @param answers Ответы
## @param.en answers Answers
func ask(question: String, answers: String) -> void:
	say(question.replace("|", "/") + " [" + answers + "]")


## Реплика печатается — допечатать сразу; допечатана — следующая; реплик нет — закрыть.
## @en A line is being typed — finish it at once; typed — the next one; no lines — close.
## @action Дальше в разговоре _PARAM0_
## @action.en Next in the conversation of _PARAM0_
func advance() -> void:
	if not _open:
		return
	if _root != null and _shown < _text.length():
		_shown = float(_text.length())
		_label.visible_characters = -1
		_on_typed()
		return
	if not _choices.is_empty() and _root != null:
		return
	if _queue.is_empty():
		_close()
		return
	_show_line(str(_queue.pop_front()))


## @action Выбрать в разговоре _PARAM0_ ответ номер _PARAM1_ (с нуля)
## @action.en Choose answer number _PARAM1_ (from zero) in the conversation of _PARAM0_
## @param index Номер
## @param.en index Number
func choose(index: float) -> void:
	if _choices.is_empty():
		return
	var i := clampi(int(index), 0, _choices.size() - 1)
	_chosen = i
	_chosen_text = _choices[i]
	_choice_frame = Engine.get_process_frames()
	_choices = PackedStringArray()
	choice_made.emit(i, _chosen_text)
	advance()


## @action Прервать разговор _PARAM0_
## @action.en Stop the conversation of _PARAM0_
func stop() -> void:
	_queue.clear()
	if _open:
		_close()


func _split(text: String) -> PackedStringArray:
	# «|» внутри [ответов] — не граница реплик.
	var out := PackedStringArray()
	var cur := ""
	var depth := 0
	for ch: String in text:
		if ch == "[":
			depth += 1
		elif ch == "]":
			depth = maxi(0, depth - 1)
		if ch == "|" and depth == 0:
			if not cur.strip_edges().is_empty():
				out.append(cur.strip_edges())
			cur = ""
		else:
			cur += ch
	if not cur.strip_edges().is_empty():
		out.append(cur.strip_edges())
	return out


## @condition _PARAM0_ разговаривает
## @condition.en _PARAM0_ is talking
func is_talking() -> bool:
	return _open


## @condition _PARAM0_ ещё печатает реплику
## @condition.en _PARAM0_ is still typing a line
func is_typing() -> bool:
	return _open and _shown < _text.length()


## @condition _PARAM0_ ждёт ответа
## @condition.en _PARAM0_ is waiting for an answer
func is_asking() -> bool:
	return _open and not _choices.is_empty()


## @condition В разговоре _PARAM0_ только что выбрали ответ номер _PARAM1_ (с нуля)
## @condition.en Answer number _PARAM1_ (from zero) has just been chosen in the conversation of _PARAM0_
## @param index Номер
## @param.en index Number
func just_chose(index: float) -> bool:
	return _chosen == int(index) and Engine.get_process_frames() - _choice_frame <= RECENT_FRAMES


## @condition Разговор _PARAM0_ только что закончился
## @condition.en The conversation of _PARAM0_ has just ended
func just_finished() -> bool:
	return Engine.get_process_frames() - _finish_frame <= RECENT_FRAMES


## @expression Номер последнего выбранного ответа, с нуля; -1 — ещё не выбирали
## @expression.en Number of the last chosen answer, from zero; -1 — nothing chosen yet
func choice_index() -> float:
	return float(_chosen)


## @expression Текст последнего выбранного ответа
## @expression.en Text of the last chosen answer
func choice_text() -> String:
	return _chosen_text


## @expression Сколько реплик ещё в очереди
## @expression.en How many lines are still in the queue
func lines_left() -> float:
	return float(_queue.size())


## @expression Текущая реплика
## @expression.en The current line
func current_line() -> String:
	return _text
