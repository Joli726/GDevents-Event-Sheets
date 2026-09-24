# GDevents

**English** · [Русский](README.ru.md)

GDevelop-style event sheets for Godot 4. Conditions and actions compile to
ordinary, readable GDScript — there is no interpreter at runtime.

**Version 0.9.2** ([changes](CHANGELOG.md), MIT license): the event sheet editor, 34 ready-made behaviors, 244
instructions, your own behaviors and extensions, scene and file checks, an
English and Russian interface.

## Editor

Enable the plugin and an **Events** tab appears in the top bar of Godot,
next to "2D / 3D / Script".

- Choose the sheet in the drop-down at the top left; every `*.gdes.json` is
  found.
- Click a row to select it, double-click to open its parameters, right-click
  for the menu. On hover, buttons appear on the right: invert, copy, delete.
- **"Add event" under the last event** — a new empty event at the end of
  the sheet, as in GDevelop (or Ctrl+N).
- The narrow strip on the left of an event card is both the event menu and a
  handle: **drag it to move the event**. Where it will land is shown in
  advance: a bar above — before, below — after, the whole card highlighted —
  inside, as a sub-event.
- **Conditions and actions can be dragged** within an event and between
  events. A line shows where the row will go. Hold Ctrl to copy instead of
  moving. Order matters: conditions are checked top to bottom and narrow the
  picked instances in turn, actions run top to bottom.
- Events can be dropped onto comments too — above or below them.
- **Row toggles** are in the settings window under the parameters, as in
  GDevelop. A condition has "Invert (NOT)": it fires when false, and the
  picking flips with it. Conditions and actions have "Disabled": the row stays
  in the sheet but is neither run nor checked. The window opens for
  conditions without parameters too — those are the ones inverted most often.
  "Disable" is also in the right-click menu; a disabled row is marked "OFF".
- A scene can be **dropped straight from the FileSystem dock** onto the panel
  or the object list — it is added to the sheet.
- **No need to save and build by hand.** The sheet saves itself a second after
  an edit and on Ctrl+S; before the game runs it is rebuilt automatically. The
  buttons remain for those who like to do it explicitly.
- **Errors show up immediately, right on the row.** The sheet is checked on
  every edit: a broken event gets a red outline, a broken row an "!" mark,
  and the details are in the tooltip. A typo in an object name suggests the
  right one: "there is no object “Plaer” in the sheet — did you mean
  “Player”?". Disabled events are not checked — people disable exactly what
  is broken for now.
- **Any of the conditions (OR).** Event menu → "Any of the conditions": the
  event runs when at least one condition is true. Instances picked by any
  true condition stay picked. For "A and (B or C)" put the OR event with B
  and C as a sub-event of the one with A.
- **Local variables.** Event menu → "Local variables…", one per line:
  `count = 0`, `name = "Bob"`. They live only in that event and its
  sub-events, reset every time the event runs, travel with "Wait", and are
  used with the same `Variable(count)` and "Change variable" as scene
  variables (a local one hides a scene variable of the same name).
- **Shared sheets.** "Add event → Include sheet" builds the events of another
  sheet in its place, as if they were copied there, and adds its objects and
  variables. Player controls, pause, score — written once, included in every
  level; a change reaches all of them on the next build. A loop of includes
  or a missing sheet is shown as an error on the include event.
- **Find and replace (Ctrl+F).** Matching events are highlighted, Enter / F3
  jump between them; "Replace all" changes parameter values, comments and
  group names in one undo step.
- **Collapsing.** The arrow in the header of an event or group with
  sub-events hides them.
- **Functions made of events.** "Add event → Function" makes your own
  action or condition: a name, a sentence such as `Hurt _PARAM0_ by _PARAM1_`
  and parameters (object, number, text); its sub-events are the body. It
  appears in the picker next to the built-in instructions, in its sheet and
  in every sheet that includes it. Inside, an object parameter is written by
  its name and means the instances picked at the call; numbers and texts are
  `Variable(amount)`. A condition function answers with "Return: the
  condition is true", and the instances picked at that moment go back to
  the calling event.
- **Debugger.** Run the game from the editor: events that fire light up
  green in the sheet, and the **GDevents** tab of Godot's debugger shows
  scene and global variables live and how many times each event fired.
- **Errors in the game name the event.** If a sheet's code fails while the
  game runs, a line under the Godot error says which event of which sheet
  it was: "the error above is in event 5 of sheet res://level.gdes.json:
  IF Left key is pressed".

### Object check

An **"Errors in objects: N"** button appears in the panel when object scenes
contain something that makes the game silently misbehave:

- a body without a collision shape — it collides with nothing and falls
  through the floor;
