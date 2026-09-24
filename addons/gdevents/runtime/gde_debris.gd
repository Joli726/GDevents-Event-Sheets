## Осколок, искра, клочок дыма — всё, что вылетает, падает, крутится и
## тает само, без хозяина. Живёт на уровне, а не в объекте, который его
## породил: тот обычно как раз исчезает.
##
##   var d := GdeDebris.new()
##   d.texture = tex
##   d.velocity = Vector2(120, -300)
##   level.add_child(d)
class_name GdeDebris
extends Sprite2D

var velocity: Vector2 = Vector2.ZERO
var gravity: float = 900.0
## Градусов в секунду.
var spin: float = 0.0
var lifetime: float = 0.8
## Во что превращается масштаб к концу жизни: 1 — не меняется, 0 — исчезает в точку.
var end_scale: float = 1.0
## Сопротивление воздуха: доля скорости, теряемая за секунду.
var drag: float = 0.0

var _age: float = 0.0
var _start_scale: Vector2 = Vector2.ONE
var _start_alpha: float = 1.0


func _ready() -> void:
	_start_scale = scale
	_start_alpha = modulate.a


func _process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		queue_free()
		return
	velocity.y += gravity * delta
	if drag > 0.0:
		velocity *= maxf(0.0, 1.0 - drag * delta)
	position += velocity * delta
	rotation_degrees += spin * delta
	var k := _age / lifetime
	# Тает во второй половине жизни — первую видно целиком.
	modulate.a = _start_alpha * clampf(2.0 - 2.0 * k, 0.0, 1.0)
	scale = _start_scale * lerpf(1.0, end_scale, k)


## Картинка объекта сейчас: Sprite2D или текущий кадр AnimatedSprite2D.
static func picture_of(n: Node) -> Dictionary:
	if n is Sprite2D:
		var s := n as Sprite2D
		if s.texture != null:
			var region := s.region_rect if s.region_enabled else Rect2(Vector2.ZERO, s.texture.get_size())
			if s.hframes > 1 or s.vframes > 1:
				var fs := s.texture.get_size() / Vector2(s.hframes, s.vframes)
				region = Rect2(Vector2(s.frame % s.hframes, floori(float(s.frame) / float(s.hframes))) * fs, fs)
			return {"texture": s.texture, "region": region, "node": s}
	if n is AnimatedSprite2D:
		var a := n as AnimatedSprite2D
		if a.sprite_frames != null and a.sprite_frames.has_animation(a.animation):
			var tex := a.sprite_frames.get_frame_texture(a.animation, a.frame)
			if tex != null:
				return {"texture": tex, "region": Rect2(Vector2.ZERO, tex.get_size()), "node": a}
	for c: Node in n.get_children():
		var r := picture_of(c)
		if not r.is_empty():
			return r
	return {}


## Разбить картинку объекта на cols × rows осколков, разлетающихся от центра.
static func shatter(n: Node, level: Node, cols: int, rows: int, speed: float,
		grav: float, life: float, spin_max: float) -> int:
	var pic := picture_of(n)
	if pic.is_empty() or level == null:
		return 0
	var src: CanvasItem = pic["node"]
	var tex: Texture2D = pic["texture"]
	var region: Rect2 = pic["region"]
	var node2d := src as Node2D
	var center := node2d.global_position
	var sc := node2d.global_scale
	var piece := region.size / Vector2(cols, rows)
	var made := 0
	for x in cols:
		for y in rows:
			var d := GdeDebris.new()
			d.texture = tex
			d.region_enabled = true
			d.region_rect = Rect2(region.position + piece * Vector2(x, y), piece)
			d.flip_h = bool(src.get("flip_h"))
			var local := (Vector2(x + 0.5, y + 0.5) * piece - region.size * 0.5) * sc
			if d.flip_h:
				local.x = -local.x
			d.scale = sc
			d.modulate = src.modulate
			d.texture_filter = src.texture_filter
			d.z_index = node2d.z_index + 1
			var out := local.normalized() if local.length() > 0.1 else Vector2.UP
			d.velocity = (out + Vector2(randf_range(-0.3, 0.3), -0.6)).normalized() * speed * randf_range(0.6, 1.2)
			d.gravity = grav
			d.lifetime = life * randf_range(0.8, 1.2)
			d.spin = randf_range(-spin_max, spin_max)
			level.add_child(d)
			d.global_position = center + local
			made += 1
	return made
