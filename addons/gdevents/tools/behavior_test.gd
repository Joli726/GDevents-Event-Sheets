## Безголовый тест поведений:
##   godot --headless --quit-after 400 res://addons/gdevents/tools/behavior_test.tscn
##
## Поведения — самая живая часть плагина, и проверять их глазами
## каждый раз — самый верный способ пропустить поломку.
extends Node2D

const PLATFORMER := preload("res://addons/gdevents/behaviors/platformer/platformer.gd")
const SHOOT := preload("res://addons/gdevents/behaviors/shoot/shoot.gd")
const HEALTH := preload("res://addons/gdevents/behaviors/health/health.gd")
const LINEAR := preload("res://addons/gdevents/behaviors/linear_move/linear_move.gd")
const OSCILLATE := preload("res://addons/gdevents/behaviors/oscillate/oscillate.gd")
const FOLLOW := preload("res://addons/gdevents/behaviors/follow/follow.gd")
const PATH := preload("res://addons/gdevents/behaviors/path/path.gd")
const DAMAGE := preload("res://addons/gdevents/behaviors/damage/damage.gd")
const PICKUP := preload("res://addons/gdevents/behaviors/pickup/pickup.gd")
const SPAWNER := preload("res://addons/gdevents/behaviors/spawner/spawner.gd")
const DUMMY_SCENE := "res://addons/gdevents/tests/enemy.tscn"

var _fails: int = 0
var _checks: int = 0
var _step: int = 0

var _hero: CharacterBody2D
var _plat: Node
var _landed: bool = false
var _fall_y: float = 0.0
var _jump_y: float = 0.0
var _osc: Node2D
var _osc_start: float = 0.0

var _path_hits: Array[int] = []
var _victim: Node2D
var _victim_x: float = 0.0
var _victim_hp: Node
var _one_shot: Node2D
var _spawner: Node
var _sprite: AnimatedSprite2D


func _ready() -> void:
	# Тест сверяет русские надписи — язык плагина здесь русский.
	GdeI18n.set_language("ru", false)
	# Объекты «как из листа»: поведениям урона, подбора и появления нужны имена.
	Gde.register_objects([
		{"name": "Victim", "scene": "res://addons/gdevents/tests/victim_virtual.tscn"},
		{"name": "Collector", "scene": "res://addons/gdevents/tests/collector_virtual.tscn"},
		{"name": "Spark", "scene": DUMMY_SCENE},
	])
	_test_all_compile()
	_build_floor()
	_build_hero()
	_test_shoot_presets()
	_test_health()
	_test_linear_gravity()
	_build_oscillator()
	_build_path()
	_build_damage()
	_build_pickup()
	_build_spawner()
	_test_impulse_on_character()
	_test_shoot_by_flip()
	_test_main_node()


func _physics_process(_d: float) -> void:
	_step += 1
	match _step:
		2:
			_fall_y = _hero.global_position.y
		20:
			_ok(_hero.global_position.y > _fall_y, "платформер: персонаж падает")
		46:
			# Событие заказало свою анимацию — платформер обязан уступить.
			Gde.play_animation(_hero, "Custom")
		45:
			_ok(_plat.call("on_floor"), "платформер: приземлился на пол")
			_ok(_landed, "платформер: сигнал landed пришёл")
			_jump_y = _hero.global_position.y
			_plat.call("simulate_jump")
		48:
			_ok(_plat.call("just_jumped"), "платформер: just_jumped сработал")
		55:
			_ok(_hero.global_position.y < _jump_y - 10.0, "платформер: прыжок поднял вверх")
			_ok(_hero.scale.x > 0.0, "платформер: объект цел")
		52:
			_eq(String(_sprite.animation), "Custom",
					"анимация из события не перебита платформером")
		70:
			_ok(absf(_osc.global_position.y - _osc_start) > 5.0, "колебание: объект сместился")
			_ok(String(_sprite.animation) != "Custom",
					"после одного прохода платформер снова ведёт анимации сам")
			_ok(_path_hits.has(1) and _path_hits.has(0), "путь: дошёл до конца и вернулся (туда-обратно)")
			_eq(_victim_hp.get("current"), 3.0, "урон при касании: ударил один раз, перезарядка не дала второй")
			_ok(absf(_victim.global_position.x - _victim_x) > 20.0, "урон при касании: жертву отбросило")
			_ok(not is_instance_valid(_one_shot), "урон при касании: снаряд исчез после удара")
			_eq(Gde.var_get("coins", 0.0), 1.0, "подбираемое: магнит притянул, монета засчитана")
			_eq(_spawner.call("spawned_total"), 5.0, "появление: выпущено ровно по пределу")
			_ok(bool(_spawner.call("is_finished")), "появление: сообщило, что всё выпущено")
			_report()


