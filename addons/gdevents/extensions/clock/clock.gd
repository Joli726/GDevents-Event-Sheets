## Расширение «Часы»: системное время и дата.
##
## Заодно — пример расширения для тех, кто пишет свои: общие условия,
## действие, выражения и объектное действие (первый параметр — Node).
##
## @extension Clock
## @title Часы
## @title.en Clock
## @description Системное время и дата: час, минута, день недели. Для смены дня и ночи по настоящим часам, ежедневных наград и циферблатов.
## @description.en System time and date: hour, minute, day of the week. For day and night by the real clock, daily rewards and clock faces.
## @icon timer
@tool
extends GdeExtension


## Истинно, если текущий час в промежутке — и через полночь тоже: от 22 до 6 — ночь.
## @en True if the current hour is within the range — across midnight too: from 22 to 6 is night.
## @condition Сейчас от _PARAM0_ до _PARAM1_ часов
## @condition.en It is between _PARAM0_ and _PARAM1_ o'clock
## @param from С какого часа
## @param.en from From hour
## @param to До какого часа
## @param.en to To hour
static func is_hour_between(from: float, to: float) -> bool:
	var h := float(Time.get_datetime_dict_from_system()["hour"])
	if from <= to:
		return h >= from and h < to
	return h >= from or h < to


## Суббота или воскресенье.
## @en Saturday or Sunday.
## @condition Сегодня выходной
## @condition.en Today is a weekend
static func is_weekend() -> bool:
	return weekday() >= 6.0


## Кладёт время в виде «13:05» в текстовую переменную сцены.
## @en Puts the time as “13:05” into a text scene variable.
## @action Записать текущее время в переменную _PARAM0_
## @action.en Store the current time in variable _PARAM0_
## @param variable Переменная
## @param.en variable Variable
static func store_time(variable: String) -> void:
	Gde.var_set(variable, time_text())


## Поворачивает объект, как стрелку часов: 0 — часовая, 1 — минутная, 2 — секундная.
## @en Rotates the object like a clock hand: 0 — hour, 1 — minute, 2 — second.
## @action Повернуть _PARAM0_ как стрелку часов _PARAM1_ (0 часовая, 1 минутная, 2 секундная)
## @action.en Rotate _PARAM0_ like clock hand _PARAM1_ (0 hour, 1 minute, 2 second)
## @param hand Стрелка
## @param.en hand Hand
static func point_hand(o: Node, hand: int) -> void:
	var t := Time.get_datetime_dict_from_system()
	var turns := 0.0
	match hand:
		0:
			turns = (float(t["hour"] % 12) + float(t["minute"]) / 60.0) / 12.0
		1:
			turns = (float(t["minute"]) + float(t["second"]) / 60.0) / 60.0
		_:
			turns = float(t["second"]) / 60.0
	var m := Gde.main(o)
	if m != null:
		# 0 градусов у Godot — вправо, а стрелка на двенадцать смотрит вверх.
		m.rotation_degrees = turns * 360.0 - 90.0


## @expression Текущий час, 0…23
## @expression.en Current hour, 0…23
static func hour() -> float:
	return float(Time.get_datetime_dict_from_system()["hour"])


## @expression Текущая минута, 0…59
## @expression.en Current minute, 0…59
static func minute() -> float:
	return float(Time.get_datetime_dict_from_system()["minute"])


## @expression Текущая секунда, 0…59
## @expression.en Current second, 0…59
static func second() -> float:
	return float(Time.get_datetime_dict_from_system()["second"])


## @expression День недели: 1 — понедельник, 7 — воскресенье
## @expression.en Day of the week: 1 — Monday, 7 — Sunday
static func weekday() -> float:
	var w := int(Time.get_datetime_dict_from_system()["weekday"])
	return 7.0 if w == 0 else float(w)


## @expression Секунд с 1 января 1970 — для отсчёта ежедневных наград
## @expression.en Seconds since January 1, 1970 — for daily reward timers
static func unix_time() -> float:
	return Time.get_unix_time_from_system()


## @expression Время текстом, например 13:05
## @expression.en Time as text, e.g. 13:05
static func time_text() -> String:
	var t := Time.get_datetime_dict_from_system()
	return "%02d:%02d" % [t["hour"], t["minute"]]
