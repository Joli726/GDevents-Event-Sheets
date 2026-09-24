## Поведение «Разрушаемое с добычей».
##
## @behavior Destructible
## @title Разрушаемое с добычей
## @title.en Destructible with loot
## @needs Sprite2D|AnimatedSprite2D Спрайт
## @needs.en Sprite2D|AnimatedSprite2D Sprite
## @description Ящик, бочка, ваза: при гибели разлетается осколками своей же картинки и выбрасывает предметы по таблице шансов. Ломается от «Здоровья», от касания или действием.
## @description.en A crate, a barrel, a vase: when destroyed it bursts into shards of its own picture and drops items by a chance table. Breaks from "Health", from a touch or by an action.
## @icon destructible
@tool
extends GdeBehavior

## Разрушено. Передаёт выпавшие предметы.
signal broken(loot: Array)

## @group.en Breaking
@export_group("Разрушение")
## Ломаться, когда «Здоровье» объекта кончилось.
## @en Break when the object's "Health" runs out.
@export var break_on_death: bool = true
## Ломаться от касания объекта — имя из листа, например Bullet. Пусто — не ломаться от касаний.
## @en Break on touching an object — a name from the sheet, e.g. Bullet. Empty — do not break on touch.
@export var break_on_touch: String = ""
## Удалить объект после разрушения.
## @en Delete the object after breaking.
@export var delete_after: bool = true
## Звук разрушения — путь к файлу. Пусто — тихо.
## @en Breaking sound — a file path. Empty — silent.
@export_file("*.wav", "*.ogg", "*.mp3") var break_sound: String = ""

## @group.en Shards
@export_group("Осколки")
## Осколков по ширине.
## @en Shards across.
@export_range(0, 12, 1) var shards_x: int = 3
## Осколков по высоте. 0 — без осколков.
## @en Shards down. 0 — no shards.
@export_range(0, 12, 1) var shards_y: int = 3
## Скорость разлёта, пикселей в секунду.
## @en Burst speed, pixels per second.
@export_range(0.0, 3000.0, 10.0) var shard_speed: float = 260.0
## Тяжесть осколков, пикселей в секунду за секунду. 0 — для вида сверху.
## @en Shard weight, pixels per second per second. 0 — for top-down games.
@export_range(0.0, 5000.0, 10.0) var shard_gravity: float = 900.0
## Сколько секунд осколки видны.
## @en How many seconds the shards are visible.
@export_range(0.1, 10.0, 0.1) var shard_lifetime: float = 0.8
## Вращение осколков, градусов в секунду.
## @en Shard spin, degrees per second.
@export_range(0.0, 3600.0, 10.0) var shard_spin: float = 540.0

## @group.en Loot
@export_group("Добыча")
## Первый предмет — сцена: монета, аптечка, что угодно.
## @en First item — a scene: a coin, a medkit, anything.
@export var loot_1: PackedScene
## Шанс первого предмета, процентов.
## @en Chance of the first item, percent.
@export_range(0.0, 100.0, 1.0) var chance_1: float = 100.0
## Сколько выпадает первого предмета.
## @en How many of the first item drop.
@export_range(1, 50, 1) var count_1: int = 1
## Второй предмет.
## @en Second item.
@export var loot_2: PackedScene
## Шанс второго предмета, процентов.
## @en Chance of the second item, percent.
@export_range(0.0, 100.0, 1.0) var chance_2: float = 30.0
## Сколько выпадает второго предмета.
## @en How many of the second item drop.
@export_range(1, 50, 1) var count_2: int = 1
## Третий предмет — редкий.
## @en Third item — a rare one.
@export var loot_3: PackedScene
## Шанс третьего предмета, процентов.
## @en Chance of the third item, percent.
@export_range(0.0, 100.0, 1.0) var chance_3: float = 5.0
## Сколько выпадает третьего предмета.
## @en How many of the third item drop.
@export_range(1, 50, 1) var count_3: int = 1
## Разброс добычи — с какой скоростью предметы выпрыгивают, пикселей в секунду.
## @en Loot scatter — how fast the items pop out, pixels per second.
@export_range(0.0, 2000.0, 10.0) var loot_pop: float = 200.0

var _broken: bool = false
var _break_frame: int = -100
var _watching: bool = false
var _last_loot: Array = []


func _physics_process(_delta: float) -> void:
	var o := object as Node2D
	if o == null or _broken:
		return
	if break_on_death and not _watching:
		var h := Gde.behavior(o, "Health", true)
		if h != null:
			_watching = true
			h.connect("died", break_now)
	if not break_on_touch.is_empty():
		for n: Node in Gde.all_instances(break_on_touch):
			if n != o and Gde.overlaps(n, o):
				break_now()
				return


## @action Разрушить _PARAM0_
## @action.en Destroy _PARAM0_
func break_now() -> void:
	var o := object as Node2D
	if o == null or _broken:
		return
	_broken = true
	_break_frame = Engine.get_physics_frames()
	var level := _level(o)
	if shards_x > 0 and shards_y > 0:
		GdeDebris.shatter(o, level, shards_x, shards_y, shard_speed, shard_gravity, shard_lifetime, shard_spin)
	_last_loot = drop_loot_list(o, level)
	if not break_sound.is_empty():
		Gde.play_sound(break_sound, 0.0, randf_range(0.92, 1.08))
	broken.emit(_last_loot)
	if delete_after:
		Gde.delete_object(o)


func _level(o: Node) -> Node:
	var scene := get_tree().current_scene
	if scene == null or scene == o or not scene.is_ancestor_of(o):
		return o.get_parent()
	return scene


## Бросить кубики по таблице и выбросить выпавшее.
func drop_loot_list(o: Node2D, level: Node) -> Array:
	var out: Array = []
	for slot: Array in [[loot_1, chance_1, count_1], [loot_2, chance_2, count_2], [loot_3, chance_3, count_3]]:
		var scene := slot[0] as PackedScene
		if scene == null or randf() * 100.0 >= float(slot[1]):
			continue
		for i in int(slot[2]):
			var item := scene.instantiate()
			level.add_child(item)
			_pop(item, o.global_position)
			out.append(item)
	return out


## Предмет выпрыгивает вверх и в сторону: телу — скорость, остальному — сдвиг.
func _pop(item: Node, at: Vector2) -> void:
	var dir := Vector2.UP.rotated(randf_range(-0.9, 0.9))
	var n2 := item as Node2D
	if n2 != null:
		n2.global_position = at
	var body := Gde.body_of(item)
	if body is RigidBody2D:
		(body as RigidBody2D).linear_velocity = dir * loot_pop
	elif body is CharacterBody2D:
		(body as CharacterBody2D).velocity = dir * loot_pop
	elif n2 != null:
		n2.global_position = at + Vector2(dir.x, dir.y * 0.3) * loot_pop * 0.1


## @condition _PARAM0_ разрушено
## @condition.en _PARAM0_ is destroyed
func is_broken() -> bool:
	return _broken


## @condition _PARAM0_ только что разрушено
## @condition.en _PARAM0_ has just been destroyed
func just_broken() -> bool:
	return Engine.get_physics_frames() - _break_frame <= RECENT_FRAMES


## @expression Сколько предметов выпало
## @expression.en How many items dropped
func loot_count() -> float:
	return float(_last_loot.size())
