## Поведение «Сочность».
##
## @behavior Juice
## @title Сочность
## @title.en Juice
## @needs AnimatedSprite2D|Sprite2D Спрайт
## @needs.en AnimatedSprite2D|Sprite2D Sprite
## @description Игра становится живой без единого события: сплющивание при прыжке и приземлении, пыль под ногами, вспышка и дрожь при ударе, шлейф при рывке. Подхватывает сигналы «Персонажа платформера», «Здоровья», «Способности», «Вида сверху» и «Выстрела» сама.
## @description.en The game comes alive without a single event: squash and stretch on jumps and landings, dust underfoot, a flash and a shake on hits, a trail on dashes. It picks up the signals of "Platformer character", "Health", "Ability", "Top-down movement" and "Shoot" by itself.
## @icon juice
@tool
extends GdeBehavior

## @group.en Squash
@export_group("Сплющивание")
## Сплющивание в прыжке — вытягиваться при прыжке и сплющиваться при приземлении.
## @en Stretch on a jump and squash on landing.
@export var squash_on_jump: bool = true
## Сила сплющивания, доля: 0.25 — на четверть.
## @en Squash strength, share: 0.25 — by a quarter.
@export_range(0.0, 0.9, 0.01) var squash_amount: float = 0.25
## Время, за которое форма возвращается, секунд.
## @en Time for the shape to come back, seconds.
@export_range(0.02, 2.0, 0.01) var squash_time: float = 0.18
## Отдача при выстреле — лёгкое сплющивание.
## @en Kick on a shot — a light squash.
@export var kick_on_shot: bool = true

## @group.en Dust
@export_group("Пыль")
## Пыль при приземлении — из-под ног, и при прыжке от стены тоже.
## @en Dust on landing — from underfoot, and on wall jumps too.
@export var dust_on_land: bool = true
## Цвет пыли.
## @en Dust color.
@export var dust_color: Color = Color(0.85, 0.8, 0.7, 0.9)
## Сколько пылинок.
## @en How many dust specks.
@export_range(1, 40, 1) var dust_count: int = 8

## @group.en Hit
@export_group("Удар")
## Вспышка при получении урона.
## @en A flash when taking damage.
@export var flash_on_hit: bool = true
## Цвет вспышки.
## @en Flash color.
@export var flash_color: Color = Color(1.0, 1.0, 1.0)
## Длительность вспышки, секунд.
## @en Flash duration, seconds.
@export_range(0.01, 1.0, 0.01) var flash_time: float = 0.08
## Дрожь при ударе, пикселей. 0 — без дрожи.
## @en Shake on a hit, pixels. 0 — no shake.
@export_range(0.0, 50.0, 0.5) var hit_shake: float = 3.0

## @group.en Trail
@export_group("Шлейф")
## Шлейф из силуэтов во время рывка.
## @en A trail of silhouettes during a dash.
@export var trail_on_dash: bool = true
## Цвет шлейфа.
## @en Trail color.
@export var trail_color: Color = Color(0.6, 0.8, 1.0, 0.6)
## Как часто оставлять силуэт, секунд.
## @en How often to leave a silhouette, seconds.
@export_range(0.01, 0.5, 0.01) var trail_interval: float = 0.03
## Сколько секунд виден каждый силуэт.
## @en How many seconds each silhouette is visible.
@export_range(0.05, 3.0, 0.05) var trail_life: float = 0.25

var _sprite: Node2D = null
var _base_scale: Vector2 = Vector2.ONE
var _base_pos: Vector2 = Vector2.ZERO
var _base_mod: Color = Color.WHITE
var _sq: Vector2 = Vector2.ZERO
var _flash_left: float = 0.0
var _shake_left: float = 0.0
var _trail_left: float = 0.0
var _trail_endless: bool = false
var _trail_tick: float = 0.0
var _hooked: bool = false
var _speck: ImageTexture = null


func _process(delta: float) -> void:
	var o := object as Node2D
	if o == null:
		return
	if not _hooked:
		_hook(o)
	if _sprite == null or not is_instance_valid(_sprite):
		return
	# Форма возвращается к исходной с затуханием.
	_sq = _sq.lerp(Vector2.ZERO, clampf(delta / squash_time * 3.0, 0.0, 1.0))
	if _sq.length() < 0.002:
		_sq = Vector2.ZERO
	_sprite.scale = _base_scale * (Vector2.ONE + _sq)
	# Ноги на месте: сплющенный спрайт опускается, вытянутый — поднимается.
	var h := _height()
	var pos := _base_pos + Vector2(0.0, -h * 0.5 * _sq.y)
	if _shake_left > 0.0:
		_shake_left -= delta
		var k := hit_shake * clampf(_shake_left / 0.15, 0.0, 1.0)
		pos += Vector2(randf_range(-k, k), randf_range(-k, k))
	_sprite.position = pos
	if _flash_left > 0.0:
		_flash_left -= delta
		if _flash_left <= 0.0:
			_sprite.self_modulate = _base_mod
	if _trail_left > 0.0 or _trail_endless:
		_trail_left -= delta
		_trail_tick -= delta
		if _trail_tick <= 0.0:
			_trail_tick = trail_interval
			_afterimage()