- a collision shape next to a body instead of inside it;
- a behavior on the wrong node (for example, the platformer not inside a
  `CharacterBody2D`);
- an animation that the sprite does not have (a typo like "Duble Jump");
- a sprite without a texture, "Shoot" without a projectile scene, "Follow"
  without a target.

Every finding comes with a plain-words explanation and fix buttons. Where the
intent cannot be guessed there are several options: for an empty body without
a shape, "Move the shape inside" and "Delete the empty body". For a missing
animation — a choice among those the sprite really has.

The same check from the command line:
`godot --headless res://addons/gdevents/tools/check_scenes.tscn`.

### Keyboard shortcuts

| Keys | What it does |
| --- | --- |
| `Ctrl+S` | save the sheet |
| `Ctrl+B` | build GDScript |
| `Ctrl+Z` / `Ctrl+Shift+Z`, `Ctrl+Y` | undo / redo |
| `Ctrl+C` / `Ctrl+X` / `Ctrl+V` | copy / cut / paste |
| `Ctrl+D` | duplicate the selected event |
| `Alt+↑` / `Alt+↓` | move the selected condition, action or event |
| `Ctrl+N` | new event at the end |
| `Delete` | delete the selection |
| `Enter` | open the parameters of the selected row |
| `Escape` | clear the selection |

The clipboard is shared by all sheets — an event can be moved from one to
another.

### Choosing and setting up a condition or action

One window with three columns, as in GDevelop: **objects on the left** (with
pictures from their sprites), **in the middle** — what can be done with the
selected object, **on the right** — the settings of the selected condition: a
live sentence, the description, parameter fields, suggestions and the
"Invert (NOT)" and "Disabled" toggles. One click on a condition and its
settings are already on the right.

A row appears in the sheet only on "Add": "Cancel" leaves no half-filled rows.
Double-clicking a condition in the list adds it at once, and so does Enter in
a parameter field.

With the keyboard: start typing in the search — the first match is selected by
itself, Enter moves to the first field (or adds right away if there are no
fields), Enter in a field adds.

Changing the object on the left does not reset the selected condition: it
stays, the object in its parameters changes, entered values are kept.

**Editing an existing row** (double-click in the sheet) opens the same window
with the condition selected and the fields filled in. It can be replaced by
another one right there.

**Common** holds what is not tied to objects: keyboard, variables, timers,
scene, sound, and the extensions. The search at the top looks through all
objects at once. An object shows only the behaviors it really has. At the top
of the list is **"Recent"**: the last chosen instructions.

### Parameter suggestions

Below the setting fields is a list of what can be typed into the field,
filtered by what is typed, with an explanation for each item. A click inserts
the value, the down arrow moves focus from the field into the list.

The list depends on the parameter:

- expressions — each sheet object's own and its behaviors', plus the common
  ones and the extensions';
- animation names — read from the object's own `AnimatedSprite2D`;
- keys and input actions — from the project settings;
- sound and scene files — from the project.

### Objects and behaviors

The **Objects** button: on the left a list with pictures of the objects (the
first frame of their own sprite), on the right the selected object — its scene
and two tabs: **"Behaviors"** and **"Scene check"** (the number of findings is
right on the tab).

**"Add behavior" puts the node into the object's scene and saves it** — no
need to dig through the scene tree by hand. The behavior's actions and
conditions then appear in the list for that object right away.

**Behavior settings are right there, as in GDevelop.** Clicking a behavior on
the left opens its description and settings on the right; a freshly added
behavior opens by itself. Names and hints come from the `##` comments above
each property, in the interface language, split into the same groups as in
the script (`@export_group`). Numbers have the limits from `@export_range`,
lists come from `@export_enum`, a target is chosen from the sheet's objects,
an animation from the object's own sprite, a projectile scene with a
"Choose…" button. A preset has an "Apply" button. A changed setting gets a ↺
arrow to reset it to the default; at the bottom is "Reset all settings to
defaults". Values are per object and are written into its scene a fraction
of a second after the edit; in an open tab the edit goes into the history,
and Ctrl+Z undoes it. Path points and other things easier to edit with the
mouse open in Godot's inspector.

**The "Code" tab** next to the settings shows how the behavior works inside:
the source with highlighting, read-only. "Go to…" lists the behavior's
actions, conditions and expressions with the same sentences as in the event
sheet and puts the cursor on their function. "Open in script editor" goes to
the same place, but with autocompletion, error highlighting and the debugger.

### Your own copy of a behavior and going back to the built-in one

Built-in behaviors in `addons/gdevents/behaviors` **are never edited** — they
are always a whole, working "default", and a plugin update will not wipe your
changes. To change or add something, press **"Edit behavior…"** on the Code
tab:

