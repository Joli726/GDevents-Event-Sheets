# Your first game in 15 minutes

**English** · [Русский](TUTORIAL.ru.md)

A tiny platformer: the hero runs and jumps, collects coins, spikes take
health away, and after dying the level starts over. The ready-made abilities
(running, jumping, picking up coins, damage, health) come from **behaviors** —
they need no events at all. Events are needed only for the score on screen,
the win and the restart.

You need Godot 4.7 with the GDevents plugin enabled (see "Install" in the
README) and any pictures: a character, a coin, spikes, a piece of ground.

## 1. Object scenes

In GDevents **an object is a scene** `.tscn`. Make three empty scenes:
**Scene → New Scene → Other Node → Node2D**, and save them as
`player.tscn`, `coin.tscn`, `spike.tscn`. For the score make a scene with a
**Label** root and save it as `score.tscn`.

## 2. The event sheet and its objects

1. Open the **Events** tab (next to 2D / 3D / Script) and press
   **Create a new sheet**. Call it `level.gdes.json`.
2. Press **Objects**. At the bottom, under "New object", type the name
   `Player`, press **Choose…**, pick `player.tscn` and press **Add**. Add
   `Coin` (`coin.tscn`), `Spike` (`spike.tscn`) and `Score` (`score.tscn`)
   the same way.

## 3. Behaviors — all the mechanics without events

In the same window pick an object on the left and press **Add behavior**.

| Object | Behavior | What to set on the right |
| --- | --- | --- |
| Player | **Platformer character** | Nothing is required; you can pick the "Classic" preset |
| Player | **Health** | "Health pool": 3; turn on "Blink when taking damage" |
| Coin | **Pickup** | Preset "Coin"; "Collector": `Player`; "Variable name": `coins` |
| Spike | **Contact damage** | Preset "Spikes"; "Victim": `Player`; "Damage per hit": 1 |

A preset is a ready-made set of settings: pick it in the "A ready-made set
of settings" list and press **Apply**, and its values are written into the
settings below.

A behavior adds to the scene whatever it is missing: "Platformer character"
turns the scene into a `CharacterBody2D` with a collision shape and an
`AnimatedSprite2D`. Open the scenes (**Open scene**) and give the sprites
pictures. If something is forgotten, the **Scene check** tab says what and
offers a one-button fix.

## 4. The level

Create a scene `level.tscn` with a **Node2D** root. Drag `player.tscn`,
several `coin.tscn` and `spike.tscn` into it, and `score.tscn` into a corner
of the screen. The floor is a **StaticBody2D** with a **CollisionShape2D**
(a rectangle) and a picture.

## 5. Events

Go back to the Events tab. An event is added with **Add event**, a
condition and an action with the **+ Condition** and **+ Action** rows
inside it. In the picker you choose the object on the left and the
instruction on the right; the values go at the bottom of the window.

1. **The score on screen.** An event with no conditions (it runs every
   frame). Action: object `Score` → "Set the text" →
   `"Coins: " + ToString(Variable(coins))`.
2. **The win.** Condition: "Common" → "Scene variable" `coins` `≥` `10`.
   Action: "Set the text" of `Score` → `"You win!"`.
3. **Death and restart.** Conditions: object `Player` → "has just died"
   (the Health behavior) and "Common" → "Trigger once while true". Actions:
   "Wait" `1` second, then "Restart the current scene".

The order matters: events run top to bottom, so "The win" comes after the
score and overwrites its text.

## 6. Run it

Press **Attach to scene…** on the yellow bar and pick `level.tscn`. Run the
scene (F6). The sheet is saved and built by itself before every run.

While the game runs, fired events light up green in the sheet, and the
**GDevents** tab of Godot's debugger at the bottom shows the value of
`coins`.

## The finished sheet

This is `level.gdes.json` after step 5 — it can be opened as text too. The
plugin's tests build this sheet: if the tutorial drifts away from the
library, a test fails.

```json
{
  "format": 2,
  "name": "level",
  "extends": "Node2D",
  "objects": [
    { "name": "Player", "scene": "res://player.tscn" },
    { "name": "Coin", "scene": "res://coin.tscn" },
    { "name": "Spike", "scene": "res://spike.tscn" },
    { "name": "Score", "scene": "res://score.tscn" }
  ],
  "variables": { "coins": 0 },
  "events": [
    { "type": "comment", "text": "The score on screen — every frame" },
    {
      "type": "standard",
      "conditions": [],
      "actions": [
        { "id": "object.set_text", "params": ["Score", "\"Coins: \" + ToString(Variable(coins))"] }
      ]
    },
    {
      "type": "standard",
      "conditions": [
        { "id": "var.compare", "params": ["coins", "≥", "10"] }
      ],
      "actions": [
        { "id": "object.set_text", "params": ["Score", "\"You win!\""] }
      ]
    },
    {
      "type": "standard",
      "conditions": [
        { "id": "Health::just_died", "params": ["Player"] },
        { "id": "system.trigger_once", "params": [] }
      ],
      "actions": [
        { "id": "system.wait", "params": ["1"] },
        { "id": "scene.restart", "params": [] }
      ]
    }
  ]
}
```

## What next

- [Instruction reference](REFERENCE.md) — every condition, action and
  expression with a description.
- [Plugin manual](../README.md) — object picking, functions made of events,
  shared sheets, local variables.
- Your own behavior or extension — the [authoring guide](AUTHORING.md).
