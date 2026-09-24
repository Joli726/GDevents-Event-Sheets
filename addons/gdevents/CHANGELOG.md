# Changelog · Список изменений

Versions follow [semantic versioning](https://semver.org/): until 1.0.0 the
sheet format and instruction ids may still change between minor versions;
every such change comes with an automatic upgrade of old sheets.

Версии идут по [семантическому версионированию](https://semver.org/lang/ru/):
до 1.0.0 формат листа и id инструкций ещё могут меняться между версиями,
и каждое такое изменение приходит с автоматическим обновлением старых листов.

## 0.5.0

- **Functions made of events**: own actions and conditions with object,
  number and text parameters, shown in the picker next to the built-in
  ones. · **Функции из событий**: свои действия и условия с параметрами.
- **Debugger**: fired events light up in the sheet while the game runs from
  the editor; the GDevents debugger tab shows live variables and event
  counts. A release export builds sheets without the debug lines.
  · **Отладка**: сработавшие события подсвечиваются, переменные видны
  вживую во вкладке GDevents отладчика.

## 0.4.0

- **Any of the conditions (OR)**: an event can join its conditions with OR
  (event menu). · **Любое из условий (ИЛИ)** — из меню события.
- **Local variables** of an event: reset on every run, seen by sub-events,
  kept by "Wait". · **Локальные переменные** события.
- **Shared sheets**: the "Include sheet" event builds another sheet's events
  in place and adds its objects and variables. · **Общие листы**: событие
  «Подключить лист».
- **Find and replace** in a sheet (Ctrl+F) and **collapsing** events with
  sub-events. · **Поиск и замена** (Ctrl+F) и **сворачивание** событий.
- **A runtime error names the event**: the generated script carries a line
  map, and a line under the Godot error says which event of which sheet
  failed. · **Ошибка в игре называет событие** листа.
- Sheet format 2 (older sheets are upgraded when opened). · Формат листа 2,
  старые листы обновляются сами.

## 0.3.0

- Sheets carry a format number. Older sheets are upgraded when opened, built
  or checked; a sheet from a newer plugin is refused instead of being damaged.
  · Лист хранит номер формата: старые листы обновляются сами, а лист из более
  новой версии плагина не открывается, чтобы его не испортить.
- Sheets are rebuilt before a game is exported, not only before it is run from
  the editor. · Листы пересобираются перед экспортом игры, а не только перед
  запуском из редактора.
- `tools/run_tests.sh` runs every test with one command; GitHub runs it on each
  pull request. `tools/export_test.sh` exports a `.pck` and runs it.
  · Все тесты одной командой; GitHub прогоняет их на каждом PR. Отдельный тест
  экспортирует игру и запускает её.
- MIT license. · Лицензия MIT.

## 0.2.0

- 20 new behaviors: Patrolling enemy, Pathfinder, Homing, Orbit, Flock, Car,
  Grid step, Platform, Ladder, Pushable, Checkpoint, Destructible, Melee,
  Ability, States, Stick to, Value bar, Juice, Menu button, Dialogue.
- Platformer: ladders, dropping through one-way platforms.
- New events: touches (just collided, touch ended, from above / below / the
  side), Wait N seconds, object timers, compare two values, pick within a
  radius, gamepad and vibration, key hold and double tap, attach / detach,
  duplicate, effects (particles, floating text, hit stop, screen flash, scene
  change with fade), lists, values on screen. 244 instructions in total.
- Interface, library and behaviors in English and Russian; own extensions
  (`res://extensions`); a per-file check command; an authoring guide for
  people and AI assistants.
- Behavior settings in the objects window, the behavior code tab, own copy of
  a built-in behavior, behavior versions and a diff with the built-in one.
- Fixes: jumping with coyote time 0, bounds of a Node2D with a child sprite,
  touching edges count as a collision, English setting names.

## 0.1.0

- First version: the event sheet editor, the sheet → GDScript generator,
  GDevelop-style object picking, 14 behaviors, the scene check.