- a copy is placed next to your project — `res://behaviors/<name>/<name>.gd`,
  with the same file name and therefore the same behavior name;
- it replaces the built-in one **for every object in the project**: the
  registry takes it instead of the built-in one, object scenes switch to its
  script, and all object settings are kept;
- the copy opens in the script editor right away.

**"Restore built-in…"** switches the objects back. The copy does not vanish —
it goes into the version history. The built-in version as of copying and the
history are kept in a hidden `.gdevents` folder next to the copy: neither the
registry, nor Godot's FileSystem dock, nor the export see it.

**"New based on this…"** makes a separate behavior with a new name — for
example "Enemy shot" (`EnemyShoot`) next to the player's "Shoot". It is added
to objects with the usual "Add behavior" button.

**Versions.** "Versions ▾" → "Remember current version…" saves the code under
a name — "stable", "before the dash". Any version can be opened, compared with
"Difference from current" and brought back with "Restore"; the current code
goes into the history first, so a restore can be undone too. After "Restore
built-in", the past copies stay in the list of the built-in behavior:
restoring such a version makes a copy of it again and switches the objects to
it.

**"Compare with built-in"** shows what is changed in the copy: added lines in
green, removed in red, unchanged folded. If the plugin was updated and the
built-in version changed after you made the copy, the Code tab says so: "What
changed" shows the update's edits — carry over what you need into the copy —
and "Noted" dismisses the reminder.

A copy or your own behavior that does not compile is marked "error" in the
behavior list, and the build before running the game warns about it: the
sheets will build, but objects with such a behavior will not work in the game.

The settings window is built from the behavior script itself, so your own
behavior in `res://behaviors/` gets it without a single extra line.

**A behavior brings its skeleton along.** Create an empty scene, add
"Platformer character" — and the scene gets a `CharacterBody2D`, a collision
shape and an `AnimatedSprite2D`. All that is left is to add sprites. What
exactly will be created is written in the behavior picker in advance. If the
needed node already exists in the scene, nothing is created.

**A removed behavior takes its skeleton with it.** The nodes a behavior
created itself are deleted with it. The skeleton stays whole if you put
something of your own into it or another behavior of the object uses one of
its nodes — for example, "Juice" uses the platformer's sprite: half a
skeleton is worse than either, a body without a shape falls through the
floor. Behaviors added before version 0.9.1 have no record of their
skeleton — their nodes stay; delete them by hand.

**No need to close the scene.** If it is open in a tab, the edit goes through
the live tree and is saved through the editor — nothing is lost.

Next to each behavior you can see **which node** it sits on
(`CharacterBody2D/Platformer`). This matters: in a live scene a behavior is
almost never on the root.

## Building

With the **Build** button in the editor, or from the menu
**Project → Tools → GDevents: rebuild event sheets**.

From the command line:

```bash
godot --headless --script res://addons/gdevents/tools/build_cli.gd
```

Every `**/*.gdes.json` becomes a `.gd` with the same name next to it. The
"Attach to scene…" button adds the resulting script to a scene as a child
node, so the scene root keeps its own script.

Sheets stay plain JSON — they can still be edited as text or by an AI; the
editor keeps them intact on a round trip.

Sheets are also rebuilt **before a game is exported**, so an exported game
never carries old event code. Each sheet stores its format number
(`"format"`): a sheet made with an older plugin is upgraded automatically,
and a sheet from a newer plugin is not opened, so it is never damaged.

## Tests

Everything with one command (the same script GitHub runs on every pull
request):

```bash
bash addons/gdevents/tools/run_tests.sh
```

Or one by one:

```bash
godot --headless --script res://addons/gdevents/tools/editor_test.gd
godot --headless --quit-after 600 res://addons/gdevents/tools/behavior_test.tscn
godot --headless res://addons/gdevents/tools/hover_test.tscn
godot --headless --script res://addons/gdevents/tools/build_tests.gd
godot --headless --quit-after 200 res://addons/gdevents/tests/selftest.tscn
godot --headless --quit-after 600 res://addons/gdevents/tools/runtime_test.tscn
godot --headless --quit-after 600 res://addons/gdevents/tools/library_test.tscn
godot --headless --quit-after 2500 res://addons/gdevents/tools/behavior_window_test.tscn
godot --headless --script res://addons/gdevents/tools/i18n_test.gd
godot --headless --quit-after 60000 res://addons/gdevents/tools/behavior_scenarios_test.tscn
godot --headless --quit-after 20000 res://addons/gdevents/tools/events_test.tscn
```

