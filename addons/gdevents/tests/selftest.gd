# =============================================================
#  СГЕНЕРИРОВАНО GDevents. Правки здесь будут перезаписаны —
#  меняйте лист событий, а не этот файл.
#  Источник: res://addons/gdevents/tests/selftest.gdes.json
# =============================================================
extends Node2D

var _delta: float = 0.0


func _ready() -> void:
	Gde.register_objects([
		{"name": "Enemy", "scene": "res://addons/gdevents/tests/enemy.tscn"},
		{"name": "Bullet", "scene": "res://addons/gdevents/tests/bullet.tscn"},
	])
	Gde.begin_scene({})


func _process(delta: float) -> void:
	_delta = delta
	Gde.frame_begin(self)
	Gde.timer_advance(self, delta)
	_events()

func _events() -> void:

	# Выборка GDevelop: условие сужает список экземпляров, а не отвечает да/нет.

	# ── Событие 1 ─
	# ЕСЛИ:  В начале сцены
	# ТО:    Создать объект Enemy в позиции 100 ; 0
	#        Создать объект Enemy в позиции 300 ; 0
	#        Создать объект Bullet в позиции 0 ; 0
	#        Записать в консоль "расставлено"
	var _c1: GdePickContext = Gde.new_context()
	if Gde.at_start(self):
		Gde.create_object(_c1, "Enemy", 100.0, 0.0, self)
		Gde.create_object(_c1, "Enemy", 300.0, 0.0, self)
		Gde.create_object(_c1, "Bullet", 0.0, 0.0, self)
		print("расставлено")

	# Уехать должен ТОЛЬКО ближайший враг. Сломается выборка — уедут оба.

	# ── Событие 2 ─
	# ЕСЛИ:  В начале сцены
	#   И:   Взять ближайший Enemy к точке 90 ; 0
	# ТО:    Изменить X у Enemy: = 999
	var _c2: GdePickContext = Gde.new_context()
	if Gde.at_start(self) \
			and Gde.pick_nearest(_c2, "Enemy", 90.0, 0.0):
		for _o1 in _c2.pick("Enemy"):
			if not is_instance_valid(_o1): continue
			Gde.main(_o1).global_position.x = 999.0

	# ── Событие 3 ─
	# ЕСЛИ:  Каждые 0.1 секунд
	# ТО:    Изменить переменную сцены ticks: + 1
	var _c3: GdePickContext = Gde.new_context()
	if Gde.every(self, 0, 0.1):
		Gde.var_set("ticks", Gde.var_get("ticks") + 1.0)

	# Через полсекунды считаем, кого куда занесло.

	# ── Событие 4 ─
	# ЕСЛИ:  Таймер итог > 0.5 сек
	#   И:   Триггер один раз, пока истинно
	var _c4: GdePickContext = Gde.new_context()
	if Gde.timer_value(self, "итог") > 0.5 \
			and Gde.once(self, 0):

		# ── Событие 5 ─
		# ЕСЛИ:  X у Enemy > 900
		# ТО:    Изменить переменную сцены уехал: + Enemy.Count()
		var _c5: GdePickContext = _c4.copy()
		if Gde.filter(_c5, "Enemy", func(_o2): return Gde.pos_of(_o2).x > 900.0):
			Gde.var_set("уехал", Gde.var_get("уехал") + Gde.count(_c5, "Enemy"))

		# ── Событие 6 ─
		# ЕСЛИ:  X у Enemy < 900
		# ТО:    Изменить переменную сцены остался: + Enemy.Count()
		var _c6: GdePickContext = _c4.copy()
		if Gde.filter(_c6, "Enemy", func(_o3): return Gde.pos_of(_o3).x < 900.0):
			Gde.var_set("остался", Gde.var_get("остался") + Gde.count(_c6, "Enemy"))

	# ── Событие 7 ─
	# ЕСЛИ:  Таймер итог > 0.6 сек
	#   И:   Триггер один раз, пока истинно
	#   И:   Взять все Enemy
	# ТО:    Записать в консоль "ИТОГ врагов=" + ToString(Enemy.Count()) + " уехал=" + ToString(Variable(уехал)) + " остался=" + ToString(Variable(остался)) + " пуля=" + ToString(Bullet.X()) + " скорость=" + ToString(Bullet.LinearMove::Speed()) + " тиков=" + ToString(Variable(ticks))
	var _c7: GdePickContext = Gde.new_context()
	if Gde.timer_value(self, "итог") > 0.6 \
			and Gde.once(self, 1) \
			and Gde.pick_all(_c7, "Enemy"):
		print(((((((((((("ИТОГ врагов=" + Gde.num_str(Gde.count(_c7, "Enemy"))) + " уехал=") + Gde.num_str(float(Gde.var_get("уехал")))) + " остался=") + Gde.num_str(float(Gde.var_get("остался")))) + " пуля=") + Gde.num_str(Gde.pos_of(_c7.first("Bullet")).x)) + " скорость=") + Gde.num_str(float(Gde.beh_get(_c7.first("Bullet"), "LinearMove", "speed")))) + " тиков=") + Gde.num_str(float(Gde.var_get("ticks")))))