# ------------------------------------------------------------------ сцена ---

func _build_floor() -> void:
	var floor_body := StaticBody2D.new()
	floor_body.global_position = Vector2(0, 200)
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(2000, 40)
	cs.shape = rect
	floor_body.add_child(cs)
	add_child(floor_body)


func _build_hero() -> void:
	_hero = CharacterBody2D.new()
	_hero.global_position = Vector2(0, 0)
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(20, 40)
	cs.shape = rect
	_hero.add_child(cs)

	_sprite = AnimatedSprite2D.new()
	var frames := SpriteFrames.new()
	var img := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	var tex := ImageTexture.create_from_image(img)
	for anim: String in ["Idle", "Run", "Jump", "Fall", "Custom"]:
		if not frames.has_animation(anim):
			frames.add_animation(anim)
		frames.add_frame(anim, tex)
		frames.add_frame(anim, tex)
		frames.set_animation_speed(anim, 20.0)
	# Два кадра по 8 в секунду — проход 0.25 с: на 6-м кадре физики ещё
	# держится, к 24-му уже отпущен.
	frames.set_animation_speed("Custom", 8.0)
	_sprite.sprite_frames = frames
	_hero.add_child(_sprite)

	_plat = Node.new()
	_plat.set_script(PLATFORMER)
	_plat.set("default_controls", false)
	_plat.set("flip_sprite", false)
	_plat.set("animate", true)
	_hero.add_child(_plat)
	add_child(_hero)
	_plat.connect("landed", func(): _landed = true)


func _build_oscillator() -> void:
	_osc = Node2D.new()
	_osc.global_position = Vector2(400, 0)
	var b := Node.new()
	b.set_script(OSCILLATE)
	b.set("amplitude", 50.0)
	b.set("frequency", 2.0)
	_osc.add_child(b)
	add_child(_osc)
	_osc_start = _osc.global_position.y


# ---------------------------------------------------------------- проверки ---

func _test_shoot_presets() -> void:
	var sh := Node.new()
	sh.set_script(SHOOT)
	add_child(sh)

	sh.set("preset", 2)          # Дробовик
	sh.set("apply_preset", true)
	_eq(sh.get("pellets"), 7, "стрельба: пресет «Дробовик» поставил 7 дробин")
	_eq(sh.get("magazine"), 6, "стрельба: пресет поставил магазин на 6")
	_ok(not bool(sh.get("apply_preset")), "стрельба: галочка пресета сама снялась")

	sh.set("preset", 3)          # Пулемёт
	sh.set("apply_preset", true)
	_eq(sh.get("pellets"), 1, "стрельба: смена пресета перезаписала значения")
	sh.queue_free()


func _test_health() -> void:
	var holder := Node2D.new()
	add_child(holder)
	var h := Node.new()
	h.set_script(HEALTH)
	holder.add_child(h)
	h.set("max_health", 10.0)
	h.set("start_full", true)
	h.set("current", 10.0)
	h.set("armor_flat", 1.0)
	h.set("min_damage", 0.0)
	h.set("invulnerable_time", 0.0)

	h.call("damage", 3.0)
	_eq(h.get("current"), 8.0, "здоровье: броня 1 съела единицу урона")

	h.set("armor_percent", 0.5)
	h.call("damage", 4.0)
	_eq(h.get("current"), 6.5, "здоровье: процентная броня считается после плоской")

	h.set("invulnerable_time", 1.0)
	h.call("damage", 5.0)
	var after := float(h.get("current"))
	h.call("damage", 5.0)
	_eq(h.get("current"), after, "здоровье: неуязвимость блокирует второй удар")

	h.call("damage_pierce", 100.0)
	_ok(bool(h.call("is_dead")), "здоровье: урон сквозь неуязвимость добивает")
	holder.queue_free()


