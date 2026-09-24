## Контекст выборки объектов — сердце семантики GDevelop.
##
## На каждое событие создаётся свой контекст. Он хранит, какие именно
## экземпляры каждого объекта «отобраны» на текущий момент. Условия сужают
## эти списки, действия работают по тому, что осталось, подсобытия получают
## копию контекста родителя.
class_name GdePickContext
extends RefCounted

var _rt: Node                  ## ссылка на GdeRuntime (автолоад)
var _picked: Dictionary = {}   ## имя объекта -> Array[Node]


func _init(runtime: Node) -> void:
	_rt = runtime


## Отобранные экземпляры объекта. При первом обращении инициализируется
## всеми живыми экземплярами — так же, как в GDevelop.
func pick(obj: String) -> Array:
	var cur: Variant = _picked.get(obj)
	if cur == null:
		cur = _rt.all_instances(obj)
		_picked[obj] = cur
	return cur


func set_pick(obj: String, list: Array) -> void:
	_picked[obj] = list


## Был ли объект уже упомянут в этом контексте.
func is_picked(obj: String) -> bool:
	return _picked.has(obj)


## Первый отобранный экземпляр или null. Используется в выражениях
## вида Player.X() — GDevelop берёт именно первый из отобранных.
func first(obj: String) -> Node:
	var list := pick(obj)
	for n: Node in list:
		if is_instance_valid(n):
			return n
	return null


## Копия для подсобытия: списки копируются поверхностно, чтобы фильтрация
## внутри подсобытия не протекала обратно в родителя.
func copy() -> GdePickContext:
	var c := GdePickContext.new(_rt)
	for k: String in _picked:
		c._picked[k] = (_picked[k] as Array).duplicate()
	return c


## Контекст, в котором объект принудительно сведён к одному экземпляру.
## Нужен для события «Для каждого объекта».
func with_single(obj: String, n: Node) -> GdePickContext:
	var c := copy()
	c._picked[obj] = [n]
	return c


## Имена объектов, уже упомянутых в контексте.
func names() -> Array:
	return _picked.keys()


## Выбросить из всех списков освобождённые ноды.
func compact() -> void:
	for k: String in _picked:
		var src: Array = _picked[k]
		var dst: Array = []
		for n: Node in src:
			if is_instance_valid(n):
				dst.append(n)
		_picked[k] = dst