The first covers the document model, the clipboard, finding behaviors in a
scene, clear names, errors on rows, the scene skeleton and the scene check
with fixes.
The second — behaviors in action: that all of them compile, falling, jumping,
an animation from an event over the platformer, armor, the path, damage,
pickups, spawning, pushing a character, shooting where the character faces,
choosing the main node.
The third drives the panel with a real mouse: hovering, clicks on row and
event buttons, the panel width in a narrow window. The other tests call
methods directly and cannot see what is under the cursor — that is how
buttons once slipped through that flickered and could not be pressed.
The fourth builds a test sheet, the fifth runs it and prints a line like:

```
ИТОГ врагов=2 уехал=1 остался=1 пуля=60.3 скорость=100 тиков=6
```

(RESULT enemies, left, stayed, bullet, speed, ticks.) Every number matters.
`уехал=1 остался=1` (left=1 stayed=1) — picking narrowed down to one instance
instead of acting on all (were it broken, it would be `2` and `0`). `пуля>0`
and `скорость=100` — a behavior that sits not on the root but inside a
`CharacterBody2D` was found and worked; everything used to stay silent with
this layout.

The sixth compares picking with GDevelop on live nodes: "Create" picks only
the new object, "NOT" keeps in the picking those who do not match, a second
sheet runner does not reset scene variables. The generator is tested there
too: fractional variables, quotes in names, the compile check of the built
code.
The seventh goes through the whole library: every condition (also with NOT),
action and expression — built-in, from behaviors and from extensions — is
built into its own sheet, compiled and run on an object that has all
behaviors at once. A new instruction in `builtin.json` or a new `@export`
property of a behavior is covered by it automatically.
The eighth — the behavior window: names and groups, writing an edit into the
scene file, resetting to the default, a preset, choosing a target and an
animation, switching to another behavior without losing the edit, the Code tab
and jumping to an action's function, your own copy (switching scenes while
keeping settings, the copy in the history after going back, a new behavior
based on another), versions (remember, restore, bring back a copy after
restoring the built-in one), comparing with the built-in one and the reminder
about its update, the English interface without Russian leftovers.
The ninth — translations: every interface string and the whole built-in
library, behaviors and extensions have English text with the same
placeholders, and no Russian strings bypass `GdeI18n.t()` in the code.
The tenth runs every newer behavior in its own small physics world, one
scenario after another: the patrolling enemy turns at edges and walls and
walks home after losing the player, pathfinding goes around a wall, a
platform carries whoever stands on it, a crate is pushed, a checkpoint
respawns, the dialogue types and takes answers, and so on (one scenario:
`GDE_SCENARIO=ladder godot --headless …`).
The eleventh runs the newer events on generated sheets with frames ticked
by hand: "has just collided" fires once, "wait" keeps the picking, object
timers are independent, lists, effects, key hold and double tap.
The twelfth, `tools/export_test.sh`, exports a game to a `.pck` (no export
templates needed), runs it without the editor and checks that the sheet was
rebuilt before the export and that the translations went into the game.
The thirteenth, `tools/debugger_test.sh`, runs a game with Godot's
debugger attached (`tools/debugger_server.gd` stands in for the editor) and
checks that fired events and live variables arrive.
The fourteenth, `tools/bench.tscn`, is a load test: 500 enemies and 300
bullets, all moving, bullets hitting enemies, "has just collided" and
"touching from above", with shapes only and with Area2D; it prints the
time of a sheet frame and fails above 33 ms (the old pair-by-pair check
took 1700 ms here; now it is about 5–15 ms).

There are also `tools/editor_shot.gd` and `tools/dialog_shot.tscn`: they put
screenshots of the panel and the dialogs into `user://` — a quick way to see
the layout without opening the editor. Tools that need behaviors run as a
scene, not through `--script`: without the `Gde` autoload behavior scripts do
not compile, and the result would be falsely clean.

## The main thing: picking objects

This is what it was all for. A condition does not return "yes/no" — it
**narrows the list of instances** that the following conditions and actions
work with.

```
IF:    Bullet collides with Enemy
THEN:  Delete object Bullet
       Change variable hp of Enemy: - 1
```

Not all bullets and not all enemies are affected, but exactly those that
really collided. Sub-events get a copy of the parent's picking. A created
object is picked by the current event right away — if the event has not
picked that object yet, only the new one: "Create Bullet" followed by "Rotate
Bullet" touches the new bullet, not every bullet of the level. A deleted one
is removed from the picking at once.

"NOT" on an object condition flips the check for each instance: "NOT Enemy is
visible → Delete Enemy" deletes the invisible ones even if there are visible
ones nearby. With "NOT collides" only the first object is narrowed.

The regression test for this is `tests/selftest.gdes.json`, run headless:

```bash
godot --headless --quit-after 200 res://addons/gdevents/tests/selftest.tscn
```

What each number of its result line means is in the "Tests" section.

## Sheet format

