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
	#        Трясти камеру: сила 10, 0.2 секунд
	var _c1: GdePickContext = Gde.new_context()
	if Gde.key_pressed("z") \
			and Gde.filter_not(_c1, "Player", func(_o1): return Gde.beh_bool(_o1, "Shoot", "is_empty", [])) \
			and Gde.filter_not(_c1, "Player", func(_o2): return Gde.beh_bool(_o2, "Shoot", "is_reloading", [])):
		Gde.shake_camera(10.0, 0.2)
		Gde.shake_camera(10.0, 0.2)

		# ── Событие 2 ─
		# ЕСЛИ:  Player отражён по горизонтали (смотрит влево)
		# ТО:    Выстрелить из Player под углом 180 градусов
		var _c2: GdePickContext = _c1.copy()
		if Gde.filter(_c2, "Player", func(_o3): return Gde.is_flipped_h(_o3)):
			for _o4 in _c2.pick("Player"):
				if not is_instance_valid(_o4): continue
				Gde.beh_call(_o4, "Shoot", "fire_at_angle", [180.0])

		# ── Событие 3 ─
		# ЕСЛИ:  НЕ Player отражён по горизонтали (смотрит влево)
		# ТО:    Выстрелить из Player под углом 0 градусов
		var _c3: GdePickContext = _c1.copy()
		if Gde.filter_not(_c3, "Player", func(_o5): return Gde.is_flipped_h(_o5)):
			for _o6 in _c3.pick("Player"):
				if not is_instance_valid(_o6): continue
				Gde.beh_call(_o6, "Shoot", "fire_at_angle", [0.0])

	# ── Событие 4 ─
	# ЕСЛИ:  Box сталкивается с Bullet
	#   И:   Box виден на экране
	# ТО:    Удалить объект Box
	#        Выстрелить из Player под углом 0 градусов
	var _c4: GdePickContext = Gde.new_context()
	if Gde.filter_pair(_c4, "Box", "Bullet", func(_a7, _b8): return Gde.overlaps(_a7, _b8)) \
			and Gde.filter(_c4, "Box", func(_o9): return Gde.on_screen(_o9)):
		Gde.delete_picked(_c4, "Box")
		for _o10 in _c4.pick("Player"):
			if not is_instance_valid(_o10): continue
			Gde.beh_call(_o10, "Shoot", "fire_at_angle", [0.0])

	# ── Событие 5 ─
	# ЕСЛИ:  Bullet сталкивается с Platform
	# ТО:    Удалить объект Bullet
	var _c5: GdePickContext = Gde.new_context()
	if Gde.filter_pair(_c5, "Bullet", "Platform", func(_a11, _b12): return Gde.overlaps(_a11, _b12)):
		Gde.delete_picked(_c5, "Bullet")

	# ── Событие 6 ─
	# ЕСЛИ:  Player жив
	# ТО:    Нанести 1 урона объекту Player
	var _c6: GdePickContext = Gde.new_context()
	if Gde.filter(_c6, "Player", func(_o13): return Gde.beh_bool(_o13, "Health", "is_alive", [])):
		for _o14 in _c6.pick("Player"):
			if not is_instance_valid(_o14): continue
			Gde.beh_call(_o14, "Health", "damage", [1.0])

	# ── Событие 7 ─
	# ЕСЛИ:  В начале сцены
	# ТО:    Масштаб камеры: 1.5
	var _c7: GdePickContext = Gde.new_context()
	if Gde.at_start(self):
		Gde.camera_zoom(1.5)

	# ── Событие 8 ─
	# ТО:    Камера следует за Player с плавностью 1
	var _c8: GdePickContext = Gde.new_context()
	for _o15 in _c8.pick("Player"):
		if not is_instance_valid(_o15): continue
		Gde.camera_follow(_o15, 1.0)

	# ── Событие 9 ─
	# ЕСЛИ:  Player только что прыгнул
	#   И:   НЕ Player стоит на земле
	# ТО:    Запустить анимацию Duble Jump у Player
	var _c9: GdePickContext = Gde.new_context()
	if Gde.filter(_c9, "Player", func(_o16): return Gde.beh_bool(_o16, "Platformer", "just_jumped", [])) \
			and Gde.filter_not(_c9, "Player", func(_o17): return Gde.beh_bool(_o17, "Platformer", "on_floor", [])):
		for _o18 in _c9.pick("Player"):
			if not is_instance_valid(_o18): continue
			Gde.play_animation(_o18, "Duble Jump")

	# ── Событие 10 ─
	# ЕСЛИ:  Player скользит по стене
	# ТО:    Запустить анимацию Wall Jump у Player
	var _c10: GdePickContext = Gde.new_context()
	if Gde.filter(_c10, "Player", func(_o19): return Gde.beh_bool(_o19, "Platformer", "is_wall_sliding", [])):
		for _o20 in _c10.pick("Player"):
			if not is_instance_valid(_o20): continue
			Gde.play_animation(_o20, "Wall Jump")

	# ── Событие 11 ─
	# ЕСЛИ:  Клавиша R нажата
	# ТО:    Перезарядить Player
	var _c11: GdePickContext = Gde.new_context()
	if Gde.key_pressed("R"):
		for _o21 in _c11.pick("Player"):
			if not is_instance_valid(_o21): continue
			Gde.beh_call(_o21, "Shoot", "start_reload", [])