func _test_linear_gravity() -> void:
	var n := Node2D.new()
	n.global_position = Vector2(800, 0)
	var b := Node.new()
	b.set_script(LINEAR)
	b.set("angle", 0.0)
	b.set("speed", 100.0)
	b.set("gravity", 500.0)
	b.set("lifetime", 0.0)
	n.add_child(b)
	add_child(n)
	_ok(true, "прямолинейное движение с гравитацией создано")


## Каждое поведение обязано компилироваться. Проверка названий читает файл
## как текст и пропустила бы поведение, которое в игре даже не загрузится —
## так однажды и случилось с «Путём».
func _test_all_compile() -> void:
	var reg := GdeRegistry.load_default()
	var broken: Array[String] = []
	for bname: String in reg.behaviors:
		var path := str((reg.behaviors[bname] as Dictionary)["path"])
		var scr := load(path) as GDScript
		if scr == null or not scr.can_instantiate():
			broken.append(bname)
	_eq(broken.size(), 0, "все %d поведений компилируются%s" % [reg.behaviors.size(),
			"" if broken.is_empty() else " (сломаны: %s)" % ", ".join(broken)])


# ----------------------------------------------------- новые поведения ---

func _tagged(obj: String, at: Vector2, box: float) -> Node2D:
	var n := Node2D.new()
	n.global_position = at
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(box, box)
	cs.shape = r
	n.add_child(cs)
	add_child(n)
	n.add_to_group(Gde.GROUP_PREFIX + obj)
	return n


func _build_path() -> void:
	var n := Node2D.new()
	n.global_position = Vector2(600, -300)
	var b := Node.new()
	b.set_script(PATH)
	b.set("points", PackedVector2Array([Vector2(0, 0), Vector2(40, 0)]))
	b.set("mode", 1)
	b.set("speed", 400.0)
	b.set("wait_time", 0.0)
	n.add_child(b)
	add_child(n)
	b.connect("reached_point", func(i: int): _path_hits.append(i))


func _build_damage() -> void:
	_victim = _tagged("Victim", Vector2(1000, -500), 20.0)
	_victim_x = _victim.global_position.x
	_victim_hp = Node.new()
	_victim_hp.set_script(HEALTH)
	_victim.add_child(_victim_hp)
	_victim_hp.set("max_health", 5.0)
	_victim_hp.set("current", 5.0)
	_victim_hp.set("invulnerable_time", 0.0)
	_victim_hp.set("armor_flat", 0.0)
	_victim_hp.set("armor_percent", 0.0)
	_victim_hp.set("min_damage", 0.0)

	# Снаряд без пробития: ударить и исчезнуть. Урон 0 — счёт проверяем по шипам.
	# Создаётся раньше шипов, чтобы бить первым: шипы отбрасывают жертву.
	_one_shot = _tagged("Bolt", Vector2(1004, -500), 10.0)
	var d2 := Node.new()
	d2.set_script(DAMAGE)
	d2.set("target_object", "Victim")
	d2.set("amount", 0.0)
	d2.set("arm_time", 0.0)
	d2.set("destroy_on_hit", true)
	d2.set("pierce", 0)
	_one_shot.add_child(d2)

	# Шипы чуть левее: касаются жертвы и отбрасывают её вправо.
	var spikes := _tagged("Spikes", Vector2(992, -500), 20.0)
	var d := Node.new()
	d.set_script(DAMAGE)
	d.set("target_object", "Victim")
	d.set("amount", 2.0)
	d.set("repeat_delay", 10.0)
	d.set("pierce", 0)
	d.set("arm_time", 0.0)
	d.set("knockback", 30.0)
	spikes.add_child(d)


func _build_pickup() -> void:
	Gde.var_set("coins", 0.0)
	_tagged("Collector", Vector2(1400, -500), 16.0)
	var coin := _tagged("Coin", Vector2(1440, -500), 8.0)
	var p := Node.new()
	p.set_script(PICKUP)
	p.set("collector", "Collector")
	p.set("gives", 0)
	p.set("variable", "coins")
	p.set("amount", 1.0)
	p.set("magnet_radius", 100.0)
	p.set("magnet_speed", 600.0)
	p.set("collect_effect", false)
	coin.add_child(p)


