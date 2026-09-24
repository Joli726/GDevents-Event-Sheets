## Базовый класс расширения GDevents — своих условий, действий и выражений,
## которые не привязаны к поведению. Как «расширения» в GDevelop.
##
## Расширение — один файл res://extensions/<имя>/<имя>.gd со статическими
## функциями. Разметка — та же, что у поведений:
##
##   ## @extension Clock
##   ## @title Часы
##   ## @title.en Clock
##   ## @icon timer
##   extends GdeExtension
##
##   ## @condition Сейчас от _PARAM0_ до _PARAM1_ часов
##   ## @condition.en It is between _PARAM0_ and _PARAM1_ o'clock
##   ## @param from С какого часа
##   ## @param.en from From hour
##   static func is_hour_between(from: float, to: float) -> bool:
##
##   ## @action Записать час в переменную _PARAM0_
##   static func store_hour(variable: String) -> void:
##
##   ## @expression Текущий час, 0…23
##   ## @expression.en Current hour, 0…23
##   static func hour() -> float:          # в листе: Clock::Hour()
##
## Правила:
##   — функции статические (static func); состояние между вызовами — в
##     static var;
##   — параметры: float, int, bool, String; _PARAM0_, _PARAM1_ во фразе —
##     параметры по порядку;
##   — первый параметр типа Node (Node2D, CharacterBody2D…) делает условие
##     или действие объектным: оно работает с отобранными экземплярами, как
##     «Изменить X у _PARAM0_», а в функцию приходит сам экземпляр;
##   — рантайм — через автозагрузку Gde: Gde.var_set(), Gde.main(o) и т. д.
@tool
class_name GdeExtension
extends RefCounted


## Текущая сцена игры.
static func scene() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	return tree.current_scene if tree != null else null