```jsonc
{
  "format": 2,
  "extends": "Node2D",              // base class of the generated script

  "objects": [                      // object type = a .tscn scene
    { "name": "Player", "scene": "res://demo/demo_player.tscn" }
  ],
  "groups": { "Enemies": ["Goblin", "Orc"] },   // GDevelop object groups
  "variables": { "score": 0 },                  // scene variables

  "events": [
    {
      "type": "standard",           // standard | comment | group | foreach | repeat | while | include
      "any": false,                 // true — "any of the conditions" (OR)
      "locals": { "count": 0 },     // local variables of the event
      "conditions": [
        { "id": "key.pressed", "params": ["Space"], "inverted": false }
      ],
      "actions": [
        { "id": "object.x", "params": ["Player", "+", "220 * TimeDelta()"] }
      ],
      "children": []                // sub-events
    }
  ]
}
```

Event types: `foreach` takes `"object"`, `repeat` — `"count"`, `comment` —
`"text"`, `group` — `"name"`, `include` — `"sheet"` (path of the sheet to
include). `"folded": true` only collapses an event in the editor. Any event can be switched off for a while with
`"disabled": true`. Sub-events go only in `"children"`, NOT is
`"inverted": true`; every parameter is a string, and text inside it is in
quotes: `"\"Score: \" + ToString(Variable(score))"`. The exact ids of all
instructions with their parameter kinds are printed by `tools/library_list.gd`
(see "Checking your files").

## Expressions

The syntax is as in GDevelop, transpiled to GDScript:

```
220 * TimeDelta()
RandomInRange(40, 440)
"Score: " + ToString(Variable(score))
Player.X() + 50
Enemy.Variable(hp)
Player.Shoot::CooldownLeft()
Clock::Hour()
```

Numbers always compile to float — so that `3 / 2` gives `1.5`, as in
GDevelop, and not `1`, as in plain GDScript.

## Library

`registry/builtin.json` holds **77 conditions, 92 actions and 75
expressions** in 21 groups: Movement, Picking, Collisions, Objects,
Variables, Lists, Animation, Appearance, Tweens, Effects, Text, Keyboard,
Mouse, Gamepad, Timers, Sound, Camera, Physics, Saving, Scene, System.
It is a curated layer: edited as text, its sentences are written in Russian
and translated into English through `i18n/en.json`.
**Every instruction has a description** — it is shown in the picker and as a
tooltip in the sheet.

