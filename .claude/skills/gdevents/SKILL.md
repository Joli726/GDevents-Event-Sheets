---
name: gdevents
description: Write, change, translate or check GDevents content for Godot — behaviors (res://behaviors, extends GdeBehavior), extensions with own conditions/actions/expressions (res://extensions, extends GdeExtension) and event sheets (*.gdes.json). Use for any request about поведение/behavior, расширение/extension, события/events, лист событий/event sheet, условие/condition, действие/action, выражение/expression in this project.
---

# GDevents: behaviors, extensions, event sheets

The full reference is `addons/gdevents/docs/AUTHORING.md`. Read the part you
need **before** writing; this skill is the workflow around it.

## Workflow

1. **Pick the kind of file** (AUTHORING.md → "What to write"):
   ability of an object → behavior; instructions not tied to an ability →
   extension; game logic → event sheet; change a built-in behavior → copy in
   `res://behaviors/<same_name>/<same_name>.gd`.
2. **Read** the matching AUTHORING.md section and the closest real example:
   `addons/gdevents/behaviors/rotate/rotate.gd` (simple),
   `addons/gdevents/behaviors/pickup/pickup.gd` (presets),
   `addons/gdevents/extensions/clock/clock.gd` (extension).
3. **Write** the file from the template in AUTHORING.md:
   - path `res://behaviors/<snake>/<snake>.gd` or `res://extensions/<snake>/<snake>.gd`;
     `@behavior` / `@extension` = the file name in PascalCase; no `class_name`;
   - `@tool`, then `extends GdeBehavior` / `extends GdeExtension`;
   - tags directly above each function; every argument has `@param` and
     appears in the sentence as `_PARAMn_`; every `@export` has a `##` comment;
   - English **and** Russian for every visible text (`.ru` / `.en` suffixes,
     `## @ru …` / `## @en …` lines).
4. **For sheets**, get exact ids and parameter kinds first:
   `godot --headless --script res://addons/gdevents/tools/library_list.gd -- <word>`.
   Parameters are JSON strings; text parameters need inner quotes
   (`"\"Hi\""`); sub-events go in `children`.
5. **Check** and fix until there is no `✗`, then resolve the `!` warnings:
   ```bash
   godot --headless --quit-after 5000 res://addons/gdevents/tools/check.tscn -- res://path/to/file
   ```
   If `godot` is missing, look for the user's Godot binary; if there is none,
   tell the user the file is unverified and how to check it in the editor.
6. **Report to the user in Russian**: what was created, what it is called in
   the editor (both names), where to add it, which instructions appeared.

## Never

- edit `res://addons/gdevents/` to add game content;
- guess instruction ids or expression names;
- use `queue_free()` for objects (use `Gde.delete_object(n)`), or `:=` with
  a `Variant` result (`var hp: float = Gde.var_get("hp")`);
- override `_ready()` in a behavior without calling `super()`;
- say the work is checked without running the check.
