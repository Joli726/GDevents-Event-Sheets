## Поведение «Полоска значения».
##
## @behavior ValueBar
## @title Полоска значения
## @title.en Value bar
## @description Полоска здоровья или любой переменной. Рисуется сама, картинки не нужны. Убывает плавно, а за ней тянется «догоняющий» след, как в файтингах. Может висеть над объектом или стоять на экране.
## @description.en A bar of health or of any variable. It draws itself, no pictures needed. It shrinks smoothly, with a "catching up" trail behind it, as in fighting games. It can hang above an object or stay on the screen.
## @icon bar
@tool
extends GdeBehavior

## @group.en Value
@export_group("Значение")
## Что показывать: «Здоровье» этого объекта, «Здоровье» другого объекта, переменную сцены или глобальную.
## @en What to show: the "Health" of this object, the "Health" of another object, a scene variable or a global one.
## @options.en Health of this object, Health of an object, Scene variable, Global variable
@export_enum("Здоровье этого объекта", "Здоровье объекта", "Переменная сцены", "Глобальная переменная") var source: int = 0
## Чьё здоровье — имя объекта из листа, например Player.
## @en Whose health — the name of a sheet object, e.g. Player.
@export var source_object: String = "Player"
## Имя переменной, например hp.
## @en Variable name, e.g. hp.
@export var variable: String = "hp"
## Максимум для переменной — полная полоска.
## @en Maximum for a variable — a full bar.
@export_range(0.01, 100000.0, 1.0) var max_value: float = 100.0

## @group.en Place
@export_group("Место")
## На экране: полоска стоит в углу, а не висит над объектом.
## @en On screen: the bar stays in a corner instead of hanging above the object.
@export var on_screen: bool = false
## Сдвиг по X — от объекта или, на экране, от левого края, пикселей.
## @en X offset — from the object or, on screen, from the left edge, pixels.
@export_range(-4000.0, 4000.0, 1.0) var offset_x: float = 0.0
## Сдвиг по Y — от объекта (минус — выше) или, на экране, от верхнего края.
## @en Y offset — from the object (minus — higher) or, on screen, from the top edge.
@export_range(-4000.0, 4000.0, 1.0) var offset_y: float = -28.0
## Ширина, пикселей.
## @en Width, pixels.
@export_range(1.0, 2000.0, 1.0) var width: float = 40.0
## Высота, пикселей.
## @en Height, pixels.
@export_range(1.0, 200.0, 1.0) var height: float = 5.0

## @group.en Look
@export_group("Вид")
## Цвет полоски.
## @en Bar color.
@export var fill_color: Color = Color(0.3, 0.85, 0.35)
## Цвет, когда значение низкое.
## @en Color when the value is low.
@export var low_color: Color = Color(0.95, 0.3, 0.25)
## Низкое — ниже этой доли, от 0 до 1.
## @en Low — below this share, from 0 to 1.
@export_range(0.0, 1.0, 0.05) var low_share: float = 0.3
## Цвет подложки.
## @en Background color.
@export var back_color: Color = Color(0.1, 0.1, 0.1, 0.8)
## Цвет догоняющего следа.
## @en Color of the catching-up trail.
@export var trail_color: Color = Color(1.0, 0.95, 0.8, 0.9)
## Прятать, когда полная.
## @en Hide when full.
@export var hide_when_full: bool = false

## @group.en Motion
@export_group("Движение")
## Скорость полоски — долей за секунду. 0 — сразу.
## @en Bar speed — share per second. 0 — at once.
@export_range(0.0, 20.0, 0.1) var fill_speed: float = 4.0
## Задержка следа — сколько секунд он стоит, прежде чем догнать.
## @en Trail delay — how many seconds it stays before catching up.
@export_range(0.0, 5.0, 0.05) var trail_delay: float = 0.4
## Скорость следа — долей за секунду.
## @en Trail speed — share per second.
@export_range(0.0, 20.0, 0.1) var trail_speed: float = 1.2

var _shown: float = -1.0
var _trail: float = -1.0
var _trail_wait: float = 0.0
var _root: Node2D = null
var _back: ColorRect = null
var _trail_rect: ColorRect = null
var _fill: ColorRect = null
var _layer: CanvasLayer = null


