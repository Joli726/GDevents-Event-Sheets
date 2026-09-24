## Пробное расширение для runtime_test: все виды параметров, объектные и
## общие инструкции, числовое и текстовое выражение.
##
## @extension Probe
## @title Проба
## @title.en Probe
@tool
extends GdeExtension

static var calls: int = 0


## @action Сбросить счётчик пробы
## @action.en Reset the probe counter
static func reset() -> void:
	calls = 0


## @action Отметить _PARAM0_: число _PARAM1_, флаг _PARAM2_, текст _PARAM3_
## @action.en Mark _PARAM0_: number _PARAM1_, flag _PARAM2_, text _PARAM3_
static func mark(o: Node, n: int, flag: bool, text: String) -> void:
	o.set_meta("probe", [n, flag, text])
	calls += 1


## @condition _PARAM0_ отмечен
## @condition.en _PARAM0_ is marked
static func is_marked(o: Node) -> bool:
	return o.has_meta("probe")


## @expression Сколько раз вызвали отметку
## @expression.en How many times marking was called
static func call_count() -> float:
	return float(calls)


## @expression Текст с приставкой
## @expression.en Text with a prefix
static func tagged(s: String) -> String:
	return "probe:" + s
