## Поведение «Кнопка меню».
##
## @behavior MenuButton
## @title Кнопка меню
## @title.en Menu button
## @description Кнопка для главного меню и паузы: наведение, нажатие, звук, лёгкое увеличение. Работает и на картинке, и на кнопке интерфейса, стрелками и Enter, и на паузе. По нажатию может сама перейти на сцену, перезапустить её, снять паузу или выйти.
## @description.en A button for the main menu and pause: hover, press, sound, a slight zoom. Works on a picture and on a UI button, with arrow keys and Enter, and during pause. On press it can go to a scene, restart it, unpause or quit by itself.
## @icon menu_button
@tool
extends GdeBehavior

## Нажата.
signal clicked
## Мышь навелась или кнопку выбрали стрелками.
signal hovered

const GROUP := "__gde_menu_button"

## @group.en Press
@export_group("Нажатие")
## Что сделать по нажатию: ничего (решают события), перейти на сцену, перезапустить сцену, снять паузу или выйти из игры.
## @en What to do on press: nothing (events decide), go to a scene, restart the scene, unpause or quit the game.
## @options.en Nothing, Go to scene, Restart scene, Unpause, Quit
@export_enum("Ничего", "Перейти на сцену", "Перезапустить сцену", "Снять паузу", "Выйти из игры") var on_click: int = 0
## Сцена, на которую перейти.
## @en The scene to go to.
@export_file("*.tscn", "*.scn") var scene_path: String = ""
## Кнопка работает.
## @en The button works.
@export var enabled: bool = true
## Работать и на паузе — для меню паузы.
## @en Work during pause too — for a pause menu.
@export var works_on_pause: bool = true

## @group.en Look
@export_group("Вид")
## Увеличение при наведении, доля: 1.08 — на 8%.
## @en Zoom on hover, share: 1.08 — by 8%.
@export_range(1.0, 2.0, 0.01) var hover_scale: float = 1.08
## Сжатие при нажатии.
## @en Shrink on press.
@export_range(0.5, 1.0, 0.01) var press_scale: float = 0.94
## Цвет при наведении.
## @en Color on hover.
@export var hover_color: Color = Color(1.15, 1.15, 1.15)
## Цвет выключенной кнопки.
## @en Color of a disabled button.
@export var disabled_color: Color = Color(0.5, 0.5, 0.5, 0.8)
## Скорость анимации — чем больше, тем резче.
## @en Animation speed — the higher, the snappier.
@export_range(1.0, 60.0, 1.0) var anim_speed: float = 18.0

## @group.en Sound
@export_group("Звук")
## Звук наведения — путь к файлу. Пусто — тихо.
## @en Hover sound — a file path. Empty — silent.
@export_file("*.wav", "*.ogg", "*.mp3") var hover_sound: String = ""
## Звук нажатия — путь к файлу.
## @en Press sound — a file path.
@export_file("*.wav", "*.ogg", "*.mp3") var click_sound: String = ""

## @group.en Keyboard
@export_group("Клавиатура")
## Выбор стрелками вверх и вниз и нажатие Enter — среди кнопок одного меню.
## @en Keyboard — choose with the up and down arrows and press with Enter, among the buttons of one menu.
@export var keyboard: bool = true
## Имя меню: стрелки переходят между кнопками с одинаковым именем.
## @en Menu name: the arrows move between buttons with the same name.
@export var menu_name: String = "main"

var _base_scale: Vector2 = Vector2.ONE
var _base_mod: Color = Color.WHITE
var _started: bool = false
var _hover: bool = false
var _selected: bool = false
var _down: bool = false
var _mouse_was: bool = false
var _k: float = 1.0
var _click_frame: int = -100


func _ready() -> void:
	super()
	if Engine.is_editor_hint():
		return
	add_to_group(GROUP)
	if works_on_pause:
		process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	var o := object as CanvasItem
	if o == null:
		return
	if not _started:
		_started = true
		_base_scale = _get_scale(o)
		_base_mod = o.modulate
	var mouse := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var over := enabled and _mouse_over(o)
	if over and not _hover:
		_hover = true
		_select_only_me()
		_on_hover()
	elif not over:
		_hover = false
	if enabled and over and mouse and not _mouse_was:
		_down = true
	if _down and not mouse:
		_down = false
		if over:
			click()
	_mouse_was = mouse
	if keyboard and enabled:
		_keys()
	var want := 1.0
	if _down:
		want = press_scale
	elif _hover or _selected:
		want = hover_scale
	_k = lerpf(_k, want, clampf(anim_speed * delta, 0.0, 1.0))
	_set_scale(o, _base_scale * _k)
	if not enabled:
		o.modulate = _base_mod * disabled_color
	elif _hover or _selected:
		o.modulate = _base_mod * hover_color
	else:
		o.modulate = _base_mod


