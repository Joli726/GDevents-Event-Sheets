# GDevents

**English** · [Русский](README.ru.md)

GDevelop-style event sheets for **Godot 4.7**. Build game logic from
conditions and actions instead of writing code; the sheets compile to plain,
readable GDScript with no interpreter at runtime.

- **Event sheet editor** inside Godot: conditions, actions, sub-events,
  loops, groups, drag and drop, undo, errors shown right on the row.
- **Object picking as in GDevelop**: "Bullet collides with Enemy → Delete
  Bullet" deletes exactly the bullets that hit.
- **14 ready-made behaviors** — platformer character, top-down movement,
  shooting, health, damage, pickups, spawner, path, follow and more — with
  a settings window, presets and a code view.
- **Your own behaviors and extensions**: one `.gd` file with a few comment
  tags becomes new conditions, actions and expressions. Built-in behaviors
  can be copied and changed, with versions and a way back to the default.
- **Scene and file checks** that explain problems in plain words and offer
  fixes.
- **English and Russian interface**, chosen on first start and switchable at
  any time.
- **Made to work with AI assistants**: an authoring guide, `AGENTS.md`, a
  Claude Code skill and a one-command check that proves a file works.

## Install

1. Copy the `addons/gdevents` folder into your project's `addons/` folder.
2. In Godot: **Project → Project Settings → Plugins**, enable **GDevents**.
3. Choose the interface language in the window that appears. An **Events**
   tab appears next to 2D / 3D / Script.

## Quick start

1. In the **Events** tab press the new-sheet button next to the sheet list.
2. Open **Objects**, add the scenes your game is made of, and give them
   behaviors — for example "Platformer character" to the player.
3. Press **Add event**, then **+ Condition** and **+ Action** inside it.
4. Press **Attach to scene…**, pick your level scene and run the game — the
   sheet is saved and built automatically.

## Documentation

- [Plugin manual](addons/gdevents/README.md) — the editor, the sheet format,
  expressions, the library, behaviors, extensions, checks and tests.
- [Authoring guide](addons/gdevents/docs/AUTHORING.md) — the exact rules for
  writing behaviors, extensions and sheets, for people and for AI models.
- [AGENTS.md](AGENTS.md) — instructions for AI assistants working in this
  repository.

## Checking your own files

```bash
godot --headless --quit-after 5000 res://addons/gdevents/tools/check.tscn -- res://behaviors/my_behavior/my_behavior.gd
```

Without a path it checks all your behaviors, extensions and sheets.
