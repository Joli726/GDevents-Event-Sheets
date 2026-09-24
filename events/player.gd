# =============================================================
#  СГЕНЕРИРОВАНО GDevents. Правки здесь будут перезаписаны —
#  меняйте лист событий, а не этот файл.
#  Источник: res://events/player.gdes.json
# =============================================================
extends Node2D

var _delta: float = 0.0


func _ready() -> void:
	Gde.register_objects([
		{"name": "Player", "scene": "res://scenes/player.tscn"},
		{"name": "Box", "scene": "res://scenes/box.tscn"},
		{"name": "Bullet", "scene": "res://scenes/bullet.tscn"},
		{"name": "Platform", "scene": "res://scenes/platform.tscn"},
	])
	Gde.begin_scene({})


func _process(delta: float) -> void:
	_delta = delta
	Gde.frame_begin(self)
	Gde.timer_advance(self, delta)
	_events()

func _events() -> void:

	# ── Событие 1 ─
	# ЕСЛИ:  Клавиша z нажата
	#   И:   НЕ У Player кончились патроны
	#   И:   НЕ Player перезаряжается
	# ТО:    Трясти камеру: сила 10, 0.2 секунд
	var _c1 := Gde.new_context()
	if Gde.key_pressed("z") \
			and Gde.filter_not(_c1, "Player", func(_o1): return Gde.beh_bool(_o1, "Shoot", "is_empty", [])) \
			and Gde.filter_not(_c1, "Player", func(_o2): return Gde.beh_bool(_o2, "Shoot", "is_reloading", [])):
		Gde.shake_camera(10.0, 0.2)

		# ── Событие 2 ─
		# ЕСЛИ:  Player отражён по горизонтали (смотрит влево)
		# ТО:    Выстрелить из Player под углом 180 градусов
		var _c2 := _c1.copy()
		if Gde.filter(_c2, "Player", func(_o3): return Gde.is_flipped_h(_o3)):
			for _o4 in _c2.pick("Player"):
				if not is_instance_valid(_o4): continue
				Gde.beh_call(_o4, "Shoot", "fire_at_angle", [180.0])

		# ── Событие 3 ─
		# ЕСЛИ:  НЕ Player отражён по горизонтали (смотрит влево)
		# ТО:    Выстрелить из Player под углом 0 градусов
		var _c3 := _c1.copy()
		if Gde.filter_not(_c3, "Player", func(_o5): return Gde.is_flipped_h(_o5)):
			for _o6 in _c3.pick("Player"):
				if not is_instance_valid(_o6): continue
				Gde.beh_call(_o6, "Shoot", "fire_at_angle", [0.0])

	# ── Событие 4 ─
	# ЕСЛИ:  Box сталкивается с Bullet
	# ТО:    Удалить объект Box
	var _c4 := Gde.new_context()
	if Gde.filter_pair(_c4, "Box", "Bullet", func(_a7, _b8): return Gde.overlaps(_a7, _b8)):
		Gde.delete_picked(_c4, "Box")

	# ── Событие 5 ─
	# ЕСЛИ:  Bullet сталкивается с Platform
	# ТО:    Удалить объект Bullet
	var _c5 := Gde.new_context()
	if Gde.filter_pair(_c5, "Bullet", "Platform", func(_a9, _b10): return Gde.overlaps(_a9, _b10)):
		Gde.delete_picked(_c5, "Bullet")

	# ── Событие 6 ─
	# ЕСЛИ:  Player жив
	# ТО:    Нанести 1 урона объекту Player
	var _c6 := Gde.new_context()
	if Gde.filter(_c6, "Player", func(_o11): return Gde.beh_bool(_o11, "Health", "is_alive", [])):
		for _o12 in _c6.pick("Player"):
			if not is_instance_valid(_o12): continue
			Gde.beh_call(_o12, "Health", "damage", [1.0])

	# ── Событие 7 ─
	# ЕСЛИ:  В начале сцены
	# ТО:    Масштаб камеры: 1.5
	var _c7 := Gde.new_context()
	if Gde.at_start(self):
		Gde.camera_zoom(1.5)

	# ── Событие 8 ─
	# ТО:    Камера следует за Player с плавностью 1
	var _c8 := Gde.new_context()
	for _o13 in _c8.pick("Player"):
		if not is_instance_valid(_o13): continue
		Gde.camera_follow(_o13, 1.0)

	# ── Событие 9 ─
	# ЕСЛИ:  Player только что прыгнул
	#   И:   НЕ Player стоит на земле
	# ТО:    Запустить анимацию Duble Jump у Player
	var _c9 := Gde.new_context()
	if Gde.filter(_c9, "Player", func(_o14): return Gde.beh_bool(_o14, "Platformer", "just_jumped", [])) \
			and Gde.filter_not(_c9, "Player", func(_o15): return Gde.beh_bool(_o15, "Platformer", "on_floor", [])):
		for _o16 in _c9.pick("Player"):
			if not is_instance_valid(_o16): continue
			Gde.play_animation(_o16, "Duble Jump")

	# ── Событие 10 ─
	# ЕСЛИ:  Player скользит по стене
	# ТО:    Запустить анимацию Wall Jump у Player
	var _c10 := Gde.new_context()
	if Gde.filter(_c10, "Player", func(_o17): return Gde.beh_bool(_o17, "Platformer", "is_wall_sliding", [])):
		for _o18 in _c10.pick("Player"):
			if not is_instance_valid(_o18): continue
			Gde.play_animation(_o18, "Wall Jump")

	# ── Событие 11 ─
	# ЕСЛИ:  Клавиша R нажата
	# ТО:    Перезарядить Player
	var _c11 := Gde.new_context()
	if Gde.key_pressed("R"):
		for _o19 in _c11.pick("Player"):
			if not is_instance_valid(_o19): continue
			Gde.beh_call(_o19, "Shoot", "start_reload", [])