func _get_scale(o: CanvasItem) -> Vector2:
	if o is Control:
		return (o as Control).scale
	return (o as Node2D).scale if o is Node2D else Vector2.ONE


func _set_scale(o: CanvasItem, s: Vector2) -> void:
	if o is Control:
		var c := o as Control
		# Увеличиваться от центра, а не от левого верхнего угла.
		c.pivot_offset = c.size * 0.5
		c.scale = s
	elif o is Node2D:
		(o as Node2D).scale = s


func _mouse_over(o: CanvasItem) -> bool:
	if o is Control:
		var c := o as Control
		return c.is_visible_in_tree() and c.get_global_rect().has_point(c.get_global_mouse_position())
	if not o.is_visible_in_tree():
		return false
	return Gde.aabb(o).has_point((o as Node2D).get_global_mouse_position() if o is Node2D else Gde.mouse_world())


func _on_hover() -> void:
	hovered.emit()
	if not hover_sound.is_empty():
		Gde.play_sound(hover_sound, 0.0)


func _select_only_me() -> void:
	for b: Node in get_tree().get_nodes_in_group(GROUP):
		if b.get("menu_name") == menu_name:
			b.set("_selected", b == self)


## Стрелки выбирают кнопку меню сверху вниз, Enter — нажимает выбранную.
## Обрабатывает первая кнопка меню, чтобы нажатие не считалось дважды.
func _keys() -> void:
	var mates: Array = []
	for b: Node in get_tree().get_nodes_in_group(GROUP):
		if b.get("menu_name") == menu_name and b.get("enabled") and (b.get("object") as CanvasItem) != null \
				and (b.get("object") as CanvasItem).is_visible_in_tree():
			mates.append(b)
	if mates.is_empty() or mates[0] != self:
		return
	mates.sort_custom(func(a: Node, b: Node) -> bool: return _y(a) < _y(b))
	var cur := -1
	for i in mates.size():
		if mates[i].get("_selected"):
			cur = i
	var step := 0
	if Input.is_action_just_pressed("ui_down"):
		step = 1
	elif Input.is_action_just_pressed("ui_up"):
		step = -1
	if step != 0:
		var next: Node = mates[posmod(cur + step, mates.size())] if cur >= 0 else mates[0]
		next.call("_select_only_me")
		next.call("_on_hover")
	elif cur >= 0 and Input.is_action_just_pressed("ui_accept"):
		mates[cur].call("click")


static func _y(b: Node) -> float:
	var o: Variant = b.get("object")
	if o is Control:
		return (o as Control).global_position.y
	return (o as Node2D).global_position.y if o is Node2D else 0.0


## @action Нажать кнопку _PARAM0_
## @action.en Press the button _PARAM0_
func click() -> void:
	if not enabled:
		return
	_click_frame = Engine.get_process_frames()
	if not click_sound.is_empty():
		Gde.play_sound(click_sound, 0.0)
	clicked.emit()
	match on_click:
		1:
			if not scene_path.is_empty():
				get_tree().paused = false
				Gde.change_scene(scene_path)
		2:
			get_tree().paused = false
			Gde.restart_scene()
		3:
			get_tree().paused = false
		4:
			get_tree().quit()


## @action Выбрать кнопку _PARAM0_ (как стрелками)
## @action.en Select the button _PARAM0_ (as with the arrows)
func select() -> void:
	_select_only_me()


## @action Включить кнопку _PARAM0_: _PARAM1_ (1 да, 0 нет)
## @action.en Enable the button _PARAM0_: _PARAM1_ (1 yes, 0 no)
## @param on Да или нет
## @param.en on Yes or no
func set_enabled(on: bool) -> void:
	enabled = on


## @condition Кнопку _PARAM0_ только что нажали
## @condition.en The button _PARAM0_ has just been pressed
func just_clicked() -> bool:
	return Engine.get_process_frames() - _click_frame <= RECENT_FRAMES


## @condition На кнопку _PARAM0_ навели мышь
## @condition.en The mouse is over the button _PARAM0_
func is_hovered() -> bool:
	return _hover


## @condition Кнопка _PARAM0_ выбрана
## @condition.en The button _PARAM0_ is selected
func is_selected() -> bool:
	return _selected
