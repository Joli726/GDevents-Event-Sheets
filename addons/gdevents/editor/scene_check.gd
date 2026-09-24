## Проверка сцены объекта: всё, из-за чего объект молча ведёт себя не так.
##
## Каждая находка здесь — случай, на котором уже спотыкались: тело без формы
## столкновения падает сквозь пол, форма рядом с телом, а не внутри, ни на
## что не влияет, поведение не на том узле ничего не двигает, анимации с
## опечаткой в имени просто нет. Godot обо всём этом молчит — плагин не должен.
##
## Находка: {"level": "error"|"warn", "text", "node", "fixes": [{"id", "label", "arg"}]}.
## Исправлений может быть несколько: намерение по сцене не угадать, и честнее
## предложить варианты, чем молча выбрать один.
@tool
class_name GdeSceneCheck
extends RefCounted

static var _cache: Dictionary = {}


## Проверить сцену. object_names — объекты листа, чтобы ловить опечатки в целях.
static func check(scene_path: String, reg: GdeRegistry, object_names: Array = []) -> Array:
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		return []
	var live := GdeBehaviorInstaller._live_root(scene_path) != null
	var stamp := GdeBehaviorInstaller._stamp(scene_path)
	var key := "%s|%s" % [scene_path, ",".join(PackedStringArray(object_names))]
	var cached: Dictionary = _cache.get(key, {})
	if not live and int(cached.get("stamp", -1)) == stamp:
		return cached["list"]
	var found: Variant = GdeBehaviorInstaller.read(scene_path, func(root: Node) -> Array:
		return _check_root(root, reg, object_names))
	var list: Array = found if found is Array else []
	if not live:
		_cache[key] = {"stamp": stamp, "list": list}
	return list


static func invalidate() -> void:
	_cache.clear()


## Сколько ошибок и предупреждений — для значков в интерфейсе.
static func count(list: Array, level: String) -> int:
	var n := 0
	for it: Dictionary in list:
		if str(it["level"]) == level:
			n += 1
	return n


# ---------------------------------------------------------------- проверки ---

static func _check_root(root: Node, reg: GdeRegistry, object_names: Array) -> Array:
	var out: Array = []
	var nodes: Array[Node] = []
	_flatten(root, nodes)

	var orphans: Array[Node] = []
	for n: Node in nodes:
		if _is_shape(n) and not (n.get_parent() is CollisionObject2D):
			orphans.append(n)

	var adopted: Dictionary = {}
	for n: Node in nodes:
		if n is CollisionObject2D and not _has_shape(n):
			var what := _body_problem(n)
			var orphan: Node = null
			for o: Node in orphans:
				if not adopted.has(o) and not o.is_ancestor_of(n):
					orphan = o
					break
			var fixes: Array = []
			if orphan != null:
				adopted[orphan] = true
				what += " Рядом лежит форма «%s» — если тело нужно, ей место внутри него." % orphan.name
				fixes.append(_fx("move_shape", "Перенести форму внутрь", [_p(root, orphan), _p(root, n)]))
			else:
				fixes.append(_fx("add_shape", "Добавить форму", [_p(root, n)]))
			# Пустое тело, скорее всего, лишнее: его добавили «на всякий случай».
			if n.get_child_count() == 0 and n != root:
				fixes.append(_fx("delete_node", "Удалить пустое тело", [_p(root, n)]))
			out.append(_issue("error", what, root, n, fixes))

	for o: Node in orphans:
		if adopted.has(o):
			continue
		out.append(_issue("warn",
				"Форма «%s» лежит не внутри тела. События считают её прямоугольником, но физика её не видит — объект проходит сквозь стены."
				% o.name, root, o, [_fx("wrap_area", "Сделать областью (Area2D)", [_p(root, o)])]))

	for n: Node in nodes:
		if n is CollisionShape2D and (n as CollisionShape2D).shape == null:
			out.append(_issue("error", "У формы «%s» не задана фигура — она пустая." % n.name,
					root, n, [_fx("fill_shape", "Задать прямоугольник", [_p(root, n)])]))

	var frames := _sprite_frames(root)
	for n: Node in nodes:
		_check_sprite(n, root, out)
		var bname := GdeBehaviorInstaller.behavior_name_of(n)
		if not bname.is_empty():
			_check_behavior(n, bname, root, reg, frames, object_names, out)
	return out


static func _body_problem(n: Node) -> String:
	if n is RigidBody2D:
		return "«%s» (RigidBody2D) без формы столкновения: ни с чем не сталкивается и падает сквозь пол." % n.name
	if n is CharacterBody2D:
		return "«%s» (CharacterBody2D) без формы: персонаж проваливается сквозь землю." % n.name
	if n is StaticBody2D:
		return "«%s» (StaticBody2D) без формы: по нему нельзя ходить, об него нельзя удариться." % n.name
	if n is Area2D:
		return "«%s» (Area2D) без формы: касания с ней не срабатывают." % n.name
	return "«%s» без формы столкновения." % n.name


