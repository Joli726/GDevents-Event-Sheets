# AGENTS.md

Instructions for AI assistants working in this repository (Claude, Codex,
Cursor, Copilot, Gemini and others).

**GDevents** is a Godot 4.7 editor plugin: GDevelop-style event sheets that
compile to plain GDScript, plus ready-made behaviors and extensions. This
repository holds only the plugin (`addons/gdevents/`) and a minimal Godot
project around it (`project.godot`) for development and tests. Games that
use the plugin live in their own projects — do not add game scenes or
assets here.

## Talking to the owner

- The owner is not a programmer, relies on AI for code and reads Russian.
  **Answer in Russian**, in plain words; explain any term you have to use.
- Deliver finished, verified work: no placeholders, no "fill this in
  yourself". If something could not be verified, say so directly.
- After a change, tell them what to do in Godot: which object gets the
  behavior, where the new instructions appear, what to press.

## Writing behaviors, extensions and event sheets

**Read [`addons/gdevents/docs/AUTHORING.md`](addons/gdevents/docs/AUTHORING.md)
before writing any of them.** It has the rules, complete templates, the sheet
format and the verification steps. The essentials:

- Behaviors: `res://behaviors/<name>/<name>.gd`, `extends GdeBehavior`.
  Extensions (own conditions, actions, expressions): `res://extensions/<name>/<name>.gd`,
  `extends GdeExtension`, static functions. Sheets: `*.gdes.json`.
- Folder, file and `@behavior` / `@extension` names match
  (`enemy_shoot.gd` ↔ `EnemyShoot`); no `class_name`.
- Every text a user reads is in **English and Russian** (`@title` +
  `@title.ru`, `## @ru …`, `@param.ru`…).
- Take instruction ids from `library_list.gd`; never guess them.
- Do not edit `addons/gdevents/` to add game content; change a built-in
  behavior through a copy in `res://behaviors/<same_name>/`.

## Verifying

Godot 4.7 must be callable as `godot` (in Claude Code cloud sessions the
SessionStart hook installs it). Run from the repository root:

```bash
godot --headless --quit-after 5000 res://addons/gdevents/tools/check.tscn -- res://behaviors/<name>/<name>.gd
godot --headless --quit-after 5000 res://addons/gdevents/tools/check.tscn      # all own files
godot --headless --script res://addons/gdevents/tools/library_list.gd          # every instruction id
```

The work is done only when the check shows no `✗`.

## Changing the plugin itself

Layout of `addons/gdevents/`:

| Path | What |
| --- | --- |
| `plugin.gd` | editor plugin entry: main screen, menu, language, build before run |
| `editor/` | event sheet panel, instruction picker, objects and behavior windows, scene check |
| `codegen/` | sheet → GDScript generator and build |
| `expr/` | expression transpiler |
| `registry/` | `builtin.json` library and the scanner of behavior/extension annotations |
| `runtime/` | `Gde` autoload, `GdeBehavior`, `GdeExtension`, picking context |
| `behaviors/`, `extensions/` | built-in behaviors and extensions (both languages in each file) |
| `i18n/` | `GdeI18n` and `en.json` (keys are the Russian source strings) |
| `tools/` | command-line tools and tests; `tests/` — test sheet and scenes |
| `docs/` | the authoring guide |

Conventions:

- GDScript with static typing, tabs, code comments in Russian that explain
  *why*. Match the surrounding code.
- Interface strings are Russian source text wrapped in `GdeI18n.t("…")`, with
  the English text added to `i18n/en.json` under the same key.
- Run the full test suite before committing:
  `bash addons/gdevents/tools/run_tests.sh` (what each test covers is in the
  "Tests" section of `addons/gdevents/README.md`). A change is not finished
  while any test fails; GitHub runs the same script on every pull request.
- A change to the sheet format bumps `GdeSheetFormat.CURRENT` and adds an
  upgrade step to `codegen/gde_sheet_format.gd`, so existing games keep
  working. Record user-visible changes in `addons/gdevents/CHANGELOG.md`.
