## Миниатюры объектов — первый кадр их собственного спрайта.
##
## Список из одинаковых кубиков заставляет читать каждое имя. Картинка
## узнаётся раньше слова: лягушку от ящика глаз отличает мгновенно.
@tool
class_name GdeThumbs
extends RefCounted

static var _cache: Dictionary = {}


## Миниатюра сцены или null, если в ней нет ни одной картинки.
static func for_scene(scene_path: String, px: int = 20) -> Texture2D:
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		return null
	var key := "%s@%d" % [scene_path, px]
	var stamp := GdeBehaviorInstaller._stamp(scene_path)
	var cached: Dictionary = _cache.get(key, {})
	if int(cached.get("stamp", -1)) == stamp:
		return cached.get("tex")
	var img: Variant = GdeBehaviorInstaller.read(scene_path, func(root: Node) -> Variant:
		return _first_image(root))
	var tex: Texture2D = null
	if img is Image:
		tex = _fit(img as Image, px)
	_cache[key] = {"stamp": stamp, "tex": tex}
	return tex


## Иконка объекта для списков: его миниатюра или общий значок.
static func icon_for(scene_path: String, px: int = 20) -> Texture2D:
	var t := for_scene(scene_path, px)
	return t if t != null else GdeIcons.get_icon("object")


static func _first_image(n: Node) -> Variant:
	if n is Sprite2D and (n as Sprite2D).texture != null:
		var sp := n as Sprite2D
		var img := _image_of(sp.texture)
		if img == null:
			return null
		var rect := Rect2i(Vector2i.ZERO, img.get_size())
		if sp.region_enabled:
			rect = Rect2i(sp.region_rect)
		# Лист кадров: берём первый кадр, а не всю полосу.
		var fw := rect.size.x / maxi(1, sp.hframes)
		var fh := rect.size.y / maxi(1, sp.vframes)
		return img.get_region(Rect2i(rect.position, Vector2i(fw, fh)))
	if n is AnimatedSprite2D and (n as AnimatedSprite2D).sprite_frames != null:
		var a := n as AnimatedSprite2D
		var fr := a.sprite_frames
		var names: Array = [a.animation]
		names.append_array(Array(fr.get_animation_names()))
		for anim: Variant in names:
			var an := StringName(str(anim))
			if fr.has_animation(an) and fr.get_frame_count(an) > 0:
				var tex := fr.get_frame_texture(an, 0)
				if tex != null:
					return _image_of(tex)
	for c: Node in n.get_children():
		var r: Variant = _first_image(c)
		if r != null:
			return r
	return null


static func _image_of(tex: Texture2D) -> Image:
	var img := tex.get_image()
	if img == null:
		return null
	if img.is_compressed():
		img.decompress()
	return img


## Вписать в квадрат px×px без размытия — пиксель-арт должен остаться чётким.
static func _fit(img: Image, px: int) -> Texture2D:
	var sz := img.get_size()
	if sz.x <= 0 or sz.y <= 0:
		return null
	var used := img.get_used_rect()
	if used.size.x > 0 and used.size.y > 0:
		img = img.get_region(used)
		sz = img.get_size()
	var k := float(px) / float(maxi(sz.x, sz.y))
	var w := maxi(1, int(round(sz.x * k)))
	var h := maxi(1, int(round(sz.y * k)))
	img.resize(w, h, Image.INTERPOLATE_NEAREST if k >= 1.0 else Image.INTERPOLATE_BILINEAR)
	var canvas := Image.create(px, px, false, Image.FORMAT_RGBA8)
	canvas.fill(Color(0, 0, 0, 0))
	img.convert(Image.FORMAT_RGBA8)
	canvas.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i((px - w) / 2, (px - h) / 2))
	return ImageTexture.create_from_image(canvas)


static func invalidate() -> void:
	_cache.clear()