static func _check_sprite(n: Node, root: Node, out: Array) -> void:
	if n is Sprite2D and (n as Sprite2D).texture == null:
		out.append(_issue("warn", "Спрайт «%s» без картинки — объект невидим. Выберите Texture в инспекторе."
				% n.name, root, n))
	elif n is AnimatedSprite2D:
		var fr := (n as AnimatedSprite2D).sprite_frames
		var empty := fr == null
		if not empty:
			empty = true
			for a: StringName in fr.get_animation_names():
				if fr.get_frame_count(a) > 0:
					empty = false
					break
		if empty:
			out.append(_issue("warn", "В «%s» нет ни одного кадра — объект невидим. Добавьте кадры в SpriteFrames."
					% n.name, root, n))


static func _check_behavior(n: Node, bname: String, root: Node, reg: GdeRegistry,
		frames: Array, object_names: Array, out: Array) -> void:
	var b: Dictionary = reg.behaviors.get(bname, {}) if reg != null else {}
	var title := str(b.get("title", bname))
	var labels: Dictionary = b.get("labels", {})

	var target := str(b.get("target", ""))
	var host := n.get_parent()
	if not target.is_empty() and host != null and not host.is_class(target):
		var proper := _find_class(root, target)
		if proper != null:
			out.append(_issue("error", "«%s» висит на «%s», а работает только внутри %s — сейчас оно ничего не двигает."
					% [title, host.name, target], root, n,
					[_fx("move_behavior", "Перенести в «%s»" % proper.name, [_p(root, n), _p(root, proper)])]))
		else:
			out.append(_issue("error", "«%s» работает только внутри %s, а в сцене его нет." % [title, target],
					root, n))

	# Анимации по имени — самая частая тихая ошибка: опечатка в имени,
	# и поведение просто ничего не показывает.
	var gated := n.get("animate")
	if not frames.is_empty() and (gated == null or bool(gated)):
		for p: Dictionary in n.get_property_list():
			var pn := str(p["name"])
			if not pn.ends_with("_animation") or typeof(n.get(pn)) != TYPE_STRING:
				continue
			var want := str(n.get(pn))
			if want.is_empty() or frames.has(want):
				continue
			var same := _ci_match(want, frames)
			var nice := str(labels.get(pn, pn))
			var text := "Анимации «%s» нет в спрайте («%s», «%s»). Есть: %s." \
					% [want, title, nice, ", ".join(PackedStringArray(frames))]
			if not same.is_empty():
				out.append(_issue("warn", text, root, n,
						[_fx("set_prop", "Взять «%s»" % same, [_p(root, n), pn, same])]))
			else:
				# Выбор из того, что реально есть в спрайте, — опечатку так
				# исправить быстрее всего.
				out.append(_issue("warn", text, root, n, [
						_fx("pick_prop", "Выбрать из спрайта", [_p(root, n), pn, frames.duplicate()]),
						_fx("set_prop", "Не использовать", [_p(root, n), pn, ""])]))

	if "bullet_scene" in n and n.get("bullet_scene") == null:
		out.append(_issue("warn", "У «%s» не выбрана сцена снаряда — выстрел ничего не создаст. Выберите её в инспекторе." % title,
				root, n))

	if "target_object" in n:
		var t := str(n.get("target_object"))
		if t.is_empty():
			out.append(_issue("warn", "У «%s» не указана цель — пока её не задать (в инспекторе или действием), поведение ничего не делает." % title,
					root, n))
		elif not object_names.is_empty() and not object_names.has(t):
			out.append(_issue("warn", "Цель «%s» у «%s» не объявлена в листе — поведение её не найдёт." % [t, title],
					root, n))


# ------------------------------------------------------------- исправление ---

## Применить один из вариантов исправления. Пустая строка — успех.
static func fix(scene_path: String, one_fix: Dictionary) -> String:
	var err: String = await GdeBehaviorInstaller.modify(scene_path, func(root: Node) -> String:
		return _apply(root, one_fix))
	invalidate()
	return err


static func _apply(root: Node, one_fix: Dictionary) -> String:
	var arg: Variant = one_fix.get("arg")
	match str(one_fix.get("id", "")):
		"move_shape":
			var shape := _node(root, arg[0])
			var body := _node(root, arg[1])
			if shape == null or body == null:
				return "узлы не найдены — сцену успели поменять"
			_reparent_keep(shape, body, root)
		"add_shape":
			var body2 := _node(root, arg[0])
			if body2 == null:
				return "тело не найдено"
			var cs := CollisionShape2D.new()
			var rect := RectangleShape2D.new()
			rect.size = _sprite_size(root)
			cs.shape = rect
			cs.name = "CollisionShape2D"
			body2.add_child(cs)
			cs.owner = root
		"fill_shape":
			var s := _node(root, arg[0]) as CollisionShape2D
			if s == null:
				return "форма не найдена"
			var r := RectangleShape2D.new()
			r.size = _sprite_size(root)
			s.shape = r
		"wrap_area":
			var o := _node(root, arg[0])
			if o == null:
				return "форма не найдена"
			var area := Area2D.new()
			area.name = "Area2D"
			var parent := o.get_parent()
			parent.add_child(area)
			parent.move_child(area, o.get_index())
			area.owner = root
			_reparent_keep(o, area, root)
		"move_behavior":
			var beh := _node(root, arg[0])
			var host := _node(root, arg[1])
			if beh == null or host == null:
				return "узлы не найдены"
			beh.get_parent().remove_child(beh)
			host.add_child(beh)
			_own(beh, root)
		"set_prop":
			var nb := _node(root, arg[0])
			if nb == null:
				return "узел не найден"
			nb.set(str(arg[1]), arg[2])
		"delete_node":
			var dn := _node(root, arg[0])
			if dn == null or dn == root:
				return "узел не найден"
			dn.get_parent().remove_child(dn)
			dn.queue_free()
		_:
			return "для этой находки автоматического исправления нет"
	return ""