The `icon` field of an instruction or the group map in `editor/gde_icons.gd`
sets its icon. The set is [Tabler Icons](https://tabler.io/icons) (MIT), see
`icons/LICENSE.txt`.

### What is there besides the basics

- **Touches**: "has just collided" and "the touch has ended" fire once;
  "touches from above / below / from the side" for a Mario-style stomp.
  Objects that only touch at the edges count as colliding.
- **Wait N seconds**: everything below in the event and its sub-events
  runs later, with the same picked objects.
- **Object timers**: every instance has its own ("timer shot of Enemy >
  2"), so enemies do not shoot in chorus; `Enemy.Timer(shot)`.
- **Compare two values** (any expressions, numbers or texts) and **pick
  all within a radius** of a point or of an object — explosions.
- **Input**: gamepad buttons and sticks (`StickX()`, `StickY()`),
  vibration, "held longer than N seconds", "released after holding" for
  charged shots, `KeyHeldTime()`, double taps.
- **Objects**: attach to an object (with an offset or where it is) and
  detach; duplicate with the object variables.
- **Effects**: ready-made particles (explosion, sparks, dust, smoke,
  magic, confetti), floating text above an object, hit stop, screen flash,
  going to a scene with a fade.
- **Lists** in scene variables and **values on screen** instead of the
  console.

### The "Picking" group — the very GDevelop mechanic

These conditions do not so much answer "yes/no" as decide which instances
the following rows of the event work with:

- **Pick the nearest to a point / to an object** — narrows down to one;
- **Pick the farthest**, **Pick a random one**;
- **Pick all** — resets the narrowing made above.

Important: `Enemy.Count()` counts the **picked** instances, not all living
ones — exactly as in GDevelop. To count all of them, put "Pick all" first.

### The "Tweens" group

One action instead of an event with a counter: "Smoothly move to X;Y in N
sec", "smoothly shift by…", scale, rotation, opacity. The condition "a tween
is running" lets you wait for the end. An object has one tween at a time: a
new one cancels the old one — otherwise two "move" tweens would fight over one
position.

### Animations: events win over behaviors

"Platformer character" and "Top-down movement" switch animations by
themselves. An animation started by an event now wins: it holds while the
event keeps starting it, and in any case for one full pass. The platformer
used to override it on the very next frame, and a "double jump" from an event
was simply invisible. For the most common cases no events are needed at all —
the platformer has slots for the air-jump animation and the wall-slide
animation.

### Where the object faces

**"Shoot" fires where the character faces by itself** (a checkbox, on by
default). In a platformer the character does not rotate but flips — two
"faces left / right" branches just for shooting are no longer needed. There
is also the action "Shoot where it faces, turned by N degrees" — for shooting
upward at an angle.

The condition **"is flipped horizontally (faces left)"** and its opposite
(right-click → "Invert") are the way to split two branches: shoot left or
right. If you do not want branches, there is the expression `Player.Facing()`:
it gives `1` to the right and `-1` to the left, so

```
Create Bullet at position Player.X() + 20 * Player.Facing() ; Player.Y()
Change "Direction in degrees" of Bullet: = 90 - 90 * Player.Facing()
```

sends the bullet the way the player faces in one line.

Flipping is set by the action "Flip horizontally" and by itself — by the
"Platformer character" and "Top-down movement" behaviors, if their checkbox
for it is on.

## Your own behaviors

A behavior is a child node of an object whose script extends `GdeBehavior`.
**The only source of truth is the `.gd` file itself:**

```gdscript
@tool
extends GdeBehavior

@export var fire_rate: float = 0.25     # property + action + condition + expression
@export var bullet_scene: PackedScene   # property only (nothing to fill it with in the event editor)

## @action Shoot from _PARAM0_
func fire() -> void: ...

## @condition _PARAM0_ can shoot
func can_fire() -> bool: ...

## @expression Seconds until the next shot
func cooldown_left() -> float: ...
```

`_PARAM0_` is always the object itself, `_PARAM1_` and on are the method's
arguments. The full rules, a template that passes the check without a single
remark, and a table of common mistakes are in
[`docs/AUTHORING.md`](docs/AUTHORING.md) (see "For AI assistants").
Edited the file → rebuilt → the new action is available in the sheet.
The behavior's name comes from the file name (`shoot.gd` → `Shoot`), or is
set explicitly with the comment `## @behavior Name`.

In sheet ids, behavior members are addressed as `Shoot::fire`. The automatic
actions for properties are called `Shoot::set_fire_rate`.

### Behavior annotations

| Annotation | What for |
| --- | --- |
| `## @behavior Name` | the id in sheets (Latin letters) |
| `## @title Title` | what the behavior is called in the interface |
| `## @description …` | the description in the picker |
| `## @icon name` | an icon from `icons/` |
| `## @target CharacterBody2D` | the node the behavior works on; created if the scene has none |
| `## @needs CollisionShape2D Shape` | a node the behavior is useless without; created automatically |
| `## @internal` | above an `@export` — do not make an action and a condition from the property |

In `@needs`, equivalent options are listed with `|`:
`## @needs Sprite2D|AnimatedSprite2D Sprite` means "some sprite is needed",
and the first one in the list is created.

### Property names come from `##` comments

A plain comment above an `@export` is not just an inspector hint. The name of
the action and the condition is built from it: its first thought up to a
period, a comma or a dash.

```gdscript
## Acceleration — how fast the speed builds up.
@export var acceleration: float = 1600.0
```

gives "Change “Acceleration” of Player (Platformer character): = 2000" and the
full description in the tooltip. Without the comment the list gets the bare
`acceleration` — exactly the line that explains nothing. So write the name
first, then the explanation.

Behaviors are looked for in `addons/gdevents/behaviors/` and in
`res://behaviors/`.

### Presets

Platformer, TopDown, Shoot and several others have ready-made sets of
settings. In the behavior window, pick a preset and press "Apply"; in the
inspector, pick it and tick **Apply Preset** — it writes the values into the
fields below and unticks itself. Then edit by hand.

The checkbox is a button, not a switch: otherwise a preset would overwrite
your edits every time the scene loads.

### Ready-made behaviors

| Name | What it gives |
|---|---|
| **Platformer** | Coyote time, jump buffer, variable height, faster falling, turning with acceleration, air control, double jump, wall slide and wall jump, ladders, dropping through one-way platforms, automatic animations. Presets: Classic, Icy, Moon, Responsive. Needs a `CharacterBody2D` |
| **Shoot** | Spread, shotgun pellets, bursts, magazine and reload, recoil, sound, inheriting the shooter's velocity, shooting at the nearest object. Presets: Pistol, Shotgun, Machine gun, Burst |
| **TopDown** | 4/8/free movement, dash with cooldown, smooth turning, pushing, animations. Presets: Classic, Slippery, Tank, Snappy |
| **Health** | Flat and percentage armor, invulnerability with blinking, regeneration with a delay, death delay, a scene on death, damage through invulnerability |
| **LinearMove** | Acceleration, gravity (an arc instead of a line), drag, bouncing off edges, fading before death, homing on an object |
| **Follow** | Three modes: chase, flee, keep distance. The noticing zone is separate from the losing zone — an enemy does not twitch at the border |
| **Draggable** | Axis lock, grid, smooth following, screen bounds, raising above the rest, returning to place |
| **Oscillate** | Three wave shapes, phase shift (a wave of several objects), oscillating position, rotation and size |
| **Rotate** | Acceleration, swinging back and forth, snapping to a step, turning to a given angle |
| **DestroyOutside** | Three modes: delete, wrap around as in "Asteroids", keep in. Edges are set separately |
| **Path** | Movement by points: loop, back and forth, once. Waiting at points, acceleration, turning and flipping by direction, going to any point. Presets: Patrol, Elevator, Square, There and back |
| **Damage** | Damage to whoever it touches: a cooldown per victim, knockback, piercing several targets, self-destruction, damage through invulnerability. Presets: Spikes, Bullet, Piercing projectile, Poison |
| **Pickup** | Coins, crystals, medkits, ammo: bobbing, a magnet to the collector, adding to a variable, healing or ammo — without a single event. Presets: Coin, Crystal, Medkit, Ammo |
| **Spawner** | A spawn point: an interval with randomness, batches, a total limit and a limit of living ones, a random place in a circle. Presets: Enemy wave, Coin rain, Boss, Fountain |
| **PatrolEnemy** | A ready-made platformer enemy without events: walks its beat, turns at edges and walls, spots the player with a ray that walls block, chases, searches, returns home |
| **Pathfinder** | Goes to a target around walls: the level is split into cells by itself, A* with smoothing, recomputes for a moving target, "cannot reach" |
| **Homing** | A missile turning to the target with a limited turn speed; it can miss and lose the target outside its field of view. Launched by Shoot in the firing direction |
| **Orbit** | Circles around another object; several spread evenly by themselves, follow the center and can disappear with it — shields, satellites, saws |
| **Flock** | Bees, birds, fish: stay together, fly the same way, do not bump into each other, go around walls, follow or flee a leader |
| **Car** | A top-down car: throttle, brake and reverse, speed-dependent steering, grip, drifting on the handbrake, "crashed". Presets: Arcade, Drift, Truck, Kart |
| **GridStep** | Movement by cells for puzzles, roguelikes and sokoban: walls stop it, grid objects block each other, pushable ones are pushed |
| **Platform** | One-way (jump up through it, drop down with down + jump), moving and carrying riders, a conveyor belt, crumbling and coming back, a trampoline |
| **Ladder** | A zone the platformer climbs up and down in; jump to get off, centering on the ladder |
| **Pushable** | A crate a character moves by leaning into its side; falls off edges, stops at walls, top-down too |
| **Checkpoint** | A touch remembers the respawn point; after Health runs out the player appears there with full health, even after a scene restart |
| **Destructible** | Bursts into shards of its own picture and drops items by a chance table — on Health death, on a touch or by an action |
| **Melee** | A strike with a hit zone on the right animation frames, once per target per swing, knockback, combos of up to three, cooldown |
| **Ability** | A dash, a shield or healing on a key with charges and a cooldown, without events; readiness for a bar |
| **StateMachine** | States like patrol / chase / attack / stunned: time in a state, "has just entered / left", timed switches |
| **StickTo** | Stays at another object with an offset and flips with it: a health bar above an enemy, a weapon in a hand |
| **ValueBar** | A bar of health or of a variable that draws itself, shrinks smoothly with a catching-up trail; above an object or on screen |
| **Juice** | Squash and stretch, dust on landing, a flash and a shake on hits, a trail on dashes — picked up from other behaviors' signals by itself |
| **MenuButton** | A menu button: hover, press, sound, zoom, arrow keys and Enter, works on pause; can go to a scene, restart, unpause or quit |
| **Dialogue** | A speech bubble (or a box at the bottom): typed letter by letter, a queue of lines, answers to choose from, pausing the game |

Every behavior has signals (`jumped`, `landed`, `died`, `fired`…) — they can
be connected from ordinary GDScript, bypassing the event sheet.

## Your own events: extensions

A behavior is an ability of an object: running, shooting, taking damage. For
everything else — your own conditions, actions and expressions not tied to a
behavior — there are **extensions**, as in GDevelop. An extension is one file
`res://extensions/<name>/<name>.gd` with static functions and the same
annotations as behaviors:

```gdscript
## @extension Clock
## @title Часы
## @title.en Clock
## @icon timer
extends GdeExtension

## @condition Сейчас от _PARAM0_ до _PARAM1_ часов
## @condition.en It is between _PARAM0_ and _PARAM1_ o'clock
## @param from С какого часа
## @param.en from From hour
static func is_hour_between(from: float, to: float) -> bool: ...

## @expression Текущий час, 0…23
## @expression.en Current hour, 0…23
static func hour() -> float: ...        # in a sheet: Clock::Hour()
```

- Conditions and actions appear in the picker in the "Common" section, in a
  group named after the extension; expressions are written as `Clock::Hour()`.
- Parameters are `float`, `int`, `bool`, `String`; values from the sheet are
  converted to the right type automatically.
- A first parameter of type `Node` (`Node2D`, `CharacterBody2D`…) makes the
  condition or action an **object** one: it works with the picked instances,
  like "Change X of ‹Object›", and the function receives the instance itself.
- State between calls lives in `static var`; the runtime is reached through
  `Gde`.
- `library_test` checks every instruction of every extension by itself.

The example shipped with the plugin is
`addons/gdevents/extensions/clock/clock.gd`: system time, the day of the week
and a clock hand.

## Checking your files

One command checks your behavior, extension or sheet the way the plugin will
use it:

```bash
godot --headless --quit-after 5000 res://addons/gdevents/tools/check.tscn -- res://behaviors/enemy_shoot/enemy_shoot.gd
godot --headless --quit-after 5000 res://addons/gdevents/tools/check.tscn -- res://events/level.gdes.json
godot --headless --quit-after 5000 res://addons/gdevents/tools/check.tscn          # everything of yours at once
```

- The script compiles — errors come with line numbers.
- The plugin sees the file, and the name from `@behavior` / `@extension`
  matches the file name.
- Every condition, action and expression is built into a real sheet and run on
  a live object.
- Warnings: a parameter without `@param`, a setting without a description,
  text without a translation, `class_name`, `_ready()` without `super()`.
- For a sheet: its structure (the key `events` instead of `children` used to
  vanish silently), the object scenes and every instruction and expression,
  with where the error is: "event 2 › 1, action 3".

`✗` is an error (exit code 1), `!` works but is worth fixing. The report is in
the plugin language; `-- --lang=en` or `--lang=ru` at the end sets it
explicitly.

The full list of instructions with exact ids and parameter kinds — for those
who write sheets as text:

```bash
godot --headless --script res://addons/gdevents/tools/library_list.gd
godot --headless --script res://addons/gdevents/tools/library_list.gd -- Shoot
```

## For AI assistants

Behaviors and events can be given to any AI model. So that it writes them
correctly the first time, the project provides:

- [`docs/AUTHORING.md`](docs/AUTHORING.md) — the full guide: where files go,
  annotations, behavior and extension templates, the sheet format,
  expressions, the `Gde` runtime, common mistakes, verification and the
  definition of done;
- `AGENTS.md` at the repository root — the entry point that Codex, Cursor,
  Copilot and others read by themselves; `CLAUDE.md` — the same for Claude
  Code;
- the `.claude/skills/gdevents` skill — Claude Code loads it by itself when
  the task is about behaviors, extensions or sheets;
- in Claude Code cloud sessions the `.claude/hooks/session-start.sh` hook
  installs Godot 4.7.1, so the check works right away.

If a model does not see these files, it is enough to tell it: "read
addons/gdevents/docs/AUTHORING.md and verify the result with the command from
it".

## Languages

The plugin works in English and Russian. The language is asked on the first
start (English by default) and can then be changed at the end of the toolbar
or in "Editor Settings → GDevents"; every person has their own. The interface
and the built-in library are translated with the dictionary
`i18n/<language>.json`, whose keys are the Russian texts from the code.
Behaviors and extensions are translated right in their own file: `@title.en`,
`@action.en`, `## @en …` under a setting description, `@options.en` for list
items, `@group.en` above `@export_group`, `@param.en` for parameter labels.
The main text may be in either language, the translation next to it.
`i18n_test` makes sure everything in the plugin is translated. An exported
game uses the player's system language.

## Not there yet

- Search in a sheet.
- Editing scene variables in the editor (for now they are edited in JSON).
- Sheets driven by signals or `_physics_process` — only per-frame for now.
- Behaviors made of events (event-based behaviors from GDevelop).
- Renaming a behavior method breaks the sheets that referred to it: the build
  reports "unknown action", but fixing is manual.

## Known trade-offs

- Every event creates a picking context — an extra allocation per frame. It
  will become noticeable with hundreds of events; then it makes sense to skip
  the context for events that do not touch objects.
- Conditions compile to lambdas: readable, but a lambda in GDScript
  allocates.
- Collisions are exact for `Area2D`; for everything else they use the AABB
  taken from a `CollisionShape2D` or the sprite.