func _process(delta: float) -> void:
	var o := object as Node2D
	if o == null:
		return
	if _root == null:
		_build()
	var target := value_share()
	if _shown < 0.0:
		_shown = target
		_trail = target
	# Полоска идёт к значению; след ждёт и догоняет, когда она убывает.
	_shown = target if fill_speed <= 0.0 else move_toward(_shown, target, fill_speed * delta)
	if target < _trail:
		if _trail_wait > 0.0:
			_trail_wait -= delta
		else:
			_trail = move_toward(_trail, _shown, trail_speed * delta)
	else:
		_trail = _shown
		_trail_wait = trail_delay
	_layout(o)


func _build() -> void:
	_root = Node2D.new()
	_root.name = "Bar"
	_root.z_index = 50
	if on_screen:
		_layer = CanvasLayer.new()
		_layer.layer = 10
		add_child(_layer)
		_layer.add_child(_root)
	else:
		_root.top_level = true
		add_child(_root)
	_back = ColorRect.new()
	_trail_rect = ColorRect.new()
	_fill = ColorRect.new()
	for r: ColorRect in [_back, _trail_rect, _fill]:
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_root.add_child(r)


func _layout(o: Node2D) -> void:
	if on_screen:
		_root.position = Vector2(offset_x, offset_y)
	else:
		_root.global_position = o.global_position + Vector2(offset_x - width * 0.5, offset_y - height * 0.5)
	_root.visible = not (hide_when_full and _shown >= 0.999 and _trail >= 0.999)
	_back.size = Vector2(width, height)
	_back.color = back_color
	_trail_rect.size = Vector2(width * clampf(_trail, 0.0, 1.0), height)
	_trail_rect.color = trail_color
	_fill.size = Vector2(width * clampf(_shown, 0.0, 1.0), height)
	_fill.color = low_color if _shown < low_share else fill_color


## Доля от максимума прямо сейчас, без плавности.
func value_share() -> float:
	match source:
		0, 1:
			var h := _health()
			if h == null:
				return 0.0
			var mx := float(h.get("max_health"))
			return clampf(float(h.get("current")) / mx, 0.0, 1.0) if mx > 0.0 else 0.0
		2:
			return clampf(float(Gde.var_get(variable, 0.0)) / max_value, 0.0, 1.0)
		3:
			return clampf(float(Gde.gvar_get(variable, 0.0)) / max_value, 0.0, 1.0)
	return 0.0


func _health() -> Node:
	if source == 0:
		return Gde.behavior(object, "Health", true)
	var best: Node = null
	var best_d := INF
	var o := object as Node2D
	for n: Node in Gde.all_instances(source_object):
		var h := Gde.behavior(n, "Health", true)
		if h == null:
			continue
		var d := Gde.pos_of(n).distance_squared_to(o.global_position) if o != null else 0.0
		if d < best_d:
			best_d = d
			best = h
	return best


## @action Показывать на полоске _PARAM0_ переменную _PARAM1_ из _PARAM2_ максимум
## @action.en Show on the bar _PARAM0_ the variable _PARAM1_ out of a maximum of _PARAM2_
## @param name Переменная
## @param.en name Variable
## @param maximum Максимум
## @param.en maximum Maximum
func show_variable(name: String, maximum: float) -> void:
	source = 2
	variable = name
	max_value = maxf(0.01, maximum)


## @action Сразу показать на полоске _PARAM0_ точное значение, без плавности
## @action.en Instantly show the exact value on the bar _PARAM0_, without smoothing
func snap() -> void:
	_shown = value_share()
	_trail = _shown


## @action Цвет полоски _PARAM0_: R _PARAM1_, G _PARAM2_, B _PARAM3_ (0…1)
## @action.en Bar color of _PARAM0_: R _PARAM1_, G _PARAM2_, B _PARAM3_ (0…1)
## @param r R
## @param g G
## @param b B
func set_color(r: float, g: float, b: float) -> void:
	fill_color = Color(r, g, b, fill_color.a)


## @condition Полоска _PARAM0_ ещё убывает
## @condition.en The bar _PARAM0_ is still shrinking
func is_draining() -> bool:
	return _trail > _shown + 0.001 or _shown > value_share() + 0.001


## @expression Показанная доля, от 0 до 1
## @expression.en Shown share, from 0 to 1
func shown_share() -> float:
	return maxf(0.0, _shown)


## @expression Доля следа, от 0 до 1
## @expression.en Trail share, from 0 to 1
func trail_share() -> float:
	return maxf(0.0, _trail)
