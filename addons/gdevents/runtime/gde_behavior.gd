## Базовый класс поведения GDevents.
##
## Поведение — дочерняя нода объекта. Свойства объявляются через @export
## и автоматически становятся настраиваемыми свойствами поведения
## (как панель свойств поведения в GDevelop) плюс действиями/выражениями.
##
## Действия, условия и выражения помечаются в исходнике комментариями:
##
##   ## @action Выстрелить из _PARAM0_
##   func fire() -> void:
##
##   ## @condition _PARAM0_ может стрелять
##   func can_fire() -> bool:
##
##   ## @expression Время до перезарядки у _PARAM0_
##   func cooldown_left() -> float:
##
## _PARAM0_ — всегда сам объект; _PARAM1_ и далее — аргументы метода.
@tool
class_name GdeBehavior
extends Node

## Поведения крутятся до листа событий — как doStepPreEvents в GDevelop.
const PRIORITY := -50

## Окно для условий вида «только что прыгнул», в кадрах.
## Не один: события считаются в _process, а физика идёт в _physics_process,
## и порядок между ними не закреплён — событие может увидеть флаг на пару
## кадров позже. Три кадра — около 50 мс, человек этого не замечает.
const RECENT_FRAMES := 3


## Наследники помечены @tool, чтобы работали пресеты в инспекторе.
## Значит, в редакторе надо глушить их обработку, иначе они начнут
## двигать объекты прямо в сцене. Если поведение переопределяет _ready,
## оно обязано вызвать super().
func _ready() -> void:
	if Engine.is_editor_hint():
		set_process(false)
		set_physics_process(false)
		return
	process_priority = PRIORITY
	process_physics_priority = PRIORITY


## Применить набор значений сразу — основа пресетов.
func apply_values(values: Dictionary) -> void:
	for k: String in values:
		set(k, values[k])
	notify_property_list_changed()


## Объект, которому принадлежит поведение.
var object: Node:
	get:
		return get_parent()


## Встроенное поведение — или своя копия в res://behaviors, если её сделали.
## Копия лежит в папке и файле с теми же именами, что и встроенное.
static func resolve(builtin_path: String) -> Script:
	var copy := "res://behaviors".path_join(builtin_path.get_base_dir().get_file()) \
			.path_join(builtin_path.get_file())
	if ResourceLoader.exists(copy):
		var s := load(copy) as Script
		if s != null:
			return s
	return load(builtin_path) as Script


## Имя поведения в редакторе событий. По умолчанию — имя файла скрипта
## в PascalCase: shoot.gd -> Shoot, double_jump.gd -> DoubleJump.
func behavior_name() -> String:
	var s := get_script() as Script
	if s == null:
		return "Behavior"
	var base := s.resource_path.get_file().get_basename()
	var out := ""
	for part: String in base.split("_", false):
		if part.is_empty():
			continue
		out += part.substr(0, 1).to_upper() + part.substr(1)
	return out