func _build_spawner() -> void:
	var n := Node2D.new()
	n.global_position = Vector2(1800, -500)
	_spawner = Node.new()
	_spawner.set_script(SPAWNER)
	_spawner.set("target_object", "Spark")
	_spawner.set("interval", 0.05)
	_spawner.set("interval_jitter", 0.0)
	_spawner.set("first_delay", 0.0)
	_spawner.set("per_spawn", 2)
	_spawner.set("total_limit", 5)
	_spawner.set("alive_limit", 0)
	n.add_child(_spawner)
	add_child(n)


## Какой узел считается объектом — от этого зависят X(), Y() и все движения.
## Три раскладки, на которых выбор уже ошибался.
func _test_main_node() -> void:
	# Как пуля пользователя: пустое RigidBody2D без формы, двигают корень.
	var a := Node2D.new()
	var rb := RigidBody2D.new()
	a.add_child(rb)
	var beh_a := Node.new()
	beh_a.set_script(OSCILLATE)
	a.add_child(beh_a)
	add_child(a)
	_ok(Gde.main(a) == a, "главный узел: пустое тело без формы не перетягивает объект на себя")

	# Тело без формы, но поведение висит на нём — двигают именно его.
	var b := Node2D.new()
	var cb := CharacterBody2D.new()
	b.add_child(cb)
	var beh_b := Node.new()
	beh_b.set_script(OSCILLATE)
	cb.add_child(beh_b)
	add_child(b)
	_ok(Gde.main(b) == cb, "главный узел: тело с поведением — объект, даже без формы")

	# Как игрок пользователя: корень Node2D, внутри тело с формой.
	var c := Node2D.new()
	var cc := CharacterBody2D.new()
	var cs := CollisionShape2D.new()
	cs.shape = RectangleShape2D.new()
	cc.add_child(cs)
	c.add_child(cc)
	add_child(c)
	_ok(Gde.main(c) == cc, "главный узел: тело с формой внутри корня")
	for n: Node in [a, b, c]:
		n.queue_free()


## Толчок раньше работал только с RigidBody2D и молча не делал ничего
## с персонажем — а персонаж и есть то, что обычно толкают.
func _test_impulse_on_character() -> void:
	var body := CharacterBody2D.new()
	body.global_position = Vector2(-800, -800)
	add_child(body)
	Gde.apply_impulse(body, 0.0, 10.0)
	_ok(body.velocity.x > 1.0, "толчок: CharacterBody2D получил скорость")
	body.queue_free()


## В платформере персонаж не поворачивается, а отражается. «Выстрелить»
## обязано стрелять туда, куда он смотрит, — без двух веток в листе.
func _test_shoot_by_flip() -> void:
	var holder := Node2D.new()
	add_child(holder)
	var shooter := Node2D.new()
	holder.add_child(shooter)
	var spr := Sprite2D.new()
	spr.flip_h = true
	shooter.add_child(spr)
	var sh := Node.new()
	sh.set_script(SHOOT)
	sh.set("bullet_scene", load(DUMMY_SCENE))
	sh.set("magazine", 0)
	sh.set("fire_rate", 0.0)
	shooter.add_child(sh)
	_eq(sh.call("forward_angle"), 180.0, "стрельба: смотрит влево — стреляет влево")
	var got: Array = []
	sh.connect("fired", func(b: Node): got.append(b))
	sh.call("fire")
	_ok(not got.is_empty() and (got[0] as Node).get_parent() == self,
			"стрельба: снаряд живёт в уровне, а не внутри стрелка")
	spr.flip_h = false
	_eq(sh.call("forward_angle"), 0.0, "стрельба: смотрит вправо — стреляет вправо")


# ----------------------------------------------------------------- служебное ---

func _ok(cond: bool, what: String) -> void:
	_checks += 1
	if cond:
		print("  ✓ %s" % what)
	else:
		_fails += 1
		print("  ✗ %s" % what)


func _eq(got: Variant, want: Variant, what: String) -> void:
	_checks += 1
	var same := false
	if got is float or got is int:
		same = is_equal_approx(float(got), float(want))
	else:
		same = str(got) == str(want)
	if same:
		print("  ✓ %s" % what)
	else:
		_fails += 1
		print("  ✗ %s — ожидалось %s, получено %s" % [what, want, got])


func _report() -> void:
	print("—— проверок: %d, провалено: %d" % [_checks, _fails])
	get_tree().quit(1 if _fails > 0 else 0)