## Перенести узел к новому родителю, не сдвинув его на экране. Считаем
## через трансформации относительно корня: у копии с диска узлы не в дереве,
## и global_transform им недоступен.
static func _reparent_keep(n: Node, to: Node, root: Node) -> void:
	var was := _to_root(n, root)
	n.get_parent().remove_child(n)
	to.add_child(n)
	if n is Node2D:
		(n as Node2D).transform = _to_root(to, root).affine_inverse() * was
	_own(n, root)


static func _to_root(n: Node, root: Node) -> Transform2D:
	var t := Transform2D.IDENTITY
	var cur := n
	while cur != null and cur != root:
		if cur is Node2D:
			t = (cur as Node2D).transform * t
		cur = cur.get_parent()
	return t


static func _own(n: Node, root: Node) -> void:
	n.owner = root
	for c: Node in n.get_children():
		if c.owner == null or c.owner == root or not root.is_ancestor_of(c.owner):
			_own(c, root)


# ------------------------------------------------------------------ мелочи ---

static func _issue(level: String, text: String, root: Node, n: Node,
		fixes: Array = []) -> Dictionary:
	return {"level": level, "text": text, "node": _p(root, n), "fixes": fixes}


static func _fx(id: String, label: String, arg: Variant) -> Dictionary:
	return {"id": id, "label": label, "arg": arg}


static func _p(root: Node, n: Node) -> String:
	return "." if n == root else String(root.get_path_to(n))


static func _node(root: Node, path: Variant) -> Node:
	var s := str(path)
	return root if s == "." else root.get_node_or_null(NodePath(s))


static func _flatten(n: Node, out: Array[Node]) -> void:
	out.append(n)
	for c: Node in n.get_children():
		_flatten(c, out)


static func _is_shape(n: Node) -> bool:
	return n is CollisionShape2D or n is CollisionPolygon2D


static func _has_shape(n: Node) -> bool:
	for c: Node in n.get_children():
		if _is_shape(c):
			return true
	return false


static func _find_class(n: Node, cls: String) -> Node:
	if n.is_class(cls):
		return n
	for c: Node in n.get_children():
		var r := _find_class(c, cls)
		if r != null:
			return r
	return null


## Имена всех анимаций сцены: AnimatedSprite2D и AnimationPlayer.
static func _sprite_frames(root: Node) -> Array:
	var out: Array = []
	var list: Array[Node] = []
	_flatten(root, list)
	for n: Node in list:
		if n is AnimatedSprite2D and (n as AnimatedSprite2D).sprite_frames != null:
			for a: StringName in (n as AnimatedSprite2D).sprite_frames.get_animation_names():
				if not out.has(String(a)):
					out.append(String(a))
		elif n is AnimationPlayer:
			for a2: StringName in (n as AnimationPlayer).get_animation_list():
				if not out.has(String(a2)):
					out.append(String(a2))
	return out


static func _ci_match(want: String, names: Array) -> String:
	for n: Variant in names:
		if str(n).to_lower() == want.to_lower():
			return str(n)
	return ""


## Размер формы по спрайту объекта — чтобы новая форма сразу была впору,
## а не стандартным квадратиком 32×32 на персонаже 64×64.
static func _sprite_size(root: Node) -> Vector2:
	var list: Array[Node] = []
	_flatten(root, list)
	for n: Node in list:
		if n is Sprite2D and (n as Sprite2D).texture != null:
			var sp := n as Sprite2D
			var sz := sp.texture.get_size()
			if sp.region_enabled:
				sz = sp.region_rect.size
			sz /= Vector2(maxi(1, sp.hframes), maxi(1, sp.vframes))
			return (sz * sp.scale).abs().max(Vector2(4, 4))
		if n is AnimatedSprite2D:
			var a := n as AnimatedSprite2D
			if a.sprite_frames != null and a.sprite_frames.has_animation(a.animation) \
					and a.sprite_frames.get_frame_count(a.animation) > 0:
				var tex := a.sprite_frames.get_frame_texture(a.animation, 0)
				if tex != null:
					return (tex.get_size() * a.scale).abs().max(Vector2(4, 4))
	return Vector2(32, 32)