## Подписаться на сигналы соседних поведений.
func _hook(o: Node2D) -> void:
	_hooked = true
	_sprite = _find_sprite(o)
	if _sprite != null:
		_base_scale = _sprite.scale
		_base_pos = _sprite.position
		_base_mod = _sprite.self_modulate
	var p := Gde.behavior(o, "Platformer", true)
	if p != null:
		p.connect("jumped", func(_i: int) -> void:
			if squash_on_jump:
				squash(-squash_amount))
		p.connect("landed", func() -> void:
			if squash_on_jump:
				squash(squash_amount)
			if dust_on_land:
				dust())
		p.connect("wall_jumped", func() -> void:
			if squash_on_jump:
				squash(-squash_amount)
			if dust_on_land:
				dust())
	var hl := Gde.behavior(o, "Health", true)
	if hl != null:
		hl.connect("damaged", func(_a: float) -> void:
			if flash_on_hit:
				flash()
			if hit_shake > 0.0:
				_shake_left = 0.15)
	var ab := Gde.behavior(o, "Ability", true)
	if ab != null:
		ab.connect("used", func() -> void:
			if trail_on_dash and int(ab.get("kind")) == 0:
				_trail_endless = true)
		ab.connect("ended", func() -> void:
			_trail_endless = false)
	var td := Gde.behavior(o, "TopDown", true)
	if td != null:
		td.connect("dashed", func() -> void:
			if trail_on_dash:
				_trail_endless = true)
		td.connect("dash_ended", func() -> void:
			_trail_endless = false)
	var sh := Gde.behavior(o, "Shoot", true)
	if sh != null:
		sh.connect("fired", func(_b: Node) -> void:
			if kick_on_shot:
				squash(squash_amount * 0.4))


func _find_sprite(n: Node) -> Node2D:
	if n is Sprite2D or n is AnimatedSprite2D:
		return n as Node2D
	for c: Node in n.get_children():
		var r := _find_sprite(c)
		if r != null:
			return r
	return null


func _height() -> float:
	var pic := GdeDebris.picture_of(_sprite)
	if pic.is_empty():
		return 0.0
	return (pic["region"] as Rect2).size.y * _base_scale.y


func _afterimage() -> void:
	var pic := GdeDebris.picture_of(_sprite)
	if pic.is_empty():
		return
	var d := GdeDebris.new()
	d.texture = pic["texture"]
	d.region_enabled = true
	d.region_rect = pic["region"]
	d.flip_h = bool(_sprite.get("flip_h"))
	d.scale = _sprite.global_scale
	d.rotation = _sprite.global_rotation
	d.modulate = trail_color
	d.texture_filter = _sprite.texture_filter
	d.z_index = _sprite.z_index - 1
	d.gravity = 0.0
	d.lifetime = trail_life
	_level().add_child(d)
	d.global_position = _sprite.global_position


func _level() -> Node:
	var scene := get_tree().current_scene
	var o := object as Node
	if scene == null or scene == o or not scene.is_ancestor_of(o):
		return o.get_parent()
	return scene


## Плюс — сплющить (шире и ниже), минус — вытянуть (уже и выше).
## @en Plus — squash (wider and lower), minus — stretch (narrower and taller).
## @action Сплющить _PARAM0_ на _PARAM1_
## @action.en Squash _PARAM0_ by _PARAM1_
## @param amount Сила
## @param.en amount Strength
func squash(amount: float) -> void:
	_sq = Vector2(amount, -amount)


## @action Вспышка на _PARAM0_
## @action.en Flash on _PARAM0_
func flash() -> void:
	if _sprite == null:
		return
	# Ярче белого: цвет больше единицы высветляет спрайт, а не только красит.
	_sprite.self_modulate = Color(flash_color.r * 3.0, flash_color.g * 3.0, flash_color.b * 3.0, _base_mod.a)
	_flash_left = flash_time


## @action Пыль из-под ног _PARAM0_
## @action.en Dust from under the feet of _PARAM0_
func dust() -> void:
	var o := object as Node2D
	if o == null:
		return
	if _speck == null:
		var img := Image.create(3, 3, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		_speck = ImageTexture.create_from_image(img)
	var r := Gde.aabb(o)
	var feet := Vector2(r.get_center().x, r.end.y) if r.size != Vector2.ZERO else o.global_position
	var level := _level()
	for i in dust_count:
		var d := GdeDebris.new()
		d.texture = _speck
		d.modulate = dust_color
		var side := -1.0 if i % 2 == 0 else 1.0
		d.velocity = Vector2(side * randf_range(40.0, 120.0), randf_range(-60.0, -15.0))
		d.gravity = 150.0
		d.drag = 3.0
		d.lifetime = randf_range(0.25, 0.45)
		d.end_scale = 0.3
		d.scale = Vector2.ONE * randf_range(0.8, 1.6)
		level.add_child(d)
		d.global_position = feet + Vector2(randf_range(-4.0, 4.0), -1.0)


## @action Шлейф за _PARAM0_ на _PARAM1_ секунд
## @action.en A trail behind _PARAM0_ for _PARAM1_ seconds
## @param seconds Секунд
## @param.en seconds Seconds
func trail(seconds: float) -> void:
	_trail_left = maxf(_trail_left, seconds)
	_trail_tick = 0.0


## @condition За _PARAM0_ тянется шлейф
## @condition.en _PARAM0_ is leaving a trail
func has_trail() -> bool:
	return _trail_left > 0.0 or _trail_endless
