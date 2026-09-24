# GDevents authoring guide

This is the reference for anyone — a person or an AI model — who writes
**behaviors**, **extensions** or **event sheets** for GDevents, the
GDevelop-style event sheets for Godot 4.7. Follow it literally: the plugin
reads these files by strict rules, and a file that breaks them either fails
to compile or silently loses its instructions.

The owner of a project may not be a programmer. Talk to them in their
language, explain what you did in plain words, and never finish without
running the check in [Verify your work](#verify-your-work).

Contents:

1. [What to write](#what-to-write)
2. [Where files go](#where-files-go)
3. [Behaviors](#behaviors)
4. [Extensions](#extensions)
5. [Two languages](#two-languages)
6. [Event sheets](#event-sheets)
7. [Expressions](#expressions)
8. [The Gde runtime](#the-gde-runtime)
9. [Common mistakes](#common-mistakes)
10. [Verify your work](#verify-your-work)
11. [Definition of done](#definition-of-done)
12. [Working on the plugin itself](#working-on-the-plugin-itself)

## What to write

| The user wants… | Write | Example in the plugin |
| --- | --- | --- |
| an ability of an object: move, shoot, take damage, collect | a **behavior** | `behaviors/rotate/rotate.gd` (simple), `behaviors/pickup/pickup.gd` (presets), `behaviors/shoot/shoot.gd` (large) |
| new conditions, actions or expressions not tied to one ability: time, math, saving, dialogs | an **extension** | `extensions/clock/clock.gd` |
| game logic: "when the key is pressed, move the player", "when a bullet hits an enemy, delete both" | an **event sheet** | `tests/selftest.gdes.json` |
| to change how a built-in behavior works | a **copy** of that behavior | see [Changing a built-in behavior](#changing-a-built-in-behavior) |

A behavior automatically gets conditions, actions and expressions in the
event sheet editor, plus a settings window. An extension adds instructions
to the "Common" section of the instruction picker. A sheet is compiled into
ordinary GDScript.

## Where files go

```
res://behaviors/<snake_name>/<snake_name>.gd      your behaviors
res://extensions/<snake_name>/<snake_name>.gd     your extensions
res://<anywhere>/<name>.gdes.json                 event sheets (not inside addons/)
```

- The folder and the file have the **same snake_case name**. The name used
  in sheets is the PascalCase form of the file name: `enemy_shoot.gd` →
  `EnemyShoot`. If you write `## @behavior Name` or `## @extension Name`, it
  must be exactly that PascalCase name.
- **Never edit `res://addons/gdevents/`** to add game content. That folder
  is the plugin; it gets replaced on update. Built-in behaviors there are the
  untouched "default" users can always return to.
- Other files the behavior needs (sounds, scenes) may sit next to it in the
  same folder.

## Behaviors

A behavior is a `Node` placed inside an object's scene. Its parent node is
the thing it controls. Its script is the single source of truth: settings
come from `@export` variables, instructions from `##` tags above functions.

### Complete template

This file passes the check with no errors and no warnings. Copy it, rename
it, and replace the logic.

```gdscript
## Behavior "Stamina": points that are spent on actions and come back over time.
##
## @behavior Stamina
## @title Stamina
## @title.ru Выносливость
## @description Points spent on running, jumping or attacks. They come back after a short pause.
## @description.ru Очки, которые тратятся на бег, прыжки или удары. Возвращаются после короткой паузы.
## @icon behavior
@tool
extends GdeBehavior

## Stamina ran out.
signal exhausted

## @group.ru Выносливость
@export_group("Stamina")
## Maximum stamina.
## @ru Максимум выносливости.
@export_range(1.0, 1000.0, 1.0) var max_stamina: float = 100.0
## Current stamina. Starts full.
## @ru Выносливость сейчас. В начале — полная.
@export_range(0.0, 1000.0, 1.0) var stamina: float = 100.0

## @group.ru Восстановление
@export_group("Recovery")
## Recovery speed, points per second.
## @ru Скорость восстановления, очков в секунду.
@export_range(0.0, 500.0, 1.0) var regen_per_second: float = 20.0
## Pause before recovery, in seconds after spending.
## @ru Пауза перед восстановлением, секунд после траты.
@export_range(0.0, 10.0, 0.1) var regen_delay: float = 1.0
## How it recovers: evenly, or faster when almost empty.
## @ru Как восстанавливается: ровно или быстрее, когда почти пусто.
## @options.ru Ровно, Быстрее на дне
@export_enum("Evenly", "Faster when low") var regen_mode: int = 0

var _since_spent: float = 0.0
var _exhausted_frame: int = -100


func _process(delta: float) -> void:
	_since_spent += delta
	if _since_spent < regen_delay or stamina >= max_stamina:
		return
	var speed := regen_per_second
	if regen_mode == 1:
		speed *= 2.0 - stamina / max_stamina
	stamina = minf(max_stamina, stamina + speed * delta)


## Takes stamina away. Nothing happens if there is not enough.
## @ru Отнимает выносливость. Если её не хватает — ничего не происходит.
## @action Spend _PARAM1_ stamina of _PARAM0_
## @action.ru Потратить _PARAM1_ выносливости у _PARAM0_
## @param amount Amount
## @param.ru amount Сколько
func spend(amount: float) -> void:
	if amount > stamina:
		return
	stamina -= amount
	_since_spent = 0.0
	if stamina <= 0.0:
		_exhausted_frame = Engine.get_process_frames()
		exhausted.emit()


## @action Fully restore the stamina of _PARAM0_
## @action.ru Полностью восстановить выносливость у _PARAM0_
func refill() -> void:
	stamina = max_stamina


## @condition _PARAM0_ has at least _PARAM1_ stamina
## @condition.ru У _PARAM0_ не меньше _PARAM1_ выносливости
## @param amount Amount
## @param.ru amount Сколько
func has_stamina(amount: float) -> bool:
	return stamina >= amount


## True for a few frames after stamina reached zero.
## @ru Истинно несколько кадров после того, как выносливость кончилась.
## @condition _PARAM0_ just got exhausted
## @condition.ru _PARAM0_ только что выдохся
func just_exhausted() -> bool:
	return Engine.get_process_frames() - _exhausted_frame <= RECENT_FRAMES


## @expression Stamina in percent, 0…100
## @expression.ru Выносливость в процентах, 0…100
func percent() -> float:
	return stamina / max_stamina * 100.0


## @expression State as text: fresh, tired or exhausted
## @expression.ru Состояние текстом: fresh, tired или exhausted
func state_text() -> String:
	if stamina <= 0.0:
		return "exhausted"
	return "tired" if stamina < max_stamina * 0.3 else "fresh"
```

In a sheet this gives `Stamina::spend`, `Stamina::refill`,
`Stamina::has_stamina`, `Stamina::just_exhausted`, the expressions
`Player.Stamina::Percent()` and `Player.Stamina::StateText()`, and for every
simple setting an action `Stamina::set_<name>`, a condition
`Stamina::is_<name>` and an expression `Player.Stamina::<PascalName>()`.

### File header tags

Write them in the first `##` comment block, before `@tool`.

| Tag | Meaning |
| --- | --- |
| `## @behavior Name` | PascalCase name used in sheets; must equal the file name in PascalCase |
| `## @title Text` | name shown in the interface |
| `## @description Text` | one or two sentences shown in the behavior list |
| `## @icon name` | icon from `addons/gdevents/icons/` (without `.svg`), e.g. `behavior`, `rotate`, `timer` |
| `## @target Class` | node class the behavior must sit on, e.g. `CharacterBody2D`; it is created if missing |
| `## @needs Class Label` | node the behavior needs next to it, e.g. `## @needs CollisionShape2D Shape`; created automatically. `Sprite2D\|AnimatedSprite2D Sprite` means "either; create the first" |

### Instructions

Put the tags in the `##` block directly above the function. Only `##`
lines and blank lines may stand between the tags and `func`.

| Tag | Function must return | Sheet id / call |
| --- | --- | --- |
| `## @action Sentence` | `void` | `Name::method` |
| `## @condition Sentence` | `bool` | `Name::method` |
| `## @expression Description` | `float`, `int`, `bool` (number) or `String` (text) | `Object.Name::PascalMethod()` |
| `## @param arg Label` | — | label for the argument `arg` in the editor |
| plain `## text` lines | — | description shown as a hint |

- `_PARAM0_` in an action or condition sentence is **always the object
  itself**; `_PARAM1_`, `_PARAM2_`… are the function's arguments in order.
  Every argument should appear in the sentence and have a `@param` label.
- Argument types: `float`, `int`, `bool`, `String`. Numbers come from the
  sheet as numbers (`bool` arguments receive 1 or 0); `String` arguments
  receive text.
- Expression names are the PascalCase form of the function name:
  `state_text()` → `StateText()`. Expression functions may take arguments
  too: `Player.Name::Method(1, "a")`.
- Functions without tags are not visible to sheets — use them as helpers.

### Settings

Every `@export` variable is a setting in the behavior window and in the
Godot inspector.

- **Always write a `##` comment above it.** Its first phrase — up to the
  first `.`, `,`, ` — `, `:` or ` (` — becomes the setting's short name;
  the whole text is the hint. Without it users see the bare variable name.
- Types `float`, `int`, `bool`, `String` also become sheet instructions
  (`set_<name>`, `is_<name>`, `<PascalName>()`). Other types
  (`PackedScene`, `Texture2D`, `AudioStream`…) are settings only.
- `@export_range(min, max, step)` gives a slider with limits.
- `@export_enum("A", "B")` gives a drop-down; the value is the index.
  Translate the items with `## @options.ru А, Б` (same count and order).
- `@export_group("Title")` starts a section; translate it with
  `## @group.ru Заголовок` on the line **above** `@export_group`.
- `## @internal` above a variable hides it from sheet instructions (it
  stays in the settings window) — use it for button-like or technical
  variables.
- A `String` setting named `target`, `target_object` or `*_object` gets a
  picker with the sheet's objects; one named `*_animation` gets a picker
  with the object's animations; a `PackedScene` gets a file button.
- Presets: a `preset` enum plus an `apply_preset` bool whose setter calls
  `apply_values(PRESETS[preset])` and resets itself. The window shows them
  as a drop-down with an "Apply" button. See `behaviors/pickup/pickup.gd`.

### Rules for behavior code

- The file starts with the header, then `@tool`, then `extends GdeBehavior`.
  **No `class_name`.**
- Put the logic in `_process` or `_physics_process`. The base class turns
  processing off inside the editor, so `@tool` does not make objects move
  in the scene editor. If you override `_ready()`, call `super()` first.
- `object` is the parent node — the node the behavior controls. Cast it:
  `var o := object as Node2D` and check for `null`. For position and
  movement of the whole object use `Gde.main(object)`.
- Other objects are found by their **sheet name**: `Gde.all_instances("Player")`.
  Store such names in a `String` setting (e.g. `target_object`).
- Delete objects with `Gde.delete_object(n)`, not `queue_free()`: it also
  removes them from the current event's picked instances.
- Call other behaviors through the runtime: `Gde.beh_call(node, "Health", "damage", [5.0])`,
  `Gde.behavior(node, "Health")`. Do not `preload` another behavior's
  script by path; if you need the script, use
  `GdeBehavior.resolve("res://addons/gdevents/behaviors/health/health.gd")` —
  it returns the user's copy when there is one.
- "Just happened" conditions (landed, got hit, fired): remember
  `Engine.get_process_frames()` (or `get_physics_frames()` in
  `_physics_process`) and compare with `RECENT_FRAMES`, as in the template.
  Events and physics do not run in a fixed order, so a one-frame flag would
  be missed.
- Declare signals with a `##` comment. They are for plain GDScript users;
  sheets use conditions.
- Use static typing. `:=` needs a typed value; `Gde.*` calls that return
  `Variant` need an explicit type: `var hp: float = Gde.var_get("hp")`.

### Changing a built-in behavior

Do not edit `addons/gdevents/behaviors/`. Instead:

- to change it for the whole project, make a **copy** with the same folder
  and file name: `res://behaviors/shoot/shoot.gd`. The copy replaces the
  built-in one everywhere, and its settings stay compatible. In the editor
  this is the "Edit behavior…" button on the Code tab, which also keeps
  version history; do it that way when the user can;
- to make a separate variant, create a new behavior with a new name
  (`res://behaviors/enemy_shoot/enemy_shoot.gd`, `## @behavior EnemyShoot`).
  The "New based on…" button does this.

Keep the public functions and `@export` names of a copy unchanged: sheets
and scenes refer to them by name. Renaming a method breaks sheets that use
it.

## Extensions

An extension is a file of **static functions** that become instructions in
the "Common" section. It has no node and no settings.

### Complete template

```gdscript
## Extension "Dice": random rolls for board-game style logic.
##
## @extension Dice
## @title Dice
## @title.ru Кубики
## @description Dice rolls and coin flips. The last roll is remembered.
## @description.ru Броски кубиков и монетки. Последний бросок запоминается.
## @icon behavior
@tool
extends GdeExtension

static var _last: float = 0.0


## @action Roll a _PARAM0_-sided die
## @action.ru Бросить кубик с _PARAM0_ гранями
## @param sides Sides
## @param.ru sides Граней
static func roll(sides: int) -> void:
	_last = float(randi_range(1, maxi(1, sides)))


## @condition The last roll is at least _PARAM0_
## @condition.ru Последний бросок не меньше _PARAM0_
## @param value Value
## @param.ru value Значение
static func last_at_least(value: float) -> bool:
	return _last >= value


## @condition The coin lands heads
## @condition.ru Монетка упала орлом
static func heads() -> bool:
	return randf() < 0.5


## Puts the object at a random point of a circle.
## @ru Ставит объект в случайную точку круга.
## @action Scatter _PARAM0_ within _PARAM1_ px of _PARAM2_ ; _PARAM3_
## @action.ru Разбросать _PARAM0_ в радиусе _PARAM1_ px от _PARAM2_ ; _PARAM3_
## @param o Object
## @param.ru o Объект
## @param radius Radius
## @param.ru radius Радиус
## @param x X
## @param y Y
static func scatter(o: Node, radius: float, x: float, y: float) -> void:
	var m := Gde.main(o)
	if m != null:
		m.global_position = Vector2(x, y) + Vector2.from_angle(randf() * TAU) * randf() * radius


## @expression The last roll
## @expression.ru Последний бросок
static func last_roll() -> float:
	return _last


## @expression The last roll as text, e.g. "Rolled 5"
## @expression.ru Последний бросок текстом, например «Rolled 5»
static func last_roll_text() -> String:
	return "Rolled %d" % int(_last)
```

In a sheet: actions `Dice::roll`, `Dice::scatter`; conditions
`Dice::last_at_least`, `Dice::heads`; expressions `Dice::LastRoll()` and
`Dice::LastRollText()`.

### Rules for extensions

- Header tags are the same as for behaviors, with `@extension` instead of
  `@behavior`; `@target` and `@needs` do not apply.
- Every instruction function is `static func`. Keep state in `static var`.
- Argument types: `float`, `int`, `bool`, `String`, or a node type as the
  **first** argument only.
- A first argument of type `Node` (or `Node2D`, `CharacterBody2D`…) makes
  the action or condition an **object instruction**: in the sheet its first
  parameter is an object, and the function is called once for each picked
  instance. For such a condition, instances where it returns `false` are
  dropped from the picked list, exactly like built-in object conditions.
  Here `_PARAM0_` is that object, and the other arguments are `_PARAM1_`….
- Without a node argument, `_PARAM0_` is the first argument.
- Expressions cannot take node arguments. Their return type decides the
  kind: `String` is text, anything else a number.
- Scene access: `GdeExtension.scene()` returns the running scene.
- An extension must not be named like a behavior.

## Two languages

The plugin interface is English and Russian, switchable at any time.
Everything a user reads in your file needs both languages.

- The main text can be in either language. Add the other one with a
  language suffix on the same tag: `@title` + `@title.ru`, `@action` +
  `@action.ru`, `@param arg Label` + `@param.ru arg Метка`,
  `@options.ru`, `@group.ru`. If the main text is Russian, add `.en`.
- Descriptions (plain `##` lines) get a translation line `## @ru …` or
  `## @en …` in the same block.
- Keep `_PARAM0_`… identical in both sentences; word order may change.
- Code identifiers (`@behavior Name`, function and variable names, sheet
  ids) are always Latin and are never translated.
- The check reports every missing translation as a warning.

## Event sheets

A sheet is a JSON file `*.gdes.json`. The plugin compiles it into a `.gd`
file with the same name next to it; the "Attach to scene…" button in the
Events tab adds that script to a scene. Never edit the generated `.gd` —
it is overwritten on every build.

### Format

```json
{
  "format": 1,
  "name": "level",
  "extends": "Node2D",
  "objects": [
    { "name": "Player", "scene": "res://scenes/player.tscn" },
    { "name": "Coin", "scene": "res://scenes/coin.tscn" },
    { "name": "Score", "scene": "res://scenes/score_label.tscn" }
  ],
  "groups": { "Pickups": ["Coin"] },
  "variables": { "score": 0, "title": "Level 1" },
  "events": [
    {
      "type": "comment",
      "text": "Movement"
    },
    {
      "type": "standard",
      "conditions": [
        { "id": "key.pressed", "params": ["Right"] }
      ],
      "actions": [
        { "id": "object.x", "params": ["Player", "+", "200 * TimeDelta()"] }
      ]
    },
    {
      "type": "standard",
      "conditions": [
        { "id": "object.collision", "params": ["Player", "Coin"] }
      ],
      "actions": [
        { "id": "object.delete", "params": ["Coin"] },
        { "id": "var.modify", "params": ["score", "+", "1"] }
      ],
      "children": [
        {
          "type": "standard",
          "conditions": [
            { "id": "var.compare", "params": ["score", "≥", "10"] }
          ],
          "actions": [
            { "id": "scene.change", "params": ["res://scenes/win.tscn"] }
          ]
        }
      ]
    },
    {
      "type": "standard",
      "conditions": [
        { "id": "system.every", "params": ["0.5"] }
      ],
      "actions": [
        { "id": "object.set_text", "params": ["Score", "\"Score: \" + ToString(Variable(score))"] }
      ]
    }
  ]
}
```

| Key | Meaning |
| --- | --- |
| `objects` | every object type the sheet uses: a name and its scene. Instances already in the scene are found automatically |
| `groups` | named sets of objects, usable wherever an object name is |
| `variables` | scene variables with their starting values (numbers or text) |
| `extends` | base class of the generated script, normally `Node2D` |
| `events` | the events, top to bottom |

Event types and their keys (any other key is an error):

| `type` | Keys |
| --- | --- |
| `standard` (default) | `conditions`, `actions`, `children` |
| `foreach` | `object`, `conditions`, `actions`, `children` — runs once per picked instance of `object` |
| `repeat` | `count` (expression), `actions`, `children` |
| `while` | `conditions`, `actions`, `children` — must have conditions |
| `group` | `name`, `children` — a folder of events |
| `comment` | `text` |

Every event may have `"disabled": true`. A condition is
`{"id", "params", "inverted"?, "disabled"?}`; an action is
`{"id", "params", "disabled"?}`. **Sub-events go in `children`**, negation
is `"inverted": true`, parameters are `params`.

### How events run

- Every frame, events run top to bottom. An event's conditions are checked
  in order; its actions run only if all are true; then its `children` run
  with the same picked instances.
- **Picking**: an object condition does not answer yes/no for the object
  type — it narrows the list of instances the following conditions and
  actions work with. "Bullet collides with Enemy → Delete Bullet" deletes
  only the bullets that collided. A created object is picked by the
  creating event. `inverted` on an object condition keeps the instances
  for which the condition is false.
- `Object.Count()` counts picked instances; add `pick.all` first to count all.
- `system.trigger_once` makes an event fire once while its other conditions
  stay true; `system.every` fires every N seconds; `system.at_start` once.

### Parameters

**Every parameter is a JSON string**, and its meaning depends on its kind:

| Kind | Write | Example |
| --- | --- | --- |
| `object` | an object name from `objects` or `groups` | `"Player"` |
| `objname` | an object name (for create, count, exists) | `"Bullet"` |
| `number` | a number [expression](#expressions) | `"10"`, `"Player.X() + 20"` |
| `string` | a text expression; literal text **in quotes** | `"\"Game over\""`, `"\"HP: \" + ToString(Player.Variable(hp))"` |
| `raw` | bare text without quotes: key, animation, timer name, file path | `"Space"`, `"Run"`, `"res://sfx/jump.wav"` |
| `varname` | a variable name or path, no quotes | `"score"`, `"player.hp"` |
| `cmpop` | `=`, `≠`, `<`, `>`, `≤`, `≥` (or `!=`, `<=`, `>=`) | `"≥"` |
| `modop` | `=`, `+`, `-`, `*`, `/` | `"+"` |

Key names are Godot key names: `Space`, `Left`, `Right`, `Up`, `Down`, `A`…`Z`,
`Enter`, `Escape`, `Shift`, `Ctrl`.

**Do not guess instruction ids.** Get the exact list with parameter kinds:

```bash
godot --headless --script res://addons/gdevents/tools/library_list.gd
godot --headless --script res://addons/gdevents/tools/library_list.gd -- Shoot   # only matching lines
```

Each line reads `id [kind] (param kinds and labels) — sentence`. The kind
`object` or `pair` means the instruction works on picked instances.

## Expressions

GDevelop syntax, compiled to GDScript:

```
200 * TimeDelta()
RandomInRange(40, 440)
"Score: " + ToString(Variable(score))
Player.X() + 50 * Player.Facing()
Enemy.Variable(hp) - 1
Player.Shoot::CooldownLeft()
Clock::Hour()
```

- Operators: `+ - * / %` and parentheses. There are no comparison or
  logic operators — comparisons are conditions.
- All numbers are floats: `3 / 2` is `1.5`.
- `+` joins text when either side is text; use `ToString(n)` and
  `ToNumber(s)` to convert.
- `Variable(name)`, `VariableString(name)` and `GlobalVariable(name)` take
  a bare variable name without quotes.
- `Object.Function()` reads the first picked instance; `Object.Behavior::Function()`
  calls a behavior expression; `Extension::Function()` an extension one.
- The full list is in the `Expressions` section of `library_list.gd`.

## The Gde runtime

`Gde` is an autoload available to behaviors, extensions and generated code.
The most useful calls:

| Call | Does |
| --- | --- |
| `Gde.all_instances(name) -> Array` | all live instances of a sheet object |
| `Gde.main(n) -> Node2D` | the node that carries an object's position (its body, if it has one) |
| `Gde.delete_object(n)` | delete an instance properly |
| `Gde.behavior(n, "Name") -> Node` / `Gde.has_behavior(n, "Name")` | find a behavior on an object |
| `Gde.beh_call(n, "Name", "method", [args])` | call a behavior function |
| `Gde.var_get(path, fallback)` / `Gde.var_set(path, v)` | scene variables |
| `Gde.gvar_get` / `Gde.gvar_set` | global variables (kept between scenes) |
| `Gde.ovar_get(n, path, fallback)` / `Gde.ovar_set(n, path, v)` | object instance variables |
| `Gde.overlaps(a, b) -> bool`, `Gde.distance(a, b)`, `Gde.aabb(n)` | collisions and geometry |
| `Gde.play_animation(n, "Run")`, `Gde.set_flip_h(n, true)` | visuals |
| `Gde.play_sound(path, db, pitch)`, `Gde.shake_camera(strength, seconds)` | effects |
| `Gde.key_pressed("Space")`, `Gde.key_held_time("Space")`, `Gde.mouse_world() -> Vector2` | input |
| `Gde.pad_pressed("A")`, `Gde.stick(JOY_AXIS_LEFT_X)`, `Gde.vibrate(weak, strong, s)` | gamepad |
| `Gde.otimer(n, "shot")` / `Gde.otimer_reset(n, "shot")` | a timer of one instance |
| `Gde.effect("explosion", x, y, size)`, `Gde.float_text(n, "-3", "red")`, `Gde.hitstop(0.08)`, `Gde.screen_flash("white", 0.2, 0.6)` | effects |
| `Gde.list_add(name, v)`, `Gde.list_contains(name, "key")`, `Gde.list_count(name)` | lists in scene variables |
| `Gde.show_value("hp", str(hp))`, `Gde.screen_log("text")` | debugging on screen |
| `GdeDebris.shatter(n, level, cols, rows, speed, gravity, life, spin)` | burst an object's picture into shards |

The full list is in `addons/gdevents/runtime/gde_runtime.gd`; functions not
starting with `_` are public.

## Common mistakes

| Mistake | Result | Do instead |
| --- | --- | --- |
| `class_name` in a behavior or extension | a copy or a second file with that class does not compile | never write `class_name` |
| file name and `@behavior` name differ | the behavior gets another name in the game; sheets break | `enemy_shoot.gd` ↔ `@behavior EnemyShoot` |
| code or an annotation between the tags and `func` | the instruction disappears | tags directly above `func` |
| overriding `_ready()` without `super()` | objects move inside the scene editor | call `super()` first |
| `queue_free()` on an object | picked lists keep a dead instance | `Gde.delete_object(n)` |
| `var x := Gde.var_get("hp")` | "Cannot infer the type" — the script does not compile | `var x: float = Gde.var_get("hp")` |
| comparing a bool setting with a number in GDScript | runtime error `true == 1.0` | read bools as bools; sheets see them as 1/0 automatically |
| text in a `string` parameter without quotes: `"Hello"` | build error: "Hello" is not an expression | `"\"Hello\""` |
| quotes in a `raw` parameter: `"\"Space\""` | the key is never found | `"Space"` |
| numbers instead of strings in `params`: `[1]` | works, but the check warns | `["1"]` |
| `"events"` inside an event, `"not"`, `"args"` | silently ignored by the compiler | `children`, `inverted`, `params` |
| guessing an id like `object.move` | "unknown action" | take it from `library_list.gd` |
| editing a generated `.gd` next to a sheet | overwritten on the next build | edit the `.gdes.json` |
| editing `addons/gdevents/behaviors/*` | lost on plugin update, no way back to default | a copy in `res://behaviors/` |
| a sentence without `_PARAM1_` for an argument | the user never sees that parameter in the sentence | mention every argument |
| a setting or an argument without a `##` comment or `@param` | bare code names in the window | always document |
| text in only one language | half of the users see untranslated text | add `.ru` / `.en` |

## Verify your work

Godot must be available as `godot` (Godot 4.7). Run from the project folder
(where `project.godot` is). If the project was never opened in the editor,
import it once first: `godot --headless --import`.

Check your files — behaviors, extensions and sheets:

```bash
godot --headless --quit-after 5000 res://addons/gdevents/tools/check.tscn -- res://behaviors/stamina/stamina.gd
godot --headless --quit-after 5000 res://addons/gdevents/tools/check.tscn -- res://levels/level.gdes.json
godot --headless --quit-after 5000 res://addons/gdevents/tools/check.tscn             # everything of yours
godot --headless --quit-after 5000 res://addons/gdevents/tools/check.tscn -- --lang=en   # report in English
```

It compiles the file (errors come with line numbers), makes sure the plugin
sees it under the right name, builds **every** condition, action and
expression of a behavior or extension into a real sheet and runs it on a
live object, and for sheets validates the structure, the object scenes and
every instruction and expression. `✗` is an error (exit code 1), `!` a
warning, `✓` fine. Ignore Godot's own `WARNING:` lines printed by built-in
behaviors on the test object.

After the check passes, build the sheets (the editor does it automatically
before running the game):

```bash
godot --headless --script res://addons/gdevents/tools/build_cli.gd
```

If Godot is not available, say so plainly to the user and ask them to press
"Build" in the Events tab and look at the error marks — never claim the
work is verified.

## Definition of done

- [ ] The file is in the right place with matching folder, file and tag names.
- [ ] `check.tscn` on it reports no `✗`.
- [ ] No `!` warnings about missing translations, `@param` labels or setting
      descriptions — or you told the user why they remain.
- [ ] Nothing under `res://addons/gdevents/` was changed (unless you work on
      the plugin itself).
- [ ] You told the user, in their language, what was added, what it is called
      in the editor, and how to use it (which object to add the behavior to,
      which instructions appeared).

## Working on the plugin itself

This part is only for changes inside `addons/gdevents/`.

- Plugin interface strings are written in Russian and wrapped:
  `GdeI18n.t("Собрать")`; the English text goes into
  `addons/gdevents/i18n/en.json` under the same Russian key. Keep `%s`, `%d`
  and `_PARAM0_` identical. A string that must not be translated gets a
  `# i18n: …` comment on its line.
- Built-in instructions live in `registry/builtin.json` (Russian text,
  translated through `en.json`); built-in behaviors and extensions carry
  both languages in their files.
- Run the whole suite before committing; the list with explanations is in
  the "Tests" section of `addons/gdevents/README.md`. The most important:

```bash
godot --headless --script res://addons/gdevents/tools/i18n_test.gd
godot --headless --script res://addons/gdevents/tools/editor_test.gd
godot --headless --quit-after 5000 res://addons/gdevents/tools/library_test.tscn
godot --headless --quit-after 600 res://addons/gdevents/tools/runtime_test.tscn
godot --headless --quit-after 2500 res://addons/gdevents/tools/behavior_window_test.tscn
godot --headless --quit-after 60000 res://addons/gdevents/tools/behavior_scenarios_test.tscn
godot --headless --quit-after 20000 res://addons/gdevents/tools/events_test.tscn
```

A new built-in behavior gets a scenario in `behavior_scenarios_test.gd`
(its own small world: build, run physics, check, free); a new built-in
event gets a check in `events_test.gd` on a generated sheet. Timing that
depends on the draw frame or real seconds must wait real time
(`_wait_ms`), because frames run much faster than 60 per second without
a screen.
