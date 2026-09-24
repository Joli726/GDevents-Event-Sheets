# GDevents instruction reference

Built from the library by `tools/make_reference.gd` — do not edit it by hand. In every parameter text goes in quotes, numbers and expressions as they are. The exact id is needed when a sheet is written as text or by an AI.

- [Conditions](#conditions)
- [Actions](#actions)
- [Expressions](#expressions)
- [Behaviors](#behaviors)

## Conditions

### Animation

- **Animation of ‹Object› finished** — `object.animation_finished`
  A non-looping animation played to its last frame. Works only with non-looping animations — otherwise there is no end.
  Parameters: Object (object)

- **‹Object› is playing animation ‹Animation›** — `object.animation_is`
  The object is currently playing the named animation.
  Parameters: Object (object), Animation (name without quotes)

### Appearance

- **‹Object› is flipped horizontally (faces left)** — `object.flipped_h`
  The object is flipped horizontally, i.e. faces left. Invert the condition (right click → “Invert”) to catch facing right.
  Parameters: Object (object)

- **‹Object› is flipped vertically** — `object.flipped_v`
  The object is flipped vertically — upside down.
  Parameters: Object (object)

- **‹Object› is on screen** — `object.on_screen`
  The object is inside the camera's visible area. Handy for not counting what the player cannot see.
  Parameters: Object (object)

- **Opacity of ‹Object› ‹Sign› ‹0…1›** — `object.opacity`
  Compares opacity: 1 — opaque, 0 — fully transparent.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), 0…1 (number)

- **Scale of ‹Object› ‹Sign› ‹Scale›** — `object.scale`
  Compares the object's horizontal scale. 1 — original size.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Scale (number)

- **‹Object› is visible** — `object.visible`
  The object is visible (neither it nor any of its parents is hidden).
  Parameters: Object (object)

### Clock

- **It is between ‹From hour› and ‹To hour› o'clock** — `Clock::is_hour_between`
  True if the current hour is within the range — across midnight too: from 22 to 6 is night.
  Parameters: From hour (number), To hour (number)

- **Today is a weekend** — `Clock::is_weekend`
  Saturday or Sunday.

### Collisions

- **‹Object› collides with ‹Object›** — `object.collision`
  The objects touch. Only the colliding pairs stay picked — the actions that follow work exactly with them.
  Parameters: Object (object), Object (object)

- **The touch of ‹Object› and ‹With what› has ended** — `object.collision_end`
  Fires once when the objects stop touching: left the water, stepped off a button, left a zone.
  Parameters: Object (object), With what (object)

- **‹Object› has just collided with ‹With what›** — `object.collision_start`
  Fires once — at the moment of touching. For damage, a sound, points: “collides” is true every frame while the objects touch, and an action on it would repeat.
  Parameters: Object (object), With what (object)

- **Distance between ‹Object› and ‹Object› ‹Sign› ‹Distance›** — `object.distance`
  Compares the distance between objects in pixels. Keeps the matching pairs picked.
  Parameters: Object (object), Object (object), Sign (= ≠ < > ≤ ≥), Distance (number)

- **A ray from ‹Object› of length ‹Length› at angle ‹Angle in degrees› reaches ‹Object›** — `object.ray`
  Casts a real ray and looks at what it hits FIRST: a wall between the objects blocks it, as it should. Only the pairs the ray passed between stay picked. The basis for lasers, aiming and checking “is there floor ahead”.
  Parameters: Object (object), Object (object), Angle in degrees (number), Length (number)

- **‹Who looks› sees ‹At whom›** — `object.sees`
  There is no obstacle between the objects: a real ray is cast and checked for what it hits. The basis for enemies with a line of sight.
  Parameters: Who looks (object), At whom (object)

- **‹Object› touches ‹With what› from below** — `object.touch_bottom`
  The first object has bumped into the second one from below — hitting a block with the head.
  Parameters: Object (object), With what (object)

- **‹Object› touches ‹With what› from the side** — `object.touch_side`
  A touch from the left or right — the enemy touched the player, not the player jumping on the enemy.
  Parameters: Object (object), With what (object)

- **‹Object› touches ‹With what› from above** — `object.touch_top`
  The first object stands or has landed on the second one — jumping on an enemy's head, as in Mario.
  Parameters: Object (object), With what (object)

### Effects

- **A hit stop is running** — `effect.in_hitstop`
  The game is frozen by a hit stop right now.

### Gamepad

- **Gamepad button ‹Button: A, B, X, Y, LB, RB, LT, RT, Start, Up…› is pressed** — `gamepad.button`
  True while the button of the first connected gamepad is held. Names are as on an Xbox gamepad: A, B, X, Y, LB, RB, LT, RT, Start, Back, L3, R3, Up, Down, Left, Right.
  Parameters: Button: A, B, X, Y, LB, RB, LT, RT, Start, Up… (name without quotes)

- **A gamepad is connected** — `gamepad.connected`
  At least one gamepad is connected — to show gamepad hints instead of keyboard ones.

- **Gamepad button ‹Button: A, B, X, Y, LB, RB, LT, RT, Start, Up…› is pressed (once)** — `gamepad.just_pressed`
  True for one frame — at the moment of pressing. For a jump, a shot, a menu.
  Parameters: Button: A, B, X, Y, LB, RB, LT, RT, Start, Up… (name without quotes)

### Keyboard

- **Input action ‹Action› is active (once)** — `input.action_just_pressed`
  The same input action, but only on the frame it is pressed.
  Parameters: Action (name without quotes)

- **Input action ‹Action› is active** — `input.action_pressed`
  Checks an input action from the project settings (Project → Project Settings → Input Map). Unlike a key, it works with gamepads and with remapping.
  Parameters: Action (name without quotes)

- **Any key is pressed** — `key.any`
  True if any key at all is pressed. Handy for “press any key” screens.

- **Key ‹Key› is pressed twice (within ‹Gap, s› s)** — `key.double_tap`
  A double press: true at the moment of the second press if it came faster than the gap. A dash on a double tap; 0.3 seconds is the usual gap.
  Parameters: Key (name without quotes), Gap, s (number)

- **Key ‹Key› is held longer than ‹Seconds› s** — `key.held`
  A long press: true while the key is held longer than N seconds. For charging a shot, running, opening a door by holding.
  Parameters: Key (name without quotes), Seconds (number)

- **Key ‹Key› is pressed (once)** — `key.just_pressed`
  Triggers once at the moment of pressing. For jumping, shooting, opening a menu.
  Parameters: Key (name without quotes)

- **The last key pressed is ‹Key›** — `key.last_is`
  Remembers the last key pressed even after it is released. For a “press a key to bind the action” screen.
  Parameters: Key (name without quotes)

- **Key ‹Key› is pressed** — `key.pressed`
  True while the key is held down. For continuous actions — running, flying, aiming.
  Parameters: Key (name without quotes)

- **Key ‹Key› is released (once)** — `key.released`
  Triggers once at the moment of release. Good for a charged hit: the longer it was held, the stronger.
  Parameters: Key (name without quotes)

- **Key ‹Key› is released after holding longer than ‹Seconds› s** — `key.released_after`
  A charged shot: true in the frame of release if it was held long enough. Released earlier — a normal shot by “released”.
  Parameters: Key (name without quotes), Seconds (number)

### Lists

- **List ‹List› contains ‹What to look for›** — `list.contains`
  Whether the list has such an item: the inventory has a key — the door opens.
  Parameters: List (variable name), What to look for (text)

- **List ‹List› is empty** — `list.empty`
  The list has nothing: the waves are over — victory.
  Parameters: List (variable name)

### Mouse

- **Mouse button ‹1 LMB, 2 RMB› is held** — `mouse.button`
  True while the mouse button is held: 1 — left, 2 — right, 3 — middle.
  Parameters: 1 LMB, 2 RMB (number)

- **‹Object› was clicked** — `mouse.click_object`
  A left click exactly on the object. The basis for buttons and unit selection.
  Parameters: Object (object)

- **The mouse is moving** — `mouse.moved`
  True on frames when the cursor moved. Lets you show a crosshair only while the mouse moves.

- **Cursor is over ‹Object›** — `mouse.over`
  The cursor is inside the object. Keeps picked only the instances under the cursor.
  Parameters: Object (object)

- **Mouse button ‹1 left, 2 right› is released (once)** — `mouse.released`
  Triggers at the moment of release: 1 — left, 2 — right, 3 — middle. For a charged throw and for dragging.
  Parameters: 1 left, 2 right (number)

- **‹Object› was right-clicked** — `mouse.right_object`
  A right click exactly on the object. For context commands and cancelling an order.
  Parameters: Object (object)

- **Mouse wheel ‹Sign› ‹Clicks›** — `mouse.wheel`
  Compares the wheel turn per frame: up — plus, down — minus. For zooming and scrolling.
  Parameters: Sign (= ≠ < > ≤ ≥), Clicks (number)

### Movement

- **Angle of ‹Object› ‹Sign› ‹Degrees›** — `object.angle`
  Compares the object's rotation in degrees: 0 — right, 90 — down, 180 — left.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Degrees (number)

- **‹Object› is inside area ‹Corner X› ; ‹Corner Y› of size ‹Width› × ‹Height›** — `object.in_rect`
  The object is inside a rectangular area. For zones, triggers and level bounds.
  Parameters: Object (object), Corner X (number), Corner Y (number), Width (number), Height (number)

- **X of ‹Object› ‹Sign› ‹Value›** — `object.x`
  Compares the object's X coordinate. Keeps picked only the instances for which the comparison is true.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **Y of ‹Object› ‹Sign› ‹Value›** — `object.y`
  Compares the object's Y coordinate. For example, “Y greater than 600” — the object fell below the bottom edge.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

### Objects

- **‹Object› is attached** — `object.attached`
  The object is attached to another one — an item in hands.
  Parameters: Object (object)

- **‹What› is attached to ‹To what›** — `object.attached_to`
  The first object is attached exactly to the second one. Keeps such pairs in the picking.
  Parameters: What (object), To what (object)

- **Number of ‹Object› objects ‹Sign› ‹Count›** — `object.count`
  Compares the number of picked instances. Important: it counts the picked ones, not all alive.
  Parameters: Object (object name), Sign (= ≠ < > ≤ ≥), Count (number)

- **‹Object› exists in the scene** — `object.exists`
  At least one living instance. Unlike “number of objects”, it looks at all living instances rather than the picked ones and does not narrow the picking — handy for checking “no enemies left”.
  Parameters: Object (object name)

### Picking

- **Pick all ‹Object›** — `pick.all`
  Resets the narrowing and puts all instances of the object back into the picking. Needed when the picking was narrowed higher up in the event.
  Parameters: Object (object)

- **Pick the ‹Object› farthest from point ‹X› ; ‹Y›** — `pick.farthest`
  Keeps picked the instance farthest from the point.
  Parameters: Object (object), X (number), Y (number)

- **Pick all ‹Object› within radius ‹Radius› of point ‹X› ; ‹Y›** — `pick.in_radius`
  Keeps in the picking everyone closer to the point than the radius. An explosion hits everyone nearby, not just one.
  Parameters: Object (object), X (number), Y (number), Radius (number)

- **Pick all ‹Object› within radius ‹Radius› of ‹Center›** — `pick.in_radius_of`
  Keeps in the picking everyone closer than the radius to a picked object: “all Enemy within 80 of Explosion”.
  Parameters: Object (object), Center (object), Radius (number)

- **Pick the ‹Object› nearest to point ‹X› ; ‹Y›** — `pick.nearest`
  Keeps one instance picked — the nearest to the point. The following actions work only with it.
  Parameters: Object (object), X (number), Y (number)

- **Pick the ‹Object› nearest to object ‹To whom›** — `pick.nearest_to`
  Narrows both lists to one pair: the object and the other object nearest to it. “An enemy shoots at the nearest player” — this is it.
  Parameters: Object (object), To whom (object)

- **Pick a random ‹Object›** — `pick.random`
  Keeps one random instance picked. For random bonuses and lines.
  Parameters: Object (object)

### Saving

- **Save ‹Slot name› exists** — `save.exists`
  There is a save in the slot. For a “Continue” button that makes no sense in a fresh game.
  Parameters: Slot name (name without quotes)

### Scene

- **A fade transition is running** — `scene.fading`
  The screen is darkening or appearing right now — for example, so as not to start the transition a second time.

- **The game is paused** — `scene.paused`
  The game is paused. Check it so the pause menu does not react twice.

### Sound

- **Music is playing** — `audio.music_playing`
  Background music is playing right now.

### System

- **Always** — `system.always`
  Always true. Used when the actions must run every frame without any checks.

- **At the beginning of the scene** — `system.at_start`
  True only on the first frame of the scene. The place for initial setup and resetting the score.

- **Chance ‹Percent› % per frame** — `system.chance`
  Triggers randomly with the given probability every frame. For rare events and variety.
  Parameters: Percent (number)

- **‹First value› ‹Sign› ‹Second value›** — `system.compare`
  Compare any two numbers or expressions: Player.Frame() = 3, Enemy.DistanceTo(Player) < 50, Variable(score) ≥ Variable(best). Covers lots of small cases at once.
  Parameters: First value (number), Sign (= ≠ < > ≤ ≥), Second value (number)

- **Text ‹First text› ‹Sign› ‹Second text›** — `system.compare_text`
  Compare two texts: Player.Animation() = "Run", VariableString(state) ≠ "menu". Usually “=” and “≠” are needed.
  Parameters: First text (text), Sign (= ≠ < > ≤ ≥), Second text (text)

- **Every ‹Seconds› seconds** — `system.every`
  Triggers at equal intervals. Replaces the “timer + reset timer” pair.
  Parameters: Seconds (number)

- **Trigger once while true** — `system.trigger_once`
  Lets the event through once while the other conditions are true. Without it the action would repeat every frame.

- **A wait is running (“Wait”)** — `system.waiting`
  True while something in this sheet is delayed by the “Wait” action and has not run yet. So as not to start the same thing a second time.

### Text

- **Text of ‹Object› equals ‹Text›** — `object.text`
  The text inside the object matches the given one. Looks for a Label or RichTextLabel anywhere in the object.
  Parameters: Object (object), Text (text)

- **Text of ‹Object› contains ‹What to look for›** — `object.text_contains`
  Checks for a substring rather than a full match.
  Parameters: Object (object), What to look for (text)

### Timers

- **Timer ‹Timer› of ‹Object› ‹Sign› ‹Seconds› s** — `object.timer`
  Every instance has its own timer: “timer shot of Enemy > 2” — and every enemy shoots at its own time, not all in chorus. The timer starts by itself at the first check.
  Parameters: Object (object), Timer (name without quotes), Sign (= ≠ < > ≤ ≥), Seconds (number)

- **Timer ‹Timer› ‹Sign› ‹Seconds› s** — `timer.compare`
  Compares the timer's time in seconds. The timer runs by itself and is reset with the “Reset timer” action.
  Parameters: Timer (name without quotes), Sign (= ≠ < > ≤ ≥), Seconds (number)

- **Timer ‹Timer name› is paused** — `timer.paused`
  True while the timer is stopped by the “pause” action.
  Parameters: Timer name (name without quotes)

### Tweens

- **‹Object› is tweening** — `tween.running`
  True while the object moves, rotates or fades by itself. Lets you wait for the end instead of guessing by time.
  Parameters: Object (object)

### Variables

- **Global variable ‹Variable› ‹Sign› ‹Value›** — `gvar.compare`
  Compares a global variable. Such variables survive scene changes — high scores, money, progress.
  Parameters: Variable (variable name), Sign (= ≠ < > ≤ ≥), Value (number)

- **Variable ‹Variable› of ‹Object› ‹Sign› ‹Value›** — `object.variable`
  Compares a variable that belongs to a specific instance. Each enemy has its own health — this is it.
  Parameters: Object (object), Variable (variable name), Sign (= ≠ < > ≤ ≥), Value (number)

- **Scene variable ‹Variable› ‹Sign› ‹Value›** — `var.compare`
  Compares a scene variable. Such variables live until the scene restarts.
  Parameters: Variable (variable name), Sign (= ≠ < > ≤ ≥), Value (number)

- **Text variable ‹Variable› equals ‹Text›** — `var.string_equals`
  Compares a text scene variable with a string. For states like “menu”, “game”, “pause”.
  Parameters: Variable (variable name), Text (text)

## Actions

### Animation

- **Animation speed of ‹Object›: ‹Speed›** — `object.animation_speed`
  Animation speed multiplier. 2 — twice as fast, 0.5 — twice as slow.
  Parameters: Object (object), Speed (number)

- **Pause the animation of ‹Object›: ‹1 yes, 0 no› (1 yes, 0 no)** — `object.pause_animation`
  Stops the animation on the current frame without resetting it.
  Parameters: Object (object), 1 yes, 0 no (number)

- **Play animation ‹Animation› on ‹Object›** — `object.play_animation`
  Starts an animation by name. The name must match the name in the object's SpriteFrames.
  Parameters: Object (object), Animation (name without quotes)

### Appearance

- **Blink ‹Object›: ‹Seconds› seconds, ‹How many times› times** — `object.blink`
  The object disappears and reappears N times. The usual reaction to damage and pickups.
  Parameters: Object (object), Seconds (number), How many times (number)

- **Flip ‹Object› horizontally: ‹1 yes, 0 no›** — `object.flip_h`
  Flips the object horizontally. 1 — faces left, 0 — right. Read with the “flipped horizontally” condition.
  Parameters: Object (object), 1 yes, 0 no (number)

- **Flip ‹Object› vertically: ‹1 yes, 0 no›** — `object.flip_v`
  Turns the object upside down. 1 — flip, 0 — restore.
  Parameters: Object (object), 1 yes, 0 no (number)

- **Tint of ‹Object›: R ‹Red›, G ‹Green›, B ‹Blue›** — `object.set_color`
  Colors the object with a color multiplier. All three at 1 — normal look, R 1 G 0 B 0 — a red damage flash.
  Parameters: Object (object), Red (number), Green (number), Blue (number)

- **Opacity of ‹Object›: ‹0…1› (0…1)** — `object.set_opacity`
  Sets opacity from 0 to 1. Lower it a little every frame — you get a fade-out.
  Parameters: Object (object), 0…1 (number)

- **Change the scale of ‹Object› to ‹Scale›** — `object.set_scale`
  Changes the object's size along both axes at once. 1 — original size.
  Parameters: Object (object), Scale (number)

- **Scale of ‹Object›: X ‹X›, Y ‹Y›** — `object.set_scale_xy`
  Changes the size along each axis separately. A negative X value flips the object.
  Parameters: Object (object), X (number), Y (number)

- **Show/hide ‹Object›: ‹1 show, 0 hide›** — `object.set_visible`
  Shows or hides the object with all its contents. 1 — show, 0 — hide.
  Parameters: Object (object), 1 show, 0 hide (number)

- **Draw order of ‹Object›: ‹Layer›** — `object.set_z`
  Sets the draw order. Higher — drawn on top of the others.
  Parameters: Object (object), Layer (number)

### Camera

- **Center the camera on ‹Object›** — `camera.center`
  Puts the camera exactly on the object — instantly, without smoothing.
  Parameters: Object (object)

- **The camera follows ‹Whom to follow› with smoothing ‹Tweens›** — `camera.follow`
  The camera smoothly follows the object. Smoothing 0 — glued tight, 10 — lags noticeably.
  Parameters: Whom to follow (object), Tweens (number)

- **Put the camera at ‹X› ; ‹Y›** — `camera.move`
  Moves the camera to the point.
  Parameters: X (number), Y (number)

- **Shake the camera: strength ‹Strength›, ‹Seconds› seconds** — `camera.shake`
  Shakes the camera with a fade-out. For explosions and hits.
  Parameters: Strength (number), Seconds (number)

- **The camera stops following anyone** — `camera.stop_follow`
  Detaches the camera from the object.

- **Camera zoom: ‹Scale›** — `camera.zoom`
  Zooms the camera in or out. Greater than 1 — closer.
  Parameters: Scale (number)

### Clock

- **Rotate ‹Object› like clock hand ‹Hand› (0 hour, 1 minute, 2 second)** — `Clock::point_hand`
  Rotates the object like a clock hand: 0 — hour, 1 — minute, 2 — second.
  Parameters: Object (object), Hand (number)

- **Store the current time in variable ‹Variable›** — `Clock::store_time`
  Puts the time as “13:05” into a text scene variable.
  Parameters: Variable (text)

### Effects

- **Effect ‹Effect: explosion, sparks, dust, smoke, magic, confetti› at point ‹X› ; ‹Y›, size ‹Size, 1 — normal›** — `effect.at`
  Ready-made particles, no pictures needed: explosion, sparks, dust, smoke, magic, confetti. The names can be written in Russian too.
  Parameters: Effect: explosion, sparks, dust, smoke, magic, confetti (name without quotes), X (number), Y (number), Size, 1 — normal (number)

- **Effect ‹Effect: explosion, sparks, dust, smoke, magic, confetti› at ‹Object›, size ‹Size, 1 — normal›** — `effect.at_object`
  The same effect where each picked instance stands: an enemy blew up, a coin burst into sparks.
  Parameters: Object (object), Effect: explosion, sparks, dust, smoke, magic, confetti (name without quotes), Size, 1 — normal (number)

- **Screen flash: color ‹Color: white, red, #ff8800…›, ‹Seconds› s, strength ‹Strength, 0…1› (0…1)** — `effect.flash`
  The screen flashes and fades: white on an explosion, red on damage. Strength 0.5 is a half-transparent flash.
  Parameters: Color: white, red, #ff8800… (name without quotes), Seconds (number), Strength, 0…1 (number)

- **Floating text ‹Text› above ‹Object›, color ‹Color: white, red, yellow, #ff8800…›** — `effect.float_text`
  “−3”, “+1 coin”: the text pops above the object, flies up and fades. The color is an English name or #ff8800.
  Parameters: Object (object), Text (text), Color: white, red, yellow, #ff8800… (name without quotes)

- **Hit stop for ‹Seconds, 0.05…0.1› s** — `effect.hitstop`
  The game freezes for a moment on a hit — 0.05–0.1 seconds. Cheap, and the hit immediately feels heavier.
  Parameters: Seconds, 0.05…0.1 (number)

### Gamepad

- **Stop the gamepad vibration** — `gamepad.stop_vibration`
  Stops the vibration at once.

- **Gamepad vibration: weak motor ‹Weak motor, 0…1›, strong ‹Strong motor, 0…1›, ‹Seconds› s** — `gamepad.vibrate`
  Shake the gamepad on a hit or an explosion. The weak motor is a fine tremble, the strong one a heavy blow. Without a gamepad a phone vibrates.
  Parameters: Weak motor, 0…1 (number), Strong motor, 0…1 (number), Seconds (number)

### Lists

- **Add text ‹Text› to list ‹List›** — `list.add`
  A list is a scene variable: an inventory, a queue of waves, lines. It is created if it does not exist yet. Text goes in quotes: "key".
  Parameters: List (variable name), Text (text)

- **Add number ‹Number› to list ‹List›** — `list.add_number`
  A number to the end of the list: wave points, level numbers.
  Parameters: List (variable name), Number (number)

- **Clear list ‹List›** — `list.clear`
  The list becomes empty.
  Parameters: List (variable name)

- **Remove item number ‹Number, from zero› from list ‹List›** — `list.remove_at`
  Removes an item by its number: 0 is the first one.
  Parameters: List (variable name), Number, from zero (number)

- **Remove item ‹What to remove› from list ‹List›** — `list.remove_value`
  Removes the first such item: a spent key is gone. Numbers and text compare the same way: 5 and "5" are one thing.
  Parameters: List (variable name), What to remove (text)

- **Shuffle list ‹List›** — `list.shuffle`
  A random order: a deck of cards, the order of waves.
  Parameters: List (variable name)

- **Take the first item of list ‹List› into variable ‹Variable›** — `list.take_first`
  A queue: the first item leaves the list for a scene variable. An empty list gives empty text.
  Parameters: List (variable name), Variable (variable name)

### Movement

- **Change the angle of ‹Object›: ‹Sign› ‹Degrees› degrees** — `object.angle`
  Rotates the object. Degrees: 0 — right, 90 — down.
  Parameters: Object (object), Sign (= + - * /), Degrees (number)

- **Keep ‹Object› inside area ‹Corner X› ; ‹Corner Y› of size ‹Width› × ‹Height›** — `object.clamp_rect`
  Does not let the object leave the rectangle. Keeps the player within the level bounds.
  Parameters: Object (object), Corner X (number), Corner Y (number), Width (number), Height (number)

- **Push ‹Object› away from ‹Object› by ‹Pixels›** — `object.knockback`
  Moves the object in a straight line away from another one. A companion of damage: a hit should knock back.
  Parameters: Object (object), Object (object), Pixels (number)

- **Turn ‹Object› toward point ‹X› ; ‹Y›** — `object.look_at`
  Turns the object nose-first toward the point. For turrets and aiming at the mouse.
  Parameters: Object (object), X (number), Y (number)

- **Turn ‹Who› toward object ‹To whom›** — `object.look_at_object`
  Turns the object toward another object.
  Parameters: Who (object), To whom (object)

- **Move ‹Object› at angle ‹Degrees› by ‹Distance›** — `object.move_angle`
  Moves the object at an angle: 0 — right, 90 — down. Multiply the distance by TimeDelta() so the speed does not depend on the frame rate.
  Parameters: Object (object), Degrees (number), Distance (number)

- **Move ‹Object› by ‹by X› ; ‹by Y›** — `object.move_by`
  Moves the object by the given offset from its current place.
  Parameters: Object (object), by X (number), by Y (number)

- **Move ‹Object› toward point ‹X› ; ‹Y› by ‹Pixels›** — `object.move_to`
  Moves the object toward the point by the given number of pixels per frame. Repeat every frame — you get smooth movement.
  Parameters: Object (object), X (number), Y (number), Pixels (number)

- **Move ‹Who› toward object ‹To whom› by ‹Pixels›** — `object.move_to_object`
  The same, but the target is another object. The simplest chase without a separate behavior.
  Parameters: Who (object), To whom (object), Pixels (number)

- **Put ‹Who› next to ‹To whom› with offset ‹Offset X› ; ‹Offset Y›** — `object.place_at`
  Puts the object right next to another one with an offset. For a health bar above an enemy or a muzzle flash.
  Parameters: Who (object), To whom (object), Offset X (number), Offset Y (number)

- **Put ‹Object› at position ‹X› ; ‹Y›** — `object.set_position`
  Moves the object to the point instantly, without animation.
  Parameters: Object (object), X (number), Y (number)

- **Change X of ‹Object›: ‹Sign› ‹Value›** — `object.x`
  Changes the X coordinate. The “=” sign sets the value, “+” moves right, “−” left.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change Y of ‹Object›: ‹Sign› ‹Value›** — `object.y`
  Changes the Y coordinate. The axis points down: “+” lowers the object.
  Parameters: Object (object), Sign (= + - * /), Value (number)

### Objects

- **Attach ‹What› to ‹To what› with an offset of ‹Offset X› ; ‹Offset Y›** — `object.attach`
  Pick up an item, take a weapon in hand: the object stands at an offset from the nearest picked second object and then moves together with it. A body stops falling for that time.
  Parameters: What (object), To what (object), Offset X (number), Offset Y (number)

- **Attach ‹What› to ‹To what› where it is now** — `object.attach_here`
  Like an arrow stuck in an enemy: it stays where it is but then moves together with the object.
  Parameters: What (object), To what (object)

- **Create object ‹Object› at position ‹X› ; ‹Y›** — `object.create`
  Creates a new instance of the object at the point. The created one is picked right away, and the following actions work with it.
  Parameters: Object (object name), X (number), Y (number)

- **Create ‹What to create› at object ‹Where› with offset ‹Offset X› ; ‹Offset Y›** — `object.create_at`
  Creates an object next to another object. For an explosion where something died, a dropped reward, a muzzle flash.
  Parameters: What to create (object name), Where (object), Offset X (number), Offset Y (number)

- **Delete object ‹Object›** — `object.delete`
  Removes the object from the game. The deleted one leaves the picking at once, so the following actions do not touch it.
  Parameters: Object (object)

- **Delete all ‹Object›** — `object.delete_all`
  Removes all instances from the scene at once, regardless of the picking. For clearing the level between waves.
  Parameters: Object (object name)

- **Detach ‹Object›** — `object.detach`
  Drop an item: the object stays where it was and lives on its own again.
  Parameters: Object (object)

- **Duplicate ‹Object› with its variables at an offset of ‹Offset X› ; ‹Offset Y›** — `object.duplicate`
  A copy of every picked instance — with its variables and behavior settings. The copy's variables are its own. The copies are picked afterwards.
  Parameters: Object (object), Offset X (number), Offset Y (number)

### Physics

- **Push ‹Object› at angle ‹Degrees› with force ‹Strength›** — `physics.impulse`
  Gives a physics body a one-time push. Works only with RigidBody2D.
  Parameters: Object (object), Degrees (number), Strength (number)

### Saving

- **Delete save ‹Slot name›** — `save.delete`
  Erases the save in the slot.
  Parameters: Slot name (name without quotes)

- **Load variables from slot ‹Slot name›** — `save.load`
  Reads the variables from the slot back into the game.
  Parameters: Slot name (name without quotes)

- **Save variables to slot ‹Slot name›** — `save.save`
  Writes all variables to a slot on disk. A slot is just a number or a name.
  Parameters: Slot name (name without quotes)

### Scene

- **Go to scene ‹Scene path›** — `scene.change`
  Switches to another scene. Scene variables are lost, global ones stay.
  Parameters: Scene path (name without quotes)

- **Go to scene ‹Scene path› with a fade over ‹Seconds› s, color ‹Color: black, white…›** — `scene.change_fade`
  The screen smoothly darkens, the scene changes and the new one smoothly appears — instead of a sudden switch. Works from a pause menu too.
  Parameters: Scene path (name without quotes), Seconds (number), Color: black, white… (name without quotes)

- **Pause the game: ‹1 yes, 0 no› (1 yes, 0 no)** — `scene.pause`
  Pauses or unpauses the game. 1 — paused, 0 — playing.
  Parameters: 1 yes, 0 no (number)

- **Restart the current scene** — `scene.restart`
  Restarts the current scene from scratch.

- **Time scale: ‹Multiplier›** — `scene.time_scale`
  Time speed: 1 — normal, 0.3 — slow motion, 2 — fast forward.
  Parameters: Multiplier (number)

### Sound

- **Music volume: ‹dB› dB** — `audio.music_volume`
  Changes the music volume in decibels without interrupting it.
  Parameters: dB (number)

- **Play sound ‹Sound file› (volume ‹dB› dB)** — `audio.play`
  Plays a sound once. Volume in decibels: 0 — as is, −10 — quieter.
  Parameters: Sound file (name without quotes), dB (number)

- **Play music ‹Music file› (volume ‹dB› dB)** — `audio.play_music`
  Starts looping background music. Separate from sound effects, so it has its own volume.
  Parameters: Music file (name without quotes), dB (number)

- **Play sound ‹Sound file› (volume ‹Volume, dB› dB, pitch ‹Height›)** — `audio.play_pitch`
  Pitch 1 — as in the file, 1.2 — higher and faster. A random pitch within 0.9…1.1 avoids the “machine-gun” repetition of the same sound.
  Parameters: Sound file (name without quotes), Volume, dB (number), Height (number)

- **Stop all sounds** — `audio.stop`
  Silences all sound effects at once. Does not touch the music.

- **Stop the music** — `audio.stop_music`
  Stops the background music.

### System

- **Remove the lines from the screen** — `debug.clear`
  Erases the shown values and the log.

- **Write on screen: ‹Text›** — `debug.log`
  A line into a log on top of the game: the last eight lines stay for a few seconds. Handy to see that an event fired.
  Parameters: Text (text)

- **Show on screen ‹Label›: ‹Value›** — `debug.show`
  A line in the corner on top of the game instead of the console: you see what is going on right while playing. Put it in an event without conditions — the value updates every frame and disappears when it is no longer shown.
  Parameters: Label (text), Value (text)

- **Print ‹Text› to the console** — `system.print`
  Writes a line to the editor console. The main tool when an event behaves differently than expected.
  Parameters: Text (text)

- **Quit the game** — `system.quit`
  Closes the game.

- **Wait ‹Seconds› seconds, then everything below** — `system.wait`
  Everything below in this event and its sub-events run after N seconds — with the same picked objects. Like “Wait” in GDevelop: a flash, a pause, an explosion.
  Parameters: Seconds (number)

### Text

- **Append to the text of ‹Object›: ‹Text›** — `object.append_text`
  Appends text at the end. For a running line and logs.
  Parameters: Object (object), Text (text)

- **Set the text of ‹Object›: ‹Text›** — `object.set_text`
  Writes text into a Label or RichTextLabel inside the object. Wrap numbers in ToString().
  Parameters: Object (object), Text (text)

### Timers

- **Pause timer ‹Timer› of ‹Object›: ‹1 pause, 0 go on› (1 yes, 0 no)** — `object.timer_pause`
  Stops or restarts the timer of an instance: a stunned enemy does not gather time until its shot.
  Parameters: Object (object), Timer (name without quotes), 1 pause, 0 go on (number)

- **Reset timer ‹Timer› of ‹Object›** — `object.timer_reset`
  Zeroes the timer of every picked instance — for the others it keeps running.
  Parameters: Object (object), Timer (name without quotes)

- **Delete timer ‹Timer name›** — `timer.delete`
  Removes the timer completely. The next use starts counting from zero.
  Parameters: Timer name (name without quotes)

- **Pause timer ‹Timer name›: ‹1 yes, 0 no›** — `timer.pause`
  1 — the timer freezes, 0 — it continues from the same point. Separate from reset: pausing does not lose the accumulated time.
  Parameters: Timer name (name without quotes), 1 yes, 0 no (number)

- **Reset timer ‹Timer›** — `timer.reset`
  Resets the timer to zero and starts counting again.
  Parameters: Timer (name without quotes)

### Tweens

- **Smoothly move ‹Object› to ‹X› ; ‹Y› over ‹Seconds› s** — `tween.move`
  The object travels to the point by itself in the given time. Replaces a “move every frame” event with its own counter. A new smooth movement cancels the previous one.
  Parameters: Object (object), X (number), Y (number), Seconds (number)

- **Smoothly move ‹Object› by ‹How far by X› ; ‹How far by Y› over ‹Seconds› s** — `tween.move_by`
  The same, but the offset is counted from the current place. For hops, bounces and sliding panels.
  Parameters: Object (object), How far by X (number), How far by Y (number), Seconds (number)

- **Smoothly change the opacity of ‹Object› to ‹Opacity 0…1› over ‹Seconds› s** — `tween.opacity`
  Fading in and out. 1 — opaque, 0 — invisible.
  Parameters: Object (object), Opacity 0…1 (number), Seconds (number)

- **Smoothly rotate ‹Object› to ‹Degrees› degrees over ‹Seconds› s** — `tween.rotate`
  A smooth turn to the angle. 0 — right, 90 — down.
  Parameters: Object (object), Degrees (number), Seconds (number)

- **Smoothly scale ‹Object› to ‹Scale› over ‹Seconds› s** — `tween.scale`
  Smooth growing or shrinking. 1 — original size.
  Parameters: Object (object), Scale (number), Seconds (number)

- **Stop the tweens of ‹Object›** — `tween.stop`
  Stops a started smooth movement on the spot. Needed when something takes over the object — for example, the player pushed something that was moving by itself.
  Parameters: Object (object)

### Variables

- **Change global variable ‹Variable›: ‹Sign› ‹Value›** — `gvar.modify`
  Changes a global variable — it survives scene changes.
  Parameters: Variable (variable name), Sign (= + - * /), Value (number)

- **Change variable ‹Variable› of ‹Object›: ‹Sign› ‹Value›** — `object.variable`
  Changes the variable of a specific instance — each enemy has its own health.
  Parameters: Object (object), Variable (variable name), Sign (= + - * /), Value (number)

- **Change scene variable ‹Variable›: ‹Sign› ‹Value›** — `var.modify`
  Changes a scene variable. It lives until the scene restarts.
  Parameters: Variable (variable name), Sign (= + - * /), Value (number)

- **Text variable ‹Variable› = ‹Text›** — `var.set_string`
  Puts a string into a scene variable. For states and names.
  Parameters: Variable (variable name), Text (text)

- **Toggle variable ‹Variable› (0 ↔ 1)** — `var.toggle`
  Toggles the variable between 0 and 1. One action instead of an event with two branches.
  Parameters: Variable (variable name)

## Expressions

Common expressions are written as `Name(…)`, object expressions as `Object.Name(…)`, behavior expressions as `Object.Behavior::Name(…)`.

| Expression | Gives | What it is |
| --- | --- | --- |
| `AngleBetween(number, number, number, number)` | number | The angle in degrees from the first point to the second: AngleBetween(x1, y1, x2, y2). |
| `Count(raw)` | number | How many instances of an object are picked now: Count(Enemy). |
| `Distance(number, number, number, number)` | number | The distance between two points: Distance(x1, y1, x2, y2). |
| `GlobalVariable(varname)` | number | A number from a global variable — it lives across scenes: GlobalVariable(coins). |
| `InstanceCount(string)` | number | How many instances of the object are alive in the scene — all of them, not just the picked ones. |
| `KeyHeldTime(raw)` | number | How many seconds a key is held: KeyHeldTime(Space). Throw strength, a charge. |
| `LastKey()` | text | The name of the last key pressed. |
| `Length(string)` | number | How many characters are in the string. |
| `ListCount(varname)` | number | How many items the list has: ListCount(inventory). |
| `ListItem(varname, number)` | text | An item by number, as text: ListItem(inventory, 0) — the first one. |
| `ListJoin(varname, string)` | text | All items in one line with a separator: ListJoin(inventory, ", "). |
| `ListNumber(varname, number)` | number | An item by number, as a number: ListNumber(waves, 2). |
| `ListRandom(varname)` | text | A random item: ListRandom(phrases) — a random line. |
| `Lowercase(string)` | text | The string in lower case. |
| `MouseWheel()` | number | How many notches the wheel turned this frame: up is above zero. |
| `MouseX()` | number | The X of the mouse cursor in the game world (camera included). |
| `MouseY()` | number | The Y of the mouse cursor in the game world (camera included). |
| `Pad(number, number)` | text | A number with leading zeros: Pad(7, 3) gives “007”. For score and timers on screen. |
| `Random(number)` | number | A random whole number from 0 up to the number, inclusive. Random(5) — one of 0, 1, 2, 3, 4, 5. |
| `RandomInRange(number, number)` | number | A random fractional number from the first to the second. RandomInRange(-50, 50) — a spread of ±50. |
| `RightStickX()` | number | Right stick horizontally: for aiming. |
| `RightStickY()` | number | Right stick vertically. |
| `SceneName()` | text | The name of the current scene. |
| `SceneTime()` | number | Seconds since the scene started. |
| `ScreenHeight()` | number | The height of the game window in pixels. |
| `ScreenWidth()` | number | The width of the game window in pixels. |
| `StickX()` | number | Left stick horizontally: from -1 (left) to 1 (right). |
| `StickY()` | number | Left stick vertically: from -1 (up) to 1 (down). |
| `Substring(string, number, number)` | text | A piece of the string: where from (the first character is zero) and how many characters. |
| `TimeDelta()` | number | Seconds since the previous frame. Multiply speeds by it: 200 * TimeDelta() — 200 pixels per second at any FPS. |
| `TimeScale()` | number | The current time scale: 1 — normal, 0.5 — slow motion. |
| `TimeText(number)` | text | Seconds shown as 1:05 — the usual look of an on-screen timer. |
| `Timer(raw)` | number | Seconds on a scene timer: Timer(spawn). |
| `ToDeg(number)` | number | Radians to degrees. |
| `ToNumber(string)` | number | Text as a number: ToNumber("42") — 42. Not a number — 0. |
| `ToRad(number)` | number | Degrees to radians: ToRad(180) — 3.14…. |
| `ToString(number)` | text | A number as text: "Score: " + ToString(Variable(score)). Whole numbers without ".0". |
| `Uppercase(string)` | text | The string in upper case. |
| `Variable(varname)` | number | A number from a scene variable (or an event local variable): Variable(score), Variable(player.hp). |
| `VariableString(varname)` | text | Text from a scene variable: VariableString(name). |
| `VariableText(varname)` | text | A scene variable as text — a number becomes text too. |
| `abs(number)` | number | The number without its sign: abs(-5) — 5. |
| `atan2(number, number)` | number | An angle in radians from dy and dx: atan2(dy, dx). |
| `ceil(number)` | number | Rounds up: ceil(2.1) — 3. |
| `clamp(number, number, number)` | number | A number held within bounds: clamp(Variable(hp), 0, 100). |
| `cos(number)` | number | Cosine of an angle in radians. For degrees: cos(ToRad(45)). |
| `floor(number)` | number | Rounds down: floor(2.7) — 2. |
| `lerp(number, number, number)` | number | A blend: lerp(from, to, weight). lerp(0, 100, 0.25) — 25. |
| `max(number, number)` | number | The larger of two: max(Variable(hp), 0) — never below zero. |
| `min(number, number)` | number | The smaller of two: min(Variable(hp), 100). |
| `pow(number, number)` | number | Power: pow(2, 3) — 8. |
| `round(number)` | number | Rounds to the nearest whole number: round(2.5) — 3. |
| `sign(number)` | number | The sign of a number: -1, 0 or 1. |
| `sin(number)` | number | Sine of an angle in radians. A bob: sin(SceneTime() * 3) * 10. |
| `sqrt(number)` | number | Square root: sqrt(16) — 4. |
| `tan(number)` | number | Tangent of an angle in radians. |
| `Object.Angle()` | number | The rotation angle in degrees. |
| `Object.AngleTo(raw)` | number | The angle in degrees to another object: Turret.AngleTo(Player). |
| `Object.Animation()` | text | The name of the current animation. |
| `Object.Count()` | number | How many instances are picked: Enemy.Count(). |
| `Object.DistanceTo(raw)` | number | The distance to the first picked instance of another object: Enemy.DistanceTo(Player). |
| `Object.Facing()` | number | Where the object faces: 1 — right, −1 — left. Multiply by a speed, and a projectile flies the same way. |
| `Object.Flipped()` | number | 1 if the object is flipped horizontally, otherwise 0. |
| `Object.Frame()` | number | The current animation frame number, from zero. |
| `Object.Height()` | number | The object's height from its collision shape or picture. |
| `Object.Opacity()` | number | Opacity from 0 (invisible) to 1. |
| `Object.ScaleX()` | number | The horizontal scale. |
| `Object.ScaleY()` | number | The vertical scale. |
| `Object.Text()` | text | The text of a label. |
| `Object.Timer(raw)` | number | Seconds on the timer of an instance: Enemy.Timer(shot). |
| `Object.Variable(varname)` | number | A number from an instance variable: Enemy.Variable(hp). |
| `Object.Width()` | number | The object's width from its collision shape or picture. |
| `Object.X()` | number | The X of the first picked instance: Player.X(). |
| `Object.Y()` | number | The Y of the first picked instance: Player.Y(). |
| `Object.ZIndex()` | number | Drawing order: higher is closer to the viewer. |
| `Clock::Hour()` | number | Current hour, 0…23 |
| `Clock::Minute()` | number | Current minute, 0…59 |
| `Clock::Second()` | number | Current second, 0…59 |
| `Clock::TimeText()` | text | Time as text, e.g. 13:05 |
| `Clock::UnixTime()` | number | Seconds since January 1, 1970 — for daily reward timers |
| `Clock::Weekday()` | number | Day of the week: 1 — Monday, 7 — Sunday |

## Behaviors

### Ability — Ability with cooldown

A dash, a shield or healing on a key — with a cooldown and charges, without events. A "custom" ability does nothing by itself: it only counts charges, and events decide what to do by the "has just been used" condition.

**Conditions**

- **The ability of ‹Object› is ready** — `Ability::can_use`
  From the “Ability with cooldown” behavior.
  Parameters: Object (object)

- **The ability of ‹Object› is in effect (a dash or a shield)** — `Ability::is_active`
  From the “Ability with cooldown” behavior.
  Parameters: Object (object)

- **“Recharge time of one charge” of ‹Object› (Ability with cooldown) ‹Sign› ‹Value›** — `Ability::is_cooldown`
  Setting of the “Ability with cooldown” behavior, section “Ability”. Recharge time of one charge, seconds.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Where to dash” of ‹Object› (Ability with cooldown) ‹Sign› ‹Value›** — `Ability::is_dash_direction`
  Setting of the “Ability with cooldown” behavior, section “Dash”. Where to dash: along the movement (standing — where it faces) or always where it faces.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Dash speed” of ‹Object› (Ability with cooldown) ‹Sign› ‹Value›** — `Ability::is_dash_speed`
  Setting of the “Ability with cooldown” behavior, section “Dash”. Dash speed, pixels per second.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Duration of a dash or a shield” of ‹Object› (Ability with cooldown) ‹Sign› ‹Value›** — `Ability::is_duration`
  Setting of the “Ability with cooldown” behavior, section “Ability”. Duration of a dash or a shield, seconds.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“How much health it heals” of ‹Object› (Ability with cooldown) ‹Sign› ‹Value›** — `Ability::is_heal_amount`
  Setting of the “Ability with cooldown” behavior, section “Shield and healing”. How much health it heals.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Keep part of the speed after the dash” of ‹Object› (Ability with cooldown) ‹Sign› ‹Value›** — `Ability::is_keep_speed`
  Setting of the “Ability with cooldown” behavior, section “Dash”. Keep part of the speed after the dash, share.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Key” of ‹Object› (Ability with cooldown) ‹Sign› ‹Value›** — `Ability::is_key`
  Setting of the “Ability with cooldown” behavior, section “Ability”. Key, e.g. Shift. Empty — only by an action from the sheet.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (text)

- **“What it does” of ‹Object› (Ability with cooldown) ‹Sign› ‹Value›** — `Ability::is_kind`
  Setting of the “Ability with cooldown” behavior, section “Ability”. What it does: a dash, a shield (invulnerability through "Health"), healing or custom — charges only.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Charges” of ‹Object› (Ability with cooldown) ‹Sign› ‹Value›** — `Ability::is_max_charges`
  Setting of the “Ability with cooldown” behavior, section “Ability”. Charges — how many times in a row it can be used.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **A charge of the ability of ‹Object› has just been restored** — `Ability::just_recharged`
  From the “Ability with cooldown” behavior.
  Parameters: Object (object)

- **The ability of ‹Object› has just been used** — `Ability::just_used`
  From the “Ability with cooldown” behavior.
  Parameters: Object (object)

**Actions**

- **Add ‹Charges› charges to the ability of ‹Object›** — `Ability::add_charges`
  From the “Ability with cooldown” behavior.
  Parameters: Object (object), Charges (number)

- **Instantly recharge ‹Object›** — `Ability::refill`
  From the “Ability with cooldown” behavior.
  Parameters: Object (object)

- **Change “Recharge time of one charge” of ‹Object› (Ability with cooldown): ‹Sign› ‹Value›** — `Ability::set_cooldown`
  Setting of the “Ability with cooldown” behavior, section “Ability”. Recharge time of one charge, seconds.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Where to dash” of ‹Object› (Ability with cooldown): ‹Sign› ‹Value›** — `Ability::set_dash_direction`
  Setting of the “Ability with cooldown” behavior, section “Dash”. Where to dash: along the movement (standing — where it faces) or always where it faces.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Dash speed” of ‹Object› (Ability with cooldown): ‹Sign› ‹Value›** — `Ability::set_dash_speed`
  Setting of the “Ability with cooldown” behavior, section “Dash”. Dash speed, pixels per second.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Duration of a dash or a shield” of ‹Object› (Ability with cooldown): ‹Sign› ‹Value›** — `Ability::set_duration`
  Setting of the “Ability with cooldown” behavior, section “Ability”. Duration of a dash or a shield, seconds.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “How much health it heals” of ‹Object› (Ability with cooldown): ‹Sign› ‹Value›** — `Ability::set_heal_amount`
  Setting of the “Ability with cooldown” behavior, section “Shield and healing”. How much health it heals.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Keep part of the speed after the dash” of ‹Object› (Ability with cooldown): ‹Sign› ‹Value›** — `Ability::set_keep_speed`
  Setting of the “Ability with cooldown” behavior, section “Dash”. Keep part of the speed after the dash, share.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Key” of ‹Object› (Ability with cooldown): ‹Sign› ‹Value›** — `Ability::set_key`
  Setting of the “Ability with cooldown” behavior, section “Ability”. Key, e.g. Shift. Empty — only by an action from the sheet.
  Parameters: Object (object), Sign (= + - * /), Value (text)

- **Change “What it does” of ‹Object› (Ability with cooldown): ‹Sign› ‹Value›** — `Ability::set_kind`
  Setting of the “Ability with cooldown” behavior, section “Ability”. What it does: a dash, a shield (invulnerability through "Health"), healing or custom — charges only.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Charges” of ‹Object› (Ability with cooldown): ‹Sign› ‹Value›** — `Ability::set_max_charges`
  Setting of the “Ability with cooldown” behavior, section “Ability”. Charges — how many times in a row it can be used.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Use the ability of ‹Object›** — `Ability::use`
  From the “Ability with cooldown” behavior.
  Parameters: Object (object)

**Expressions**

- `Object.Ability::Charges()` — How many charges there are
- `Object.Ability::Cooldown()` — Recharge time of one charge, seconds.
- `Object.Ability::CooldownLeft()` — Seconds until the next charge
- `Object.Ability::DashDirection()` — Where to dash: along the movement (standing — where it faces) or always where it faces.
- `Object.Ability::DashSpeed()` — Dash speed, pixels per second.
- `Object.Ability::Duration()` — Duration of a dash or a shield, seconds.
- `Object.Ability::HealAmount()` — How much health it heals.
- `Object.Ability::KeepSpeed()` — Keep part of the speed after the dash, share.
- `Object.Ability::Key()` — Key, e.g. Shift. Empty — only by an action from the sheet.
- `Object.Ability::Kind()` — What it does: a dash, a shield (invulnerability through "Health"), healing or custom — charges only.
- `Object.Ability::MaxCharges()` — Charges — how many times in a row it can be used.
- `Object.Ability::Readiness()` — Readiness of the next charge, from 0 to 1 — for a bar

### Car — Car (top-down)

A car for top-down games: throttle, brake, reverse, steering, drifting and a handbrake. The car sprite must face right. Arrow keys and space controls — without events.

**Conditions**

- **“Acceleration” of ‹Object› (Car (top-down)) ‹Sign› ‹Value›** — `Car::is_acceleration`
  Setting of the “Car (top-down)” behavior, section “Engine”. Acceleration, pixels per second per second.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Braking” of ‹Object› (Car (top-down)) ‹Sign› ‹Value›** — `Car::is_braking`
  Setting of the “Car (top-down)” behavior, section “Engine”. Braking, pixels per second per second.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Impact speed at which "crashed" fires” of ‹Object› (Car (top-down)) ‹Sign› ‹Value›** — `Car::is_crash_speed`
  Setting of the “Car (top-down)” behavior, section “Controls”. Impact speed at which "crashed" fires.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Arrow keys and space controls” of ‹Object› (Car (top-down)) ‹Sign› ‹Value›** — `Car::is_default_controls`
  Setting of the “Car (top-down)” behavior, section “Controls”. Arrow keys and space controls — automatic, without events: up — throttle, down — brake and reverse, space — handbrake.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Grip on the handbrake” of ‹Object› (Car (top-down)) ‹Sign› ‹Value›** — `Car::is_drift_grip`
  Setting of the “Car (top-down)” behavior, section “Handling”. Grip on the handbrake — lower than normal so the car slides.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Drift threshold” of ‹Object› (Car (top-down)) ‹Sign› ‹Value›** — `Car::is_drift_threshold`
  Setting of the “Car (top-down)” behavior, section “Handling”. Drift threshold — from what sideways sliding speed the car counts as drifting.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **‹Object› is drifting** — `Car::is_drifting`
  From the “Car (top-down)” behavior.
  Parameters: Object (object)

- **“Rolling resistance” of ‹Object› (Car (top-down)) ‹Sign› ‹Value›** — `Car::is_friction`
  Setting of the “Car (top-down)” behavior, section “Engine”. Rolling resistance — how fast the car rolls to a stop without throttle.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Grip” of ‹Object› (Car (top-down)) ‹Sign› ‹Value›** — `Car::is_grip`
  Setting of the “Car (top-down)” behavior, section “Handling”. Grip — how fast sideways sliding dies down. 1 — like on rails, less — more drifting.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Handbrake braking” of ‹Object› (Car (top-down)) ‹Sign› ‹Value›** — `Car::is_handbrake_force`
  Setting of the “Car (top-down)” behavior, section “Handling”. Handbrake braking, pixels per second per second.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Maximum forward speed” of ‹Object› (Car (top-down)) ‹Sign› ‹Value›** — `Car::is_max_speed`
  Setting of the “Car (top-down)” behavior, section “Engine”. Maximum forward speed, pixels per second.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **‹Object› is moving** — `Car::is_moving`
  From the “Car (top-down)” behavior.
  Parameters: Object (object)

- **“Reverse speed” of ‹Object› (Car (top-down)) ‹Sign› ‹Value›** — `Car::is_reverse_speed`
  Setting of the “Car (top-down)” behavior, section “Engine”. Reverse speed.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **‹Object› is reversing** — `Car::is_reversing`
  From the “Car (top-down)” behavior.
  Parameters: Object (object)

- **“Steering speed” of ‹Object› (Car (top-down)) ‹Sign› ‹Value›** — `Car::is_turn_speed`
  Setting of the “Car (top-down)” behavior, section “Handling”. Steering speed, degrees per second at full speed.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **‹Object› has just crashed** — `Car::just_crashed`
  From the “Car (top-down)” behavior.
  Parameters: Object (object)

**Actions**

- **Brake and reverse: ‹Object›** — `Car::brake`
  Brakes while moving, reverses when the car stands still.
  Parameters: Object (object)

- **Throttle: ‹Object›** — `Car::gas`
  From the “Car (top-down)” behavior.
  Parameters: Object (object)

- **Handbrake: ‹Object›** — `Car::handbrake`
  From the “Car (top-down)” behavior.
  Parameters: Object (object)

- **Change “Acceleration” of ‹Object› (Car (top-down)): ‹Sign› ‹Value›** — `Car::set_acceleration`
  Setting of the “Car (top-down)” behavior, section “Engine”. Acceleration, pixels per second per second.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Braking” of ‹Object› (Car (top-down)): ‹Sign› ‹Value›** — `Car::set_braking`
  Setting of the “Car (top-down)” behavior, section “Engine”. Braking, pixels per second per second.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Impact speed at which "crashed" fires” of ‹Object› (Car (top-down)): ‹Sign› ‹Value›** — `Car::set_crash_speed`
  Setting of the “Car (top-down)” behavior, section “Controls”. Impact speed at which "crashed" fires.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Arrow keys and space controls” of ‹Object› (Car (top-down)): ‹Sign› ‹Value›** — `Car::set_default_controls`
  Setting of the “Car (top-down)” behavior, section “Controls”. Arrow keys and space controls — automatic, without events: up — throttle, down — brake and reverse, space — handbrake.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Grip on the handbrake” of ‹Object› (Car (top-down)): ‹Sign› ‹Value›** — `Car::set_drift_grip`
  Setting of the “Car (top-down)” behavior, section “Handling”. Grip on the handbrake — lower than normal so the car slides.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Drift threshold” of ‹Object› (Car (top-down)): ‹Sign› ‹Value›** — `Car::set_drift_threshold`
  Setting of the “Car (top-down)” behavior, section “Handling”. Drift threshold — from what sideways sliding speed the car counts as drifting.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Rolling resistance” of ‹Object› (Car (top-down)): ‹Sign› ‹Value›** — `Car::set_friction`
  Setting of the “Car (top-down)” behavior, section “Engine”. Rolling resistance — how fast the car rolls to a stop without throttle.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Grip” of ‹Object› (Car (top-down)): ‹Sign› ‹Value›** — `Car::set_grip`
  Setting of the “Car (top-down)” behavior, section “Handling”. Grip — how fast sideways sliding dies down. 1 — like on rails, less — more drifting.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Handbrake braking” of ‹Object› (Car (top-down)): ‹Sign› ‹Value›** — `Car::set_handbrake_force`
  Setting of the “Car (top-down)” behavior, section “Handling”. Handbrake braking, pixels per second per second.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Turn ‹Object› to an angle of ‹Angle, degrees› degrees** — `Car::set_heading`
  From the “Car (top-down)” behavior.
  Parameters: Object (object), Angle, degrees (number)

- **Change “Maximum forward speed” of ‹Object› (Car (top-down)): ‹Sign› ‹Value›** — `Car::set_max_speed`
  Setting of the “Car (top-down)” behavior, section “Engine”. Maximum forward speed, pixels per second.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Reverse speed” of ‹Object› (Car (top-down)): ‹Sign› ‹Value›** — `Car::set_reverse_speed`
  Setting of the “Car (top-down)” behavior, section “Engine”. Reverse speed.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Steering speed” of ‹Object› (Car (top-down)): ‹Sign› ‹Value›** — `Car::set_turn_speed`
  Setting of the “Car (top-down)” behavior, section “Handling”. Steering speed, degrees per second at full speed.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Steer left: ‹Object›** — `Car::steer_left`
  From the “Car (top-down)” behavior.
  Parameters: Object (object)

- **Steer right: ‹Object›** — `Car::steer_right`
  From the “Car (top-down)” behavior.
  Parameters: Object (object)

- **Stop ‹Object› on the spot** — `Car::stop`
  From the “Car (top-down)” behavior.
  Parameters: Object (object)

**Expressions**

- `Object.Car::Acceleration()` — Acceleration, pixels per second per second.
- `Object.Car::Braking()` — Braking, pixels per second per second.
- `Object.Car::CrashSpeed()` — Impact speed at which "crashed" fires.
- `Object.Car::DefaultControls()` — Arrow keys and space controls — automatic, without events: up — throttle, down — brake and reverse, space — handbrake.
- `Object.Car::DriftGrip()` — Grip on the handbrake — lower than normal so the car slides.
- `Object.Car::DriftSpeed()` — Sideways sliding speed
- `Object.Car::DriftThreshold()` — Drift threshold — from what sideways sliding speed the car counts as drifting.
- `Object.Car::ForwardSpeed()` — Forward speed, negative — reversing
- `Object.Car::Friction()` — Rolling resistance — how fast the car rolls to a stop without throttle.
- `Object.Car::Grip()` — Grip — how fast sideways sliding dies down. 1 — like on rails, less — more drifting.
- `Object.Car::HandbrakeForce()` — Handbrake braking, pixels per second per second.
- `Object.Car::Heading()` — Heading in degrees
- `Object.Car::MaxSpeed()` — Maximum forward speed, pixels per second.
- `Object.Car::ReverseSpeed()` — Reverse speed.
- `Object.Car::TurnSpeed()` — Steering speed, degrees per second at full speed.

### Checkpoint — Checkpoint

A touch remembers the respawn point. After death (its "Health" ran out) the player appears at the last touched point — with full health and a short invulnerability. It is remembered after a scene restart too.

**Conditions**

- **“Become current on touch” of ‹Object› (Checkpoint) ‹Sign› ‹Value›** — `Checkpoint::is_activate_on_touch`
  Setting of the “Checkpoint” behavior, section “Player”. Become current on touch.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **‹Object› is the current respawn point** — `Checkpoint::is_active`
  From the “Checkpoint” behavior.
  Parameters: Object (object)

- **“Animation of the current point” of ‹Object› (Checkpoint) ‹Sign› ‹Value›** — `Checkpoint::is_active_animation`
  Setting of the “Checkpoint” behavior, section “Look”. Animation of the current point, e.g. a raised flag.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (text)

- **“Animation of an inactive point” of ‹Object› (Checkpoint) ‹Sign› ‹Value›** — `Checkpoint::is_inactive_animation`
  Setting of the “Checkpoint” behavior, section “Look”. Animation of an inactive point, e.g. a lowered flag. Empty — do not change.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (text)

- **“Invulnerability after appearing” of ‹Object› (Checkpoint) ‹Sign› ‹Value›** — `Checkpoint::is_invulnerable_after`
  Setting of the “Checkpoint” behavior, section “Respawn”. Invulnerability after appearing, seconds.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Start point” of ‹Object› (Checkpoint) ‹Sign› ‹Value›** — `Checkpoint::is_is_start`
  Setting of the “Checkpoint” behavior, section “Player”. Start point — current from the very beginning, before any touch.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Spawn offset X” of ‹Object› (Checkpoint) ‹Sign› ‹Value›** — `Checkpoint::is_offset_x`
  Setting of the “Checkpoint” behavior, section “Respawn”. Spawn offset X — from the point, pixels.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Spawn offset Y” of ‹Object› (Checkpoint) ‹Sign› ‹Value›** — `Checkpoint::is_offset_y`
  Setting of the “Checkpoint” behavior, section “Respawn”. Spawn offset Y — from the point, pixels. Minus — higher.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Player” of ‹Object› (Checkpoint) ‹Sign› ‹Value›** — `Checkpoint::is_player_object`
  Setting of the “Checkpoint” behavior, section “Player”. Player — the name of an object from the event sheet, e.g. Player.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (text)

- **“Recreate the player” of ‹Object› (Checkpoint) ‹Sign› ‹Value›** — `Checkpoint::is_recreate_if_deleted`
  Setting of the “Checkpoint” behavior, section “Respawn”. Recreate the player — if it was deleted on death.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Remember the point after a scene restart” of ‹Object› (Checkpoint) ‹Sign› ‹Value›** — `Checkpoint::is_remember_after_restart`
  Setting of the “Checkpoint” behavior, section “Respawn”. Remember the point after a scene restart: the player starts from it.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“How many seconds after death to appear” of ‹Object› (Checkpoint) ‹Sign› ‹Value›** — `Checkpoint::is_respawn_delay`
  Setting of the “Checkpoint” behavior, section “Respawn”. How many seconds after death to appear.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Respawn on death” of ‹Object› (Checkpoint) ‹Sign› ‹Value›** — `Checkpoint::is_respawn_on_death`
  Setting of the “Checkpoint” behavior, section “Respawn”. Respawn on death — here, when the player's "Health" runs out.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **‹Object› has just become current** — `Checkpoint::just_activated`
  From the “Checkpoint” behavior.
  Parameters: Object (object)

**Actions**

- **Make ‹Object› the current respawn point** — `Checkpoint::activate`
  From the “Checkpoint” behavior.
  Parameters: Object (object)

- **Respawn the player at the current point (via ‹Object›)** — `Checkpoint::respawn_player`
  The player is moved to the current point — this one or the last touched one.
  Parameters: Object (object)

- **Change “Become current on touch” of ‹Object› (Checkpoint): ‹Sign› ‹Value›** — `Checkpoint::set_activate_on_touch`
  Setting of the “Checkpoint” behavior, section “Player”. Become current on touch.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Animation of the current point” of ‹Object› (Checkpoint): ‹Sign› ‹Value›** — `Checkpoint::set_active_animation`
  Setting of the “Checkpoint” behavior, section “Look”. Animation of the current point, e.g. a raised flag.
  Parameters: Object (object), Sign (= + - * /), Value (text)

- **Change “Animation of an inactive point” of ‹Object› (Checkpoint): ‹Sign› ‹Value›** — `Checkpoint::set_inactive_animation`
  Setting of the “Checkpoint” behavior, section “Look”. Animation of an inactive point, e.g. a lowered flag. Empty — do not change.
  Parameters: Object (object), Sign (= + - * /), Value (text)

- **Change “Invulnerability after appearing” of ‹Object› (Checkpoint): ‹Sign› ‹Value›** — `Checkpoint::set_invulnerable_after`
  Setting of the “Checkpoint” behavior, section “Respawn”. Invulnerability after appearing, seconds.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Start point” of ‹Object› (Checkpoint): ‹Sign› ‹Value›** — `Checkpoint::set_is_start`
  Setting of the “Checkpoint” behavior, section “Player”. Start point — current from the very beginning, before any touch.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Spawn offset X” of ‹Object› (Checkpoint): ‹Sign› ‹Value›** — `Checkpoint::set_offset_x`
  Setting of the “Checkpoint” behavior, section “Respawn”. Spawn offset X — from the point, pixels.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Spawn offset Y” of ‹Object› (Checkpoint): ‹Sign› ‹Value›** — `Checkpoint::set_offset_y`
  Setting of the “Checkpoint” behavior, section “Respawn”. Spawn offset Y — from the point, pixels. Minus — higher.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Player” of ‹Object› (Checkpoint): ‹Sign› ‹Value›** — `Checkpoint::set_player_object`
  Setting of the “Checkpoint” behavior, section “Player”. Player — the name of an object from the event sheet, e.g. Player.
  Parameters: Object (object), Sign (= + - * /), Value (text)

- **Change “Recreate the player” of ‹Object› (Checkpoint): ‹Sign› ‹Value›** — `Checkpoint::set_recreate_if_deleted`
  Setting of the “Checkpoint” behavior, section “Respawn”. Recreate the player — if it was deleted on death.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Remember the point after a scene restart” of ‹Object› (Checkpoint): ‹Sign› ‹Value›** — `Checkpoint::set_remember_after_restart`
  Setting of the “Checkpoint” behavior, section “Respawn”. Remember the point after a scene restart: the player starts from it.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “How many seconds after death to appear” of ‹Object› (Checkpoint): ‹Sign› ‹Value›** — `Checkpoint::set_respawn_delay`
  Setting of the “Checkpoint” behavior, section “Respawn”. How many seconds after death to appear.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Respawn on death” of ‹Object› (Checkpoint): ‹Sign› ‹Value›** — `Checkpoint::set_respawn_on_death`
  Setting of the “Checkpoint” behavior, section “Respawn”. Respawn on death — here, when the player's "Health" runs out.
  Parameters: Object (object), Sign (= + - * /), Value (number)

**Expressions**

- `Object.Checkpoint::ActivateOnTouch()` — Become current on touch.
- `Object.Checkpoint::ActiveAnimation()` — Animation of the current point, e.g. a raised flag.
- `Object.Checkpoint::InactiveAnimation()` — Animation of an inactive point, e.g. a lowered flag. Empty — do not change.
- `Object.Checkpoint::InvulnerableAfter()` — Invulnerability after appearing, seconds.
- `Object.Checkpoint::IsStart()` — Start point — current from the very beginning, before any touch.
- `Object.Checkpoint::OffsetX()` — Spawn offset X — from the point, pixels.
- `Object.Checkpoint::OffsetY()` — Spawn offset Y — from the point, pixels. Minus — higher.
- `Object.Checkpoint::PlayerObject()` — Player — the name of an object from the event sheet, e.g. Player.
- `Object.Checkpoint::RecreateIfDeleted()` — Recreate the player — if it was deleted on death.
- `Object.Checkpoint::RememberAfterRestart()` — Remember the point after a scene restart: the player starts from it.
- `Object.Checkpoint::RespawnCount()` — How many times the player appeared at this point
- `Object.Checkpoint::RespawnDelay()` — How many seconds after death to appear.
- `Object.Checkpoint::RespawnOnDeath()` — Respawn on death — here, when the player's "Health" runs out.

### Damage — Contact damage

Takes health from whoever it touches: spikes, a bullet, fire, an enemy. With a per-victim cooldown, knockback, piercing several targets and self-destruction after a hit.

**Conditions**

- **Damage of ‹Object› is on** — `Damage::is_active`
  From the “Contact damage” behavior.
  Parameters: Object (object)

- **“Damage per hit” of ‹Object› (Contact damage) ‹Sign› ‹Value›** — `Damage::is_amount`
  Setting of the “Contact damage” behavior, section “Whom to hit”. Damage per hit.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Arming delay” of ‹Object› (Contact damage) ‹Sign› ‹Value›** — `Damage::is_arm_time`
  Setting of the “Contact damage” behavior, section “How often”. Arming delay — how many seconds after creation not to hit anyone. Keeps a projectile from hitting whoever fired it.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Self-destruct” of ‹Object› (Contact damage) ‹Sign› ‹Value›** — `Damage::is_destroy_on_hit`
  Setting of the “Contact damage” behavior, section “What happens on a hit”. Self-destruct — disappear after a hit. If piercing is above 1 — after the last hit.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Hit sound” of ‹Object› (Contact damage) ‹Sign› ‹Value›** — `Damage::is_hit_sound`
  Setting of the “Contact damage” behavior, section “What happens on a hit”. Hit sound — a path to the file.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (text)

- **“Knockback of the victim away from itself” of ‹Object› (Contact damage) ‹Sign› ‹Value›** — `Damage::is_knockback`
  Setting of the “Contact damage” behavior, section “What happens on a hit”. Knockback of the victim away from itself, pixels per hit.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Piercing” of ‹Object› (Contact damage) ‹Sign› ‹Value›** — `Damage::is_pierce`
  Setting of the “Contact damage” behavior, section “How often”. Piercing — how many hits in total the object survives. 0 — any number.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Damage through invulnerability” of ‹Object› (Contact damage) ‹Sign› ‹Value›** — `Damage::is_pierce_invulnerability`
  Setting of the “Contact damage” behavior, section “What happens on a hit”. Damage through invulnerability — does not let the victim wait it out after the first hit.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Cooldown per victim” of ‹Object› (Contact damage) ‹Sign› ‹Value›** — `Damage::is_repeat_delay`
  Setting of the “Contact damage” behavior, section “How often”. Cooldown per victim — how many seconds not to hit it again. 0 — hit every frame while touching.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **‹Object› has run out of hits** — `Damage::is_spent`
  From the “Contact damage” behavior.
  Parameters: Object (object)

- **“Victim” of ‹Object› (Contact damage) ‹Sign› ‹Value›** — `Damage::is_target_object`
  Setting of the “Contact damage” behavior, section “Whom to hit”. Victim — the name of an object from the event sheet, e.g. Player. Empty — hits no one: the target is set by an action from events.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (text)

- **‹Object› has just dealt damage** — `Damage::just_hit`
  From the “Contact damage” behavior.
  Parameters: Object (object)

**Actions**

- **Turn damage on for ‹Object›** — `Damage::arm`
  From the “Contact damage” behavior.
  Parameters: Object (object)

- **Turn damage off for ‹Object›** — `Damage::disarm`
  From the “Contact damage” behavior.
  Parameters: Object (object)

- **Reset the damage cooldown of ‹Object› — it can hit again** — `Damage::reset_cooldowns`
  From the “Contact damage” behavior.
  Parameters: Object (object)

- **Change “Damage is on” of ‹Object› (Contact damage): ‹Sign› ‹Value›** — `Damage::set_active`
  Setting of the “Contact damage” behavior, section “Whom to hit”. Damage is on.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Damage per hit” of ‹Object› (Contact damage): ‹Sign› ‹Value›** — `Damage::set_amount`
  Setting of the “Contact damage” behavior, section “Whom to hit”. Damage per hit.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Arming delay” of ‹Object› (Contact damage): ‹Sign› ‹Value›** — `Damage::set_arm_time`
  Setting of the “Contact damage” behavior, section “How often”. Arming delay — how many seconds after creation not to hit anyone. Keeps a projectile from hitting whoever fired it.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Self-destruct” of ‹Object› (Contact damage): ‹Sign› ‹Value›** — `Damage::set_destroy_on_hit`
  Setting of the “Contact damage” behavior, section “What happens on a hit”. Self-destruct — disappear after a hit. If piercing is above 1 — after the last hit.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Hit sound” of ‹Object› (Contact damage): ‹Sign› ‹Value›** — `Damage::set_hit_sound`
  Setting of the “Contact damage” behavior, section “What happens on a hit”. Hit sound — a path to the file.
  Parameters: Object (object), Sign (= + - * /), Value (text)

- **Change “Knockback of the victim away from itself” of ‹Object› (Contact damage): ‹Sign› ‹Value›** — `Damage::set_knockback`
  Setting of the “Contact damage” behavior, section “What happens on a hit”. Knockback of the victim away from itself, pixels per hit.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Piercing” of ‹Object› (Contact damage): ‹Sign› ‹Value›** — `Damage::set_pierce`
  Setting of the “Contact damage” behavior, section “How often”. Piercing — how many hits in total the object survives. 0 — any number.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Damage through invulnerability” of ‹Object› (Contact damage): ‹Sign› ‹Value›** — `Damage::set_pierce_invulnerability`
  Setting of the “Contact damage” behavior, section “What happens on a hit”. Damage through invulnerability — does not let the victim wait it out after the first hit.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Cooldown per victim” of ‹Object› (Contact damage): ‹Sign› ‹Value›** — `Damage::set_repeat_delay`
  Setting of the “Contact damage” behavior, section “How often”. Cooldown per victim — how many seconds not to hit it again. 0 — hit every frame while touching.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Victim” of ‹Object› (Contact damage): ‹Sign› ‹Value›** — `Damage::set_target_object`
  Setting of the “Contact damage” behavior, section “Whom to hit”. Victim — the name of an object from the event sheet, e.g. Player. Empty — hits no one: the target is set by an action from events.
  Parameters: Object (object), Sign (= + - * /), Value (text)

- **Set the victim of ‹Object›: object ‹Object name›** — `Damage::target`
  From the “Contact damage” behavior.
  Parameters: Object (object), Object name (text)

**Expressions**

- `Object.Damage::Active()` — Damage is on.
- `Object.Damage::Amount()` — Damage per hit.
- `Object.Damage::ArmTime()` — Arming delay — how many seconds after creation not to hit anyone. Keeps a projectile from hitting whoever fired it.
- `Object.Damage::DestroyOnHit()` — Self-destruct — disappear after a hit. If piercing is above 1 — after the last hit.
- `Object.Damage::HitSound()` — Hit sound — a path to the file.
- `Object.Damage::HitsDone()` — How many times the object has already hit
- `Object.Damage::HitsLeft()` — How many hits are left
- `Object.Damage::Knockback()` — Knockback of the victim away from itself, pixels per hit.
- `Object.Damage::Pierce()` — Piercing — how many hits in total the object survives. 0 — any number.
- `Object.Damage::PierceInvulnerability()` — Damage through invulnerability — does not let the victim wait it out after the first hit.
- `Object.Damage::RepeatDelay()` — Cooldown per victim — how many seconds not to hit it again. 0 — hit every frame while touching.
- `Object.Damage::TargetObject()` — Victim — the name of an object from the event sheet, e.g. Player. Empty — hits no one: the target is set by an action from events.

### DestroyOutside — Off-screen edges

What to do when the object leaves the screen: delete it, move it to the opposite side, or keep it in.

**Conditions**

- **“Watch the bottom edge” of ‹Object› (Off-screen edges) ‹Sign› ‹Value›** — `DestroyOutside::is_bottom`
  Setting of the “Off-screen edges” behavior, section “Which edges count”. Watch the bottom edge.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Grace time after creation” of ‹Object› (Off-screen edges) ‹Sign› ‹Value›** — `DestroyOutside::is_grace_time`
  Setting of the “Off-screen edges” behavior, section “Behavior”. Grace time after creation — how many seconds to leave the object alone. Saves those born off-screen.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Watch the left edge” of ‹Object› (Off-screen edges) ‹Sign› ‹Value›** — `DestroyOutside::is_left`
  Setting of the “Off-screen edges” behavior, section “Which edges count”. Watch the left edge.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Margin beyond the edge” of ‹Object› (Off-screen edges) ‹Sign› ‹Value›** — `DestroyOutside::is_margin`
  Setting of the “Off-screen edges” behavior, section “Behavior”. Margin beyond the edge — how many pixels the object may go out before it triggers.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Beyond the edge” of ‹Object› (Off-screen edges) ‹Sign› ‹Value›** — `DestroyOutside::is_mode`
  Setting of the “Off-screen edges” behavior, section “Behavior”. Beyond the edge — delete, wrap around or keep in. Delete for bullets, wrap around as in “Asteroids”, keep in for the player.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **‹Object› is off-screen** — `DestroyOutside::is_outside`
  From the “Off-screen edges” behavior.
  Parameters: Object (object)

- **“Watch the right edge” of ‹Object› (Off-screen edges) ‹Sign› ‹Value›** — `DestroyOutside::is_right`
  Setting of the “Off-screen edges” behavior, section “Which edges count”. Watch the right edge.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Watch the top edge” of ‹Object› (Off-screen edges) ‹Sign› ‹Value›** — `DestroyOutside::is_top`
  Setting of the “Off-screen edges” behavior, section “Which edges count”. Watch the top edge.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

**Actions**

- **Change “Watch the bottom edge” of ‹Object› (Off-screen edges): ‹Sign› ‹Value›** — `DestroyOutside::set_bottom`
  Setting of the “Off-screen edges” behavior, section “Which edges count”. Watch the bottom edge.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Edge mode of ‹Object›: ‹Mode› (0 delete, 1 wrap around, 2 keep in)** — `DestroyOutside::set_edge_mode`
  From the “Off-screen edges” behavior.
  Parameters: Object (object), Mode (number)

- **Change “Grace time after creation” of ‹Object› (Off-screen edges): ‹Sign› ‹Value›** — `DestroyOutside::set_grace_time`
  Setting of the “Off-screen edges” behavior, section “Behavior”. Grace time after creation — how many seconds to leave the object alone. Saves those born off-screen.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Watch the left edge” of ‹Object› (Off-screen edges): ‹Sign› ‹Value›** — `DestroyOutside::set_left`
  Setting of the “Off-screen edges” behavior, section “Which edges count”. Watch the left edge.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Margin beyond the edge” of ‹Object› (Off-screen edges): ‹Sign› ‹Value›** — `DestroyOutside::set_margin`
  Setting of the “Off-screen edges” behavior, section “Behavior”. Margin beyond the edge — how many pixels the object may go out before it triggers.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Beyond the edge” of ‹Object› (Off-screen edges): ‹Sign› ‹Value›** — `DestroyOutside::set_mode`
  Setting of the “Off-screen edges” behavior, section “Behavior”. Beyond the edge — delete, wrap around or keep in. Delete for bullets, wrap around as in “Asteroids”, keep in for the player.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Watch the right edge” of ‹Object› (Off-screen edges): ‹Sign› ‹Value›** — `DestroyOutside::set_right`
  Setting of the “Off-screen edges” behavior, section “Which edges count”. Watch the right edge.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Watch the top edge” of ‹Object› (Off-screen edges): ‹Sign› ‹Value›** — `DestroyOutside::set_top`
  Setting of the “Off-screen edges” behavior, section “Which edges count”. Watch the top edge.
  Parameters: Object (object), Sign (= + - * /), Value (number)

**Expressions**

- `Object.DestroyOutside::Age()` — How many seconds the object has existed
- `Object.DestroyOutside::Bottom()` — Watch the bottom edge.
- `Object.DestroyOutside::GraceTime()` — Grace time after creation — how many seconds to leave the object alone. Saves those born off-screen.
- `Object.DestroyOutside::Left()` — Watch the left edge.
- `Object.DestroyOutside::Margin()` — Margin beyond the edge — how many pixels the object may go out before it triggers.
- `Object.DestroyOutside::Mode()` — Beyond the edge — delete, wrap around or keep in. Delete for bullets, wrap around as in “Asteroids”, keep in for the player.
- `Object.DestroyOutside::Right()` — Watch the right edge.
- `Object.DestroyOutside::Top()` — Watch the top edge.

### Destructible — Destructible with loot

A crate, a barrel, a vase: when destroyed it bursts into shards of its own picture and drops items by a chance table. Breaks from "Health", from a touch or by an action.

**Conditions**

- **“Break when the object's "Health" runs out” of ‹Object› (Destructible with loot) ‹Sign› ‹Value›** — `Destructible::is_break_on_death`
  Setting of the “Destructible with loot” behavior, section “Breaking”. Break when the object's "Health" runs out.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Break on touching an object” of ‹Object› (Destructible with loot) ‹Sign› ‹Value›** — `Destructible::is_break_on_touch`
  Setting of the “Destructible with loot” behavior, section “Breaking”. Break on touching an object — a name from the sheet, e.g. Bullet. Empty — do not break on touch.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (text)

- **“Breaking sound” of ‹Object› (Destructible with loot) ‹Sign› ‹Value›** — `Destructible::is_break_sound`
  Setting of the “Destructible with loot” behavior, section “Breaking”. Breaking sound — a file path. Empty — silent.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (text)

- **‹Object› is destroyed** — `Destructible::is_broken`
  From the “Destructible with loot” behavior.
  Parameters: Object (object)

- **“Chance of the first item” of ‹Object› (Destructible with loot) ‹Sign› ‹Value›** — `Destructible::is_chance_1`
  Setting of the “Destructible with loot” behavior, section “Loot”. Chance of the first item, percent.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Chance of the second item” of ‹Object› (Destructible with loot) ‹Sign› ‹Value›** — `Destructible::is_chance_2`
  Setting of the “Destructible with loot” behavior, section “Loot”. Chance of the second item, percent.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Chance of the third item” of ‹Object› (Destructible with loot) ‹Sign› ‹Value›** — `Destructible::is_chance_3`
  Setting of the “Destructible with loot” behavior, section “Loot”. Chance of the third item, percent.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“How many of the first item drop” of ‹Object› (Destructible with loot) ‹Sign› ‹Value›** — `Destructible::is_count_1`
  Setting of the “Destructible with loot” behavior, section “Loot”. How many of the first item drop.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“How many of the second item drop” of ‹Object› (Destructible with loot) ‹Sign› ‹Value›** — `Destructible::is_count_2`
  Setting of the “Destructible with loot” behavior, section “Loot”. How many of the second item drop.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“How many of the third item drop” of ‹Object› (Destructible with loot) ‹Sign› ‹Value›** — `Destructible::is_count_3`
  Setting of the “Destructible with loot” behavior, section “Loot”. How many of the third item drop.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Delete the object after breaking” of ‹Object› (Destructible with loot) ‹Sign› ‹Value›** — `Destructible::is_delete_after`
  Setting of the “Destructible with loot” behavior, section “Breaking”. Delete the object after breaking.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Loot scatter” of ‹Object› (Destructible with loot) ‹Sign› ‹Value›** — `Destructible::is_loot_pop`
  Setting of the “Destructible with loot” behavior, section “Loot”. Loot scatter — how fast the items pop out, pixels per second.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Shard weight” of ‹Object› (Destructible with loot) ‹Sign› ‹Value›** — `Destructible::is_shard_gravity`
  Setting of the “Destructible with loot” behavior, section “Shards”. Shard weight, pixels per second per second. 0 — for top-down games.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“How many seconds the shards are visible” of ‹Object› (Destructible with loot) ‹Sign› ‹Value›** — `Destructible::is_shard_lifetime`
  Setting of the “Destructible with loot” behavior, section “Shards”. How many seconds the shards are visible.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Burst speed” of ‹Object› (Destructible with loot) ‹Sign› ‹Value›** — `Destructible::is_shard_speed`
  Setting of the “Destructible with loot” behavior, section “Shards”. Burst speed, pixels per second.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Shard spin” of ‹Object› (Destructible with loot) ‹Sign› ‹Value›** — `Destructible::is_shard_spin`
  Setting of the “Destructible with loot” behavior, section “Shards”. Shard spin, degrees per second.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Shards across” of ‹Object› (Destructible with loot) ‹Sign› ‹Value›** — `Destructible::is_shards_x`
  Setting of the “Destructible with loot” behavior, section “Shards”. Shards across.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Shards down” of ‹Object› (Destructible with loot) ‹Sign› ‹Value›** — `Destructible::is_shards_y`
  Setting of the “Destructible with loot” behavior, section “Shards”. Shards down. 0 — no shards.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **‹Object› has just been destroyed** — `Destructible::just_broken`
  From the “Destructible with loot” behavior.
  Parameters: Object (object)

**Actions**

- **Destroy ‹Object›** — `Destructible::break_now`
  From the “Destructible with loot” behavior.
  Parameters: Object (object)

- **Change “Break when the object's "Health" runs out” of ‹Object› (Destructible with loot): ‹Sign› ‹Value›** — `Destructible::set_break_on_death`
  Setting of the “Destructible with loot” behavior, section “Breaking”. Break when the object's "Health" runs out.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Break on touching an object” of ‹Object› (Destructible with loot): ‹Sign› ‹Value›** — `Destructible::set_break_on_touch`
  Setting of the “Destructible with loot” behavior, section “Breaking”. Break on touching an object — a name from the sheet, e.g. Bullet. Empty — do not break on touch.
  Parameters: Object (object), Sign (= + - * /), Value (text)

- **Change “Breaking sound” of ‹Object› (Destructible with loot): ‹Sign› ‹Value›** — `Destructible::set_break_sound`
  Setting of the “Destructible with loot” behavior, section “Breaking”. Breaking sound — a file path. Empty — silent.
  Parameters: Object (object), Sign (= + - * /), Value (text)

- **Change “Chance of the first item” of ‹Object› (Destructible with loot): ‹Sign› ‹Value›** — `Destructible::set_chance_1`
  Setting of the “Destructible with loot” behavior, section “Loot”. Chance of the first item, percent.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Chance of the second item” of ‹Object› (Destructible with loot): ‹Sign› ‹Value›** — `Destructible::set_chance_2`
  Setting of the “Destructible with loot” behavior, section “Loot”. Chance of the second item, percent.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Chance of the third item” of ‹Object› (Destructible with loot): ‹Sign› ‹Value›** — `Destructible::set_chance_3`
  Setting of the “Destructible with loot” behavior, section “Loot”. Chance of the third item, percent.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “How many of the first item drop” of ‹Object› (Destructible with loot): ‹Sign› ‹Value›** — `Destructible::set_count_1`
  Setting of the “Destructible with loot” behavior, section “Loot”. How many of the first item drop.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “How many of the second item drop” of ‹Object› (Destructible with loot): ‹Sign› ‹Value›** — `Destructible::set_count_2`
  Setting of the “Destructible with loot” behavior, section “Loot”. How many of the second item drop.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “How many of the third item drop” of ‹Object› (Destructible with loot): ‹Sign› ‹Value›** — `Destructible::set_count_3`
  Setting of the “Destructible with loot” behavior, section “Loot”. How many of the third item drop.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Delete the object after breaking” of ‹Object› (Destructible with loot): ‹Sign› ‹Value›** — `Destructible::set_delete_after`
  Setting of the “Destructible with loot” behavior, section “Breaking”. Delete the object after breaking.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Loot scatter” of ‹Object› (Destructible with loot): ‹Sign› ‹Value›** — `Destructible::set_loot_pop`
  Setting of the “Destructible with loot” behavior, section “Loot”. Loot scatter — how fast the items pop out, pixels per second.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Shard weight” of ‹Object› (Destructible with loot): ‹Sign› ‹Value›** — `Destructible::set_shard_gravity`
  Setting of the “Destructible with loot” behavior, section “Shards”. Shard weight, pixels per second per second. 0 — for top-down games.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “How many seconds the shards are visible” of ‹Object› (Destructible with loot): ‹Sign› ‹Value›** — `Destructible::set_shard_lifetime`
  Setting of the “Destructible with loot” behavior, section “Shards”. How many seconds the shards are visible.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Burst speed” of ‹Object› (Destructible with loot): ‹Sign› ‹Value›** — `Destructible::set_shard_speed`
  Setting of the “Destructible with loot” behavior, section “Shards”. Burst speed, pixels per second.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Shard spin” of ‹Object› (Destructible with loot): ‹Sign› ‹Value›** — `Destructible::set_shard_spin`
  Setting of the “Destructible with loot” behavior, section “Shards”. Shard spin, degrees per second.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Shards across” of ‹Object› (Destructible with loot): ‹Sign› ‹Value›** — `Destructible::set_shards_x`
  Setting of the “Destructible with loot” behavior, section “Shards”. Shards across.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Shards down” of ‹Object› (Destructible with loot): ‹Sign› ‹Value›** — `Destructible::set_shards_y`
  Setting of the “Destructible with loot” behavior, section “Shards”. Shards down. 0 — no shards.
  Parameters: Object (object), Sign (= + - * /), Value (number)

**Expressions**

- `Object.Destructible::BreakOnDeath()` — Break when the object's "Health" runs out.
- `Object.Destructible::BreakOnTouch()` — Break on touching an object — a name from the sheet, e.g. Bullet. Empty — do not break on touch.
- `Object.Destructible::BreakSound()` — Breaking sound — a file path. Empty — silent.
- `Object.Destructible::Chance1()` — Chance of the first item, percent.
- `Object.Destructible::Chance2()` — Chance of the second item, percent.
- `Object.Destructible::Chance3()` — Chance of the third item, percent.
- `Object.Destructible::Count1()` — How many of the first item drop.
- `Object.Destructible::Count2()` — How many of the second item drop.
- `Object.Destructible::Count3()` — How many of the third item drop.
- `Object.Destructible::DeleteAfter()` — Delete the object after breaking.
- `Object.Destructible::LootCount()` — How many items dropped
- `Object.Destructible::LootPop()` — Loot scatter — how fast the items pop out, pixels per second.
- `Object.Destructible::ShardGravity()` — Shard weight, pixels per second per second. 0 — for top-down games.
- `Object.Destructible::ShardLifetime()` — How many seconds the shards are visible.
- `Object.Destructible::ShardSpeed()` — Burst speed, pixels per second.
- `Object.Destructible::ShardSpin()` — Shard spin, degrees per second.
- `Object.Destructible::ShardsX()` — Shards across.
- `Object.Destructible::ShardsY()` — Shards down. 0 — no shards.

### Dialogue — Dialogue

A speech bubble above a character: the text is typed letter by letter, lines go in a queue, Enter or a click moves on, and a question offers answers to choose from. Several lines at once — with "|": "Hi!|How are you?".

**Conditions**

- **“The "next" key” of ‹Object› (Dialogue) ‹Sign› ‹Value›** — `Dialogue::is_advance_key`
  Setting of the “Dialogue” behavior, section “Text”. The "next" key, e.g. Enter or E.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (text)

- **‹Object› is waiting for an answer** — `Dialogue::is_asking`
  From the “Dialogue” behavior.
  Parameters: Object (object)

- **“Auto-advance” of ‹Object› (Dialogue) ‹Sign› ‹Value›** — `Dialogue::is_auto_advance`
  Setting of the “Dialogue” behavior, section “Text”. Auto-advance — how many seconds after typing to move on. 0 — wait for Enter or a click.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“A mouse click moves on too” of ‹Object› (Dialogue) ‹Sign› ‹Value›** — `Dialogue::is_click_to_advance`
  Setting of the “Dialogue” behavior, section “Text”. A mouse click moves on too.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Font size” of ‹Object› (Dialogue) ‹Sign› ‹Value›** — `Dialogue::is_font_size`
  Setting of the “Dialogue” behavior, section “Bubble”. Font size.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“The sound of each letter” of ‹Object› (Dialogue) ‹Sign› ‹Value›** — `Dialogue::is_letter_sound`
  Setting of the “Dialogue” behavior, section “Text”. The sound of each letter — a file path. Empty — silent.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (text)

- **“Typing speed” of ‹Object› (Dialogue) ‹Sign› ‹Value›** — `Dialogue::is_letters_per_second`
  Setting of the “Dialogue” behavior, section “Text”. Typing speed, letters per second. 0 — all at once.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“How high the bubble floats above the object” of ‹Object› (Dialogue) ‹Sign› ‹Value›** — `Dialogue::is_lift`
  Setting of the “Dialogue” behavior, section “Bubble”. How high the bubble floats above the object, pixels.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Maximum bubble width” of ‹Object› (Dialogue) ‹Sign› ‹Value›** — `Dialogue::is_max_width`
  Setting of the “Dialogue” behavior, section “Bubble”. Maximum bubble width, pixels.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“At the bottom of the screen” of ‹Object› (Dialogue) ‹Sign› ‹Value›** — `Dialogue::is_on_screen`
  Setting of the “Dialogue” behavior, section “Bubble”. At the bottom of the screen, as in role-playing games, instead of above the character.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Pause the game” of ‹Object› (Dialogue) ‹Sign› ‹Value›** — `Dialogue::is_pause_game`
  Setting of the “Dialogue” behavior, section “Text”. Pause the game — while the conversation goes on.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“The speaker's name above the text” of ‹Object› (Dialogue) ‹Sign› ‹Value›** — `Dialogue::is_speaker_name`
  Setting of the “Dialogue” behavior, section “Text”. The speaker's name above the text. Empty — no name.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (text)

- **‹Object› is talking** — `Dialogue::is_talking`
  From the “Dialogue” behavior.
  Parameters: Object (object)

- **‹Object› is still typing a line** — `Dialogue::is_typing`
  From the “Dialogue” behavior.
  Parameters: Object (object)

- **Answer number ‹Number› (from zero) has just been chosen in the conversation of ‹Object›** — `Dialogue::just_chose`
  From the “Dialogue” behavior.
  Parameters: Object (object), Number (number)

- **The conversation of ‹Object› has just ended** — `Dialogue::just_finished`
  From the “Dialogue” behavior.
  Parameters: Object (object)

**Actions**

- **Next in the conversation of ‹Object›** — `Dialogue::advance`
  A line is being typed — finish it at once; typed — the next one; no lines — close.
  Parameters: Object (object)

- **‹Object› asks: ‹Question›, answers: ‹Answers›** — `Dialogue::ask`
  Answers separated by "|".
  Parameters: Object (object), Question (text), Answers (text)

- **Choose answer number ‹Number› (from zero) in the conversation of ‹Object›** — `Dialogue::choose`
  From the “Dialogue” behavior.
  Parameters: Object (object), Number (number)

- **‹Object› says: ‹Text›** — `Dialogue::say`
  Several lines at once — with "|". A question with answers: "Shall we go? [Yes|No]".
  Parameters: Object (object), Text (text)

- **Change “The "next" key” of ‹Object› (Dialogue): ‹Sign› ‹Value›** — `Dialogue::set_advance_key`
  Setting of the “Dialogue” behavior, section “Text”. The "next" key, e.g. Enter or E.
  Parameters: Object (object), Sign (= + - * /), Value (text)

- **Change “Auto-advance” of ‹Object› (Dialogue): ‹Sign› ‹Value›** — `Dialogue::set_auto_advance`
  Setting of the “Dialogue” behavior, section “Text”. Auto-advance — how many seconds after typing to move on. 0 — wait for Enter or a click.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “A mouse click moves on too” of ‹Object› (Dialogue): ‹Sign› ‹Value›** — `Dialogue::set_click_to_advance`
  Setting of the “Dialogue” behavior, section “Text”. A mouse click moves on too.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Font size” of ‹Object› (Dialogue): ‹Sign› ‹Value›** — `Dialogue::set_font_size`
  Setting of the “Dialogue” behavior, section “Bubble”. Font size.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “The sound of each letter” of ‹Object› (Dialogue): ‹Sign› ‹Value›** — `Dialogue::set_letter_sound`
  Setting of the “Dialogue” behavior, section “Text”. The sound of each letter — a file path. Empty — silent.
  Parameters: Object (object), Sign (= + - * /), Value (text)

- **Change “Typing speed” of ‹Object› (Dialogue): ‹Sign› ‹Value›** — `Dialogue::set_letters_per_second`
  Setting of the “Dialogue” behavior, section “Text”. Typing speed, letters per second. 0 — all at once.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “How high the bubble floats above the object” of ‹Object› (Dialogue): ‹Sign› ‹Value›** — `Dialogue::set_lift`
  Setting of the “Dialogue” behavior, section “Bubble”. How high the bubble floats above the object, pixels.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Maximum bubble width” of ‹Object› (Dialogue): ‹Sign› ‹Value›** — `Dialogue::set_max_width`
  Setting of the “Dialogue” behavior, section “Bubble”. Maximum bubble width, pixels.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “At the bottom of the screen” of ‹Object› (Dialogue): ‹Sign› ‹Value›** — `Dialogue::set_on_screen`
  Setting of the “Dialogue” behavior, section “Bubble”. At the bottom of the screen, as in role-playing games, instead of above the character.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Pause the game” of ‹Object› (Dialogue): ‹Sign› ‹Value›** — `Dialogue::set_pause_game`
  Setting of the “Dialogue” behavior, section “Text”. Pause the game — while the conversation goes on.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “The speaker's name above the text” of ‹Object› (Dialogue): ‹Sign› ‹Value›** — `Dialogue::set_speaker_name`
  Setting of the “Dialogue” behavior, section “Text”. The speaker's name above the text. Empty — no name.
  Parameters: Object (object), Sign (= + - * /), Value (text)

- **Stop the conversation of ‹Object›** — `Dialogue::stop`
  From the “Dialogue” behavior.
  Parameters: Object (object)

**Expressions**

- `Object.Dialogue::AdvanceKey()` — The "next" key, e.g. Enter or E.
- `Object.Dialogue::AutoAdvance()` — Auto-advance — how many seconds after typing to move on. 0 — wait for Enter or a click.
- `Object.Dialogue::ChoiceIndex()` — Number of the last chosen answer, from zero; -1 — nothing chosen yet
- `Object.Dialogue::ChoiceText()` — Text of the last chosen answer
- `Object.Dialogue::ClickToAdvance()` — A mouse click moves on too.
- `Object.Dialogue::CurrentLine()` — The current line
- `Object.Dialogue::FontSize()` — Font size.
- `Object.Dialogue::LetterSound()` — The sound of each letter — a file path. Empty — silent.
- `Object.Dialogue::LettersPerSecond()` — Typing speed, letters per second. 0 — all at once.
- `Object.Dialogue::Lift()` — How high the bubble floats above the object, pixels.
- `Object.Dialogue::LinesLeft()` — How many lines are still in the queue
- `Object.Dialogue::MaxWidth()` — Maximum bubble width, pixels.
- `Object.Dialogue::OnScreen()` — At the bottom of the screen, as in role-playing games, instead of above the character.
- `Object.Dialogue::PauseGame()` — Pause the game — while the conversation goes on.
- `Object.Dialogue::SpeakerName()` — The speaker's name above the text. Empty — no name.

### Draggable — Draggable

Mouse dragging with a grid, axis locking, smooth following and returning home.

**Conditions**

- **“Movement axes” of ‹Object› (Draggable) ‹Sign› ‹Value›** — `Draggable::is_axis_lock`
  Setting of the “Draggable” behavior, section “Dragging”. Movement axes — along which the object can be moved.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Keep on screen” of ‹Object› (Draggable) ‹Sign› ‹Value›** — `Draggable::is_clamp_to_screen`
  Setting of the “Draggable” behavior, section “Bounds”. Keep on screen — do not let it past the edges.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Size while dragging” of ‹Object› (Draggable) ‹Sign› ‹Value›** — `Draggable::is_drag_scale`
  Setting of the “Draggable” behavior, section “Look”. Size while dragging. 1.1 — a little bigger than usual.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **‹Object› is being dragged** — `Draggable::is_dragging`
  From the “Draggable” behavior.
  Parameters: Object (object)

- **“Dragging is on” of ‹Object› (Draggable) ‹Sign› ‹Value›** — `Draggable::is_enabled`
  Setting of the “Draggable” behavior, section “Dragging”. Dragging is on. Turn it off to pin the object in place for a while.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Grid snapping in pixels” of ‹Object› (Draggable) ‹Sign› ‹Value›** — `Draggable::is_grid`
  Setting of the “Draggable” behavior, section “Dragging”. Grid snapping in pixels. 0 — no snapping.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Grab at the touch point” of ‹Object› (Draggable) ‹Sign› ‹Value›** — `Draggable::is_keep_grab_offset`
  Setting of the “Draggable” behavior, section “Dragging”. Grab at the touch point — the object does not jump its center under the cursor.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Lift above others” of ‹Object› (Draggable) ‹Sign› ‹Value›** — `Draggable::is_lift_while_dragging`
  Setting of the “Draggable” behavior, section “Look”. Lift above others — while the object is dragged.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Mouse button used to drag the object” of ‹Object› (Draggable) ‹Sign› ‹Value›** — `Draggable::is_mouse_button`
  Setting of the “Draggable” behavior, section “Dragging”. Mouse button used to drag the object.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Return home after release” of ‹Object› (Draggable) ‹Sign› ‹Value›** — `Draggable::is_return_on_drop`
  Setting of the “Draggable” behavior, section “Return”. Return home after release.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Speed of returning home” of ‹Object› (Draggable) ‹Sign› ‹Value›** — `Draggable::is_return_speed`
  Setting of the “Draggable” behavior, section “Return”. Speed of returning home, pixels per second.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **‹Object› is returning home** — `Draggable::is_returning`
  From the “Draggable” behavior.
  Parameters: Object (object)

- **“Smoothness of following the cursor” of ‹Object› (Draggable) ‹Sign› ‹Value›** — `Draggable::is_smoothing`
  Setting of the “Draggable” behavior, section “Dragging”. Smoothness of following the cursor. 0 — glued tight.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

**Actions**

- **Allow dragging ‹Object›: ‹1 yes, 0 no› (1 yes, 0 no)** — `Draggable::allow`
  From the “Draggable” behavior.
  Parameters: Object (object), 1 yes, 0 no (number)

- **Return ‹Object› home** — `Draggable::go_home`
  From the “Draggable” behavior.
  Parameters: Object (object)

- **Change “Movement axes” of ‹Object› (Draggable): ‹Sign› ‹Value›** — `Draggable::set_axis_lock`
  Setting of the “Draggable” behavior, section “Dragging”. Movement axes — along which the object can be moved.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Keep on screen” of ‹Object› (Draggable): ‹Sign› ‹Value›** — `Draggable::set_clamp_to_screen`
  Setting of the “Draggable” behavior, section “Bounds”. Keep on screen — do not let it past the edges.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Size while dragging” of ‹Object› (Draggable): ‹Sign› ‹Value›** — `Draggable::set_drag_scale`
  Setting of the “Draggable” behavior, section “Look”. Size while dragging. 1.1 — a little bigger than usual.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Dragging is on” of ‹Object› (Draggable): ‹Sign› ‹Value›** — `Draggable::set_enabled`
  Setting of the “Draggable” behavior, section “Dragging”. Dragging is on. Turn it off to pin the object in place for a while.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Grid snapping in pixels” of ‹Object› (Draggable): ‹Sign› ‹Value›** — `Draggable::set_grid`
  Setting of the “Draggable” behavior, section “Dragging”. Grid snapping in pixels. 0 — no snapping.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Remember the current place of ‹Object› as home** — `Draggable::set_home`
  From the “Draggable” behavior.
  Parameters: Object (object)

- **Change “Grab at the touch point” of ‹Object› (Draggable): ‹Sign› ‹Value›** — `Draggable::set_keep_grab_offset`
  Setting of the “Draggable” behavior, section “Dragging”. Grab at the touch point — the object does not jump its center under the cursor.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Lift above others” of ‹Object› (Draggable): ‹Sign› ‹Value›** — `Draggable::set_lift_while_dragging`
  Setting of the “Draggable” behavior, section “Look”. Lift above others — while the object is dragged.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Mouse button used to drag the object” of ‹Object› (Draggable): ‹Sign› ‹Value›** — `Draggable::set_mouse_button`
  Setting of the “Draggable” behavior, section “Dragging”. Mouse button used to drag the object.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Return home after release” of ‹Object› (Draggable): ‹Sign› ‹Value›** — `Draggable::set_return_on_drop`
  Setting of the “Draggable” behavior, section “Return”. Return home after release.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Speed of returning home” of ‹Object› (Draggable): ‹Sign› ‹Value›** — `Draggable::set_return_speed`
  Setting of the “Draggable” behavior, section “Return”. Speed of returning home, pixels per second.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Smoothness of following the cursor” of ‹Object› (Draggable): ‹Sign› ‹Value›** — `Draggable::set_smoothing`
  Setting of the “Draggable” behavior, section “Dragging”. Smoothness of following the cursor. 0 — glued tight.
  Parameters: Object (object), Sign (= + - * /), Value (number)

**Expressions**

- `Object.Draggable::AxisLock()` — Movement axes — along which the object can be moved.
- `Object.Draggable::ClampToScreen()` — Keep on screen — do not let it past the edges.
- `Object.Draggable::DistanceFromHome()` — Distance to the home place
- `Object.Draggable::DragScale()` — Size while dragging. 1.1 — a little bigger than usual.
- `Object.Draggable::Enabled()` — Dragging is on. Turn it off to pin the object in place for a while.
- `Object.Draggable::Grid()` — Grid snapping in pixels. 0 — no snapping.
- `Object.Draggable::KeepGrabOffset()` — Grab at the touch point — the object does not jump its center under the cursor.
- `Object.Draggable::LiftWhileDragging()` — Lift above others — while the object is dragged.
- `Object.Draggable::MouseButton()` — Mouse button used to drag the object.
- `Object.Draggable::ReturnOnDrop()` — Return home after release.
- `Object.Draggable::ReturnSpeed()` — Speed of returning home, pixels per second.
- `Object.Draggable::Smoothing()` — Smoothness of following the cursor. 0 — glued tight.

### Flock — Flock

Bees, birds, fish: they stay together, fly the same way, do not bump into each other and go around walls. Can follow an object or flee from it.

**Conditions**

- **‹Object› has flock neighbors** — `Flock::has_neighbors`
  From the “Flock” behavior.
  Parameters: Object (object)

- **“Alignment” of ‹Object› (Flock) ‹Sign› ‹Value›** — `Flock::is_alignment`
  Setting of the “Flock” behavior, section “Rules”. Alignment — how much to fly the same way as the neighbors.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“At what distance to notice a wall ahead” of ‹Object› (Flock) ‹Sign› ‹Value›** — `Flock::is_avoid_distance`
  Setting of the “Flock” behavior, section “Obstacles”. At what distance to notice a wall ahead, pixels.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Go around walls” of ‹Object› (Flock) ‹Sign› ‹Value›** — `Flock::is_avoid_walls`
  Setting of the “Flock” behavior, section “Obstacles”. Go around walls.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Wall avoidance strength” of ‹Object› (Flock) ‹Sign› ‹Value›** — `Flock::is_avoid_weight`
  Setting of the “Flock” behavior, section “Obstacles”. Wall avoidance strength.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Cohesion” of ‹Object› (Flock) ‹Sign› ‹Value›** — `Flock::is_cohesion`
  Setting of the “Flock” behavior, section “Rules”. Cohesion — how much to pull toward the center of the neighbors.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Flip the sprite” of ‹Object› (Flock) ‹Sign› ‹Value›** — `Flock::is_flip_sprite`
  Setting of the “Flock” behavior, section “Look”. Flip the sprite — toward the movement direction.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Flock name” of ‹Object› (Flock) ‹Sign› ‹Value›** — `Flock::is_flock_name`
  Setting of the “Flock” behavior, section “Flock”. Flock name: objects with the same name stay together. Different names — different flocks.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (text)

- **“An object to follow” of ‹Object› (Flock) ‹Sign› ‹Value›** — `Flock::is_follow_object`
  Setting of the “Flock” behavior, section “Leader”. An object to follow, e.g. Player. Empty — fly freely.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (text)

- **“How strongly to pull toward it” of ‹Object› (Flock) ‹Sign› ‹Value›** — `Flock::is_follow_weight`
  Setting of the “Flock” behavior, section “Leader”. How strongly to pull toward it. Negative — flee.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Agility” of ‹Object› (Flock) ‹Sign› ‹Value›** — `Flock::is_max_force`
  Setting of the “Flock” behavior, section “Movement”. Agility — how sharply the course changes.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Speed” of ‹Object› (Flock) ‹Sign› ‹Value›** — `Flock::is_max_speed`
  Setting of the “Flock” behavior, section “Movement”. Speed, pixels per second.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Neighbor radius” of ‹Object› (Flock) ‹Sign› ‹Value›** — `Flock::is_neighbor_radius`
  Setting of the “Flock” behavior, section “Flock”. Neighbor radius — who counts as a neighbor, pixels.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Rotate the object toward its course” of ‹Object› (Flock) ‹Sign› ‹Value›** — `Flock::is_rotate_object`
  Setting of the “Flock” behavior, section “Look”. Rotate the object toward its course.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“The flock is on” of ‹Object› (Flock) ‹Sign› ‹Value›** — `Flock::is_running`
  Setting of the “Flock” behavior, section “Flock”. The flock is on.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Separation” of ‹Object› (Flock) ‹Sign› ‹Value›** — `Flock::is_separation`
  Setting of the “Flock” behavior, section “Rules”. Separation — how strongly they keep their distance.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Personal space” of ‹Object› (Flock) ‹Sign› ‹Value›** — `Flock::is_separation_radius`
  Setting of the “Flock” behavior, section “Flock”. Personal space — closer than this, neighbors push apart, pixels.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“How much random wandering to add” of ‹Object› (Flock) ‹Sign› ‹Value›** — `Flock::is_wander`
  Setting of the “Flock” behavior, section “Movement”. How much random wandering to add, 0 — none.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

**Actions**

- **Scare the flock of ‹Object› with object ‹Object name›** — `Flock::flee_from`
  From the “Flock” behavior.
  Parameters: Object (object), Object name (text)

- **Lead the flock of ‹Object› to object ‹Object name›** — `Flock::follow`
  From the “Flock” behavior.
  Parameters: Object (object), Object name (text)

- **Push ‹Object› at an angle of ‹Angle, degrees› degrees with speed ‹Speed›** — `Flock::push`
  From the “Flock” behavior.
  Parameters: Object (object), Angle, degrees (number), Speed (number)

- **Change “Alignment” of ‹Object› (Flock): ‹Sign› ‹Value›** — `Flock::set_alignment`
  Setting of the “Flock” behavior, section “Rules”. Alignment — how much to fly the same way as the neighbors.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “At what distance to notice a wall ahead” of ‹Object› (Flock): ‹Sign› ‹Value›** — `Flock::set_avoid_distance`
  Setting of the “Flock” behavior, section “Obstacles”. At what distance to notice a wall ahead, pixels.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Go around walls” of ‹Object› (Flock): ‹Sign› ‹Value›** — `Flock::set_avoid_walls`
  Setting of the “Flock” behavior, section “Obstacles”. Go around walls.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Wall avoidance strength” of ‹Object› (Flock): ‹Sign› ‹Value›** — `Flock::set_avoid_weight`
  Setting of the “Flock” behavior, section “Obstacles”. Wall avoidance strength.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Cohesion” of ‹Object› (Flock): ‹Sign› ‹Value›** — `Flock::set_cohesion`
  Setting of the “Flock” behavior, section “Rules”. Cohesion — how much to pull toward the center of the neighbors.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Flip the sprite” of ‹Object› (Flock): ‹Sign› ‹Value›** — `Flock::set_flip_sprite`
  Setting of the “Flock” behavior, section “Look”. Flip the sprite — toward the movement direction.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Flock name” of ‹Object› (Flock): ‹Sign› ‹Value›** — `Flock::set_flock_name`
  Setting of the “Flock” behavior, section “Flock”. Flock name: objects with the same name stay together. Different names — different flocks.
  Parameters: Object (object), Sign (= + - * /), Value (text)

- **Change “An object to follow” of ‹Object› (Flock): ‹Sign› ‹Value›** — `Flock::set_follow_object`
  Setting of the “Flock” behavior, section “Leader”. An object to follow, e.g. Player. Empty — fly freely.
  Parameters: Object (object), Sign (= + - * /), Value (text)

- **Change “How strongly to pull toward it” of ‹Object› (Flock): ‹Sign› ‹Value›** — `Flock::set_follow_weight`
  Setting of the “Flock” behavior, section “Leader”. How strongly to pull toward it. Negative — flee.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Agility” of ‹Object› (Flock): ‹Sign› ‹Value›** — `Flock::set_max_force`
  Setting of the “Flock” behavior, section “Movement”. Agility — how sharply the course changes.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Speed” of ‹Object› (Flock): ‹Sign› ‹Value›** — `Flock::set_max_speed`
  Setting of the “Flock” behavior, section “Movement”. Speed, pixels per second.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Neighbor radius” of ‹Object› (Flock): ‹Sign› ‹Value›** — `Flock::set_neighbor_radius`
  Setting of the “Flock” behavior, section “Flock”. Neighbor radius — who counts as a neighbor, pixels.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Rotate the object toward its course” of ‹Object› (Flock): ‹Sign› ‹Value›** — `Flock::set_rotate_object`
  Setting of the “Flock” behavior, section “Look”. Rotate the object toward its course.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “The flock is on” of ‹Object› (Flock): ‹Sign› ‹Value›** — `Flock::set_running`
  Setting of the “Flock” behavior, section “Flock”. The flock is on.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Separation” of ‹Object› (Flock): ‹Sign› ‹Value›** — `Flock::set_separation`
  Setting of the “Flock” behavior, section “Rules”. Separation — how strongly they keep their distance.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Personal space” of ‹Object› (Flock): ‹Sign› ‹Value›** — `Flock::set_separation_radius`
  Setting of the “Flock” behavior, section “Flock”. Personal space — closer than this, neighbors push apart, pixels.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “How much random wandering to add” of ‹Object› (Flock): ‹Sign› ‹Value›** — `Flock::set_wander`
  Setting of the “Flock” behavior, section “Movement”. How much random wandering to add, 0 — none.
  Parameters: Object (object), Sign (= + - * /), Value (number)

**Expressions**

- `Object.Flock::Alignment()` — Alignment — how much to fly the same way as the neighbors.
- `Object.Flock::AvoidDistance()` — At what distance to notice a wall ahead, pixels.
- `Object.Flock::AvoidWalls()` — Go around walls.
- `Object.Flock::AvoidWeight()` — Wall avoidance strength.
- `Object.Flock::Cohesion()` — Cohesion — how much to pull toward the center of the neighbors.
- `Object.Flock::Course()` — Course in degrees
- `Object.Flock::FlipSprite()` — Flip the sprite — toward the movement direction.
- `Object.Flock::FlockName()` — Flock name: objects with the same name stay together. Different names — different flocks.
- `Object.Flock::FollowObject()` — An object to follow, e.g. Player. Empty — fly freely.
- `Object.Flock::FollowWeight()` — How strongly to pull toward it. Negative — flee.
- `Object.Flock::MaxForce()` — Agility — how sharply the course changes.
- `Object.Flock::MaxSpeed()` — Speed, pixels per second.
- `Object.Flock::NeighborCount()` — How many neighbors are near
- `Object.Flock::NeighborRadius()` — Neighbor radius — who counts as a neighbor, pixels.
- `Object.Flock::RotateObject()` — Rotate the object toward its course.
- `Object.Flock::Running()` — The flock is on.
- `Object.Flock::Separation()` — Separation — how strongly they keep their distance.
- `Object.Flock::SeparationRadius()` — Personal space — closer than this, neighbors push apart, pixels.
- `Object.Flock::Speed()` — Speed
- `Object.Flock::Wander()` — How much random wandering to add, 0 — none.

### Follow — Follow

Chase, flee or keep a distance. With acceleration, a detection zone and losing the target.

**Conditions**

- **‹Object› sees the target** — `Follow::has_target`
  From the “Follow” behavior.
  Parameters: Object (object)

- **“Acceleration” of ‹Object› (Follow) ‹Sign› ‹Value›** — `Follow::is_acceleration`
  Setting of the “Follow” behavior, section “Movement”. Acceleration, pixels per second per second. 0 — instant start.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Tolerance band around the distance” of ‹Object› (Follow) ‹Sign› ‹Value›** — `Follow::is_deadzone`
  Setting of the “Follow” behavior, section “Movement”. Tolerance band around the distance, so the object does not jitter in place.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Detection radius” of ‹Object› (Follow) ‹Sign› ‹Value›** — `Follow::is_detection_range`
  Setting of the “Follow” behavior, section “Vision”. Detection radius — the target is not noticed beyond it. 0 — no limit.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Flip the sprite” of ‹Object› (Follow) ‹Sign› ‹Value›** — `Follow::is_flip_sprite`
  Setting of the “Follow” behavior, section “Look”. Flip the sprite — toward the movement direction.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Lose radius” of ‹Object› (Follow) ‹Sign› ‹Value›** — `Follow::is_lose_range`
  Setting of the “Follow” behavior, section “Vision”. Lose radius — at what distance the target is lost.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“What to do with the target” of ‹Object› (Follow) ‹Sign› ‹Value›** — `Follow::is_mode`
  Setting of the “Follow” behavior, section “Target”. What to do with the target — chase, flee or keep a distance.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Turn toward the target” of ‹Object› (Follow) ‹Sign› ‹Value›** — `Follow::is_rotate_object`
  Setting of the “Follow” behavior, section “Look”. Turn toward the target.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Turn speed” of ‹Object› (Follow) ‹Sign› ‹Value›** — `Follow::is_rotation_speed`
  Setting of the “Follow” behavior, section “Look”. Turn speed, degrees per second.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Following is on” of ‹Object› (Follow) ‹Sign› ‹Value›** — `Follow::is_running`
  Setting of the “Follow” behavior, section “Target”. Following is on.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Chase speed” of ‹Object› (Follow) ‹Sign› ‹Value›** — `Follow::is_speed`
  Setting of the “Follow” behavior, section “Movement”. Chase speed, pixels per second.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Stop distance” of ‹Object› (Follow) ‹Sign› ‹Value›** — `Follow::is_stop_distance`
  Setting of the “Follow” behavior, section “Movement”. Stop distance — at what distance to stand still.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Target” of ‹Object› (Follow) ‹Sign› ‹Value›** — `Follow::is_target_object`
  Setting of the “Follow” behavior, section “Target”. Target — the name of an object from the event sheet, e.g. Player.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (text)

- **‹Object› reached the target** — `Follow::reached_target`
  From the “Follow” behavior.
  Parameters: Object (object)

**Actions**

- **Change “Acceleration” of ‹Object› (Follow): ‹Sign› ‹Value›** — `Follow::set_acceleration`
  Setting of the “Follow” behavior, section “Movement”. Acceleration, pixels per second per second. 0 — instant start.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Tolerance band around the distance” of ‹Object› (Follow): ‹Sign› ‹Value›** — `Follow::set_deadzone`
  Setting of the “Follow” behavior, section “Movement”. Tolerance band around the distance, so the object does not jitter in place.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Detection radius” of ‹Object› (Follow): ‹Sign› ‹Value›** — `Follow::set_detection_range`
  Setting of the “Follow” behavior, section “Vision”. Detection radius — the target is not noticed beyond it. 0 — no limit.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Flip the sprite” of ‹Object› (Follow): ‹Sign› ‹Value›** — `Follow::set_flip_sprite`
  Setting of the “Follow” behavior, section “Look”. Flip the sprite — toward the movement direction.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Lose radius” of ‹Object› (Follow): ‹Sign› ‹Value›** — `Follow::set_lose_range`
  Setting of the “Follow” behavior, section “Vision”. Lose radius — at what distance the target is lost.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Mode of ‹Object›: ‹Mode› (0 chase, 1 flee, 2 keep distance)** — `Follow::set_mode`
  From the “Follow” behavior.
  Parameters: Object (object), Mode (number)

- **Change “Turn toward the target” of ‹Object› (Follow): ‹Sign› ‹Value›** — `Follow::set_rotate_object`
  Setting of the “Follow” behavior, section “Look”. Turn toward the target.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Turn speed” of ‹Object› (Follow): ‹Sign› ‹Value›** — `Follow::set_rotation_speed`
  Setting of the “Follow” behavior, section “Look”. Turn speed, degrees per second.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Following is on” of ‹Object› (Follow): ‹Sign› ‹Value›** — `Follow::set_running`
  Setting of the “Follow” behavior, section “Target”. Following is on.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Chase speed” of ‹Object› (Follow): ‹Sign› ‹Value›** — `Follow::set_speed`
  Setting of the “Follow” behavior, section “Movement”. Chase speed, pixels per second.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Stop distance” of ‹Object› (Follow): ‹Sign› ‹Value›** — `Follow::set_stop_distance`
  Setting of the “Follow” behavior, section “Movement”. Stop distance — at what distance to stand still.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Target” of ‹Object› (Follow): ‹Sign› ‹Value›** — `Follow::set_target_object`
  Setting of the “Follow” behavior, section “Target”. Target — the name of an object from the event sheet, e.g. Player.
  Parameters: Object (object), Sign (= + - * /), Value (text)

- **Set the target of ‹Object›: object ‹Object name›** — `Follow::target`
  From the “Follow” behavior.
  Parameters: Object (object), Object name (text)

**Expressions**

- `Object.Follow::Acceleration()` — Acceleration, pixels per second per second. 0 — instant start.
- `Object.Follow::AngleToTarget()` — Angle to the target in degrees
- `Object.Follow::Deadzone()` — Tolerance band around the distance, so the object does not jitter in place.
- `Object.Follow::DetectionRange()` — Detection radius — the target is not noticed beyond it. 0 — no limit.
- `Object.Follow::DistanceToTarget()` — Distance to the target
- `Object.Follow::FlipSprite()` — Flip the sprite — toward the movement direction.
- `Object.Follow::LoseRange()` — Lose radius — at what distance the target is lost.
- `Object.Follow::Mode()` — What to do with the target — chase, flee or keep a distance.
- `Object.Follow::RotateObject()` — Turn toward the target.
- `Object.Follow::RotationSpeed()` — Turn speed, degrees per second.
- `Object.Follow::Running()` — Following is on.
- `Object.Follow::Speed()` — Chase speed, pixels per second.
- `Object.Follow::StopDistance()` — Stop distance — at what distance to stand still.
- `Object.Follow::TargetObject()` — Target — the name of an object from the event sheet, e.g. Player.

### GridStep — Grid step

Movement by cells: puzzles, roguelikes, sokoban. Walls stop it, objects with the same behavior occupy cells, and "pushable" ones move one cell further.

**Conditions**

- **‹Object› can step toward ‹Direction› (0 right, 1 down, 2 left, 3 up)** — `GridStep::can_step`
  From the “Grid step” behavior.
  Parameters: Object (object), Direction (number)

- **“Can push pushable objects” of ‹Object› (Grid step) ‹Sign› ‹Value›** — `GridStep::is_can_push`
  Setting of the “Grid step” behavior, section “Grid”. Can push pushable objects.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Cell size” of ‹Object› (Grid step) ‹Sign› ‹Value›** — `GridStep::is_cell_size`
  Setting of the “Grid step” behavior, section “Grid”. Cell size, pixels.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Arrow keys controls” of ‹Object› (Grid step) ‹Sign› ‹Value›** — `GridStep::is_default_controls`
  Setting of the “Grid step” behavior, section “Movement”. Arrow keys controls — automatic, without events.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Flip the sprite toward the step direction” of ‹Object› (Grid step) ‹Sign› ‹Value›** — `GridStep::is_flip_sprite`
  Setting of the “Grid step” behavior, section “Movement”. Flip the sprite toward the step direction.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Step repeat while a key is held” of ‹Object› (Grid step) ‹Sign› ‹Value›** — `GridStep::is_hold_repeat`
  Setting of the “Grid step” behavior, section “Movement”. Step repeat while a key is held, seconds. 0 — one step per press.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Pushable” of ‹Object› (Grid step) ‹Sign› ‹Value›** — `GridStep::is_pushable`
  Setting of the “Grid step” behavior, section “Grid”. Pushable — like a sokoban crate: it can be moved if the cell behind it is free.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Rotate the object toward the step” of ‹Object› (Grid step) ‹Sign› ‹Value›** — `GridStep::is_rotate_object`
  Setting of the “Grid step” behavior, section “Movement”. Rotate the object toward the step.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Snap to the center of a cell at the start” of ‹Object› (Grid step) ‹Sign› ‹Value›** — `GridStep::is_snap_on_start`
  Setting of the “Grid step” behavior, section “Grid”. Snap to the center of a cell at the start.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Occupies its cell” of ‹Object› (Grid step) ‹Sign› ‹Value›** — `GridStep::is_solid`
  Setting of the “Grid step” behavior, section “Grid”. Occupies its cell: other objects with "Grid step" cannot enter it.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Time of one step” of ‹Object› (Grid step) ‹Sign› ‹Value›** — `GridStep::is_step_time`
  Setting of the “Grid step” behavior, section “Movement”. Time of one step, seconds. 0 — instant.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **‹Object› is stepping** — `GridStep::is_stepping`
  From the “Grid step” behavior.
  Parameters: Object (object)

- **‹Object› has just bumped into something** — `GridStep::just_bumped`
  From the “Grid step” behavior.
  Parameters: Object (object)

- **‹Object› has just stepped** — `GridStep::just_stepped`
  From the “Grid step” behavior.
  Parameters: Object (object)

**Actions**

- **Change “Can push pushable objects” of ‹Object› (Grid step): ‹Sign› ‹Value›** — `GridStep::set_can_push`
  Setting of the “Grid step” behavior, section “Grid”. Can push pushable objects.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Cell size” of ‹Object› (Grid step): ‹Sign› ‹Value›** — `GridStep::set_cell_size`
  Setting of the “Grid step” behavior, section “Grid”. Cell size, pixels.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Arrow keys controls” of ‹Object› (Grid step): ‹Sign› ‹Value›** — `GridStep::set_default_controls`
  Setting of the “Grid step” behavior, section “Movement”. Arrow keys controls — automatic, without events.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Flip the sprite toward the step direction” of ‹Object› (Grid step): ‹Sign› ‹Value›** — `GridStep::set_flip_sprite`
  Setting of the “Grid step” behavior, section “Movement”. Flip the sprite toward the step direction.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Step repeat while a key is held” of ‹Object› (Grid step): ‹Sign› ‹Value›** — `GridStep::set_hold_repeat`
  Setting of the “Grid step” behavior, section “Movement”. Step repeat while a key is held, seconds. 0 — one step per press.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Pushable” of ‹Object› (Grid step): ‹Sign› ‹Value›** — `GridStep::set_pushable`
  Setting of the “Grid step” behavior, section “Grid”. Pushable — like a sokoban crate: it can be moved if the cell behind it is free.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Rotate the object toward the step” of ‹Object› (Grid step): ‹Sign› ‹Value›** — `GridStep::set_rotate_object`
  Setting of the “Grid step” behavior, section “Movement”. Rotate the object toward the step.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Snap to the center of a cell at the start” of ‹Object› (Grid step): ‹Sign› ‹Value›** — `GridStep::set_snap_on_start`
  Setting of the “Grid step” behavior, section “Grid”. Snap to the center of a cell at the start.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Occupies its cell” of ‹Object› (Grid step): ‹Sign› ‹Value›** — `GridStep::set_solid`
  Setting of the “Grid step” behavior, section “Grid”. Occupies its cell: other objects with "Grid step" cannot enter it.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Time of one step” of ‹Object› (Grid step): ‹Sign› ‹Value›** — `GridStep::set_step_time`
  Setting of the “Grid step” behavior, section “Movement”. Time of one step, seconds. 0 — instant.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Step ‹Object› toward ‹Direction› (0 right, 1 down, 2 left, 3 up)** — `GridStep::step`
  0 — right, 1 — down, 2 — left, 3 — up.
  Parameters: Object (object), Direction (number)

- **Step ‹Object› down** — `GridStep::step_down`
  From the “Grid step” behavior.
  Parameters: Object (object)

- **Step ‹Object› left** — `GridStep::step_left`
  From the “Grid step” behavior.
  Parameters: Object (object)

- **Step ‹Object› right** — `GridStep::step_right`
  From the “Grid step” behavior.
  Parameters: Object (object)

- **Step ‹Object› up** — `GridStep::step_up`
  From the “Grid step” behavior.
  Parameters: Object (object)

- **Put ‹Object› into cell ‹Cell X› ; ‹Cell Y›** — `GridStep::teleport`
  From the “Grid step” behavior.
  Parameters: Object (object), Cell X (number), Cell Y (number)

**Expressions**

- `Object.GridStep::CanPush()` — Can push pushable objects.
- `Object.GridStep::CellSize()` — Cell size, pixels.
- `Object.GridStep::CellX()` — Cell X
- `Object.GridStep::CellY()` — Cell Y
- `Object.GridStep::DefaultControls()` — Arrow keys controls — automatic, without events.
- `Object.GridStep::Facing()` — Where it faces: 0 right, 1 down, 2 left, 3 up
- `Object.GridStep::FlipSprite()` — Flip the sprite toward the step direction.
- `Object.GridStep::HoldRepeat()` — Step repeat while a key is held, seconds. 0 — one step per press.
- `Object.GridStep::Pushable()` — Pushable — like a sokoban crate: it can be moved if the cell behind it is free.
- `Object.GridStep::RotateObject()` — Rotate the object toward the step.
- `Object.GridStep::SnapOnStart()` — Snap to the center of a cell at the start.
- `Object.GridStep::Solid()` — Occupies its cell: other objects with "Grid step" cannot enter it.
- `Object.GridStep::StepTime()` — Time of one step, seconds. 0 — instant.
- `Object.GridStep::StepsTaken()` — How many steps were taken

### Health — Health

Health with armor, invulnerability after a hit, regeneration, blinking and a death scene.

**Conditions**

- **Health of ‹Object› is below ‹Percent› percent** — `Health::below_percent`
  From the “Health” behavior.
  Parameters: Object (object), Percent (number)

- **‹Object› is alive** — `Health::is_alive`
  From the “Health” behavior.
  Parameters: Object (object)

- **“Armor” of ‹Object› (Health) ‹Sign› ‹Value›** — `Health::is_armor_flat`
  Setting of the “Health” behavior, section “Protection”. Armor — how much damage is removed from each hit.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Armor share” of ‹Object› (Health) ‹Sign› ‹Value›** — `Health::is_armor_percent`
  Setting of the “Health” behavior, section “Protection”. Armor share — what part of the damage is absorbed, from 0 to 1.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Blink when taking damage” of ‹Object› (Health) ‹Sign› ‹Value›** — `Health::is_blink_on_hit`
  Setting of the “Health” behavior, section “Look”. Blink when taking damage.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Blink rate” of ‹Object› (Health) ‹Sign› ‹Value›** — `Health::is_blink_speed`
  Setting of the “Health” behavior, section “Look”. Blink rate, times per second.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Current health” of ‹Object› (Health) ‹Sign› ‹Value›** — `Health::is_current`
  Setting of the “Health” behavior, section “Health”. Current health. At start it is raised to the maximum, if enabled below.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **‹Object› has run out of health** — `Health::is_dead`
  From the “Health” behavior.
  Parameters: Object (object)

- **“Delay before deletion” of ‹Object› (Health) ‹Sign› ‹Value›** — `Health::is_death_delay`
  Setting of the “Health” behavior, section “Death”. Delay before deletion — time to finish the death animation.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Delete the object on death” of ‹Object› (Health) ‹Sign› ‹Value›** — `Health::is_destroy_on_death`
  Setting of the “Health” behavior, section “Death”. Delete the object on death.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Hurt animation” of ‹Object› (Health) ‹Sign› ‹Value›** — `Health::is_hurt_animation`
  Setting of the “Health” behavior, section “Look”. Hurt animation — the name of the animation that plays on a hit.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (text)

- **‹Object› is invulnerable now** — `Health::is_invulnerable`
  From the “Health” behavior.
  Parameters: Object (object)

- **“Invulnerability after a hit” of ‹Object› (Health) ‹Sign› ‹Value›** — `Health::is_invulnerable_time`
  Setting of the “Health” behavior, section “Protection”. Invulnerability after a hit, seconds.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Health pool” of ‹Object› (Health) ‹Sign› ‹Value›** — `Health::is_max_health`
  Setting of the “Health” behavior, section “Health”. Health pool — the object starts with it and heals up to it.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Minimum damage per hit” of ‹Object› (Health) ‹Sign› ‹Value›** — `Health::is_min_damage`
  Setting of the “Health” behavior, section “Protection”. Minimum damage per hit — armor cannot lower it further.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Regeneration delay” of ‹Object› (Health) ‹Sign› ‹Value›** — `Health::is_regen_delay`
  Setting of the “Health” behavior, section “Regeneration”. Regeneration delay — how many seconds it stays silent after damage.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Regeneration” of ‹Object› (Health) ‹Sign› ‹Value›** — `Health::is_regen_per_second`
  Setting of the “Health” behavior, section “Regeneration”. Regeneration — health units per second. 0 — no healing.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Full health at start” of ‹Object› (Health) ‹Sign› ‹Value›** — `Health::is_start_full`
  Setting of the “Health” behavior, section “Health”. Full health at start, regardless of the field above.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **‹Object› has just died** — `Health::just_died`
  From the “Health” behavior.
  Parameters: Object (object)

- **‹Object› has just taken damage** — `Health::just_hurt`
  From the “Health” behavior.
  Parameters: Object (object)

**Actions**

- **Deal ‹Damage› damage to ‹Object›** — `Health::damage`
  From the “Health” behavior.
  Parameters: Object (object), Damage (number)

- **Deal ‹Damage› damage to ‹Object› through invulnerability** — `Health::damage_pierce`
  From the “Health” behavior.
  Parameters: Object (object), Damage (number)

- **Heal ‹Object› by ‹Health›** — `Health::heal`
  From the “Health” behavior.
  Parameters: Object (object), Health (number)

- **Kill ‹Object› immediately** — `Health::kill`
  From the “Health” behavior.
  Parameters: Object (object)

- **Make ‹Object› invulnerable for ‹Seconds› seconds** — `Health::make_invulnerable`
  From the “Health” behavior.
  Parameters: Object (object), Seconds (number)

- **Fully heal ‹Object›** — `Health::restore`
  From the “Health” behavior.
  Parameters: Object (object)

- **Change “Armor” of ‹Object› (Health): ‹Sign› ‹Value›** — `Health::set_armor_flat`
  Setting of the “Health” behavior, section “Protection”. Armor — how much damage is removed from each hit.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Armor share” of ‹Object› (Health): ‹Sign› ‹Value›** — `Health::set_armor_percent`
  Setting of the “Health” behavior, section “Protection”. Armor share — what part of the damage is absorbed, from 0 to 1.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Blink when taking damage” of ‹Object› (Health): ‹Sign› ‹Value›** — `Health::set_blink_on_hit`
  Setting of the “Health” behavior, section “Look”. Blink when taking damage.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Blink rate” of ‹Object› (Health): ‹Sign› ‹Value›** — `Health::set_blink_speed`
  Setting of the “Health” behavior, section “Look”. Blink rate, times per second.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Current health” of ‹Object› (Health): ‹Sign› ‹Value›** — `Health::set_current`
  Setting of the “Health” behavior, section “Health”. Current health. At start it is raised to the maximum, if enabled below.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Delay before deletion” of ‹Object› (Health): ‹Sign› ‹Value›** — `Health::set_death_delay`
  Setting of the “Health” behavior, section “Death”. Delay before deletion — time to finish the death animation.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Delete the object on death” of ‹Object› (Health): ‹Sign› ‹Value›** — `Health::set_destroy_on_death`
  Setting of the “Health” behavior, section “Death”. Delete the object on death.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Hurt animation” of ‹Object› (Health): ‹Sign› ‹Value›** — `Health::set_hurt_animation`
  Setting of the “Health” behavior, section “Look”. Hurt animation — the name of the animation that plays on a hit.
  Parameters: Object (object), Sign (= + - * /), Value (text)

- **Change “Invulnerability after a hit” of ‹Object› (Health): ‹Sign› ‹Value›** — `Health::set_invulnerable_time`
  Setting of the “Health” behavior, section “Protection”. Invulnerability after a hit, seconds.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Health pool” of ‹Object› (Health): ‹Sign› ‹Value›** — `Health::set_max_health`
  Setting of the “Health” behavior, section “Health”. Health pool — the object starts with it and heals up to it.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Minimum damage per hit” of ‹Object› (Health): ‹Sign› ‹Value›** — `Health::set_min_damage`
  Setting of the “Health” behavior, section “Protection”. Minimum damage per hit — armor cannot lower it further.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Regeneration delay” of ‹Object› (Health): ‹Sign› ‹Value›** — `Health::set_regen_delay`
  Setting of the “Health” behavior, section “Regeneration”. Regeneration delay — how many seconds it stays silent after damage.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Regeneration” of ‹Object› (Health): ‹Sign› ‹Value›** — `Health::set_regen_per_second`
  Setting of the “Health” behavior, section “Regeneration”. Regeneration — health units per second. 0 — no healing.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Full health at start” of ‹Object› (Health): ‹Sign› ‹Value›** — `Health::set_start_full`
  Setting of the “Health” behavior, section “Health”. Full health at start, regardless of the field above.
  Parameters: Object (object), Sign (= + - * /), Value (number)

**Expressions**

- `Object.Health::ArmorFlat()` — Armor — how much damage is removed from each hit.
- `Object.Health::ArmorPercent()` — Armor share — what part of the damage is absorbed, from 0 to 1.
- `Object.Health::BlinkOnHit()` — Blink when taking damage.
- `Object.Health::BlinkSpeed()` — Blink rate, times per second.
- `Object.Health::Current()` — Current health. At start it is raised to the maximum, if enabled below.
- `Object.Health::DeathDelay()` — Delay before deletion — time to finish the death animation.
- `Object.Health::DestroyOnDeath()` — Delete the object on death.
- `Object.Health::Fraction()` — Health share from 0 to 1
- `Object.Health::HurtAnimation()` — Hurt animation — the name of the animation that plays on a hit.
- `Object.Health::InvulnerableLeft()` — Seconds of invulnerability left
- `Object.Health::InvulnerableTime()` — Invulnerability after a hit, seconds.
- `Object.Health::MaxHealth()` — Health pool — the object starts with it and heals up to it.
- `Object.Health::MinDamage()` — Minimum damage per hit — armor cannot lower it further.
- `Object.Health::Missing()` — How much health is missing to the maximum
- `Object.Health::RegenDelay()` — Regeneration delay — how many seconds it stays silent after damage.
- `Object.Health::RegenPerSecond()` — Regeneration — health units per second. 0 — no healing.
- `Object.Health::StartFull()` — Full health at start, regardless of the field above.

### Homing — Homing

A missile flies forward and turns toward the target with a limited turn speed. It can miss and lose the target if the target leaves its field of view. With "Shoot" it starts where it was fired.

**Conditions**

- **‹Object› has a target locked** — `Homing::has_target`
  From the “Homing” behavior.
  Parameters: Object (object)

- **“Acceleration” of ‹Object› (Homing) ‹Sign› ‹Value›** — `Homing::is_acceleration`
  Setting of the “Homing” behavior, section “Flight”. Acceleration, pixels per second per second. 0 — a constant speed.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Homing delay” of ‹Object› (Homing) ‹Sign› ‹Value›** — `Homing::is_arm_time`
  Setting of the “Homing” behavior, section “Flight”. Homing delay — how many seconds to fly straight after the start.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Lifetime” of ‹Object› (Homing) ‹Sign› ‹Value›** — `Homing::is_lifetime`
  Setting of the “Homing” behavior, section “Flight”. Lifetime, seconds: then the projectile disappears. 0 — forever.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Lock range” of ‹Object› (Homing) ‹Sign› ‹Value›** — `Homing::is_lock_range`
  Setting of the “Homing” behavior, section “Target”. Lock range — the target is not noticed beyond it. 0 — no limit.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Speed limit when accelerating” of ‹Object› (Homing) ‹Sign› ‹Value›** — `Homing::is_max_speed`
  Setting of the “Homing” behavior, section “Flight”. Speed limit when accelerating.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“After losing the target” of ‹Object› (Homing) ‹Sign› ‹Value›** — `Homing::is_retarget`
  Setting of the “Homing” behavior, section “Target”. After losing the target, look for a new one.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Rotate the object” of ‹Object› (Homing) ‹Sign› ‹Value›** — `Homing::is_rotate_object`
  Setting of the “Homing” behavior, section “Flight”. Rotate the object — toward the flight direction.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Homing is on” of ‹Object› (Homing) ‹Sign› ‹Value›** — `Homing::is_running`
  Setting of the “Homing” behavior, section “Flight”. Homing is on.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Speed” of ‹Object› (Homing) ‹Sign› ‹Value›** — `Homing::is_speed`
  Setting of the “Homing” behavior, section “Flight”. Speed, pixels per second.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Target” of ‹Object› (Homing) ‹Sign› ‹Value›** — `Homing::is_target_object`
  Setting of the “Homing” behavior, section “Target”. Target — the name of an object from the event sheet, e.g. Enemy.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (text)

- **“Turn speed” of ‹Object› (Homing) ‹Sign› ‹Value›** — `Homing::is_turn_speed`
  Setting of the “Homing” behavior, section “Flight”. Turn speed, degrees per second. Less — a wider arc and more misses.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Field of view” of ‹Object› (Homing) ‹Sign› ‹Value›** — `Homing::is_view_angle`
  Setting of the “Homing” behavior, section “Target”. Field of view, degrees: a target outside it is lost. 360 — sees all around and never misses.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **‹Object› has just locked a target** — `Homing::just_locked`
  From the “Homing” behavior.
  Parameters: Object (object)

- **‹Object› has just lost the target** — `Homing::just_lost`
  From the “Homing” behavior.
  Parameters: Object (object)

**Actions**

- **Drop the target of ‹Object›** — `Homing::drop_target`
  The projectile keeps flying straight and no longer looks for a target.
  Parameters: Object (object)

- **Launch ‹Object› at an angle of ‹Angle, degrees› degrees** — `Homing::launch`
  Set the flight direction. Needed if the projectile was created by an event, not by "Shoot".
  Parameters: Object (object), Angle, degrees (number)

- **Change “Acceleration” of ‹Object› (Homing): ‹Sign› ‹Value›** — `Homing::set_acceleration`
  Setting of the “Homing” behavior, section “Flight”. Acceleration, pixels per second per second. 0 — a constant speed.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Homing delay” of ‹Object› (Homing): ‹Sign› ‹Value›** — `Homing::set_arm_time`
  Setting of the “Homing” behavior, section “Flight”. Homing delay — how many seconds to fly straight after the start.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Lifetime” of ‹Object› (Homing): ‹Sign› ‹Value›** — `Homing::set_lifetime`
  Setting of the “Homing” behavior, section “Flight”. Lifetime, seconds: then the projectile disappears. 0 — forever.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Lock range” of ‹Object› (Homing): ‹Sign› ‹Value›** — `Homing::set_lock_range`
  Setting of the “Homing” behavior, section “Target”. Lock range — the target is not noticed beyond it. 0 — no limit.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Speed limit when accelerating” of ‹Object› (Homing): ‹Sign› ‹Value›** — `Homing::set_max_speed`
  Setting of the “Homing” behavior, section “Flight”. Speed limit when accelerating.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “After losing the target” of ‹Object› (Homing): ‹Sign› ‹Value›** — `Homing::set_retarget`
  Setting of the “Homing” behavior, section “Target”. After losing the target, look for a new one.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Rotate the object” of ‹Object› (Homing): ‹Sign› ‹Value›** — `Homing::set_rotate_object`
  Setting of the “Homing” behavior, section “Flight”. Rotate the object — toward the flight direction.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Homing is on” of ‹Object› (Homing): ‹Sign› ‹Value›** — `Homing::set_running`
  Setting of the “Homing” behavior, section “Flight”. Homing is on.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Speed” of ‹Object› (Homing): ‹Sign› ‹Value›** — `Homing::set_speed`
  Setting of the “Homing” behavior, section “Flight”. Speed, pixels per second.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Aim ‹Object› at object ‹Object name›** — `Homing::set_target`
  From the “Homing” behavior.
  Parameters: Object (object), Object name (text)

- **Change “Target” of ‹Object› (Homing): ‹Sign› ‹Value›** — `Homing::set_target_object`
  Setting of the “Homing” behavior, section “Target”. Target — the name of an object from the event sheet, e.g. Enemy.
  Parameters: Object (object), Sign (= + - * /), Value (text)

- **Change “Turn speed” of ‹Object› (Homing): ‹Sign› ‹Value›** — `Homing::set_turn_speed`
  Setting of the “Homing” behavior, section “Flight”. Turn speed, degrees per second. Less — a wider arc and more misses.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Field of view” of ‹Object› (Homing): ‹Sign› ‹Value›** — `Homing::set_view_angle`
  Setting of the “Homing” behavior, section “Target”. Field of view, degrees: a target outside it is lost. 360 — sees all around and never misses.
  Parameters: Object (object), Sign (= + - * /), Value (number)

**Expressions**

- `Object.Homing::Acceleration()` — Acceleration, pixels per second per second. 0 — a constant speed.
- `Object.Homing::ArmTime()` — Homing delay — how many seconds to fly straight after the start.
- `Object.Homing::CurrentSpeed()` — Current speed
- `Object.Homing::DistanceToTarget()` — Distance to the target, -1 — no target
- `Object.Homing::Heading()` — Flight direction in degrees
- `Object.Homing::Lifetime()` — Lifetime, seconds: then the projectile disappears. 0 — forever.
- `Object.Homing::LockRange()` — Lock range — the target is not noticed beyond it. 0 — no limit.
- `Object.Homing::MaxSpeed()` — Speed limit when accelerating.
- `Object.Homing::Retarget()` — After losing the target, look for a new one.
- `Object.Homing::RotateObject()` — Rotate the object — toward the flight direction.
- `Object.Homing::Running()` — Homing is on.
- `Object.Homing::Speed()` — Speed, pixels per second.
- `Object.Homing::TargetObject()` — Target — the name of an object from the event sheet, e.g. Enemy.
- `Object.Homing::TurnSpeed()` — Turn speed, degrees per second. Less — a wider arc and more misses.
- `Object.Homing::ViewAngle()` — Field of view, degrees: a target outside it is lost. 360 — sees all around and never misses.

### Juice — Juice

The game comes alive without a single event: squash and stretch on jumps and landings, dust underfoot, a flash and a shake on hits, a trail on dashes. It picks up the signals of "Platformer character", "Health", "Ability", "Top-down movement" and "Shoot" by itself.

**Conditions**

- **‹Object› is leaving a trail** — `Juice::has_trail`
  From the “Juice” behavior.
  Parameters: Object (object)

- **“How many dust specks” of ‹Object› (Juice) ‹Sign› ‹Value›** — `Juice::is_dust_count`
  Setting of the “Juice” behavior, section “Dust”. How many dust specks.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Dust on landing” of ‹Object› (Juice) ‹Sign› ‹Value›** — `Juice::is_dust_on_land`
  Setting of the “Juice” behavior, section “Dust”. Dust on landing — from underfoot, and on wall jumps too.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“A flash when taking damage” of ‹Object› (Juice) ‹Sign› ‹Value›** — `Juice::is_flash_on_hit`
  Setting of the “Juice” behavior, section “Hit”. A flash when taking damage.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Flash duration” of ‹Object› (Juice) ‹Sign› ‹Value›** — `Juice::is_flash_time`
  Setting of the “Juice” behavior, section “Hit”. Flash duration, seconds.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Shake on a hit” of ‹Object› (Juice) ‹Sign› ‹Value›** — `Juice::is_hit_shake`
  Setting of the “Juice” behavior, section “Hit”. Shake on a hit, pixels. 0 — no shake.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Kick on a shot” of ‹Object› (Juice) ‹Sign› ‹Value›** — `Juice::is_kick_on_shot`
  Setting of the “Juice” behavior, section “Squash”. Kick on a shot — a light squash.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Squash strength” of ‹Object› (Juice) ‹Sign› ‹Value›** — `Juice::is_squash_amount`
  Setting of the “Juice” behavior, section “Squash”. Squash strength, share: 0.25 — by a quarter.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Stretch on a jump and squash on landing” of ‹Object› (Juice) ‹Sign› ‹Value›** — `Juice::is_squash_on_jump`
  Setting of the “Juice” behavior, section “Squash”. Stretch on a jump and squash on landing.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Time for the shape to come back” of ‹Object› (Juice) ‹Sign› ‹Value›** — `Juice::is_squash_time`
  Setting of the “Juice” behavior, section “Squash”. Time for the shape to come back, seconds.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“How often to leave a silhouette” of ‹Object› (Juice) ‹Sign› ‹Value›** — `Juice::is_trail_interval`
  Setting of the “Juice” behavior, section “Trail”. How often to leave a silhouette, seconds.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“How many seconds each silhouette is visible” of ‹Object› (Juice) ‹Sign› ‹Value›** — `Juice::is_trail_life`
  Setting of the “Juice” behavior, section “Trail”. How many seconds each silhouette is visible.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“A trail of silhouettes during a dash” of ‹Object› (Juice) ‹Sign› ‹Value›** — `Juice::is_trail_on_dash`
  Setting of the “Juice” behavior, section “Trail”. A trail of silhouettes during a dash.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

**Actions**

- **Dust from under the feet of ‹Object›** — `Juice::dust`
  From the “Juice” behavior.
  Parameters: Object (object)

- **Flash on ‹Object›** — `Juice::flash`
  From the “Juice” behavior.
  Parameters: Object (object)

- **Change “How many dust specks” of ‹Object› (Juice): ‹Sign› ‹Value›** — `Juice::set_dust_count`
  Setting of the “Juice” behavior, section “Dust”. How many dust specks.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Dust on landing” of ‹Object› (Juice): ‹Sign› ‹Value›** — `Juice::set_dust_on_land`
  Setting of the “Juice” behavior, section “Dust”. Dust on landing — from underfoot, and on wall jumps too.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “A flash when taking damage” of ‹Object› (Juice): ‹Sign› ‹Value›** — `Juice::set_flash_on_hit`
  Setting of the “Juice” behavior, section “Hit”. A flash when taking damage.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Flash duration” of ‹Object› (Juice): ‹Sign› ‹Value›** — `Juice::set_flash_time`
  Setting of the “Juice” behavior, section “Hit”. Flash duration, seconds.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Shake on a hit” of ‹Object› (Juice): ‹Sign› ‹Value›** — `Juice::set_hit_shake`
  Setting of the “Juice” behavior, section “Hit”. Shake on a hit, pixels. 0 — no shake.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Kick on a shot” of ‹Object› (Juice): ‹Sign› ‹Value›** — `Juice::set_kick_on_shot`
  Setting of the “Juice” behavior, section “Squash”. Kick on a shot — a light squash.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Squash strength” of ‹Object› (Juice): ‹Sign› ‹Value›** — `Juice::set_squash_amount`
  Setting of the “Juice” behavior, section “Squash”. Squash strength, share: 0.25 — by a quarter.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Stretch on a jump and squash on landing” of ‹Object› (Juice): ‹Sign› ‹Value›** — `Juice::set_squash_on_jump`
  Setting of the “Juice” behavior, section “Squash”. Stretch on a jump and squash on landing.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Time for the shape to come back” of ‹Object› (Juice): ‹Sign› ‹Value›** — `Juice::set_squash_time`
  Setting of the “Juice” behavior, section “Squash”. Time for the shape to come back, seconds.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “How often to leave a silhouette” of ‹Object› (Juice): ‹Sign› ‹Value›** — `Juice::set_trail_interval`
  Setting of the “Juice” behavior, section “Trail”. How often to leave a silhouette, seconds.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “How many seconds each silhouette is visible” of ‹Object› (Juice): ‹Sign› ‹Value›** — `Juice::set_trail_life`
  Setting of the “Juice” behavior, section “Trail”. How many seconds each silhouette is visible.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “A trail of silhouettes during a dash” of ‹Object› (Juice): ‹Sign› ‹Value›** — `Juice::set_trail_on_dash`
  Setting of the “Juice” behavior, section “Trail”. A trail of silhouettes during a dash.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Squash ‹Object› by ‹Strength›** — `Juice::squash`
  Plus — squash (wider and lower), minus — stretch (narrower and taller).
  Parameters: Object (object), Strength (number)

- **A trail behind ‹Object› for ‹Seconds› seconds** — `Juice::trail`
  From the “Juice” behavior.
  Parameters: Object (object), Seconds (number)

**Expressions**

- `Object.Juice::DustCount()` — How many dust specks.
- `Object.Juice::DustOnLand()` — Dust on landing — from underfoot, and on wall jumps too.
- `Object.Juice::FlashOnHit()` — A flash when taking damage.
- `Object.Juice::FlashTime()` — Flash duration, seconds.
- `Object.Juice::HitShake()` — Shake on a hit, pixels. 0 — no shake.
- `Object.Juice::KickOnShot()` — Kick on a shot — a light squash.
- `Object.Juice::SquashAmount()` — Squash strength, share: 0.25 — by a quarter.
- `Object.Juice::SquashOnJump()` — Stretch on a jump and squash on landing.
- `Object.Juice::SquashTime()` — Time for the shape to come back, seconds.
- `Object.Juice::TrailInterval()` — How often to leave a silhouette, seconds.
- `Object.Juice::TrailLife()` — How many seconds each silhouette is visible.
- `Object.Juice::TrailOnDash()` — A trail of silhouettes during a dash.

### Ladder — Ladder

A zone where a "Platformer character" climbs up and down with the arrow keys. Jump to get off. A vine, a rope and ivy are ladders too.

**Conditions**

- **Someone is climbing ‹Object›** — `Ladder::has_climber`
  From the “Ladder” behavior.
  Parameters: Object (object)

- **“Climbing speed” of ‹Object› (Ladder) ‹Sign› ‹Value›** — `Ladder::is_climb_speed`
  Setting of the “Ladder” behavior. Climbing speed, pixels per second. 0 — as in the platformer settings.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Climbing is allowed” of ‹Object› (Ladder) ‹Sign› ‹Value›** — `Ladder::is_enabled`
  Setting of the “Ladder” behavior. Climbing is allowed.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Put the climber at the center of the ladder” of ‹Object› (Ladder) ‹Sign› ‹Value›** — `Ladder::is_snap_to_center`
  Setting of the “Ladder” behavior. Put the climber at the center of the ladder, as on a real ladder. Turn off for a wide wall with ivy.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

**Actions**

- **Change “Climbing speed” of ‹Object› (Ladder): ‹Sign› ‹Value›** — `Ladder::set_climb_speed`
  Setting of the “Ladder” behavior. Climbing speed, pixels per second. 0 — as in the platformer settings.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Allow climbing ‹Object›: ‹Yes or no› (1 yes, 0 no)** — `Ladder::set_enabled`
  From the “Ladder” behavior.
  Parameters: Object (object), Yes or no (number)

- **Change “Put the climber at the center of the ladder” of ‹Object› (Ladder): ‹Sign› ‹Value›** — `Ladder::set_snap_to_center`
  Setting of the “Ladder” behavior. Put the climber at the center of the ladder, as on a real ladder. Turn off for a wide wall with ivy.
  Parameters: Object (object), Sign (= + - * /), Value (number)

**Expressions**

- `Object.Ladder::ClimbSpeed()` — Climbing speed, pixels per second. 0 — as in the platformer settings.
- `Object.Ladder::Enabled()` — Climbing is allowed.
- `Object.Ladder::SnapToCenter()` — Put the climber at the center of the ladder, as on a real ladder. Turn off for a wide wall with ivy.

### LinearMove — Linear movement

Movement at an angle with acceleration, gravity, drag, bouncing off the edges and fading. The basis for bullets and simple enemies.

**Conditions**

- **“Acceleration” of ‹Object› (Linear movement) ‹Sign› ‹Value›** — `LinearMove::is_acceleration`
  Setting of the “Linear movement” behavior, section “Movement”. Acceleration, pixels per second per second. Negative — slowing down.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Direction in degrees” of ‹Object› (Linear movement) ‹Sign› ‹Value›** — `LinearMove::is_angle`
  Setting of the “Linear movement” behavior, section “Movement”. Direction in degrees: 0 right, −90 up, 90 down.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Bounce off the screen edges” of ‹Object› (Linear movement) ‹Sign› ‹Value›** — `LinearMove::is_bounce_off_edges`
  Setting of the “Linear movement” behavior, section “Screen edges”. Bounce off the screen edges — instead of flying out.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Bounciness” of ‹Object› (Linear movement) ‹Sign› ‹Value›** — `LinearMove::is_bounciness`
  Setting of the “Linear movement” behavior, section “Screen edges”. Bounciness — what share of the speed remains after a bounce.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Drag of the medium” of ‹Object› (Linear movement) ‹Sign› ‹Value›** — `LinearMove::is_drag`
  Setting of the “Linear movement” behavior, section “Movement”. Drag of the medium — what share of the speed is lost per second.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Fade-out” of ‹Object› (Linear movement) ‹Sign› ‹Value›** — `LinearMove::is_fade_out`
  Setting of the “Linear movement” behavior, section “Life”. Fade-out — how many seconds before the end to start fading.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Gravity” of ‹Object› (Linear movement) ‹Sign› ‹Value›** — `LinearMove::is_gravity`
  Setting of the “Linear movement” behavior, section “Gravity”. Gravity — pulls down, turning the flight into an arc.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Lifetime” of ‹Object› (Linear movement) ‹Sign› ‹Value›** — `LinearMove::is_lifetime`
  Setting of the “Linear movement” behavior, section “Life”. Lifetime, seconds. 0 — lives forever.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Speed limit when accelerating” of ‹Object› (Linear movement) ‹Sign› ‹Value›** — `LinearMove::is_max_speed`
  Setting of the “Linear movement” behavior, section “Movement”. Speed limit when accelerating.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **‹Object› is moving** — `LinearMove::is_moving`
  From the “Linear movement” behavior.
  Parameters: Object (object)

- **“Rotate the object” of ‹Object› (Linear movement) ‹Sign› ‹Value›** — `LinearMove::is_rotate_to_direction`
  Setting of the “Linear movement” behavior, section “Look”. Rotate the object — toward the flight direction.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Flight speed” of ‹Object› (Linear movement) ‹Sign› ‹Value›** — `LinearMove::is_speed`
  Setting of the “Linear movement” behavior, section “Movement”. Flight speed, pixels per second.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

**Actions**

- **Aim ‹Object› at the nearest object ‹Object name›** — `LinearMove::aim_at`
  From the “Linear movement” behavior.
  Parameters: Object (object), Object name (text)

- **Extend the life of ‹Object› by ‹Seconds› seconds** — `LinearMove::extend_life`
  From the “Linear movement” behavior.
  Parameters: Object (object), Seconds (number)

- **Turn ‹Object› around by 180 degrees** — `LinearMove::reverse`
  From the “Linear movement” behavior.
  Parameters: Object (object)

- **Change “Acceleration” of ‹Object› (Linear movement): ‹Sign› ‹Value›** — `LinearMove::set_acceleration`
  Setting of the “Linear movement” behavior, section “Movement”. Acceleration, pixels per second per second. Negative — slowing down.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Direction in degrees” of ‹Object› (Linear movement): ‹Sign› ‹Value›** — `LinearMove::set_angle`
  Setting of the “Linear movement” behavior, section “Movement”. Direction in degrees: 0 right, −90 up, 90 down.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Bounce off the screen edges” of ‹Object› (Linear movement): ‹Sign› ‹Value›** — `LinearMove::set_bounce_off_edges`
  Setting of the “Linear movement” behavior, section “Screen edges”. Bounce off the screen edges — instead of flying out.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Bounciness” of ‹Object› (Linear movement): ‹Sign› ‹Value›** — `LinearMove::set_bounciness`
  Setting of the “Linear movement” behavior, section “Screen edges”. Bounciness — what share of the speed remains after a bounce.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Set the movement of ‹Object›: angle ‹Angle, degrees› degrees, speed ‹Speed›** — `LinearMove::set_direction`
  From the “Linear movement” behavior.
  Parameters: Object (object), Angle, degrees (number), Speed (number)

- **Change “Drag of the medium” of ‹Object› (Linear movement): ‹Sign› ‹Value›** — `LinearMove::set_drag`
  Setting of the “Linear movement” behavior, section “Movement”. Drag of the medium — what share of the speed is lost per second.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Fade-out” of ‹Object› (Linear movement): ‹Sign› ‹Value›** — `LinearMove::set_fade_out`
  Setting of the “Linear movement” behavior, section “Life”. Fade-out — how many seconds before the end to start fading.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Gravity” of ‹Object› (Linear movement): ‹Sign› ‹Value›** — `LinearMove::set_gravity`
  Setting of the “Linear movement” behavior, section “Gravity”. Gravity — pulls down, turning the flight into an arc.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Lifetime” of ‹Object› (Linear movement): ‹Sign› ‹Value›** — `LinearMove::set_lifetime`
  Setting of the “Linear movement” behavior, section “Life”. Lifetime, seconds. 0 — lives forever.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Speed limit when accelerating” of ‹Object› (Linear movement): ‹Sign› ‹Value›** — `LinearMove::set_max_speed`
  Setting of the “Linear movement” behavior, section “Movement”. Speed limit when accelerating.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Rotate the object” of ‹Object› (Linear movement): ‹Sign› ‹Value›** — `LinearMove::set_rotate_to_direction`
  Setting of the “Linear movement” behavior, section “Look”. Rotate the object — toward the flight direction.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Flight speed” of ‹Object› (Linear movement): ‹Sign› ‹Value›** — `LinearMove::set_speed`
  Setting of the “Linear movement” behavior, section “Movement”. Flight speed, pixels per second.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Turn the flight of ‹Object› by ‹Degrees› degrees** — `LinearMove::turn`
  From the “Linear movement” behavior.
  Parameters: Object (object), Degrees (number)

**Expressions**

- `Object.LinearMove::Acceleration()` — Acceleration, pixels per second per second. Negative — slowing down.
- `Object.LinearMove::Age()` — How many seconds the object has lived
- `Object.LinearMove::Angle()` — Direction in degrees: 0 right, −90 up, 90 down.
- `Object.LinearMove::BounceOffEdges()` — Bounce off the screen edges — instead of flying out.
- `Object.LinearMove::Bounciness()` — Bounciness — what share of the speed remains after a bounce.
- `Object.LinearMove::Drag()` — Drag of the medium — what share of the speed is lost per second.
- `Object.LinearMove::FadeOut()` — Fade-out — how many seconds before the end to start fading.
- `Object.LinearMove::Gravity()` — Gravity — pulls down, turning the flight into an arc.
- `Object.LinearMove::LifeLeft()` — How many seconds of life are left
- `Object.LinearMove::Lifetime()` — Lifetime, seconds. 0 — lives forever.
- `Object.LinearMove::MaxSpeed()` — Speed limit when accelerating.
- `Object.LinearMove::RotateToDirection()` — Rotate the object — toward the flight direction.
- `Object.LinearMove::Speed()` — Flight speed, pixels per second.

### Melee — Melee attack

A strike with a sword, a fist, a paw. The hit zone turns on at the right frames of the attack animation, hits everyone once per swing and knocks them back. Combos of up to three strikes and a cooldown.

**Conditions**

- **‹Object› can attack** — `Melee::can_attack`
  From the “Melee attack” behavior.
  Parameters: Object (object)

- **“Active share” of ‹Object› (Melee attack) ‹Sign› ‹Value›** — `Melee::is_active_share`
  Setting of the “Melee attack” behavior, section “Timing”. Active share — without an animation, the share of the strike the zone is on, around the middle.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Animation of the second strike” of ‹Object› (Melee attack) ‹Sign› ‹Value›** — `Melee::is_attack_2_animation`
  Setting of the “Melee attack” behavior, section “Combo”. Animation of the second strike. Empty — as the first.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (text)

- **“Animation of the third strike” of ‹Object› (Melee attack) ‹Sign› ‹Value›** — `Melee::is_attack_3_animation`
  Setting of the “Melee attack” behavior, section “Combo”. Animation of the third strike. Empty — as the second.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (text)

- **“Animation of the first strike” of ‹Object› (Melee attack) ‹Sign› ‹Value›** — `Melee::is_attack_animation`
  Setting of the “Melee attack” behavior, section “Combo”. Animation of the first strike — a name from AnimatedSprite2D. Empty — a timed strike.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (text)

- **“Attack key” of ‹Object› (Melee attack) ‹Sign› ‹Value›** — `Melee::is_attack_key`
  Setting of the “Melee attack” behavior, section “Controls”. Attack key, e.g. X. Empty — only by an action from the sheet.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (text)

- **‹Object› is attacking** — `Melee::is_attacking`
  From the “Melee attack” behavior.
  Parameters: Object (object)

- **“Damage added on each next strike of a combo” of ‹Object› (Melee attack) ‹Sign› ‹Value›** — `Melee::is_combo_bonus`
  Setting of the “Melee attack” behavior, section “Target”. Damage added on each next strike of a combo.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Strikes in a combo” of ‹Object› (Melee attack) ‹Sign› ‹Value›** — `Melee::is_combo_steps`
  Setting of the “Melee attack” behavior, section “Combo”. Strikes in a combo: 1 — no combo.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Combo window” of ‹Object› (Melee attack) ‹Sign› ‹Value›** — `Melee::is_combo_window`
  Setting of the “Melee attack” behavior, section “Combo”. Combo window — how many seconds after a strike to wait for the next press.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Cooldown after a combo” of ‹Object› (Melee attack) ‹Sign› ‹Value›** — `Melee::is_cooldown`
  Setting of the “Melee attack” behavior, section “Timing”. Cooldown after a combo, seconds.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Damage per strike” of ‹Object› (Melee attack) ‹Sign› ‹Value›** — `Melee::is_damage`
  Setting of the “Melee attack” behavior, section “Target”. Damage per strike. Hits through the target's "Health" behavior.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“First hit frame” of ‹Object› (Melee attack) ‹Sign› ‹Value›** — `Melee::is_hit_frame_from`
  Setting of the “Melee attack” behavior, section “Timing”. First hit frame — from which frame of the attack animation the zone turns on.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Up to which frame the zone is on” of ‹Object› (Melee attack) ‹Sign› ‹Value›** — `Melee::is_hit_frame_to`
  Setting of the “Melee attack” behavior, section “Timing”. Up to which frame the zone is on.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Target knockback” of ‹Object› (Melee attack) ‹Sign› ‹Value›** — `Melee::is_knockback`
  Setting of the “Melee attack” behavior, section “Target”. Target knockback, pixels.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Show the hit zone” of ‹Object› (Melee attack) ‹Sign› ‹Value›** — `Melee::is_show_zone`
  Setting of the “Melee attack” behavior, section “Hit zone”. Show the hit zone — for debugging.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Strike duration without an animation” of ‹Object› (Melee attack) ‹Sign› ‹Value›** — `Melee::is_swing_time`
  Setting of the “Melee attack” behavior, section “Timing”. Strike duration without an animation, seconds. With an animation, the strike lasts while it plays.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Whom to hit” of ‹Object› (Melee attack) ‹Sign› ‹Value›** — `Melee::is_target_object`
  Setting of the “Melee attack” behavior, section “Target”. Whom to hit — the name of a sheet object, e.g. Enemy.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (text)

- **“Zone offset forward from the object” of ‹Object› (Melee attack) ‹Sign› ‹Value›** — `Melee::is_zone_forward`
  Setting of the “Melee attack” behavior, section “Hit zone”. Zone offset forward from the object, pixels. It does not hit behind: the zone turns with the sprite.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Zone height” of ‹Object› (Melee attack) ‹Sign› ‹Value›** — `Melee::is_zone_height`
  Setting of the “Melee attack” behavior, section “Hit zone”. Zone height, pixels.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Vertical zone offset” of ‹Object› (Melee attack) ‹Sign› ‹Value›** — `Melee::is_zone_up`
  Setting of the “Melee attack” behavior, section “Hit zone”. Vertical zone offset, pixels. Minus — higher.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Zone width” of ‹Object› (Melee attack) ‹Sign› ‹Value›** — `Melee::is_zone_width`
  Setting of the “Melee attack” behavior, section “Hit zone”. Zone width, pixels.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **‹Object› has just hit** — `Melee::just_hit`
  From the “Melee attack” behavior.
  Parameters: Object (object)

- **The hit zone of ‹Object› is on** — `Melee::zone_active`
  From the “Melee attack” behavior.
  Parameters: Object (object)

**Actions**

- **Attack: ‹Object›** — `Melee::attack`
  A press during a strike is remembered and continues the combo.
  Parameters: Object (object)

- **Interrupt the attack of ‹Object›** — `Melee::interrupt`
  From the “Melee attack” behavior.
  Parameters: Object (object)

- **Change “Active share” of ‹Object› (Melee attack): ‹Sign› ‹Value›** — `Melee::set_active_share`
  Setting of the “Melee attack” behavior, section “Timing”. Active share — without an animation, the share of the strike the zone is on, around the middle.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Animation of the second strike” of ‹Object› (Melee attack): ‹Sign› ‹Value›** — `Melee::set_attack_2_animation`
  Setting of the “Melee attack” behavior, section “Combo”. Animation of the second strike. Empty — as the first.
  Parameters: Object (object), Sign (= + - * /), Value (text)

- **Change “Animation of the third strike” of ‹Object› (Melee attack): ‹Sign› ‹Value›** — `Melee::set_attack_3_animation`
  Setting of the “Melee attack” behavior, section “Combo”. Animation of the third strike. Empty — as the second.
  Parameters: Object (object), Sign (= + - * /), Value (text)

- **Change “Animation of the first strike” of ‹Object› (Melee attack): ‹Sign› ‹Value›** — `Melee::set_attack_animation`
  Setting of the “Melee attack” behavior, section “Combo”. Animation of the first strike — a name from AnimatedSprite2D. Empty — a timed strike.
  Parameters: Object (object), Sign (= + - * /), Value (text)

- **Change “Attack key” of ‹Object› (Melee attack): ‹Sign› ‹Value›** — `Melee::set_attack_key`
  Setting of the “Melee attack” behavior, section “Controls”. Attack key, e.g. X. Empty — only by an action from the sheet.
  Parameters: Object (object), Sign (= + - * /), Value (text)

- **Change “Damage added on each next strike of a combo” of ‹Object› (Melee attack): ‹Sign› ‹Value›** — `Melee::set_combo_bonus`
  Setting of the “Melee attack” behavior, section “Target”. Damage added on each next strike of a combo.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Strikes in a combo” of ‹Object› (Melee attack): ‹Sign› ‹Value›** — `Melee::set_combo_steps`
  Setting of the “Melee attack” behavior, section “Combo”. Strikes in a combo: 1 — no combo.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Combo window” of ‹Object› (Melee attack): ‹Sign› ‹Value›** — `Melee::set_combo_window`
  Setting of the “Melee attack” behavior, section “Combo”. Combo window — how many seconds after a strike to wait for the next press.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Cooldown after a combo” of ‹Object› (Melee attack): ‹Sign› ‹Value›** — `Melee::set_cooldown`
  Setting of the “Melee attack” behavior, section “Timing”. Cooldown after a combo, seconds.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Damage per strike” of ‹Object› (Melee attack): ‹Sign› ‹Value›** — `Melee::set_damage`
  Setting of the “Melee attack” behavior, section “Target”. Damage per strike. Hits through the target's "Health" behavior.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “First hit frame” of ‹Object› (Melee attack): ‹Sign› ‹Value›** — `Melee::set_hit_frame_from`
  Setting of the “Melee attack” behavior, section “Timing”. First hit frame — from which frame of the attack animation the zone turns on.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Up to which frame the zone is on” of ‹Object› (Melee attack): ‹Sign› ‹Value›** — `Melee::set_hit_frame_to`
  Setting of the “Melee attack” behavior, section “Timing”. Up to which frame the zone is on.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Target knockback” of ‹Object› (Melee attack): ‹Sign› ‹Value›** — `Melee::set_knockback`
  Setting of the “Melee attack” behavior, section “Target”. Target knockback, pixels.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Show the hit zone” of ‹Object› (Melee attack): ‹Sign› ‹Value›** — `Melee::set_show_zone`
  Setting of the “Melee attack” behavior, section “Hit zone”. Show the hit zone — for debugging.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Strike duration without an animation” of ‹Object› (Melee attack): ‹Sign› ‹Value›** — `Melee::set_swing_time`
  Setting of the “Melee attack” behavior, section “Timing”. Strike duration without an animation, seconds. With an animation, the strike lasts while it plays.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Whom to hit” of ‹Object› (Melee attack): ‹Sign› ‹Value›** — `Melee::set_target_object`
  Setting of the “Melee attack” behavior, section “Target”. Whom to hit — the name of a sheet object, e.g. Enemy.
  Parameters: Object (object), Sign (= + - * /), Value (text)

- **Change “Zone offset forward from the object” of ‹Object› (Melee attack): ‹Sign› ‹Value›** — `Melee::set_zone_forward`
  Setting of the “Melee attack” behavior, section “Hit zone”. Zone offset forward from the object, pixels. It does not hit behind: the zone turns with the sprite.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Zone height” of ‹Object› (Melee attack): ‹Sign› ‹Value›** — `Melee::set_zone_height`
  Setting of the “Melee attack” behavior, section “Hit zone”. Zone height, pixels.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Vertical zone offset” of ‹Object› (Melee attack): ‹Sign› ‹Value›** — `Melee::set_zone_up`
  Setting of the “Melee attack” behavior, section “Hit zone”. Vertical zone offset, pixels. Minus — higher.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Zone width” of ‹Object› (Melee attack): ‹Sign› ‹Value›** — `Melee::set_zone_width`
  Setting of the “Melee attack” behavior, section “Hit zone”. Zone width, pixels.
  Parameters: Object (object), Sign (= + - * /), Value (number)

**Expressions**

- `Object.Melee::ActiveShare()` — Active share — without an animation, the share of the strike the zone is on, around the middle.
- `Object.Melee::Attack2Animation()` — Animation of the second strike. Empty — as the first.
- `Object.Melee::Attack3Animation()` — Animation of the third strike. Empty — as the second.
- `Object.Melee::AttackAnimation()` — Animation of the first strike — a name from AnimatedSprite2D. Empty — a timed strike.
- `Object.Melee::AttackKey()` — Attack key, e.g. X. Empty — only by an action from the sheet.
- `Object.Melee::ComboBonus()` — Damage added on each next strike of a combo.
- `Object.Melee::ComboStep()` — Combo step: 0 — not attacking, 1, 2, 3
- `Object.Melee::ComboSteps()` — Strikes in a combo: 1 — no combo.
- `Object.Melee::ComboWindow()` — Combo window — how many seconds after a strike to wait for the next press.
- `Object.Melee::Cooldown()` — Cooldown after a combo, seconds.
- `Object.Melee::CooldownLeft()` — How many seconds until the cooldown ends
- `Object.Melee::Damage()` — Damage per strike. Hits through the target's "Health" behavior.
- `Object.Melee::HitCount()` — How many times it hit
- `Object.Melee::HitFrameFrom()` — First hit frame — from which frame of the attack animation the zone turns on.
- `Object.Melee::HitFrameTo()` — Up to which frame the zone is on.
- `Object.Melee::Knockback()` — Target knockback, pixels.
- `Object.Melee::ShowZone()` — Show the hit zone — for debugging.
- `Object.Melee::SwingTime()` — Strike duration without an animation, seconds. With an animation, the strike lasts while it plays.
- `Object.Melee::TargetObject()` — Whom to hit — the name of a sheet object, e.g. Enemy.
- `Object.Melee::ZoneForward()` — Zone offset forward from the object, pixels. It does not hit behind: the zone turns with the sprite.
- `Object.Melee::ZoneHeight()` — Zone height, pixels.
- `Object.Melee::ZoneUp()` — Vertical zone offset, pixels. Minus — higher.
- `Object.Melee::ZoneWidth()` — Zone width, pixels.

### MenuButton — Menu button

A button for the main menu and pause: hover, press, sound, a slight zoom. Works on a picture and on a UI button, with arrow keys and Enter, and during pause. On press it can go to a scene, restart it, unpause or quit by itself.

**Conditions**

- **“Animation speed” of ‹Object› (Menu button) ‹Sign› ‹Value›** — `MenuButton::is_anim_speed`
  Setting of the “Menu button” behavior, section “Look”. Animation speed — the higher, the snappier.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Press sound” of ‹Object› (Menu button) ‹Sign› ‹Value›** — `MenuButton::is_click_sound`
  Setting of the “Menu button” behavior, section “Sound”. Press sound — a file path.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (text)

- **“The button works” of ‹Object› (Menu button) ‹Sign› ‹Value›** — `MenuButton::is_enabled`
  Setting of the “Menu button” behavior, section “Press”. The button works.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Zoom on hover” of ‹Object› (Menu button) ‹Sign› ‹Value›** — `MenuButton::is_hover_scale`
  Setting of the “Menu button” behavior, section “Look”. Zoom on hover, share: 1.08 — by 8%.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Hover sound” of ‹Object› (Menu button) ‹Sign› ‹Value›** — `MenuButton::is_hover_sound`
  Setting of the “Menu button” behavior, section “Sound”. Hover sound — a file path. Empty — silent.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (text)

- **The mouse is over the button ‹Object›** — `MenuButton::is_hovered`
  From the “Menu button” behavior.
  Parameters: Object (object)

- **“Keyboard” of ‹Object› (Menu button) ‹Sign› ‹Value›** — `MenuButton::is_keyboard`
  Setting of the “Menu button” behavior, section “Keyboard”. Keyboard — choose with the up and down arrows and press with Enter, among the buttons of one menu.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Menu name” of ‹Object› (Menu button) ‹Sign› ‹Value›** — `MenuButton::is_menu_name`
  Setting of the “Menu button” behavior, section “Keyboard”. Menu name: the arrows move between buttons with the same name.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (text)

- **“What to do on press” of ‹Object› (Menu button) ‹Sign› ‹Value›** — `MenuButton::is_on_click`
  Setting of the “Menu button” behavior, section “Press”. What to do on press: nothing (events decide), go to a scene, restart the scene, unpause or quit the game.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Shrink on press” of ‹Object› (Menu button) ‹Sign› ‹Value›** — `MenuButton::is_press_scale`
  Setting of the “Menu button” behavior, section “Look”. Shrink on press.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“The scene to go to” of ‹Object› (Menu button) ‹Sign› ‹Value›** — `MenuButton::is_scene_path`
  Setting of the “Menu button” behavior, section “Press”. The scene to go to.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (text)

- **The button ‹Object› is selected** — `MenuButton::is_selected`
  From the “Menu button” behavior.
  Parameters: Object (object)

- **“Work during pause too” of ‹Object› (Menu button) ‹Sign› ‹Value›** — `MenuButton::is_works_on_pause`
  Setting of the “Menu button” behavior, section “Press”. Work during pause too — for a pause menu.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **The button ‹Object› has just been pressed** — `MenuButton::just_clicked`
  From the “Menu button” behavior.
  Parameters: Object (object)

**Actions**

- **Press the button ‹Object›** — `MenuButton::click`
  From the “Menu button” behavior.
  Parameters: Object (object)

- **Select the button ‹Object› (as with the arrows)** — `MenuButton::select`
  From the “Menu button” behavior.
  Parameters: Object (object)

- **Change “Animation speed” of ‹Object› (Menu button): ‹Sign› ‹Value›** — `MenuButton::set_anim_speed`
  Setting of the “Menu button” behavior, section “Look”. Animation speed — the higher, the snappier.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Press sound” of ‹Object› (Menu button): ‹Sign› ‹Value›** — `MenuButton::set_click_sound`
  Setting of the “Menu button” behavior, section “Sound”. Press sound — a file path.
  Parameters: Object (object), Sign (= + - * /), Value (text)

- **Enable the button ‹Object›: ‹Yes or no› (1 yes, 0 no)** — `MenuButton::set_enabled`
  From the “Menu button” behavior.
  Parameters: Object (object), Yes or no (number)

- **Change “Zoom on hover” of ‹Object› (Menu button): ‹Sign› ‹Value›** — `MenuButton::set_hover_scale`
  Setting of the “Menu button” behavior, section “Look”. Zoom on hover, share: 1.08 — by 8%.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Hover sound” of ‹Object› (Menu button): ‹Sign› ‹Value›** — `MenuButton::set_hover_sound`
  Setting of the “Menu button” behavior, section “Sound”. Hover sound — a file path. Empty — silent.
  Parameters: Object (object), Sign (= + - * /), Value (text)

- **Change “Keyboard” of ‹Object› (Menu button): ‹Sign› ‹Value›** — `MenuButton::set_keyboard`
  Setting of the “Menu button” behavior, section “Keyboard”. Keyboard — choose with the up and down arrows and press with Enter, among the buttons of one menu.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Menu name” of ‹Object› (Menu button): ‹Sign› ‹Value›** — `MenuButton::set_menu_name`
  Setting of the “Menu button” behavior, section “Keyboard”. Menu name: the arrows move between buttons with the same name.
  Parameters: Object (object), Sign (= + - * /), Value (text)

- **Change “What to do on press” of ‹Object› (Menu button): ‹Sign› ‹Value›** — `MenuButton::set_on_click`
  Setting of the “Menu button” behavior, section “Press”. What to do on press: nothing (events decide), go to a scene, restart the scene, unpause or quit the game.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Shrink on press” of ‹Object› (Menu button): ‹Sign› ‹Value›** — `MenuButton::set_press_scale`
  Setting of the “Menu button” behavior, section “Look”. Shrink on press.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “The scene to go to” of ‹Object› (Menu button): ‹Sign› ‹Value›** — `MenuButton::set_scene_path`
  Setting of the “Menu button” behavior, section “Press”. The scene to go to.
  Parameters: Object (object), Sign (= + - * /), Value (text)

- **Change “Work during pause too” of ‹Object› (Menu button): ‹Sign› ‹Value›** — `MenuButton::set_works_on_pause`
  Setting of the “Menu button” behavior, section “Press”. Work during pause too — for a pause menu.
  Parameters: Object (object), Sign (= + - * /), Value (number)

**Expressions**

- `Object.MenuButton::AnimSpeed()` — Animation speed — the higher, the snappier.
- `Object.MenuButton::ClickSound()` — Press sound — a file path.
- `Object.MenuButton::Enabled()` — The button works.
- `Object.MenuButton::HoverScale()` — Zoom on hover, share: 1.08 — by 8%.
- `Object.MenuButton::HoverSound()` — Hover sound — a file path. Empty — silent.
- `Object.MenuButton::Keyboard()` — Keyboard — choose with the up and down arrows and press with Enter, among the buttons of one menu.
- `Object.MenuButton::MenuName()` — Menu name: the arrows move between buttons with the same name.
- `Object.MenuButton::OnClick()` — What to do on press: nothing (events decide), go to a scene, restart the scene, unpause or quit the game.
- `Object.MenuButton::PressScale()` — Shrink on press.
- `Object.MenuButton::ScenePath()` — The scene to go to.
- `Object.MenuButton::WorksOnPause()` — Work during pause too — for a pause menu.

### Orbit — Orbit

Circles around another object: shields, satellites, saws around a boss. Several objects around one center spread evenly around the circle by themselves.

**Conditions**

- **‹Object› has an orbit center** — `Orbit::has_center`
  From the “Orbit” behavior.
  Parameters: Object (object)

- **“Center” of ‹Object› (Orbit) ‹Sign› ‹Value›** — `Orbit::is_center_object`
  Setting of the “Orbit” behavior, section “Center”. Center — the name of an object from the event sheet, e.g. Boss. Empty — circle around the start point.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (text)

- **“Speed” of ‹Object› (Orbit) ‹Sign› ‹Value›** — `Orbit::is_degrees_per_second`
  Setting of the “Orbit” behavior, section “Circle”. Speed, degrees per second. Negative — counterclockwise.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Disappear together with the center” of ‹Object› (Orbit) ‹Sign› ‹Value›** — `Orbit::is_delete_with_center`
  Setting of the “Orbit” behavior, section “Center”. Disappear together with the center: shields vanish when the boss is defeated.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Rotate the object along the orbit” of ‹Object› (Orbit) ‹Sign› ‹Value›** — `Orbit::is_face_along`
  Setting of the “Orbit” behavior, section “Look”. Rotate the object along the orbit — like a saw facing the way it moves.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Orbit radius” of ‹Object› (Orbit) ‹Sign› ‹Value›** — `Orbit::is_radius`
  Setting of the “Orbit” behavior, section “Circle”. Orbit radius, pixels.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Orbit breathing” of ‹Object› (Orbit) ‹Sign› ‹Value›** — `Orbit::is_radius_wobble`
  Setting of the “Orbit” behavior, section “Wobble”. Orbit breathing — how much the radius grows and shrinks, pixels. 0 — an even circle.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Circling is on” of ‹Object› (Orbit) ‹Sign› ‹Value›** — `Orbit::is_running`
  Setting of the “Orbit” behavior, section “Center”. Circling is on.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“The object's own spin” of ‹Object› (Orbit) ‹Sign› ‹Value›** — `Orbit::is_spin`
  Setting of the “Orbit” behavior, section “Look”. The object's own spin, degrees per second — like a spinning saw.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Spread evenly” of ‹Object› (Orbit) ‹Sign› ‹Value›** — `Orbit::is_spread_evenly`
  Setting of the “Orbit” behavior, section “Circle”. Spread evenly — around the circle with other objects on the same orbit.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Start angle” of ‹Object› (Orbit) ‹Sign› ‹Value›** — `Orbit::is_start_angle`
  Setting of the “Orbit” behavior, section “Circle”. Start angle, degrees: 0 — to the right of the center, 90 — below.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Breathing frequency” of ‹Object› (Orbit) ‹Sign› ‹Value›** — `Orbit::is_wobble_speed`
  Setting of the “Orbit” behavior, section “Wobble”. Breathing frequency, times per second.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

**Actions**

- **Reverse the circling of ‹Object›** — `Orbit::reverse`
  From the “Orbit” behavior.
  Parameters: Object (object)

- **Put ‹Object› at an angle of ‹Angle, degrees› degrees** — `Orbit::set_angle`
  From the “Orbit” behavior.
  Parameters: Object (object), Angle, degrees (number)

- **Circle ‹Object› around object ‹Object name›** — `Orbit::set_center`
  From the “Orbit” behavior.
  Parameters: Object (object), Object name (text)

- **Change “Center” of ‹Object› (Orbit): ‹Sign› ‹Value›** — `Orbit::set_center_object`
  Setting of the “Orbit” behavior, section “Center”. Center — the name of an object from the event sheet, e.g. Boss. Empty — circle around the start point.
  Parameters: Object (object), Sign (= + - * /), Value (text)

- **Change “Speed” of ‹Object› (Orbit): ‹Sign› ‹Value›** — `Orbit::set_degrees_per_second`
  Setting of the “Orbit” behavior, section “Circle”. Speed, degrees per second. Negative — counterclockwise.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Disappear together with the center” of ‹Object› (Orbit): ‹Sign› ‹Value›** — `Orbit::set_delete_with_center`
  Setting of the “Orbit” behavior, section “Center”. Disappear together with the center: shields vanish when the boss is defeated.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Rotate the object along the orbit” of ‹Object› (Orbit): ‹Sign› ‹Value›** — `Orbit::set_face_along`
  Setting of the “Orbit” behavior, section “Look”. Rotate the object along the orbit — like a saw facing the way it moves.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Orbit radius of ‹Object›: ‹Radius›** — `Orbit::set_radius`
  From the “Orbit” behavior.
  Parameters: Object (object), Radius (number)

- **Change “Orbit breathing” of ‹Object› (Orbit): ‹Sign› ‹Value›** — `Orbit::set_radius_wobble`
  Setting of the “Orbit” behavior, section “Wobble”. Orbit breathing — how much the radius grows and shrinks, pixels. 0 — an even circle.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Circling is on” of ‹Object› (Orbit): ‹Sign› ‹Value›** — `Orbit::set_running`
  Setting of the “Orbit” behavior, section “Center”. Circling is on.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “The object's own spin” of ‹Object› (Orbit): ‹Sign› ‹Value›** — `Orbit::set_spin`
  Setting of the “Orbit” behavior, section “Look”. The object's own spin, degrees per second — like a spinning saw.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Spread evenly” of ‹Object› (Orbit): ‹Sign› ‹Value›** — `Orbit::set_spread_evenly`
  Setting of the “Orbit” behavior, section “Circle”. Spread evenly — around the circle with other objects on the same orbit.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Start angle” of ‹Object› (Orbit): ‹Sign› ‹Value›** — `Orbit::set_start_angle`
  Setting of the “Orbit” behavior, section “Circle”. Start angle, degrees: 0 — to the right of the center, 90 — below.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Breathing frequency” of ‹Object› (Orbit): ‹Sign› ‹Value›** — `Orbit::set_wobble_speed`
  Setting of the “Orbit” behavior, section “Wobble”. Breathing frequency, times per second.
  Parameters: Object (object), Sign (= + - * /), Value (number)

**Expressions**

- `Object.Orbit::Angle()` — Angle on the orbit in degrees
- `Object.Orbit::CenterObject()` — Center — the name of an object from the event sheet, e.g. Boss. Empty — circle around the start point.
- `Object.Orbit::CurrentRadius()` — Current radius including breathing
- `Object.Orbit::DegreesPerSecond()` — Speed, degrees per second. Negative — counterclockwise.
- `Object.Orbit::DeleteWithCenter()` — Disappear together with the center: shields vanish when the boss is defeated.
- `Object.Orbit::FaceAlong()` — Rotate the object along the orbit — like a saw facing the way it moves.
- `Object.Orbit::Radius()` — Orbit radius, pixels.
- `Object.Orbit::RadiusWobble()` — Orbit breathing — how much the radius grows and shrinks, pixels. 0 — an even circle.
- `Object.Orbit::Running()` — Circling is on.
- `Object.Orbit::Spin()` — The object's own spin, degrees per second — like a spinning saw.
- `Object.Orbit::SpreadEvenly()` — Spread evenly — around the circle with other objects on the same orbit.
- `Object.Orbit::StartAngle()` — Start angle, degrees: 0 — to the right of the center, 90 — below.
- `Object.Orbit::WobbleSpeed()` — Breathing frequency, times per second.

### Oscillate — Oscillation

Oscillation of position, rotation and size with different waves. Platforms, coins, hovering enemies.

**Conditions**

- **“Position amplitude” of ‹Object› (Oscillation) ‹Sign› ‹Value›** — `Oscillate::is_amplitude`
  Setting of the “Oscillation” behavior, section “Position”. Position amplitude, in pixels.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Angle of the oscillation axis in degrees” of ‹Object› (Oscillation) ‹Sign› ‹Value›** — `Oscillate::is_axis_angle`
  Setting of the “Oscillation” behavior, section “Position”. Angle of the oscillation axis in degrees: 0 — sideways, 90 — up and down.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Frequency” of ‹Object› (Oscillation) ‹Sign› ‹Value›** — `Oscillate::is_frequency`
  Setting of the “Oscillation” behavior, section “Wave”. Frequency — oscillations per second.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Phase shift from 0 to 1” of ‹Object› (Oscillation) ‹Sign› ‹Value›** — `Oscillate::is_phase`
  Setting of the “Oscillation” behavior, section “Wave”. Phase shift from 0 to 1, so identical objects do not sway in sync.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Swaying amplitude” of ‹Object› (Oscillation) ‹Sign› ‹Value›** — `Oscillate::is_rotation_amplitude`
  Setting of the “Oscillation” behavior, section “Rotation and size”. Swaying amplitude, in degrees.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **‹Object› is oscillating** — `Oscillate::is_running`
  From the “Oscillation” behavior.
  Parameters: Object (object)

- **“Size pulsation amplitude” of ‹Object› (Oscillation) ‹Sign› ‹Value›** — `Oscillate::is_scale_amplitude`
  Setting of the “Oscillation” behavior, section “Rotation and size”. Size pulsation amplitude.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Waveform” of ‹Object› (Oscillation) ‹Sign› ‹Value›** — `Oscillate::is_waveform`
  Setting of the “Oscillation” behavior, section “Wave”. Waveform — sine, triangle or step.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

**Actions**

- **Remember the current point of ‹Object› as the oscillation center** — `Oscillate::recenter`
  From the “Oscillation” behavior.
  Parameters: Object (object)

- **Reset the oscillation phase of ‹Object›** — `Oscillate::reset_phase`
  From the “Oscillation” behavior.
  Parameters: Object (object)

- **Change “Position amplitude” of ‹Object› (Oscillation): ‹Sign› ‹Value›** — `Oscillate::set_amplitude`
  Setting of the “Oscillation” behavior, section “Position”. Position amplitude, in pixels.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Angle of the oscillation axis in degrees” of ‹Object› (Oscillation): ‹Sign› ‹Value›** — `Oscillate::set_axis_angle`
  Setting of the “Oscillation” behavior, section “Position”. Angle of the oscillation axis in degrees: 0 — sideways, 90 — up and down.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Frequency” of ‹Object› (Oscillation): ‹Sign› ‹Value›** — `Oscillate::set_frequency`
  Setting of the “Oscillation” behavior, section “Wave”. Frequency — oscillations per second.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Phase shift from 0 to 1” of ‹Object› (Oscillation): ‹Sign› ‹Value›** — `Oscillate::set_phase`
  Setting of the “Oscillation” behavior, section “Wave”. Phase shift from 0 to 1, so identical objects do not sway in sync.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Swaying amplitude” of ‹Object› (Oscillation): ‹Sign› ‹Value›** — `Oscillate::set_rotation_amplitude`
  Setting of the “Oscillation” behavior, section “Rotation and size”. Swaying amplitude, in degrees.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Oscillation is on” of ‹Object› (Oscillation): ‹Sign› ‹Value›** — `Oscillate::set_running`
  Setting of the “Oscillation” behavior, section “Wave”. Oscillation is on.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Size pulsation amplitude” of ‹Object› (Oscillation): ‹Sign› ‹Value›** — `Oscillate::set_scale_amplitude`
  Setting of the “Oscillation” behavior, section “Rotation and size”. Size pulsation amplitude.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Waveform” of ‹Object› (Oscillation): ‹Sign› ‹Value›** — `Oscillate::set_waveform`
  Setting of the “Oscillation” behavior, section “Wave”. Waveform — sine, triangle or step.
  Parameters: Object (object), Sign (= + - * /), Value (number)

**Expressions**

- `Object.Oscillate::Amplitude()` — Position amplitude, in pixels.
- `Object.Oscillate::AxisAngle()` — Angle of the oscillation axis in degrees: 0 — sideways, 90 — up and down.
- `Object.Oscillate::Frequency()` — Frequency — oscillations per second.
- `Object.Oscillate::Offset()` — Current offset from the center
- `Object.Oscillate::Phase()` — Phase shift from 0 to 1, so identical objects do not sway in sync.
- `Object.Oscillate::RotationAmplitude()` — Swaying amplitude, in degrees.
- `Object.Oscillate::Running()` — Oscillation is on.
- `Object.Oscillate::ScaleAmplitude()` — Size pulsation amplitude.
- `Object.Oscillate::WaveValue()` — Wave value from -1 to 1
- `Object.Oscillate::Waveform()` — Waveform — sine, triangle or step.

### Path — Path by points

Movement along points: patrol, loop, back and forth. With waiting at points, acceleration, turning toward the direction and going to any point from events.

**Conditions**

- **“Acceleration” of ‹Object› (Path by points) ‹Sign› ‹Value›** — `Path::is_acceleration`
  Setting of the “Path by points” behavior, section “Movement”. Acceleration, pixels per second per second. 0 — instant start.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **‹Object› has gone the whole path to the end** — `Path::is_finished`
  From the “Path by points” behavior.
  Parameters: Object (object)

- **“Flip the sprite” of ‹Object› (Path by points) ‹Sign› ‹Value›** — `Path::is_flip_sprite`
  Setting of the “Path by points” behavior, section “Look”. Flip the sprite — toward the movement direction.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“How to go along the path” of ‹Object› (Path by points) ‹Sign› ‹Value›** — `Path::is_mode`
  Setting of the “Path by points” behavior, section “Points”. How to go along the path: in a loop, back and forth, or once to the end.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **‹Object› is moving along the path** — `Path::is_moving`
  From the “Path by points” behavior.
  Parameters: Object (object)

- **“How close counts as reaching a point” of ‹Object› (Path by points) ‹Sign› ‹Value›** — `Path::is_reach_distance`
  Setting of the “Path by points” behavior, section “Points”. How close counts as reaching a point, in pixels.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Rotate the object” of ‹Object› (Path by points) ‹Sign› ‹Value›** — `Path::is_rotate_object`
  Setting of the “Path by points” behavior, section “Look”. Rotate the object — toward the movement direction.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Movement is on” of ‹Object› (Path by points) ‹Sign› ‹Value›** — `Path::is_running`
  Setting of the “Path by points” behavior, section “Movement”. Movement is on.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Movement speed” of ‹Object› (Path by points) ‹Sign› ‹Value›** — `Path::is_speed`
  Setting of the “Path by points” behavior, section “Movement”. Movement speed, pixels per second.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Wait at each point” of ‹Object› (Path by points) ‹Sign› ‹Value›** — `Path::is_wait_time`
  Setting of the “Path by points” behavior, section “Points”. Wait at each point, seconds.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **‹Object› is waiting at a point** — `Path::is_waiting`
  From the “Path by points” behavior.
  Parameters: Object (object)

- **‹Object› has just reached a point** — `Path::just_reached`
  From the “Path by points” behavior.
  Parameters: Object (object)

**Actions**

- **Send ‹Object› to path point number ‹Point number›** — `Path::go_to_point`
  From the “Path by points” behavior.
  Parameters: Object (object), Point number (number)

- **Treat the current place of ‹Object› as the start of the path** — `Path::rebase`
  From the “Path by points” behavior.
  Parameters: Object (object)

- **Return ‹Object› to the start of the path** — `Path::restart`
  From the “Path by points” behavior.
  Parameters: Object (object)

- **Reverse ‹Object› on the path** — `Path::reverse`
  From the “Path by points” behavior.
  Parameters: Object (object)

- **Change “Acceleration” of ‹Object› (Path by points): ‹Sign› ‹Value›** — `Path::set_acceleration`
  Setting of the “Path by points” behavior, section “Movement”. Acceleration, pixels per second per second. 0 — instant start.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Flip the sprite” of ‹Object› (Path by points): ‹Sign› ‹Value›** — `Path::set_flip_sprite`
  Setting of the “Path by points” behavior, section “Look”. Flip the sprite — toward the movement direction.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “How to go along the path” of ‹Object› (Path by points): ‹Sign› ‹Value›** — `Path::set_mode`
  Setting of the “Path by points” behavior, section “Points”. How to go along the path: in a loop, back and forth, or once to the end.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “How close counts as reaching a point” of ‹Object› (Path by points): ‹Sign› ‹Value›** — `Path::set_reach_distance`
  Setting of the “Path by points” behavior, section “Points”. How close counts as reaching a point, in pixels.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Rotate the object” of ‹Object› (Path by points): ‹Sign› ‹Value›** — `Path::set_rotate_object`
  Setting of the “Path by points” behavior, section “Look”. Rotate the object — toward the movement direction.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Movement is on” of ‹Object› (Path by points): ‹Sign› ‹Value›** — `Path::set_running`
  Setting of the “Path by points” behavior, section “Movement”. Movement is on.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Movement speed” of ‹Object› (Path by points): ‹Sign› ‹Value›** — `Path::set_speed`
  Setting of the “Path by points” behavior, section “Movement”. Movement speed, pixels per second.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Wait at each point” of ‹Object› (Path by points): ‹Sign› ‹Value›** — `Path::set_wait_time`
  Setting of the “Path by points” behavior, section “Points”. Wait at each point, seconds.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Start the path movement of ‹Object›** — `Path::start`
  From the “Path by points” behavior.
  Parameters: Object (object)

- **Stop the path movement of ‹Object›** — `Path::stop`
  From the “Path by points” behavior.
  Parameters: Object (object)

**Expressions**

- `Object.Path::Acceleration()` — Acceleration, pixels per second per second. 0 — instant start.
- `Object.Path::CurrentPoint()` — Number of the point the object is heading to
- `Object.Path::DistanceToPoint()` — Distance to the next point
- `Object.Path::FlipSprite()` — Flip the sprite — toward the movement direction.
- `Object.Path::Mode()` — How to go along the path: in a loop, back and forth, or once to the end.
- `Object.Path::PointCount()` — How many points are in the path
- `Object.Path::ReachDistance()` — How close counts as reaching a point, in pixels.
- `Object.Path::RotateObject()` — Rotate the object — toward the movement direction.
- `Object.Path::Running()` — Movement is on.
- `Object.Path::Speed()` — Movement speed, pixels per second.
- `Object.Path::WaitTime()` — Wait at each point, seconds.

### Pathfinder — Pathfinding

Walks to the target around walls instead of bumping into them. For top-down games: the level is split into cells by itself, the path is found with A* and smoothed.

**Conditions**

- **‹Object› reached the target** — `Pathfinder::has_arrived`
  From the “Pathfinding” behavior.
  Parameters: Object (object)

- **“Object radius” of ‹Object› (Pathfinding) ‹Sign› ‹Value›** — `Pathfinder::is_agent_radius`
  Setting of the “Pathfinding” behavior, section “Grid”. Object radius — how far to keep from walls. 0 — half a cell.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Cell size” of ‹Object› (Pathfinding) ‹Sign› ‹Value›** — `Pathfinder::is_cell_size`
  Setting of the “Pathfinding” behavior, section “Grid”. Cell size, pixels. Smaller — a more precise path in narrow passages, but a longer search.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Walk diagonally” of ‹Object› (Pathfinding) ‹Sign› ‹Value›** — `Pathfinder::is_diagonals`
  Setting of the “Pathfinding” behavior, section “Grid”. Walk diagonally.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Flip the sprite” of ‹Object› (Pathfinding) ‹Sign› ‹Value›** — `Pathfinder::is_flip_sprite`
  Setting of the “Pathfinding” behavior, section “Movement”. Flip the sprite — toward the movement direction.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **‹Object› is following a path** — `Pathfinder::is_moving`
  From the “Pathfinding” behavior.
  Parameters: Object (object)

- **“If the target is unreachable” of ‹Object› (Pathfinding) ‹Sign› ‹Value›** — `Pathfinder::is_partial_path`
  Setting of the “Pathfinding” behavior, section “Grid”. If the target is unreachable, come as close as possible.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Repath interval” of ‹Object› (Pathfinding) ‹Sign› ‹Value›** — `Pathfinder::is_repath_interval`
  Setting of the “Pathfinding” behavior, section “Target”. Repath interval — how often to look for a new path to a moving target, seconds.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Turn toward the movement direction” of ‹Object› (Pathfinding) ‹Sign› ‹Value›** — `Pathfinder::is_rotate_object`
  Setting of the “Pathfinding” behavior, section “Movement”. Turn toward the movement direction.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Moving to the target is on” of ‹Object› (Pathfinding) ‹Sign› ‹Value›** — `Pathfinder::is_running`
  Setting of the “Pathfinding” behavior, section “Target”. Moving to the target is on.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Search margin” of ‹Object› (Pathfinding) ‹Sign› ‹Value›** — `Pathfinder::is_search_margin`
  Setting of the “Pathfinding” behavior, section “Grid”. Search margin, in cells — how far a detour around the object and the target may go.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Show the path as a line” of ‹Object› (Pathfinding) ‹Sign› ‹Value›** — `Pathfinder::is_show_path`
  Setting of the “Pathfinding” behavior, section “Grid”. Show the path as a line — for debugging.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Speed” of ‹Object› (Pathfinding) ‹Sign› ‹Value›** — `Pathfinder::is_speed`
  Setting of the “Pathfinding” behavior, section “Movement”. Speed, pixels per second.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Stop distance” of ‹Object› (Pathfinding) ‹Sign› ‹Value›** — `Pathfinder::is_stop_distance`
  Setting of the “Pathfinding” behavior, section “Target”. Stop distance — how far from the target to stop.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Target” of ‹Object› (Pathfinding) ‹Sign› ‹Value›** — `Pathfinder::is_target_object`
  Setting of the “Pathfinding” behavior, section “Target”. Target — the name of an object from the event sheet, e.g. Player. Empty — go to the point from the action.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (text)

- **‹Object› has just reached the target** — `Pathfinder::just_arrived`
  From the “Pathfinding” behavior.
  Parameters: Object (object)

- **‹Object› cannot reach the target** — `Pathfinder::no_path`
  From the “Pathfinding” behavior.
  Parameters: Object (object)

**Actions**

- **Send ‹Object› to point ‹X› ; ‹Y›** — `Pathfinder::go_to`
  From the “Pathfinding” behavior.
  Parameters: Object (object), X (number), Y (number)

- **Lead ‹Object› to object ‹Object name›** — `Pathfinder::go_to_object`
  From the “Pathfinding” behavior.
  Parameters: Object (object), Object name (text)

- **Recompute the path of ‹Object› from scratch** — `Pathfinder::recompute`
  Needed if walls were moved or created: the level layout is forgotten and built again.
  Parameters: Object (object)

- **Change “Object radius” of ‹Object› (Pathfinding): ‹Sign› ‹Value›** — `Pathfinder::set_agent_radius`
  Setting of the “Pathfinding” behavior, section “Grid”. Object radius — how far to keep from walls. 0 — half a cell.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Cell size” of ‹Object› (Pathfinding): ‹Sign› ‹Value›** — `Pathfinder::set_cell_size`
  Setting of the “Pathfinding” behavior, section “Grid”. Cell size, pixels. Smaller — a more precise path in narrow passages, but a longer search.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Walk diagonally” of ‹Object› (Pathfinding): ‹Sign› ‹Value›** — `Pathfinder::set_diagonals`
  Setting of the “Pathfinding” behavior, section “Grid”. Walk diagonally.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Flip the sprite” of ‹Object› (Pathfinding): ‹Sign› ‹Value›** — `Pathfinder::set_flip_sprite`
  Setting of the “Pathfinding” behavior, section “Movement”. Flip the sprite — toward the movement direction.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “If the target is unreachable” of ‹Object› (Pathfinding): ‹Sign› ‹Value›** — `Pathfinder::set_partial_path`
  Setting of the “Pathfinding” behavior, section “Grid”. If the target is unreachable, come as close as possible.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Repath interval” of ‹Object› (Pathfinding): ‹Sign› ‹Value›** — `Pathfinder::set_repath_interval`
  Setting of the “Pathfinding” behavior, section “Target”. Repath interval — how often to look for a new path to a moving target, seconds.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Turn toward the movement direction” of ‹Object› (Pathfinding): ‹Sign› ‹Value›** — `Pathfinder::set_rotate_object`
  Setting of the “Pathfinding” behavior, section “Movement”. Turn toward the movement direction.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Moving to the target is on” of ‹Object› (Pathfinding): ‹Sign› ‹Value›** — `Pathfinder::set_running`
  Setting of the “Pathfinding” behavior, section “Target”. Moving to the target is on.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Search margin” of ‹Object› (Pathfinding): ‹Sign› ‹Value›** — `Pathfinder::set_search_margin`
  Setting of the “Pathfinding” behavior, section “Grid”. Search margin, in cells — how far a detour around the object and the target may go.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Show the path as a line” of ‹Object› (Pathfinding): ‹Sign› ‹Value›** — `Pathfinder::set_show_path`
  Setting of the “Pathfinding” behavior, section “Grid”. Show the path as a line — for debugging.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Speed” of ‹Object› (Pathfinding): ‹Sign› ‹Value›** — `Pathfinder::set_speed`
  Setting of the “Pathfinding” behavior, section “Movement”. Speed, pixels per second.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Stop distance” of ‹Object› (Pathfinding): ‹Sign› ‹Value›** — `Pathfinder::set_stop_distance`
  Setting of the “Pathfinding” behavior, section “Target”. Stop distance — how far from the target to stop.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Target” of ‹Object› (Pathfinding): ‹Sign› ‹Value›** — `Pathfinder::set_target_object`
  Setting of the “Pathfinding” behavior, section “Target”. Target — the name of an object from the event sheet, e.g. Player. Empty — go to the point from the action.
  Parameters: Object (object), Sign (= + - * /), Value (text)

- **Stop ‹Object›** — `Pathfinder::stop`
  From the “Pathfinding” behavior.
  Parameters: Object (object)

**Expressions**

- `Object.Pathfinder::AgentRadius()` — Object radius — how far to keep from walls. 0 — half a cell.
- `Object.Pathfinder::CellSize()` — Cell size, pixels. Smaller — a more precise path in narrow passages, but a longer search.
- `Object.Pathfinder::Diagonals()` — Walk diagonally.
- `Object.Pathfinder::FlipSprite()` — Flip the sprite — toward the movement direction.
- `Object.Pathfinder::NextX()` — X of the next path point
- `Object.Pathfinder::NextY()` — Y of the next path point
- `Object.Pathfinder::PartialPath()` — If the target is unreachable, come as close as possible.
- `Object.Pathfinder::PathLength()` — Length of the remaining path, pixels
- `Object.Pathfinder::PointsLeft()` — How many path points are left
- `Object.Pathfinder::RepathInterval()` — Repath interval — how often to look for a new path to a moving target, seconds.
- `Object.Pathfinder::RotateObject()` — Turn toward the movement direction.
- `Object.Pathfinder::Running()` — Moving to the target is on.
- `Object.Pathfinder::SearchMargin()` — Search margin, in cells — how far a detour around the object and the target may go.
- `Object.Pathfinder::ShowPath()` — Show the path as a line — for debugging.
- `Object.Pathfinder::Speed()` — Speed, pixels per second.
- `Object.Pathfinder::StopDistance()` — Stop distance — how far from the target to stop.
- `Object.Pathfinder::TargetObject()` — Target — the name of an object from the event sheet, e.g. Player. Empty — go to the point from the action.

### PatrolEnemy — Patrolling enemy

A ready-made platformer enemy without a single event: walks along a platform, turns at edges and walls, spots the player with a ray, chases, loses and returns to its beat.

**Conditions**

- **“Automatic animations by state” of ‹Object› (Patrolling enemy) ‹Sign› ‹Value›** — `PatrolEnemy::is_animate`
  Setting of the “Patrolling enemy” behavior, section “Look”. Automatic animations by state. The names below must match the AnimatedSprite2D.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Chase a spotted target” of ‹Object› (Patrolling enemy) ‹Sign› ‹Value›** — `PatrolEnemy::is_chase`
  Setting of the “Patrolling enemy” behavior, section “Chase”. Chase a spotted target.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Chase animation” of ‹Object› (Patrolling enemy) ‹Sign› ‹Value›** — `PatrolEnemy::is_chase_animation`
  Setting of the “Patrolling enemy” behavior, section “Look”. Chase animation. Empty — the walk animation.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (text)

- **“Chase speed” of ‹Object› (Patrolling enemy) ‹Sign› ‹Value›** — `PatrolEnemy::is_chase_speed`
  Setting of the “Patrolling enemy” behavior, section “Chase”. Chase speed, pixels per second.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **‹Object› is chasing the target** — `PatrolEnemy::is_chasing`
  From the “Patrolling enemy” behavior.
  Parameters: Object (object)

- **“Flip the sprite” of ‹Object› (Patrolling enemy) ‹Sign› ‹Value›** — `PatrolEnemy::is_flip_sprite`
  Setting of the “Patrolling enemy” behavior, section “Look”. Flip the sprite — toward the movement direction.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Gravity strength” of ‹Object› (Patrolling enemy) ‹Sign› ‹Value›** — `PatrolEnemy::is_gravity`
  Setting of the “Patrolling enemy” behavior, section “Gravity”. Gravity strength, pixels per second per second.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Idle animation” of ‹Object› (Patrolling enemy) ‹Sign› ‹Value›** — `PatrolEnemy::is_idle_animation`
  Setting of the “Patrolling enemy” behavior, section “Look”. Idle animation — during pauses and waiting.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (text)

- **“Search time” of ‹Object› (Patrolling enemy) ‹Sign› ‹Value›** — `PatrolEnemy::is_lose_time`
  Setting of the “Patrolling enemy” behavior, section “Chase”. Search time — how many seconds to look for a target out of sight before giving up.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Maximum fall speed” of ‹Object› (Patrolling enemy) ‹Sign› ‹Value›** — `PatrolEnemy::is_max_fall_speed`
  Setting of the “Patrolling enemy” behavior, section “Gravity”. Maximum fall speed.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Patrol beat” of ‹Object› (Patrolling enemy) ‹Sign› ‹Value›** — `PatrolEnemy::is_patrol_range`
  Setting of the “Patrolling enemy” behavior, section “Patrol”. Patrol beat — how many pixels it may walk away from the start. 0 — no limit.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **‹Object› is patrolling** — `PatrolEnemy::is_patrolling`
  From the “Patrolling enemy” behavior.
  Parameters: Object (object)

- **“After losing the target” of ‹Object› (Patrolling enemy) ‹Sign› ‹Value›** — `PatrolEnemy::is_return_home`
  Setting of the “Patrolling enemy” behavior, section “Chase”. After losing the target, return to its beat.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **‹Object› is returning to its beat** — `PatrolEnemy::is_returning`
  From the “Patrolling enemy” behavior.
  Parameters: Object (object)

- **“The patrol is on” of ‹Object› (Patrolling enemy) ‹Sign› ‹Value›** — `PatrolEnemy::is_running`
  Setting of the “Patrolling enemy” behavior, section “Patrol”. The patrol is on.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **‹Object› is searching for a lost target** — `PatrolEnemy::is_searching`
  From the “Patrolling enemy” behavior.
  Parameters: Object (object)

- **“Notices behind its back too” of ‹Object› (Patrolling enemy) ‹Sign› ‹Value›** — `PatrolEnemy::is_sees_behind`
  Setting of the “Patrolling enemy” behavior, section “Vision”. Notices behind its back too, not only in front.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Sight height” of ‹Object› (Patrolling enemy) ‹Sign› ‹Value›** — `PatrolEnemy::is_sight_height`
  Setting of the “Patrolling enemy” behavior, section “Vision”. Sight height — how far above or below itself it notices the target.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Sight range” of ‹Object› (Patrolling enemy) ‹Sign› ‹Value›** — `PatrolEnemy::is_sight_range`
  Setting of the “Patrolling enemy” behavior, section “Vision”. Sight range, pixels.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Which way to walk first” of ‹Object› (Patrolling enemy) ‹Sign› ‹Value›** — `PatrolEnemy::is_start_direction`
  Setting of the “Patrolling enemy” behavior, section “Patrol”. Which way to walk first.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Do not jump off an edge while chasing” of ‹Object› (Patrolling enemy) ‹Sign› ‹Value›** — `PatrolEnemy::is_stop_at_edges`
  Setting of the “Patrolling enemy” behavior, section “Chase”. Do not jump off an edge while chasing — stop and wait.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Target” of ‹Object› (Patrolling enemy) ‹Sign› ‹Value›** — `PatrolEnemy::is_target_object`
  Setting of the “Patrolling enemy” behavior, section “Vision”. Target — the name of an object from the event sheet, e.g. Player.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (text)

- **“Turn at the platform edge” of ‹Object› (Patrolling enemy) ‹Sign› ‹Value›** — `PatrolEnemy::is_turn_at_edges`
  Setting of the “Patrolling enemy” behavior, section “Patrol”. Turn at the platform edge — do not fall off.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Turn when bumping into a wall” of ‹Object› (Patrolling enemy) ‹Sign› ‹Value›** — `PatrolEnemy::is_turn_at_walls`
  Setting of the “Patrolling enemy” behavior, section “Patrol”. Turn when bumping into a wall.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Pause when turning” of ‹Object› (Patrolling enemy) ‹Sign› ‹Value›** — `PatrolEnemy::is_turn_pause`
  Setting of the “Patrolling enemy” behavior, section “Patrol”. Pause when turning, seconds.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Walk animation” of ‹Object› (Patrolling enemy) ‹Sign› ‹Value›** — `PatrolEnemy::is_walk_animation`
  Setting of the “Patrolling enemy” behavior, section “Look”. Walk animation — a name from AnimatedSprite2D.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (text)

- **“Patrol speed” of ‹Object› (Patrolling enemy) ‹Sign› ‹Value›** — `PatrolEnemy::is_walk_speed`
  Setting of the “Patrolling enemy” behavior, section “Patrol”. Patrol speed, pixels per second.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Walls block the view” of ‹Object› (Patrolling enemy) ‹Sign› ‹Value›** — `PatrolEnemy::is_walls_block_sight`
  Setting of the “Patrolling enemy” behavior, section “Vision”. Walls block the view.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **‹Object› has just spotted the target** — `PatrolEnemy::just_spotted`
  From the “Patrolling enemy” behavior.
  Parameters: Object (object)

- **‹Object› has just turned around** — `PatrolEnemy::just_turned`
  From the “Patrolling enemy” behavior.
  Parameters: Object (object)

- **‹Object› sees the target** — `PatrolEnemy::sees_target`
  From the “Patrolling enemy” behavior.
  Parameters: Object (object)

**Actions**

- **Send ‹Object› back to patrolling** — `PatrolEnemy::back_to_patrol`
  Stop chasing and searching.
  Parameters: Object (object)

- **Change “Automatic animations by state” of ‹Object› (Patrolling enemy): ‹Sign› ‹Value›** — `PatrolEnemy::set_animate`
  Setting of the “Patrolling enemy” behavior, section “Look”. Automatic animations by state. The names below must match the AnimatedSprite2D.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Chase a spotted target” of ‹Object› (Patrolling enemy): ‹Sign› ‹Value›** — `PatrolEnemy::set_chase`
  Setting of the “Patrolling enemy” behavior, section “Chase”. Chase a spotted target.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Chase animation” of ‹Object› (Patrolling enemy): ‹Sign› ‹Value›** — `PatrolEnemy::set_chase_animation`
  Setting of the “Patrolling enemy” behavior, section “Look”. Chase animation. Empty — the walk animation.
  Parameters: Object (object), Sign (= + - * /), Value (text)

- **Change “Chase speed” of ‹Object› (Patrolling enemy): ‹Sign› ‹Value›** — `PatrolEnemy::set_chase_speed`
  Setting of the “Patrolling enemy” behavior, section “Chase”. Chase speed, pixels per second.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Flip the sprite” of ‹Object› (Patrolling enemy): ‹Sign› ‹Value›** — `PatrolEnemy::set_flip_sprite`
  Setting of the “Patrolling enemy” behavior, section “Look”. Flip the sprite — toward the movement direction.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Gravity strength” of ‹Object› (Patrolling enemy): ‹Sign› ‹Value›** — `PatrolEnemy::set_gravity`
  Setting of the “Patrolling enemy” behavior, section “Gravity”. Gravity strength, pixels per second per second.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Make the current place of ‹Object› the center of its patrol beat** — `PatrolEnemy::set_home_here`
  From the “Patrolling enemy” behavior.
  Parameters: Object (object)

- **Change “Idle animation” of ‹Object› (Patrolling enemy): ‹Sign› ‹Value›** — `PatrolEnemy::set_idle_animation`
  Setting of the “Patrolling enemy” behavior, section “Look”. Idle animation — during pauses and waiting.
  Parameters: Object (object), Sign (= + - * /), Value (text)

- **Change “Search time” of ‹Object› (Patrolling enemy): ‹Sign› ‹Value›** — `PatrolEnemy::set_lose_time`
  Setting of the “Patrolling enemy” behavior, section “Chase”. Search time — how many seconds to look for a target out of sight before giving up.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Maximum fall speed” of ‹Object› (Patrolling enemy): ‹Sign› ‹Value›** — `PatrolEnemy::set_max_fall_speed`
  Setting of the “Patrolling enemy” behavior, section “Gravity”. Maximum fall speed.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Patrol beat” of ‹Object› (Patrolling enemy): ‹Sign› ‹Value›** — `PatrolEnemy::set_patrol_range`
  Setting of the “Patrolling enemy” behavior, section “Patrol”. Patrol beat — how many pixels it may walk away from the start. 0 — no limit.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “After losing the target” of ‹Object› (Patrolling enemy): ‹Sign› ‹Value›** — `PatrolEnemy::set_return_home`
  Setting of the “Patrolling enemy” behavior, section “Chase”. After losing the target, return to its beat.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “The patrol is on” of ‹Object› (Patrolling enemy): ‹Sign› ‹Value›** — `PatrolEnemy::set_running`
  Setting of the “Patrolling enemy” behavior, section “Patrol”. The patrol is on.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Notices behind its back too” of ‹Object› (Patrolling enemy): ‹Sign› ‹Value›** — `PatrolEnemy::set_sees_behind`
  Setting of the “Patrolling enemy” behavior, section “Vision”. Notices behind its back too, not only in front.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Sight height” of ‹Object› (Patrolling enemy): ‹Sign› ‹Value›** — `PatrolEnemy::set_sight_height`
  Setting of the “Patrolling enemy” behavior, section “Vision”. Sight height — how far above or below itself it notices the target.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Sight range” of ‹Object› (Patrolling enemy): ‹Sign› ‹Value›** — `PatrolEnemy::set_sight_range`
  Setting of the “Patrolling enemy” behavior, section “Vision”. Sight range, pixels.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Which way to walk first” of ‹Object› (Patrolling enemy): ‹Sign› ‹Value›** — `PatrolEnemy::set_start_direction`
  Setting of the “Patrolling enemy” behavior, section “Patrol”. Which way to walk first.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Do not jump off an edge while chasing” of ‹Object› (Patrolling enemy): ‹Sign› ‹Value›** — `PatrolEnemy::set_stop_at_edges`
  Setting of the “Patrolling enemy” behavior, section “Chase”. Do not jump off an edge while chasing — stop and wait.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Set the target of ‹Object›: object ‹Object name›** — `PatrolEnemy::set_target`
  From the “Patrolling enemy” behavior.
  Parameters: Object (object), Object name (text)

- **Change “Target” of ‹Object› (Patrolling enemy): ‹Sign› ‹Value›** — `PatrolEnemy::set_target_object`
  Setting of the “Patrolling enemy” behavior, section “Vision”. Target — the name of an object from the event sheet, e.g. Player.
  Parameters: Object (object), Sign (= + - * /), Value (text)

- **Change “Turn at the platform edge” of ‹Object› (Patrolling enemy): ‹Sign› ‹Value›** — `PatrolEnemy::set_turn_at_edges`
  Setting of the “Patrolling enemy” behavior, section “Patrol”. Turn at the platform edge — do not fall off.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Turn when bumping into a wall” of ‹Object› (Patrolling enemy): ‹Sign› ‹Value›** — `PatrolEnemy::set_turn_at_walls`
  Setting of the “Patrolling enemy” behavior, section “Patrol”. Turn when bumping into a wall.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Pause when turning” of ‹Object› (Patrolling enemy): ‹Sign› ‹Value›** — `PatrolEnemy::set_turn_pause`
  Setting of the “Patrolling enemy” behavior, section “Patrol”. Pause when turning, seconds.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Walk animation” of ‹Object› (Patrolling enemy): ‹Sign› ‹Value›** — `PatrolEnemy::set_walk_animation`
  Setting of the “Patrolling enemy” behavior, section “Look”. Walk animation — a name from AnimatedSprite2D.
  Parameters: Object (object), Sign (= + - * /), Value (text)

- **Change “Patrol speed” of ‹Object› (Patrolling enemy): ‹Sign› ‹Value›** — `PatrolEnemy::set_walk_speed`
  Setting of the “Patrolling enemy” behavior, section “Patrol”. Patrol speed, pixels per second.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Walls block the view” of ‹Object› (Patrolling enemy): ‹Sign› ‹Value›** — `PatrolEnemy::set_walls_block_sight`
  Setting of the “Patrolling enemy” behavior, section “Vision”. Walls block the view.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Turn ‹Object› around** — `PatrolEnemy::turn_around`
  From the “Patrolling enemy” behavior.
  Parameters: Object (object)

**Expressions**

- `Object.PatrolEnemy::Animate()` — Automatic animations by state. The names below must match the AnimatedSprite2D.
- `Object.PatrolEnemy::Chase()` — Chase a spotted target.
- `Object.PatrolEnemy::ChaseAnimation()` — Chase animation. Empty — the walk animation.
- `Object.PatrolEnemy::ChaseSpeed()` — Chase speed, pixels per second.
- `Object.PatrolEnemy::Direction()` — Direction: 1 right, -1 left
- `Object.PatrolEnemy::DistanceToTarget()` — Distance to the spotted target, -1 — does not see it
- `Object.PatrolEnemy::FlipSprite()` — Flip the sprite — toward the movement direction.
- `Object.PatrolEnemy::Gravity()` — Gravity strength, pixels per second per second.
- `Object.PatrolEnemy::IdleAnimation()` — Idle animation — during pauses and waiting.
- `Object.PatrolEnemy::LoseTime()` — Search time — how many seconds to look for a target out of sight before giving up.
- `Object.PatrolEnemy::MaxFallSpeed()` — Maximum fall speed.
- `Object.PatrolEnemy::PatrolRange()` — Patrol beat — how many pixels it may walk away from the start. 0 — no limit.
- `Object.PatrolEnemy::ReturnHome()` — After losing the target, return to its beat.
- `Object.PatrolEnemy::Running()` — The patrol is on.
- `Object.PatrolEnemy::SeesBehind()` — Notices behind its back too, not only in front.
- `Object.PatrolEnemy::SightHeight()` — Sight height — how far above or below itself it notices the target.
- `Object.PatrolEnemy::SightRange()` — Sight range, pixels.
- `Object.PatrolEnemy::StartDirection()` — Which way to walk first.
- `Object.PatrolEnemy::StateName()` — State as text: patrol, chase, search or return
- `Object.PatrolEnemy::StopAtEdges()` — Do not jump off an edge while chasing — stop and wait.
- `Object.PatrolEnemy::TargetObject()` — Target — the name of an object from the event sheet, e.g. Player.
- `Object.PatrolEnemy::TurnAtEdges()` — Turn at the platform edge — do not fall off.
- `Object.PatrolEnemy::TurnAtWalls()` — Turn when bumping into a wall.
- `Object.PatrolEnemy::TurnPause()` — Pause when turning, seconds.
- `Object.PatrolEnemy::WalkAnimation()` — Walk animation — a name from AnimatedSprite2D.
- `Object.PatrolEnemy::WalkSpeed()` — Patrol speed, pixels per second.
- `Object.PatrolEnemy::WallsBlockSight()` — Walls block the view.

### Pickup — Pickup

A coin, a crystal, a medkit, ammo: it bobs in place, is pulled to the player by a magnet and on touch adds points, heals or refills the magazine by itself. No events are needed for that.

**Conditions**

- **“Picking up is on” of ‹Object› (Pickup) ‹Sign› ‹Value›** — `Pickup::is_active`
  Setting of the “Pickup” behavior, section “Who picks up”. Picking up is on.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“How much it gives” of ‹Object› (Pickup) ‹Sign› ‹Value›** — `Pickup::is_amount`
  Setting of the “Pickup” behavior, section “What it gives”. How much it gives — added to the variable, health or ammo.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Bobbing height in place” of ‹Object› (Pickup) ‹Sign› ‹Value›** — `Pickup::is_bob_height`
  Setting of the “Pickup” behavior, section “Look”. Bobbing height in place, in pixels. 0 — stands still.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Bobbing rate” of ‹Object› (Pickup) ‹Sign› ‹Value›** — `Pickup::is_bob_speed`
  Setting of the “Pickup” behavior, section “Look”. Bobbing rate, times per second.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Pickup effect” of ‹Object› (Pickup) ‹Sign› ‹Value›** — `Pickup::is_collect_effect`
  Setting of the “Pickup” behavior, section “Look”. Pickup effect — shrink and fade instead of vanishing instantly.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Pickup sound” of ‹Object› (Pickup) ‹Sign› ‹Value›** — `Pickup::is_collect_sound`
  Setting of the “Pickup” behavior, section “Look”. Pickup sound — a path to the file.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (text)

- **“Collector” of ‹Object› (Pickup) ‹Sign› ‹Value›** — `Pickup::is_collector`
  Setting of the “Pickup” behavior, section “Who picks up”. Collector — the name of an object from the event sheet, e.g. Player.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (text)

- **‹Object› is flying to the collector** — `Pickup::is_flying`
  From the “Pickup” behavior.
  Parameters: Object (object)

- **“Magnet radius” of ‹Object› (Pickup) ‹Sign› ‹Value›** — `Pickup::is_magnet_radius`
  Setting of the “Pickup” behavior, section “Magnet”. Magnet radius — from what distance the item flies to the collector. 0 — no magnet.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Flight speed to the collector” of ‹Object› (Pickup) ‹Sign› ‹Value›** — `Pickup::is_magnet_speed`
  Setting of the “Pickup” behavior, section “Magnet”. Flight speed to the collector, pixels per second.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Pickup delay” of ‹Object› (Pickup) ‹Sign› ‹Value›** — `Pickup::is_pickup_delay`
  Setting of the “Pickup” behavior, section “Who picks up”. Pickup delay — how many seconds after appearing the item cannot be taken. Needed for a drop from an enemy: otherwise it vanishes before it is even seen.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **‹Object› can already be picked up** — `Pickup::is_ready`
  From the “Pickup” behavior.
  Parameters: Object (object)

- **“Variable name” of ‹Object› (Pickup) ‹Sign› ‹Value›** — `Pickup::is_variable`
  Setting of the “Pickup” behavior, section “What it gives”. Variable name — where to add, e.g. coins.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (text)

- **‹Object› has just been picked up** — `Pickup::just_collected`
  From the “Pickup” behavior.
  Parameters: Object (object)

**Actions**

- **Forbid picking up ‹Object› for another ‹Seconds› seconds** — `Pickup::block_for`
  From the “Pickup” behavior.
  Parameters: Object (object), Seconds (number)

- **Give ‹Object› to the collector right away** — `Pickup::give_now`
  From the “Pickup” behavior.
  Parameters: Object (object)

- **Change “Picking up is on” of ‹Object› (Pickup): ‹Sign› ‹Value›** — `Pickup::set_active`
  Setting of the “Pickup” behavior, section “Who picks up”. Picking up is on.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “How much it gives” of ‹Object› (Pickup): ‹Sign› ‹Value›** — `Pickup::set_amount`
  Setting of the “Pickup” behavior, section “What it gives”. How much it gives — added to the variable, health or ammo.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Bobbing height in place” of ‹Object› (Pickup): ‹Sign› ‹Value›** — `Pickup::set_bob_height`
  Setting of the “Pickup” behavior, section “Look”. Bobbing height in place, in pixels. 0 — stands still.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Bobbing rate” of ‹Object› (Pickup): ‹Sign› ‹Value›** — `Pickup::set_bob_speed`
  Setting of the “Pickup” behavior, section “Look”. Bobbing rate, times per second.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Pickup effect” of ‹Object› (Pickup): ‹Sign› ‹Value›** — `Pickup::set_collect_effect`
  Setting of the “Pickup” behavior, section “Look”. Pickup effect — shrink and fade instead of vanishing instantly.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Pickup sound” of ‹Object› (Pickup): ‹Sign› ‹Value›** — `Pickup::set_collect_sound`
  Setting of the “Pickup” behavior, section “Look”. Pickup sound — a path to the file.
  Parameters: Object (object), Sign (= + - * /), Value (text)

- **Set the collector of ‹Object›: object ‹Object name›** — `Pickup::set_collector`
  From the “Pickup” behavior.
  Parameters: Object (object), Object name (text)

- **Change “Magnet radius” of ‹Object› (Pickup): ‹Sign› ‹Value›** — `Pickup::set_magnet_radius`
  Setting of the “Pickup” behavior, section “Magnet”. Magnet radius — from what distance the item flies to the collector. 0 — no magnet.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Flight speed to the collector” of ‹Object› (Pickup): ‹Sign› ‹Value›** — `Pickup::set_magnet_speed`
  Setting of the “Pickup” behavior, section “Magnet”. Flight speed to the collector, pixels per second.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Pickup delay” of ‹Object› (Pickup): ‹Sign› ‹Value›** — `Pickup::set_pickup_delay`
  Setting of the “Pickup” behavior, section “Who picks up”. Pickup delay — how many seconds after appearing the item cannot be taken. Needed for a drop from an enemy: otherwise it vanishes before it is even seen.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Variable name” of ‹Object› (Pickup): ‹Sign› ‹Value›** — `Pickup::set_variable`
  Setting of the “Pickup” behavior, section “What it gives”. Variable name — where to add, e.g. coins.
  Parameters: Object (object), Sign (= + - * /), Value (text)

**Expressions**

- `Object.Pickup::Active()` — Picking up is on.
- `Object.Pickup::Amount()` — How much it gives — added to the variable, health or ammo.
- `Object.Pickup::BobHeight()` — Bobbing height in place, in pixels. 0 — stands still.
- `Object.Pickup::BobSpeed()` — Bobbing rate, times per second.
- `Object.Pickup::CollectEffect()` — Pickup effect — shrink and fade instead of vanishing instantly.
- `Object.Pickup::CollectSound()` — Pickup sound — a path to the file.
- `Object.Pickup::Collector()` — Collector — the name of an object from the event sheet, e.g. Player.
- `Object.Pickup::DistanceToCollector()` — Distance to the nearest collector
- `Object.Pickup::MagnetRadius()` — Magnet radius — from what distance the item flies to the collector. 0 — no magnet.
- `Object.Pickup::MagnetSpeed()` — Flight speed to the collector, pixels per second.
- `Object.Pickup::PickupDelay()` — Pickup delay — how many seconds after appearing the item cannot be taken. Needed for a drop from an enemy: otherwise it vanishes before it is even seen.
- `Object.Pickup::Variable()` — Variable name — where to add, e.g. coins.

### Platform — Platform

Everything a platform can be: one-way (jump up through it, drop down with "down" and jump), moving and carrying whoever stands on it, a conveyor belt, crumbling after N seconds and a trampoline. Turn on what you need.

**Conditions**

- **Someone stands on ‹Object›** — `Platform::has_rider`
  From the “Platform” behavior.
  Parameters: Object (object)

- **“Trampoline force” of ‹Object› (Platform) ‹Sign› ‹Value›** — `Platform::is_bounce_force`
  Setting of the “Platform” behavior, section “Trampoline”. Trampoline force, pixels per second.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **‹Object› has crumbled** — `Platform::is_broken`
  From the “Platform” behavior.
  Parameters: Object (object)

- **“Conveyor belt speed” of ‹Object› (Platform) ‹Sign› ‹Value›** — `Platform::is_conveyor_speed`
  Setting of the “Platform” behavior, section “Conveyor”. Conveyor belt speed, pixels per second: carries whoever stands on it sideways. Negative — to the left. 0 — not a belt.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Crumble delay” of ‹Object› (Platform) ‹Sign› ‹Value›** — `Platform::is_crumble_delay`
  Setting of the “Platform” behavior, section “Crumbling”. Crumble delay — seconds after someone stood on it.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Crumble when someone stands on the platform” of ‹Object› (Platform) ‹Sign› ‹Value›** — `Platform::is_crumbles`
  Setting of the “Platform” behavior, section “Crumbling”. Crumble when someone stands on the platform.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **‹Object› is about to crumble** — `Platform::is_crumbling`
  From the “Platform” behavior.
  Parameters: Object (object)

- **“Smooth ends” of ‹Object› (Platform) ‹Sign› ‹Value›** — `Platform::is_ease_ends`
  Setting of the “Platform” behavior, section “Movement”. Smooth ends — acceleration and braking near the ends.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Pause at the ends” of ‹Object› (Platform) ‹Sign› ‹Value›** — `Platform::is_end_pause`
  Setting of the “Platform” behavior, section “Movement”. Pause at the ends, seconds.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Travel time one way” of ‹Object› (Platform) ‹Sign› ‹Value›** — `Platform::is_move_time`
  Setting of the “Platform” behavior, section “Movement”. Travel time one way, seconds.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Offset to the far point along X” of ‹Object› (Platform) ‹Sign› ‹Value›** — `Platform::is_move_x`
  Setting of the “Platform” behavior, section “Movement”. Offset to the far point along X, pixels.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Offset to the far point along Y” of ‹Object› (Platform) ‹Sign› ‹Value›** — `Platform::is_move_y`
  Setting of the “Platform” behavior, section “Movement”. Offset to the far point along Y, pixels.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Move back and forth” of ‹Object› (Platform) ‹Sign› ‹Value›** — `Platform::is_moving`
  Setting of the “Platform” behavior, section “Movement”. Move back and forth. Whoever stands on the platform rides along.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“One-way” of ‹Object› (Platform) ‹Sign› ‹Value›** — `Platform::is_one_way`
  Setting of the “Platform” behavior, section “One-way”. One-way: passable from below, holds from above. Drop down from it with "down" and jump.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“How many seconds until it comes back” of ‹Object› (Platform) ‹Sign› ‹Value›** — `Platform::is_respawn_time`
  Setting of the “Platform” behavior, section “Crumbling”. How many seconds until it comes back. 0 — never.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Shake before crumbling” of ‹Object› (Platform) ‹Sign› ‹Value›** — `Platform::is_shake`
  Setting of the “Platform” behavior, section “Crumbling”. Shake before crumbling.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Trampoline” of ‹Object› (Platform) ‹Sign› ‹Value›** — `Platform::is_trampoline`
  Setting of the “Platform” behavior, section “Trampoline”. Trampoline: throws up whoever lands on top.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

**Actions**

- **Crumble ‹Object› now** — `Platform::crumble_now`
  From the “Platform” behavior.
  Parameters: Object (object)

- **Bring back the crumbled ‹Object›** — `Platform::restore`
  From the “Platform” behavior.
  Parameters: Object (object)

- **Change “Trampoline force” of ‹Object› (Platform): ‹Sign› ‹Value›** — `Platform::set_bounce_force`
  Setting of the “Platform” behavior, section “Trampoline”. Trampoline force, pixels per second.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Belt speed of ‹Object›: ‹Speed›** — `Platform::set_conveyor`
  From the “Platform” behavior.
  Parameters: Object (object), Speed (number)

- **Change “Conveyor belt speed” of ‹Object› (Platform): ‹Sign› ‹Value›** — `Platform::set_conveyor_speed`
  Setting of the “Platform” behavior, section “Conveyor”. Conveyor belt speed, pixels per second: carries whoever stands on it sideways. Negative — to the left. 0 — not a belt.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Crumble delay” of ‹Object› (Platform): ‹Sign› ‹Value›** — `Platform::set_crumble_delay`
  Setting of the “Platform” behavior, section “Crumbling”. Crumble delay — seconds after someone stood on it.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Crumble when someone stands on the platform” of ‹Object› (Platform): ‹Sign› ‹Value›** — `Platform::set_crumbles`
  Setting of the “Platform” behavior, section “Crumbling”. Crumble when someone stands on the platform.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Smooth ends” of ‹Object› (Platform): ‹Sign› ‹Value›** — `Platform::set_ease_ends`
  Setting of the “Platform” behavior, section “Movement”. Smooth ends — acceleration and braking near the ends.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Pause at the ends” of ‹Object› (Platform): ‹Sign› ‹Value›** — `Platform::set_end_pause`
  Setting of the “Platform” behavior, section “Movement”. Pause at the ends, seconds.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Travel time one way” of ‹Object› (Platform): ‹Sign› ‹Value›** — `Platform::set_move_time`
  Setting of the “Platform” behavior, section “Movement”. Travel time one way, seconds.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Offset to the far point along X” of ‹Object› (Platform): ‹Sign› ‹Value›** — `Platform::set_move_x`
  Setting of the “Platform” behavior, section “Movement”. Offset to the far point along X, pixels.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Offset to the far point along Y” of ‹Object› (Platform): ‹Sign› ‹Value›** — `Platform::set_move_y`
  Setting of the “Platform” behavior, section “Movement”. Offset to the far point along Y, pixels.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Move back and forth” of ‹Object› (Platform): ‹Sign› ‹Value›** — `Platform::set_moving`
  Setting of the “Platform” behavior, section “Movement”. Move back and forth. Whoever stands on the platform rides along.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “One-way” of ‹Object› (Platform): ‹Sign› ‹Value›** — `Platform::set_one_way`
  Setting of the “Platform” behavior, section “One-way”. One-way: passable from below, holds from above. Drop down from it with "down" and jump.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “How many seconds until it comes back” of ‹Object› (Platform): ‹Sign› ‹Value›** — `Platform::set_respawn_time`
  Setting of the “Platform” behavior, section “Crumbling”. How many seconds until it comes back. 0 — never.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Shake before crumbling” of ‹Object› (Platform): ‹Sign› ‹Value›** — `Platform::set_shake`
  Setting of the “Platform” behavior, section “Crumbling”. Shake before crumbling.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Trampoline” of ‹Object› (Platform): ‹Sign› ‹Value›** — `Platform::set_trampoline`
  Setting of the “Platform” behavior, section “Trampoline”. Trampoline: throws up whoever lands on top.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Start the movement of ‹Object›** — `Platform::start_moving`
  From the “Platform” behavior.
  Parameters: Object (object)

- **Stop the movement of ‹Object›** — `Platform::stop_moving`
  From the “Platform” behavior.
  Parameters: Object (object)

**Expressions**

- `Object.Platform::BounceForce()` — Trampoline force, pixels per second.
- `Object.Platform::ConveyorSpeed()` — Conveyor belt speed, pixels per second: carries whoever stands on it sideways. Negative — to the left. 0 — not a belt.
- `Object.Platform::CrumbleDelay()` — Crumble delay — seconds after someone stood on it.
- `Object.Platform::Crumbles()` — Crumble when someone stands on the platform.
- `Object.Platform::EaseEnds()` — Smooth ends — acceleration and braking near the ends.
- `Object.Platform::EndPause()` — Pause at the ends, seconds.
- `Object.Platform::MoveTime()` — Travel time one way, seconds.
- `Object.Platform::MoveX()` — Offset to the far point along X, pixels.
- `Object.Platform::MoveY()` — Offset to the far point along Y, pixels.
- `Object.Platform::Moving()` — Move back and forth. Whoever stands on the platform rides along.
- `Object.Platform::OneWay()` — One-way: passable from below, holds from above. Drop down from it with "down" and jump.
- `Object.Platform::RespawnTime()` — How many seconds until it comes back. 0 — never.
- `Object.Platform::RiderCount()` — How many objects stand on the platform
- `Object.Platform::Shake()` — Shake before crumbling.
- `Object.Platform::Trampoline()` — Trampoline: throws up whoever lands on top.

### Platformer — Platformer character

A platformer with character: coyote time, jump buffer, variable height, double jump, wall sliding and wall jumps. Needs a CharacterBody2D with a collision shape.

**Conditions**

- **‹Object› is at a ladder — can grab it** — `Platformer::at_ladder`
  From the “Platformer character” behavior.
  Parameters: Object (object)

- **‹Object› can jump right now** — `Platformer::can_jump`
  From the “Platformer character” behavior.
  Parameters: Object (object)

- **“Acceleration” of ‹Object› (Platformer character) ‹Sign› ‹Value›** — `Platformer::is_acceleration`
  Setting of the “Platformer character” behavior, section “Running”. Acceleration — how fast the speed builds up.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Air control” of ‹Object› (Platformer character) ‹Sign› ‹Value›** — `Platformer::is_air_control`
  Setting of the “Platformer character” behavior, section “Running”. Air control, share of the ground one: 1 — as on the ground, 0 — none.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Force of jumps in the air” of ‹Object› (Platformer character) ‹Sign› ‹Value›** — `Platformer::is_air_jump_factor`
  Setting of the “Platformer character” behavior, section “Jump”. Force of jumps in the air, share of a normal one.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Automatic animations by state” of ‹Object› (Platformer character) ‹Sign› ‹Value›** — `Platformer::is_animate`
  Setting of the “Platformer character” behavior, section “Look”. Automatic animations by state. The names below must match the AnimatedSprite2D.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Ladder climbing animation” of ‹Object› (Platformer character) ‹Sign› ‹Value›** — `Platformer::is_climb_animation`
  Setting of the “Platformer character” behavior, section “Look”. Ladder climbing animation. Empty — the idle animation.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (text)

- **“Climb ladders” of ‹Object› (Platformer character) ‹Sign› ‹Value›** — `Platformer::is_climb_ladders`
  Setting of the “Platformer character” behavior, section “Ladders and platforms”. Climb ladders — zones with the "Ladder" behavior: up and down with the arrow keys, jump to get off.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Climbing speed” of ‹Object› (Platformer character) ‹Sign› ‹Value›** — `Platformer::is_climb_speed`
  Setting of the “Platformer character” behavior, section “Ladders and platforms”. Climbing speed, pixels per second.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **‹Object› is climbing a ladder** — `Platformer::is_climbing`
  From the “Platformer character” behavior.
  Parameters: Object (object)

- **“Coyote time” of ‹Object› (Platformer character) ‹Sign› ‹Value›** — `Platformer::is_coyote_time`
  Setting of the “Platformer character” behavior, section “Jump”. Coyote time — how many seconds after leaving an edge a jump is still possible.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Deceleration” of ‹Object› (Platformer character) ‹Sign› ‹Value›** — `Platformer::is_deceleration`
  Setting of the “Platformer character” behavior, section “Running”. Deceleration — how fast the speed dies down without input.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Arrow keys and space controls” of ‹Object› (Platformer character) ‹Sign› ‹Value›** — `Platformer::is_default_controls`
  Setting of the “Platformer character” behavior, section “Controls”. Arrow keys and space controls — automatic, without events.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Animation of a jump in the air” of ‹Object› (Platformer character) ‹Sign› ‹Value›** — `Platformer::is_double_jump_animation`
  Setting of the “Platformer character” behavior, section “Look”. Animation of a jump in the air (the second and later). Empty — the same as a normal one.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (text)

- **“Drop down through one-way platforms” of ‹Object› (Platformer character) ‹Sign› ‹Value›** — `Platformer::is_drop_through`
  Setting of the “Platformer character” behavior, section “Ladders and platforms”. Drop down through one-way platforms: "down" and jump.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Fall animation” of ‹Object› (Platformer character) ‹Sign› ‹Value›** — `Platformer::is_fall_animation`
  Setting of the “Platformer character” behavior, section “Look”. Fall animation.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (text)

- **“Fall weight” of ‹Object› (Platformer character) ‹Sign› ‹Value›** — `Platformer::is_fall_gravity_factor`
  Setting of the “Platformer character” behavior, section “Gravity”. Fall weight — how many times heavier a fall is than a rise.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **‹Object› is falling** — `Platformer::is_falling`
  From the “Platformer character” behavior.
  Parameters: Object (object)

- **“Flip the sprite” of ‹Object› (Platformer character) ‹Sign› ‹Value›** — `Platformer::is_flip_sprite`
  Setting of the “Platformer character” behavior, section “Look”. Flip the sprite — toward the movement direction.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Gravity strength” of ‹Object› (Platformer character) ‹Sign› ‹Value›** — `Platformer::is_gravity`
  Setting of the “Platformer character” behavior, section “Gravity”. Gravity strength, pixels per second per second.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Idle animation” of ‹Object› (Platformer character) ‹Sign› ‹Value›** — `Platformer::is_idle_animation`
  Setting of the “Platformer character” behavior, section “Look”. Idle animation — a name from AnimatedSprite2D.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (text)

- **“Animation of rising in a jump” of ‹Object› (Platformer character) ‹Sign› ‹Value›** — `Platformer::is_jump_animation`
  Setting of the “Platformer character” behavior, section “Look”. Animation of rising in a jump.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (text)

- **“Jump buffer” of ‹Object› (Platformer character) ‹Sign› ‹Value›** — `Platformer::is_jump_buffer_time`
  Setting of the “Platformer character” behavior, section “Jump”. Jump buffer — how many seconds a press waits for landing.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Jump cut” of ‹Object› (Platformer character) ‹Sign› ‹Value›** — `Platformer::is_jump_cut`
  Setting of the “Platformer character” behavior, section “Jump”. Jump cut — how many times the rise is reduced on release.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Jump force” of ‹Object› (Platformer character) ‹Sign› ‹Value›** — `Platformer::is_jump_force`
  Setting of the “Platformer character” behavior, section “Jump”. Jump force, pixels per second.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **‹Object› is jumping up** — `Platformer::is_jumping`
  From the “Platformer character” behavior.
  Parameters: Object (object)

- **“Sideways speed on a ladder” of ‹Object› (Platformer character) ‹Sign› ‹Value›** — `Platformer::is_ladder_side_speed`
  Setting of the “Platformer character” behavior, section “Ladders and platforms”. Sideways speed on a ladder, share of running. 0 — only up and down.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Maximum fall speed” of ‹Object› (Platformer character) ‹Sign› ‹Value›** — `Platformer::is_max_fall_speed`
  Setting of the “Platformer character” behavior, section “Gravity”. Maximum fall speed.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Number of jumps without touching the ground” of ‹Object› (Platformer character) ‹Sign› ‹Value›** — `Platformer::is_max_jumps`
  Setting of the “Platformer character” behavior, section “Jump”. Number of jumps without touching the ground. 2 — double jump.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Maximum running speed” of ‹Object› (Platformer character) ‹Sign› ‹Value›** — `Platformer::is_max_speed`
  Setting of the “Platformer character” behavior, section “Running”. Maximum running speed, pixels per second.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **‹Object› is moving** — `Platformer::is_moving`
  From the “Platformer character” behavior.
  Parameters: Object (object)

- **“Run animation” of ‹Object› (Platformer character) ‹Sign› ‹Value›** — `Platformer::is_run_animation`
  Setting of the “Platformer character” behavior, section “Look”. Run animation — a name from AnimatedSprite2D.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (text)

- **“Turn boost” of ‹Object› (Platformer character) ‹Sign› ‹Value›** — `Platformer::is_turn_boost`
  Setting of the “Platformer character” behavior, section “Running”. Turn boost — how many times faster a change of direction is.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Variable jump height” of ‹Object› (Platformer character) ‹Sign› ‹Value›** — `Platformer::is_variable_height`
  Setting of the “Platformer character” behavior, section “Jump”. Variable jump height — release the button and the jump is cut.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Jump off a wall in the opposite direction” of ‹Object› (Platformer character) ‹Sign› ‹Value›** — `Platformer::is_wall_jump`
  Setting of the “Platformer character” behavior, section “Walls”. Jump off a wall in the opposite direction.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Input lock after a wall jump” of ‹Object› (Platformer character) ‹Sign› ‹Value›** — `Platformer::is_wall_jump_lock`
  Setting of the “Platformer character” behavior, section “Walls”. Input lock after a wall jump, seconds.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Horizontal push off the wall” of ‹Object› (Platformer character) ‹Sign› ‹Value›** — `Platformer::is_wall_jump_push`
  Setting of the “Platformer character” behavior, section “Walls”. Horizontal push off the wall.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Upward force of a wall jump” of ‹Object› (Platformer character) ‹Sign› ‹Value›** — `Platformer::is_wall_jump_up`
  Setting of the “Platformer character” behavior, section “Walls”. Upward force of a wall jump, share of a normal one.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Slide down a wall instead of falling” of ‹Object› (Platformer character) ‹Sign› ‹Value›** — `Platformer::is_wall_slide`
  Setting of the “Platformer character” behavior, section “Walls”. Slide down a wall instead of falling.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Wall slide animation” of ‹Object› (Platformer character) ‹Sign› ‹Value›** — `Platformer::is_wall_slide_animation`
  Setting of the “Platformer character” behavior, section “Look”. Wall slide animation. Empty — the fall animation.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (text)

- **“Wall slide speed” of ‹Object› (Platformer character) ‹Sign› ‹Value›** — `Platformer::is_wall_slide_speed`
  Setting of the “Platformer character” behavior, section “Walls”. Wall slide speed.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **‹Object› is sliding down a wall** — `Platformer::is_wall_sliding`
  From the “Platformer character” behavior.
  Parameters: Object (object)

- **‹Object› has just dropped down through a platform** — `Platformer::just_dropped`
  From the “Platformer character” behavior.
  Parameters: Object (object)

- **‹Object› has just jumped** — `Platformer::just_jumped`
  From the “Platformer character” behavior.
  Parameters: Object (object)

- **‹Object› has just landed** — `Platformer::just_landed`
  From the “Platformer character” behavior.
  Parameters: Object (object)

- **‹Object› is on the floor** — `Platformer::on_floor`
  From the “Platformer character” behavior.
  Parameters: Object (object)

**Actions**

- **Bounce ‹Object› with force ‹Force›** — `Platformer::bounce`
  From the “Platformer character” behavior.
  Parameters: Object (object), Force (number)

- **Get off the ladder: ‹Object›** — `Platformer::leave_ladder`
  From the “Platformer character” behavior.
  Parameters: Object (object)

- **Cut the jump of ‹Object› (like releasing the button)** — `Platformer::release_jump`
  From the “Platformer character” behavior.
  Parameters: Object (object)

- **Change “Acceleration” of ‹Object› (Platformer character): ‹Sign› ‹Value›** — `Platformer::set_acceleration`
  Setting of the “Platformer character” behavior, section “Running”. Acceleration — how fast the speed builds up.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Air control” of ‹Object› (Platformer character): ‹Sign› ‹Value›** — `Platformer::set_air_control`
  Setting of the “Platformer character” behavior, section “Running”. Air control, share of the ground one: 1 — as on the ground, 0 — none.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Force of jumps in the air” of ‹Object› (Platformer character): ‹Sign› ‹Value›** — `Platformer::set_air_jump_factor`
  Setting of the “Platformer character” behavior, section “Jump”. Force of jumps in the air, share of a normal one.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Automatic animations by state” of ‹Object› (Platformer character): ‹Sign› ‹Value›** — `Platformer::set_animate`
  Setting of the “Platformer character” behavior, section “Look”. Automatic animations by state. The names below must match the AnimatedSprite2D.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Ladder climbing animation” of ‹Object› (Platformer character): ‹Sign› ‹Value›** — `Platformer::set_climb_animation`
  Setting of the “Platformer character” behavior, section “Look”. Ladder climbing animation. Empty — the idle animation.
  Parameters: Object (object), Sign (= + - * /), Value (text)

- **Change “Climb ladders” of ‹Object› (Platformer character): ‹Sign› ‹Value›** — `Platformer::set_climb_ladders`
  Setting of the “Platformer character” behavior, section “Ladders and platforms”. Climb ladders — zones with the "Ladder" behavior: up and down with the arrow keys, jump to get off.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Climbing speed” of ‹Object› (Platformer character): ‹Sign› ‹Value›** — `Platformer::set_climb_speed`
  Setting of the “Platformer character” behavior, section “Ladders and platforms”. Climbing speed, pixels per second.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Coyote time” of ‹Object› (Platformer character): ‹Sign› ‹Value›** — `Platformer::set_coyote_time`
  Setting of the “Platformer character” behavior, section “Jump”. Coyote time — how many seconds after leaving an edge a jump is still possible.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Deceleration” of ‹Object› (Platformer character): ‹Sign› ‹Value›** — `Platformer::set_deceleration`
  Setting of the “Platformer character” behavior, section “Running”. Deceleration — how fast the speed dies down without input.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Arrow keys and space controls” of ‹Object› (Platformer character): ‹Sign› ‹Value›** — `Platformer::set_default_controls`
  Setting of the “Platformer character” behavior, section “Controls”. Arrow keys and space controls — automatic, without events.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Animation of a jump in the air” of ‹Object› (Platformer character): ‹Sign› ‹Value›** — `Platformer::set_double_jump_animation`
  Setting of the “Platformer character” behavior, section “Look”. Animation of a jump in the air (the second and later). Empty — the same as a normal one.
  Parameters: Object (object), Sign (= + - * /), Value (text)

- **Change “Drop down through one-way platforms” of ‹Object› (Platformer character): ‹Sign› ‹Value›** — `Platformer::set_drop_through`
  Setting of the “Platformer character” behavior, section “Ladders and platforms”. Drop down through one-way platforms: "down" and jump.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Fall animation” of ‹Object› (Platformer character): ‹Sign› ‹Value›** — `Platformer::set_fall_animation`
  Setting of the “Platformer character” behavior, section “Look”. Fall animation.
  Parameters: Object (object), Sign (= + - * /), Value (text)

- **Change “Fall weight” of ‹Object› (Platformer character): ‹Sign› ‹Value›** — `Platformer::set_fall_gravity_factor`
  Setting of the “Platformer character” behavior, section “Gravity”. Fall weight — how many times heavier a fall is than a rise.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Flip the sprite” of ‹Object› (Platformer character): ‹Sign› ‹Value›** — `Platformer::set_flip_sprite`
  Setting of the “Platformer character” behavior, section “Look”. Flip the sprite — toward the movement direction.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Gravity strength” of ‹Object› (Platformer character): ‹Sign› ‹Value›** — `Platformer::set_gravity`
  Setting of the “Platformer character” behavior, section “Gravity”. Gravity strength, pixels per second per second.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Idle animation” of ‹Object› (Platformer character): ‹Sign› ‹Value›** — `Platformer::set_idle_animation`
  Setting of the “Platformer character” behavior, section “Look”. Idle animation — a name from AnimatedSprite2D.
  Parameters: Object (object), Sign (= + - * /), Value (text)

- **Change “Animation of rising in a jump” of ‹Object› (Platformer character): ‹Sign› ‹Value›** — `Platformer::set_jump_animation`
  Setting of the “Platformer character” behavior, section “Look”. Animation of rising in a jump.
  Parameters: Object (object), Sign (= + - * /), Value (text)

- **Change “Jump buffer” of ‹Object› (Platformer character): ‹Sign› ‹Value›** — `Platformer::set_jump_buffer_time`
  Setting of the “Platformer character” behavior, section “Jump”. Jump buffer — how many seconds a press waits for landing.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Jump cut” of ‹Object› (Platformer character): ‹Sign› ‹Value›** — `Platformer::set_jump_cut`
  Setting of the “Platformer character” behavior, section “Jump”. Jump cut — how many times the rise is reduced on release.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Jump force” of ‹Object› (Platformer character): ‹Sign› ‹Value›** — `Platformer::set_jump_force`
  Setting of the “Platformer character” behavior, section “Jump”. Jump force, pixels per second.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Sideways speed on a ladder” of ‹Object› (Platformer character): ‹Sign› ‹Value›** — `Platformer::set_ladder_side_speed`
  Setting of the “Platformer character” behavior, section “Ladders and platforms”. Sideways speed on a ladder, share of running. 0 — only up and down.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Maximum fall speed” of ‹Object› (Platformer character): ‹Sign› ‹Value›** — `Platformer::set_max_fall_speed`
  Setting of the “Platformer character” behavior, section “Gravity”. Maximum fall speed.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Number of jumps without touching the ground” of ‹Object› (Platformer character): ‹Sign› ‹Value›** — `Platformer::set_max_jumps`
  Setting of the “Platformer character” behavior, section “Jump”. Number of jumps without touching the ground. 2 — double jump.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Maximum running speed” of ‹Object› (Platformer character): ‹Sign› ‹Value›** — `Platformer::set_max_speed`
  Setting of the “Platformer character” behavior, section “Running”. Maximum running speed, pixels per second.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Run animation” of ‹Object› (Platformer character): ‹Sign› ‹Value›** — `Platformer::set_run_animation`
  Setting of the “Platformer character” behavior, section “Look”. Run animation — a name from AnimatedSprite2D.
  Parameters: Object (object), Sign (= + - * /), Value (text)

- **Change “Turn boost” of ‹Object› (Platformer character): ‹Sign› ‹Value›** — `Platformer::set_turn_boost`
  Setting of the “Platformer character” behavior, section “Running”. Turn boost — how many times faster a change of direction is.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Variable jump height” of ‹Object› (Platformer character): ‹Sign› ‹Value›** — `Platformer::set_variable_height`
  Setting of the “Platformer character” behavior, section “Jump”. Variable jump height — release the button and the jump is cut.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Jump off a wall in the opposite direction” of ‹Object› (Platformer character): ‹Sign› ‹Value›** — `Platformer::set_wall_jump`
  Setting of the “Platformer character” behavior, section “Walls”. Jump off a wall in the opposite direction.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Input lock after a wall jump” of ‹Object› (Platformer character): ‹Sign› ‹Value›** — `Platformer::set_wall_jump_lock`
  Setting of the “Platformer character” behavior, section “Walls”. Input lock after a wall jump, seconds.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Horizontal push off the wall” of ‹Object› (Platformer character): ‹Sign› ‹Value›** — `Platformer::set_wall_jump_push`
  Setting of the “Platformer character” behavior, section “Walls”. Horizontal push off the wall.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Upward force of a wall jump” of ‹Object› (Platformer character): ‹Sign› ‹Value›** — `Platformer::set_wall_jump_up`
  Setting of the “Platformer character” behavior, section “Walls”. Upward force of a wall jump, share of a normal one.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Slide down a wall instead of falling” of ‹Object› (Platformer character): ‹Sign› ‹Value›** — `Platformer::set_wall_slide`
  Setting of the “Platformer character” behavior, section “Walls”. Slide down a wall instead of falling.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Wall slide animation” of ‹Object› (Platformer character): ‹Sign› ‹Value›** — `Platformer::set_wall_slide_animation`
  Setting of the “Platformer character” behavior, section “Look”. Wall slide animation. Empty — the fall animation.
  Parameters: Object (object), Sign (= + - * /), Value (text)

- **Change “Wall slide speed” of ‹Object› (Platformer character): ‹Sign› ‹Value›** — `Platformer::set_wall_slide_speed`
  Setting of the “Platformer character” behavior, section “Walls”. Wall slide speed.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Climb down the ladder: ‹Object›** — `Platformer::simulate_down`
  From the “Platformer character” behavior.
  Parameters: Object (object)

- **Drop down: ‹Object›** — `Platformer::simulate_drop`
  Through the one-way platform underfoot. On a normal floor — just a jump.
  Parameters: Object (object)

- **Jump: ‹Object›** — `Platformer::simulate_jump`
  From the “Platformer character” behavior.
  Parameters: Object (object)

- **Walk left: ‹Object›** — `Platformer::simulate_left`
  From the “Platformer character” behavior.
  Parameters: Object (object)

- **Walk right: ‹Object›** — `Platformer::simulate_right`
  From the “Platformer character” behavior.
  Parameters: Object (object)

- **Climb up the ladder: ‹Object›** — `Platformer::simulate_up`
  From the “Platformer character” behavior.
  Parameters: Object (object)

- **Stop ‹Object›** — `Platformer::stop`
  From the “Platformer character” behavior.
  Parameters: Object (object)

**Expressions**

- `Object.Platformer::Acceleration()` — Acceleration — how fast the speed builds up.
- `Object.Platformer::AirControl()` — Air control, share of the ground one: 1 — as on the ground, 0 — none.
- `Object.Platformer::AirJumpFactor()` — Force of jumps in the air, share of a normal one.
- `Object.Platformer::Animate()` — Automatic animations by state. The names below must match the AnimatedSprite2D.
- `Object.Platformer::ClimbAnimation()` — Ladder climbing animation. Empty — the idle animation.
- `Object.Platformer::ClimbLadders()` — Climb ladders — zones with the "Ladder" behavior: up and down with the arrow keys, jump to get off.
- `Object.Platformer::ClimbSpeed()` — Climbing speed, pixels per second.
- `Object.Platformer::CoyoteTime()` — Coyote time — how many seconds after leaving an edge a jump is still possible.
- `Object.Platformer::Deceleration()` — Deceleration — how fast the speed dies down without input.
- `Object.Platformer::DefaultControls()` — Arrow keys and space controls — automatic, without events.
- `Object.Platformer::DoubleJumpAnimation()` — Animation of a jump in the air (the second and later). Empty — the same as a normal one.
- `Object.Platformer::DropThrough()` — Drop down through one-way platforms: "down" and jump.
- `Object.Platformer::FallAnimation()` — Fall animation.
- `Object.Platformer::FallGravityFactor()` — Fall weight — how many times heavier a fall is than a rise.
- `Object.Platformer::FlipSprite()` — Flip the sprite — toward the movement direction.
- `Object.Platformer::Gravity()` — Gravity strength, pixels per second per second.
- `Object.Platformer::IdleAnimation()` — Idle animation — a name from AnimatedSprite2D.
- `Object.Platformer::JumpAnimation()` — Animation of rising in a jump.
- `Object.Platformer::JumpBufferTime()` — Jump buffer — how many seconds a press waits for landing.
- `Object.Platformer::JumpCut()` — Jump cut — how many times the rise is reduced on release.
- `Object.Platformer::JumpForce()` — Jump force, pixels per second.
- `Object.Platformer::JumpsLeft()` — How many jumps are left
- `Object.Platformer::LadderSideSpeed()` — Sideways speed on a ladder, share of running. 0 — only up and down.
- `Object.Platformer::MaxFallSpeed()` — Maximum fall speed.
- `Object.Platformer::MaxJumps()` — Number of jumps without touching the ground. 2 — double jump.
- `Object.Platformer::MaxSpeed()` — Maximum running speed, pixels per second.
- `Object.Platformer::RunAnimation()` — Run animation — a name from AnimatedSprite2D.
- `Object.Platformer::SpeedX()` — Horizontal speed
- `Object.Platformer::SpeedY()` — Vertical speed
- `Object.Platformer::TurnBoost()` — Turn boost — how many times faster a change of direction is.
- `Object.Platformer::VariableHeight()` — Variable jump height — release the button and the jump is cut.
- `Object.Platformer::WallJump()` — Jump off a wall in the opposite direction.
- `Object.Platformer::WallJumpLock()` — Input lock after a wall jump, seconds.
- `Object.Platformer::WallJumpPush()` — Horizontal push off the wall.
- `Object.Platformer::WallJumpUp()` — Upward force of a wall jump, share of a normal one.
- `Object.Platformer::WallSlide()` — Slide down a wall instead of falling.
- `Object.Platformer::WallSlideAnimation()` — Wall slide animation. Empty — the fall animation.
- `Object.Platformer::WallSlideSpeed()` — Wall slide speed.

### Pushable — Pushable

A crate a character moves by leaning into its side. It falls off edges, stops at walls, and in top-down games is pushed in every direction.

**Conditions**

- **“Pushing is allowed” of ‹Object› (Pushable) ‹Sign› ‹Value›** — `Pushable::is_enabled`
  Setting of the “Pushable” behavior, section “Pushing”. Pushing is allowed.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Gravity strength” of ‹Object› (Pushable) ‹Sign› ‹Value›** — `Pushable::is_gravity`
  Setting of the “Pushable” behavior, section “Gravity”. Gravity strength, pixels per second per second.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Maximum fall speed” of ‹Object› (Pushable) ‹Sign› ‹Value›** — `Pushable::is_max_fall_speed`
  Setting of the “Pushable” behavior, section “Gravity”. Maximum fall speed.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Heaviness” of ‹Object› (Pushable) ‹Sign› ‹Value›** — `Pushable::is_push_delay`
  Setting of the “Pushable” behavior, section “Pushing”. Heaviness — how many seconds to lean before the crate moves.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Speed at which the crate moves” of ‹Object› (Pushable) ‹Sign› ‹Value›** — `Pushable::is_push_speed`
  Setting of the “Pushable” behavior, section “Pushing”. Speed at which the crate moves, pixels per second. Better lower than the running speed — pushing is hard.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **‹Object› is being pushed** — `Pushable::is_pushed`
  From the “Pushable” behavior.
  Parameters: Object (object)

- **“Who can push” of ‹Object› (Pushable) ‹Sign› ‹Value›** — `Pushable::is_pusher_object`
  Setting of the “Pushable” behavior, section “Pushing”. Who can push — the name of a sheet object, e.g. Player. Empty — any character.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (text)

- **“Sliding” of ‹Object› (Pushable) ‹Sign› ‹Value›** — `Pushable::is_slide_friction`
  Setting of the “Pushable” behavior, section “Pushing”. Sliding — how fast the crate stops when released. 0 — at once.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Top-down” of ‹Object› (Pushable) ‹Sign› ‹Value›** — `Pushable::is_top_down`
  Setting of the “Pushable” behavior, section “Gravity”. Top-down: no gravity, pushed in every direction.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

**Actions**

- **Allow pushing ‹Object›: ‹Yes or no› (1 yes, 0 no)** — `Pushable::set_enabled`
  From the “Pushable” behavior.
  Parameters: Object (object), Yes or no (number)

- **Change “Gravity strength” of ‹Object› (Pushable): ‹Sign› ‹Value›** — `Pushable::set_gravity`
  Setting of the “Pushable” behavior, section “Gravity”. Gravity strength, pixels per second per second.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Maximum fall speed” of ‹Object› (Pushable): ‹Sign› ‹Value›** — `Pushable::set_max_fall_speed`
  Setting of the “Pushable” behavior, section “Gravity”. Maximum fall speed.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Heaviness” of ‹Object› (Pushable): ‹Sign› ‹Value›** — `Pushable::set_push_delay`
  Setting of the “Pushable” behavior, section “Pushing”. Heaviness — how many seconds to lean before the crate moves.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Speed at which the crate moves” of ‹Object› (Pushable): ‹Sign› ‹Value›** — `Pushable::set_push_speed`
  Setting of the “Pushable” behavior, section “Pushing”. Speed at which the crate moves, pixels per second. Better lower than the running speed — pushing is hard.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Who can push” of ‹Object› (Pushable): ‹Sign› ‹Value›** — `Pushable::set_pusher_object`
  Setting of the “Pushable” behavior, section “Pushing”. Who can push — the name of a sheet object, e.g. Player. Empty — any character.
  Parameters: Object (object), Sign (= + - * /), Value (text)

- **Change “Sliding” of ‹Object› (Pushable): ‹Sign› ‹Value›** — `Pushable::set_slide_friction`
  Setting of the “Pushable” behavior, section “Pushing”. Sliding — how fast the crate stops when released. 0 — at once.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Top-down” of ‹Object› (Pushable): ‹Sign› ‹Value›** — `Pushable::set_top_down`
  Setting of the “Pushable” behavior, section “Gravity”. Top-down: no gravity, pushed in every direction.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Push ‹Object› by ‹Along X› ; ‹Along Y› pixels** — `Pushable::shove`
  From the “Pushable” behavior.
  Parameters: Object (object), Along X (number), Along Y (number)

**Expressions**

- `Object.Pushable::Enabled()` — Pushing is allowed.
- `Object.Pushable::Gravity()` — Gravity strength, pixels per second per second.
- `Object.Pushable::MaxFallSpeed()` — Maximum fall speed.
- `Object.Pushable::PushDelay()` — Heaviness — how many seconds to lean before the crate moves.
- `Object.Pushable::PushSpeed()` — Speed at which the crate moves, pixels per second. Better lower than the running speed — pushing is hard.
- `Object.Pushable::PushedDistance()` — How many pixels the crate moved while being pushed
- `Object.Pushable::PusherObject()` — Who can push — the name of a sheet object, e.g. Player. Empty — any character.
- `Object.Pushable::SlideFriction()` — Sliding — how fast the crate stops when released. 0 — at once.
- `Object.Pushable::TopDown()` — Top-down: no gravity, pushed in every direction.

### Rotate — Rotation

Rotation with acceleration, swinging back and forth, snapping to a step and turning to a target.

**Conditions**

- **“Rotation acceleration” of ‹Object› (Rotation) ‹Sign› ‹Value›** — `Rotate::is_acceleration`
  Setting of the “Rotation” behavior, section “Rotation”. Rotation acceleration, degrees per second per second.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Rotation speed” of ‹Object› (Rotation) ‹Sign› ‹Value›** — `Rotate::is_degrees_per_second`
  Setting of the “Rotation” behavior, section “Rotation”. Rotation speed, degrees per second.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **‹Object› is rotating** — `Rotate::is_running`
  From the “Rotation” behavior.
  Parameters: Object (object)

- **“Snapping to a step” of ‹Object› (Rotation) ‹Sign› ‹Value›** — `Rotate::is_snap_step`
  Setting of the “Rotation” behavior, section “Snapping”. Snapping to a step — round the angle to a step in degrees. 0 — no snapping.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Swing back and forth instead of a full turn” of ‹Object› (Rotation) ‹Sign› ‹Value›** — `Rotate::is_swing`
  Setting of the “Rotation” behavior, section “Swing”. Swing back and forth instead of a full turn.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Swing amplitude” of ‹Object› (Rotation) ‹Sign› ‹Value›** — `Rotate::is_swing_degrees`
  Setting of the “Rotation” behavior, section “Swing”. Swing amplitude, in degrees.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **‹Object› is turning to the target** — `Rotate::is_turning`
  From the “Rotation” behavior.
  Parameters: Object (object)

**Actions**

- **Reverse the rotation of ‹Object›** — `Rotate::reverse`
  From the “Rotation” behavior.
  Parameters: Object (object)

- **Change “Rotation acceleration” of ‹Object› (Rotation): ‹Sign› ‹Value›** — `Rotate::set_acceleration`
  Setting of the “Rotation” behavior, section “Rotation”. Rotation acceleration, degrees per second per second.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Rotation speed” of ‹Object› (Rotation): ‹Sign› ‹Value›** — `Rotate::set_degrees_per_second`
  Setting of the “Rotation” behavior, section “Rotation”. Rotation speed, degrees per second.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Set the rotation speed of ‹Object›: ‹Degrees per second› degrees per second** — `Rotate::set_rotation_speed`
  From the “Rotation” behavior.
  Parameters: Object (object), Degrees per second (number)

- **Change “Rotation is on” of ‹Object› (Rotation): ‹Sign› ‹Value›** — `Rotate::set_running`
  Setting of the “Rotation” behavior, section “Rotation”. Rotation is on.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Snapping to a step” of ‹Object› (Rotation): ‹Sign› ‹Value›** — `Rotate::set_snap_step`
  Setting of the “Rotation” behavior, section “Snapping”. Snapping to a step — round the angle to a step in degrees. 0 — no snapping.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Swing back and forth instead of a full turn” of ‹Object› (Rotation): ‹Sign› ‹Value›** — `Rotate::set_swing`
  Setting of the “Rotation” behavior, section “Swing”. Swing back and forth instead of a full turn.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Swing amplitude” of ‹Object› (Rotation): ‹Sign› ‹Value›** — `Rotate::set_swing_degrees`
  Setting of the “Rotation” behavior, section “Swing”. Swing amplitude, in degrees.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Turn ‹Object› to angle ‹Angle, degrees› at ‹Degrees per second› degrees per second** — `Rotate::turn_to`
  From the “Rotation” behavior.
  Parameters: Object (object), Angle, degrees (number), Degrees per second (number)

**Expressions**

- `Object.Rotate::Acceleration()` — Rotation acceleration, degrees per second per second.
- `Object.Rotate::CurrentSpeed()` — Current rotation speed
- `Object.Rotate::DegreesPerSecond()` — Rotation speed, degrees per second.
- `Object.Rotate::Running()` — Rotation is on.
- `Object.Rotate::SnapStep()` — Snapping to a step — round the angle to a step in degrees. 0 — no snapping.
- `Object.Rotate::Swing()` — Swing back and forth instead of a full turn.
- `Object.Rotate::SwingDegrees()` — Swing amplitude, in degrees.

### Shoot — Shoot

Shooting with spread, pellets, bursts, a magazine and reloading. If a bullet has no movement of its own, it gives it one.

**Conditions**

- **‹Object› can shoot** — `Shoot::can_fire`
  From the “Shoot” behavior.
  Parameters: Object (object)

- **“Shoot where the sprite faces” of ‹Object› (Shoot) ‹Sign› ‹Value›** — `Shoot::is_aim_by_flip`
  Setting of the “Shoot” behavior, section “Direction”. Shoot where the sprite faces. In a platformer the character does not rotate but flips — without this “Shoot” would always fire to the right.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Shooting without events” of ‹Object› (Shoot) ‹Sign› ‹Value›** — `Shoot::is_auto_fire`
  Setting of the “Shoot” behavior, section “Controls”. Shooting without events — the object fires by itself.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Auto movement” of ‹Object› (Shoot) ‹Sign› ‹Value›** — `Shoot::is_auto_move`
  Setting of the “Shoot” behavior, section “Projectile”. Auto movement — give the projectile movement if it has no “Linear movement” behavior.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Auto reload” of ‹Object› (Shoot) ‹Sign› ‹Value›** — `Shoot::is_auto_reload`
  Setting of the “Shoot” behavior, section “Ammo”. Auto reload — as soon as the magazine is empty.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Projectile lifetime” of ‹Object› (Shoot) ‹Sign› ‹Value›** — `Shoot::is_bullet_lifetime`
  Setting of the “Shoot” behavior, section “Projectile”. Projectile lifetime, seconds.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Projectile speed” of ‹Object› (Shoot) ‹Sign› ‹Value›** — `Shoot::is_bullet_speed`
  Setting of the “Shoot” behavior, section “Projectile”. Projectile speed, pixels per second.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Burst” of ‹Object› (Shoot) ‹Sign› ‹Value›** — `Shoot::is_burst_count`
  Setting of the “Shoot” behavior, section “Firing”. Burst — shots per press.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Pause between burst shots” of ‹Object› (Shoot) ‹Sign› ‹Value›** — `Shoot::is_burst_delay`
  Setting of the “Shoot” behavior, section “Firing”. Pause between burst shots, seconds.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Firing direction” of ‹Object› (Shoot) ‹Sign› ‹Value›** — `Shoot::is_direction_deg`
  Setting of the “Shoot” behavior, section “Direction”. Firing direction — angle relative to the object's rotation, in degrees.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **‹Object› is out of ammo** — `Shoot::is_empty`
  From the “Shoot” behavior.
  Parameters: Object (object)

- **“Fire rate” of ‹Object› (Shoot) ‹Sign› ‹Value›** — `Shoot::is_fire_rate`
  Setting of the “Shoot” behavior, section “Firing”. Fire rate — seconds between shots.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Add the shooter's velocity to the projectile” of ‹Object› (Shoot) ‹Sign› ‹Value›** — `Shoot::is_inherit_velocity`
  Setting of the “Shoot” behavior, section “Projectile”. Add the shooter's velocity to the projectile.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Rounds in the magazine” of ‹Object› (Shoot) ‹Sign› ‹Value›** — `Shoot::is_magazine`
  Setting of the “Shoot” behavior, section “Ammo”. Rounds in the magazine. 0 — no reloading.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Muzzle forward” of ‹Object› (Shoot) ‹Sign› ‹Value›** — `Shoot::is_offset_forward`
  Setting of the “Shoot” behavior, section “Direction”. Muzzle forward — offset of the shot point from the center.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Muzzle side” of ‹Object› (Shoot) ‹Sign› ‹Value›** — `Shoot::is_offset_side`
  Setting of the “Shoot” behavior, section “Direction”. Muzzle side — sideways offset of the shot point.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Pellets” of ‹Object› (Shoot) ‹Sign› ‹Value›** — `Shoot::is_pellets`
  Setting of the “Shoot” behavior, section “Firing”. Pellets — how many projectiles per shot.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Recoil” of ‹Object› (Shoot) ‹Sign› ‹Value›** — `Shoot::is_recoil`
  Setting of the “Shoot” behavior, section “Recoil”. Recoil — pushes the shooter back on a shot.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Reload time” of ‹Object› (Shoot) ‹Sign› ‹Value›** — `Shoot::is_reload_time`
  Setting of the “Shoot” behavior, section “Ammo”. Reload time, seconds.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **‹Object› is reloading** — `Shoot::is_reloading`
  From the “Shoot” behavior.
  Parameters: Object (object)

- **“Shot sound” of ‹Object› (Shoot) ‹Sign› ‹Value›** — `Shoot::is_shot_sound`
  Setting of the “Shoot” behavior, section “Sound”. Shot sound — a path to the file.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (text)

- **“Shot volume” of ‹Object› (Shoot) ‹Sign› ‹Value›** — `Shoot::is_shot_volume_db`
  Setting of the “Shoot” behavior, section “Sound”. Shot volume, in decibels. 0 — as in the file.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Spread” of ‹Object› (Shoot) ‹Sign› ‹Value›** — `Shoot::is_spread`
  Setting of the “Shoot” behavior, section “Firing”. Spread, in degrees.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **‹Object› has just fired** — `Shoot::just_fired`
  From the “Shoot” behavior.
  Parameters: Object (object)

**Actions**

- **Add ammo to ‹Object›: ‹Rounds›** — `Shoot::add_ammo`
  From the “Shoot” behavior.
  Parameters: Object (object), Rounds (number)

- **Shoot from ‹Object›** — `Shoot::fire`
  From the “Shoot” behavior.
  Parameters: Object (object)

- **Shoot from ‹Object› at an angle of ‹Angle, degrees› degrees** — `Shoot::fire_at_angle`
  From the “Shoot” behavior.
  Parameters: Object (object), Angle, degrees (number)

- **Shoot from ‹Object› at the nearest object ‹Object name›** — `Shoot::fire_at_object`
  From the “Shoot” behavior.
  Parameters: Object (object), Object name (text)

- **Shoot from ‹Object› where it faces, shifted by ‹Shift, degrees› degrees** — `Shoot::fire_forward`
  From the “Shoot” behavior.
  Parameters: Object (object), Shift, degrees (number)

- **Change “Shoot where the sprite faces” of ‹Object› (Shoot): ‹Sign› ‹Value›** — `Shoot::set_aim_by_flip`
  Setting of the “Shoot” behavior, section “Direction”. Shoot where the sprite faces. In a platformer the character does not rotate but flips — without this “Shoot” would always fire to the right.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Shooting without events” of ‹Object› (Shoot): ‹Sign› ‹Value›** — `Shoot::set_auto_fire`
  Setting of the “Shoot” behavior, section “Controls”. Shooting without events — the object fires by itself.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Auto movement” of ‹Object› (Shoot): ‹Sign› ‹Value›** — `Shoot::set_auto_move`
  Setting of the “Shoot” behavior, section “Projectile”. Auto movement — give the projectile movement if it has no “Linear movement” behavior.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Auto reload” of ‹Object› (Shoot): ‹Sign› ‹Value›** — `Shoot::set_auto_reload`
  Setting of the “Shoot” behavior, section “Ammo”. Auto reload — as soon as the magazine is empty.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Projectile lifetime” of ‹Object› (Shoot): ‹Sign› ‹Value›** — `Shoot::set_bullet_lifetime`
  Setting of the “Shoot” behavior, section “Projectile”. Projectile lifetime, seconds.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Projectile speed” of ‹Object› (Shoot): ‹Sign› ‹Value›** — `Shoot::set_bullet_speed`
  Setting of the “Shoot” behavior, section “Projectile”. Projectile speed, pixels per second.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Burst” of ‹Object› (Shoot): ‹Sign› ‹Value›** — `Shoot::set_burst_count`
  Setting of the “Shoot” behavior, section “Firing”. Burst — shots per press.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Pause between burst shots” of ‹Object› (Shoot): ‹Sign› ‹Value›** — `Shoot::set_burst_delay`
  Setting of the “Shoot” behavior, section “Firing”. Pause between burst shots, seconds.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Firing direction” of ‹Object› (Shoot): ‹Sign› ‹Value›** — `Shoot::set_direction_deg`
  Setting of the “Shoot” behavior, section “Direction”. Firing direction — angle relative to the object's rotation, in degrees.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Fire rate” of ‹Object› (Shoot): ‹Sign› ‹Value›** — `Shoot::set_fire_rate`
  Setting of the “Shoot” behavior, section “Firing”. Fire rate — seconds between shots.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Add the shooter's velocity to the projectile” of ‹Object› (Shoot): ‹Sign› ‹Value›** — `Shoot::set_inherit_velocity`
  Setting of the “Shoot” behavior, section “Projectile”. Add the shooter's velocity to the projectile.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Rounds in the magazine” of ‹Object› (Shoot): ‹Sign› ‹Value›** — `Shoot::set_magazine`
  Setting of the “Shoot” behavior, section “Ammo”. Rounds in the magazine. 0 — no reloading.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Muzzle forward” of ‹Object› (Shoot): ‹Sign› ‹Value›** — `Shoot::set_offset_forward`
  Setting of the “Shoot” behavior, section “Direction”. Muzzle forward — offset of the shot point from the center.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Muzzle side” of ‹Object› (Shoot): ‹Sign› ‹Value›** — `Shoot::set_offset_side`
  Setting of the “Shoot” behavior, section “Direction”. Muzzle side — sideways offset of the shot point.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Pellets” of ‹Object› (Shoot): ‹Sign› ‹Value›** — `Shoot::set_pellets`
  Setting of the “Shoot” behavior, section “Firing”. Pellets — how many projectiles per shot.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Recoil” of ‹Object› (Shoot): ‹Sign› ‹Value›** — `Shoot::set_recoil`
  Setting of the “Shoot” behavior, section “Recoil”. Recoil — pushes the shooter back on a shot.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Reload time” of ‹Object› (Shoot): ‹Sign› ‹Value›** — `Shoot::set_reload_time`
  Setting of the “Shoot” behavior, section “Ammo”. Reload time, seconds.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Shot sound” of ‹Object› (Shoot): ‹Sign› ‹Value›** — `Shoot::set_shot_sound`
  Setting of the “Shoot” behavior, section “Sound”. Shot sound — a path to the file.
  Parameters: Object (object), Sign (= + - * /), Value (text)

- **Change “Shot volume” of ‹Object› (Shoot): ‹Sign› ‹Value›** — `Shoot::set_shot_volume_db`
  Setting of the “Shoot” behavior, section “Sound”. Shot volume, in decibels. 0 — as in the file.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Spread” of ‹Object› (Shoot): ‹Sign› ‹Value›** — `Shoot::set_spread`
  Setting of the “Shoot” behavior, section “Firing”. Spread, in degrees.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Reload ‹Object›** — `Shoot::start_reload`
  From the “Shoot” behavior.
  Parameters: Object (object)

**Expressions**

- `Object.Shoot::AimAngle()` — The angle the object is firing at now
- `Object.Shoot::AimByFlip()` — Shoot where the sprite faces. In a platformer the character does not rotate but flips — without this “Shoot” would always fire to the right.
- `Object.Shoot::Ammo()` — Rounds in the magazine
- `Object.Shoot::AmmoFraction()` — Ammo share from 0 to 1
- `Object.Shoot::AutoFire()` — Shooting without events — the object fires by itself.
- `Object.Shoot::AutoMove()` — Auto movement — give the projectile movement if it has no “Linear movement” behavior.
- `Object.Shoot::AutoReload()` — Auto reload — as soon as the magazine is empty.
- `Object.Shoot::BulletLifetime()` — Projectile lifetime, seconds.
- `Object.Shoot::BulletSpeed()` — Projectile speed, pixels per second.
- `Object.Shoot::BurstCount()` — Burst — shots per press.
- `Object.Shoot::BurstDelay()` — Pause between burst shots, seconds.
- `Object.Shoot::CooldownLeft()` — Seconds until the next shot
- `Object.Shoot::DirectionDeg()` — Firing direction — angle relative to the object's rotation, in degrees.
- `Object.Shoot::FireRate()` — Fire rate — seconds between shots.
- `Object.Shoot::InheritVelocity()` — Add the shooter's velocity to the projectile.
- `Object.Shoot::Magazine()` — Rounds in the magazine. 0 — no reloading.
- `Object.Shoot::OffsetForward()` — Muzzle forward — offset of the shot point from the center.
- `Object.Shoot::OffsetSide()` — Muzzle side — sideways offset of the shot point.
- `Object.Shoot::Pellets()` — Pellets — how many projectiles per shot.
- `Object.Shoot::Recoil()` — Recoil — pushes the shooter back on a shot.
- `Object.Shoot::ReloadLeft()` — Seconds until the reload ends
- `Object.Shoot::ReloadTime()` — Reload time, seconds.
- `Object.Shoot::ShotSound()` — Shot sound — a path to the file.
- `Object.Shoot::ShotVolumeDb()` — Shot volume, in decibels. 0 — as in the file.
- `Object.Shoot::Spread()` — Spread, in degrees.

### Spawner — Spawner

A point that objects come out of by themselves: waves of enemies, a rain of coins, a fountain of sparks. With an interval and jitter, in batches, with a total limit and a limit of those alive at once.

**Conditions**

- **Everything spawned from ‹Object› has been destroyed** — `Spawner::all_dead`
  From the “Spawner” behavior.
  Parameters: Object (object)

- **“Alive limit” of ‹Object› (Spawner) ‹Sign› ‹Value›** — `Spawner::is_alive_limit`
  Setting of the “Spawner” behavior, section “How many”. Alive limit — there will never be more than this many at once. 0 — no limit.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **‹Object› has spawned everything it was told to** — `Spawner::is_finished`
  From the “Spawner” behavior.
  Parameters: Object (object)

- **“First delay” of ‹Object› (Spawner) ‹Sign› ‹Value›** — `Spawner::is_first_delay`
  Setting of the “Spawner” behavior, section “When”. First delay — how many seconds to wait after the start.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Interval between spawns” of ‹Object› (Spawner) ‹Sign› ‹Value›** — `Spawner::is_interval`
  Setting of the “Spawner” behavior, section “When”. Interval between spawns, seconds.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Interval jitter” of ‹Object› (Spawner) ‹Sign› ‹Value›** — `Spawner::is_interval_jitter`
  Setting of the “Spawner” behavior, section “When”. Interval jitter, seconds: ± this much to every wait, so the rhythm is not mechanical.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“X offset from the spawn point” of ‹Object› (Spawner) ‹Sign› ‹Value›** — `Spawner::is_offset_x`
  Setting of the “Spawner” behavior, section “Where”. X offset from the spawn point.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Y offset from the spawn point” of ‹Object› (Spawner) ‹Sign› ‹Value›** — `Spawner::is_offset_y`
  Setting of the “Spawner” behavior, section “Where”. Y offset from the spawn point.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Batch” of ‹Object› (Spawner) ‹Sign› ‹Value›** — `Spawner::is_per_spawn`
  Setting of the “Spawner” behavior, section “How many”. Batch — how many objects per spawn.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Position spread” of ‹Object› (Spawner) ‹Sign› ‹Value›** — `Spawner::is_radius`
  Setting of the “Spawner” behavior, section “Where”. Position spread, in pixels: the object appears at a random point of a circle.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Spawning is on” of ‹Object› (Spawner) ‹Sign› ‹Value›** — `Spawner::is_running`
  Setting of the “Spawner” behavior, section “What to spawn”. Spawning is on.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Object” of ‹Object› (Spawner) ‹Sign› ‹Value›** — `Spawner::is_target_object`
  Setting of the “Spawner” behavior, section “What to spawn”. Object — a name from the event sheet, e.g. Enemy.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (text)

- **“Total limit” of ‹Object› (Spawner) ‹Sign› ‹Value›** — `Spawner::is_total_limit`
  Setting of the “Spawner” behavior, section “How many”. Total limit — how many to spawn over all time. 0 — endless.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **‹Object› has just spawned an object** — `Spawner::just_spawned`
  From the “Spawner” behavior.
  Parameters: Object (object)

**Actions**

- **Restart spawning at ‹Object› (count from zero)** — `Spawner::restart`
  From the “Spawner” behavior.
  Parameters: Object (object)

- **Change “Alive limit” of ‹Object› (Spawner): ‹Sign› ‹Value›** — `Spawner::set_alive_limit`
  Setting of the “Spawner” behavior, section “How many”. Alive limit — there will never be more than this many at once. 0 — no limit.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “First delay” of ‹Object› (Spawner): ‹Sign› ‹Value›** — `Spawner::set_first_delay`
  Setting of the “Spawner” behavior, section “When”. First delay — how many seconds to wait after the start.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Interval between spawns” of ‹Object› (Spawner): ‹Sign› ‹Value›** — `Spawner::set_interval`
  Setting of the “Spawner” behavior, section “When”. Interval between spawns, seconds.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Interval jitter” of ‹Object› (Spawner): ‹Sign› ‹Value›** — `Spawner::set_interval_jitter`
  Setting of the “Spawner” behavior, section “When”. Interval jitter, seconds: ± this much to every wait, so the rhythm is not mechanical.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Spawn object ‹Object name› from ‹Object›** — `Spawner::set_object`
  From the “Spawner” behavior.
  Parameters: Object (object), Object name (text)

- **Change “X offset from the spawn point” of ‹Object› (Spawner): ‹Sign› ‹Value›** — `Spawner::set_offset_x`
  Setting of the “Spawner” behavior, section “Where”. X offset from the spawn point.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Y offset from the spawn point” of ‹Object› (Spawner): ‹Sign› ‹Value›** — `Spawner::set_offset_y`
  Setting of the “Spawner” behavior, section “Where”. Y offset from the spawn point.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Batch” of ‹Object› (Spawner): ‹Sign› ‹Value›** — `Spawner::set_per_spawn`
  Setting of the “Spawner” behavior, section “How many”. Batch — how many objects per spawn.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Position spread” of ‹Object› (Spawner): ‹Sign› ‹Value›** — `Spawner::set_radius`
  Setting of the “Spawner” behavior, section “Where”. Position spread, in pixels: the object appears at a random point of a circle.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Spawning is on” of ‹Object› (Spawner): ‹Sign› ‹Value›** — `Spawner::set_running`
  Setting of the “Spawner” behavior, section “What to spawn”. Spawning is on.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Object” of ‹Object› (Spawner): ‹Sign› ‹Value›** — `Spawner::set_target_object`
  Setting of the “Spawner” behavior, section “What to spawn”. Object — a name from the event sheet, e.g. Enemy.
  Parameters: Object (object), Sign (= + - * /), Value (text)

- **Change “Total limit” of ‹Object› (Spawner): ‹Sign› ‹Value›** — `Spawner::set_total_limit`
  Setting of the “Spawner” behavior, section “How many”. Total limit — how many to spawn over all time. 0 — endless.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Spawn from ‹Object› now: ‹How many› pcs.** — `Spawner::spawn_now`
  From the “Spawner” behavior.
  Parameters: Object (object), How many (number)

- **Start spawning at ‹Object›** — `Spawner::start`
  From the “Spawner” behavior.
  Parameters: Object (object)

- **Stop spawning at ‹Object›** — `Spawner::stop`
  From the “Spawner” behavior.
  Parameters: Object (object)

**Expressions**

- `Object.Spawner::AliveCount()` — How many of the spawned are alive now
- `Object.Spawner::AliveLimit()` — Alive limit — there will never be more than this many at once. 0 — no limit.
- `Object.Spawner::FirstDelay()` — First delay — how many seconds to wait after the start.
- `Object.Spawner::Interval()` — Interval between spawns, seconds.
- `Object.Spawner::IntervalJitter()` — Interval jitter, seconds: ± this much to every wait, so the rhythm is not mechanical.
- `Object.Spawner::OffsetX()` — X offset from the spawn point.
- `Object.Spawner::OffsetY()` — Y offset from the spawn point.
- `Object.Spawner::PerSpawn()` — Batch — how many objects per spawn.
- `Object.Spawner::Radius()` — Position spread, in pixels: the object appears at a random point of a circle.
- `Object.Spawner::Running()` — Spawning is on.
- `Object.Spawner::SpawnedTotal()` — How many were spawned in total
- `Object.Spawner::TargetObject()` — Object — a name from the event sheet, e.g. Enemy.
- `Object.Spawner::TimeLeft()` — Seconds until the next spawn
- `Object.Spawner::TotalLimit()` — Total limit — how many to spawn over all time. 0 — endless.

### StateMachine — States

"Patrol / chase / attack / stunned": one current state, the time in it, "has just entered" and "has just left", a timed transition ("stunned for 2 seconds, then back"). It greatly unloads enemy sheets: events are written for each state separately.

**Conditions**

- **“Initial state” of ‹Object› (States) ‹Sign› ‹Value›** — `StateMachine::is_initial_state`
  Setting of the “States” behavior. Initial state.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (text)

- **‹Object› is in state ‹State›** — `StateMachine::is_state`
  From the “States” behavior.
  Parameters: Object (object), State (text)

- **“Play the animation named after the state” of ‹Object› (States) ‹Sign› ‹Value›** — `StateMachine::is_state_animations`
  Setting of the “States” behavior. Play the animation named after the state, if the sprite has one.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“States separated by commas” of ‹Object› (States) ‹Sign› ‹Value›** — `StateMachine::is_states`
  Setting of the “States” behavior. States separated by commas — for hints and checks. Empty — any.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (text)

- **‹Object› has just entered state ‹State›** — `StateMachine::just_entered`
  From the “States” behavior.
  Parameters: Object (object), State (text)

- **‹Object› has just left state ‹State›** — `StateMachine::just_left`
  From the “States” behavior.
  Parameters: Object (object), State (text)

- **‹Object› has been in the current state longer than ‹Seconds› seconds** — `StateMachine::longer_than`
  From the “States” behavior.
  Parameters: Object (object), Seconds (number)

**Actions**

- **Return ‹Object› to the previous state** — `StateMachine::back`
  From the “States” behavior.
  Parameters: Object (object)

- **Change “Initial state” of ‹Object› (States): ‹Sign› ‹Value›** — `StateMachine::set_initial_state`
  Setting of the “States” behavior. Initial state.
  Parameters: Object (object), Sign (= + - * /), Value (text)

- **Switch ‹Object› to state ‹State›** — `StateMachine::set_state`
  From the “States” behavior.
  Parameters: Object (object), State (text)

- **Change “Play the animation named after the state” of ‹Object› (States): ‹Sign› ‹Value›** — `StateMachine::set_state_animations`
  Setting of the “States” behavior. Play the animation named after the state, if the sprite has one.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Switch ‹Object› to state ‹State› for ‹Seconds› seconds, then to ‹Then›** — `StateMachine::set_state_for`
  Then into the state from the third field, and an empty one means back to the previous.
  Parameters: Object (object), State (text), Seconds (number), Then (text)

- **Change “States separated by commas” of ‹Object› (States): ‹Sign› ‹Value›** — `StateMachine::set_states`
  Setting of the “States” behavior. States separated by commas — for hints and checks. Empty — any.
  Parameters: Object (object), Sign (= + - * /), Value (text)

**Expressions**

- `Object.StateMachine::InitialState()` — Initial state.
- `Object.StateMachine::PreviousState()` — Previous state
- `Object.StateMachine::State()` — Current state
- `Object.StateMachine::StateAnimations()` — Play the animation named after the state, if the sprite has one.
- `Object.StateMachine::States()` — States separated by commas — for hints and checks. Empty — any.
- `Object.StateMachine::TimeInState()` — How many seconds in the current state

### StickTo — Stick to an object

Stays next to another object with an offset: a health bar above an enemy, a weapon in a hand, a name above a head. Turns together with it and can disappear together with it.

**Conditions**

- **“Disappear together with it” of ‹Object› (Stick to an object) ‹Sign› ‹Value›** — `StickTo::is_delete_with_target`
  Setting of the “Stick to an object” behavior, section “Target”. Disappear together with it.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Flip together with it” of ‹Object› (Stick to an object) ‹Sign› ‹Value›** — `StickTo::is_follow_flip`
  Setting of the “Stick to an object” behavior, section “Offset”. Flip together with it: the X offset changes sides, the sprite flips.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Rotate together with it” of ‹Object› (Stick to an object) ‹Sign› ‹Value›** — `StickTo::is_follow_rotation`
  Setting of the “Stick to an object” behavior, section “Offset”. Rotate together with it — like a weapon in a hand.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Offset along X” of ‹Object› (Stick to an object) ‹Sign› ‹Value›** — `StickTo::is_offset_x`
  Setting of the “Stick to an object” behavior, section “Offset”. Offset along X, pixels.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Offset along Y” of ‹Object› (Stick to an object) ‹Sign› ‹Value›** — `StickTo::is_offset_y`
  Setting of the “Stick to an object” behavior, section “Offset”. Offset along Y, pixels. Minus — higher.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Sticking is on” of ‹Object› (Stick to an object) ‹Sign› ‹Value›** — `StickTo::is_running`
  Setting of the “Stick to an object” behavior, section “Target”. Sticking is on.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Smoothness” of ‹Object› (Stick to an object) ‹Sign› ‹Value›** — `StickTo::is_smoothing`
  Setting of the “Stick to an object” behavior, section “Offset”. Smoothness: 0 — rigid, closer to 1 — softly catches up.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **‹Object› is stuck to an object** — `StickTo::is_stuck`
  From the “Stick to an object” behavior.
  Parameters: Object (object)

- **“Which object to stay at” of ‹Object› (Stick to an object) ‹Sign› ‹Value›** — `StickTo::is_target_object`
  Setting of the “Stick to an object” behavior, section “Target”. Which object to stay at — a name from the sheet, e.g. Enemy. The nearest one at the moment of sticking is taken.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (text)

**Actions**

- **Change “Disappear together with it” of ‹Object› (Stick to an object): ‹Sign› ‹Value›** — `StickTo::set_delete_with_target`
  Setting of the “Stick to an object” behavior, section “Target”. Disappear together with it.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Flip together with it” of ‹Object› (Stick to an object): ‹Sign› ‹Value›** — `StickTo::set_follow_flip`
  Setting of the “Stick to an object” behavior, section “Offset”. Flip together with it: the X offset changes sides, the sprite flips.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Rotate together with it” of ‹Object› (Stick to an object): ‹Sign› ‹Value›** — `StickTo::set_follow_rotation`
  Setting of the “Stick to an object” behavior, section “Offset”. Rotate together with it — like a weapon in a hand.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Sticking offset of ‹Object›: ‹X› ; ‹Y›** — `StickTo::set_offset`
  From the “Stick to an object” behavior.
  Parameters: Object (object), X (number), Y (number)

- **Change “Offset along X” of ‹Object› (Stick to an object): ‹Sign› ‹Value›** — `StickTo::set_offset_x`
  Setting of the “Stick to an object” behavior, section “Offset”. Offset along X, pixels.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Offset along Y” of ‹Object› (Stick to an object): ‹Sign› ‹Value›** — `StickTo::set_offset_y`
  Setting of the “Stick to an object” behavior, section “Offset”. Offset along Y, pixels. Minus — higher.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Sticking is on” of ‹Object› (Stick to an object): ‹Sign› ‹Value›** — `StickTo::set_running`
  Setting of the “Stick to an object” behavior, section “Target”. Sticking is on.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Smoothness” of ‹Object› (Stick to an object): ‹Sign› ‹Value›** — `StickTo::set_smoothing`
  Setting of the “Stick to an object” behavior, section “Offset”. Smoothness: 0 — rigid, closer to 1 — softly catches up.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Which object to stay at” of ‹Object› (Stick to an object): ‹Sign› ‹Value›** — `StickTo::set_target_object`
  Setting of the “Stick to an object” behavior, section “Target”. Which object to stay at — a name from the sheet, e.g. Enemy. The nearest one at the moment of sticking is taken.
  Parameters: Object (object), Sign (= + - * /), Value (text)

- **Stick ‹Object› to the nearest object ‹Object name›** — `StickTo::stick_to`
  From the “Stick to an object” behavior.
  Parameters: Object (object), Object name (text)

- **Unstick ‹Object›** — `StickTo::unstick`
  From the “Stick to an object” behavior.
  Parameters: Object (object)

**Expressions**

- `Object.StickTo::DeleteWithTarget()` — Disappear together with it.
- `Object.StickTo::FollowFlip()` — Flip together with it: the X offset changes sides, the sprite flips.
- `Object.StickTo::FollowRotation()` — Rotate together with it — like a weapon in a hand.
- `Object.StickTo::OffsetX()` — Offset along X, pixels.
- `Object.StickTo::OffsetY()` — Offset along Y, pixels. Minus — higher.
- `Object.StickTo::Running()` — Sticking is on.
- `Object.StickTo::Smoothing()` — Smoothness: 0 — rigid, closer to 1 — softly catches up.
- `Object.StickTo::TargetObject()` — Which object to stay at — a name from the sheet, e.g. Enemy. The nearest one at the moment of sticking is taken.

### TopDown — Top-down movement

Movement in 4 or 8 directions with acceleration, a dash, smooth turning and animations.

**Conditions**

- **‹Object› can dash** — `TopDown::can_dash`
  From the “Top-down movement” behavior.
  Parameters: Object (object)

- **“Acceleration” of ‹Object› (Top-down movement) ‹Sign› ‹Value›** — `TopDown::is_acceleration`
  Setting of the “Top-down movement” behavior, section “Movement”. Acceleration — how fast the speed builds up.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Automatic animations by state” of ‹Object› (Top-down movement) ‹Sign› ‹Value›** — `TopDown::is_animate`
  Setting of the “Top-down movement” behavior, section “Turning and look”. Automatic animations by state.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Dash cooldown” of ‹Object› (Top-down movement) ‹Sign› ‹Value›** — `TopDown::is_dash_cooldown`
  Setting of the “Top-down movement” behavior, section “Dash”. Dash cooldown — how many seconds until the next one.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Dash allowed” of ‹Object› (Top-down movement) ‹Sign› ‹Value›** — `TopDown::is_dash_enabled`
  Setting of the “Top-down movement” behavior, section “Dash”. Dash allowed — a short fast lunge forward.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Dash on Shift without events” of ‹Object› (Top-down movement) ‹Sign› ‹Value›** — `TopDown::is_dash_on_shift`
  Setting of the “Top-down movement” behavior, section “Dash”. Dash on Shift without events.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Speed during a dash” of ‹Object› (Top-down movement) ‹Sign› ‹Value›** — `TopDown::is_dash_speed`
  Setting of the “Top-down movement” behavior, section “Dash”. Speed during a dash.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Dash duration” of ‹Object› (Top-down movement) ‹Sign› ‹Value›** — `TopDown::is_dash_time`
  Setting of the “Top-down movement” behavior, section “Dash”. Dash duration, seconds.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **‹Object› is dashing** — `TopDown::is_dashing`
  From the “Top-down movement” behavior.
  Parameters: Object (object)

- **“Deceleration” of ‹Object› (Top-down movement) ‹Sign› ‹Value›** — `TopDown::is_deceleration`
  Setting of the “Top-down movement” behavior, section “Movement”. Deceleration — how fast the speed dies down without input.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Arrow keys controls” of ‹Object› (Top-down movement) ‹Sign› ‹Value›** — `TopDown::is_default_controls`
  Setting of the “Top-down movement” behavior, section “Controls”. Arrow keys controls, automatic.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Number of directions” of ‹Object› (Top-down movement) ‹Sign› ‹Value›** — `TopDown::is_directions`
  Setting of the “Top-down movement” behavior, section “Movement”. Number of directions: 4 — a cross, 8 — with diagonals, 0 — free.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Flip the sprite” of ‹Object› (Top-down movement) ‹Sign› ‹Value›** — `TopDown::is_flip_sprite`
  Setting of the “Top-down movement” behavior, section “Turning and look”. Flip the sprite — toward the movement direction.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Idle animation” of ‹Object› (Top-down movement) ‹Sign› ‹Value›** — `TopDown::is_idle_animation`
  Setting of the “Top-down movement” behavior, section “Turning and look”. Idle animation — a name from AnimatedSprite2D.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (text)

- **“Maximum speed” of ‹Object› (Top-down movement) ‹Sign› ‹Value›** — `TopDown::is_max_speed`
  Setting of the “Top-down movement” behavior, section “Movement”. Maximum speed, pixels per second.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **‹Object› is moving** — `TopDown::is_moving`
  From the “Top-down movement” behavior.
  Parameters: Object (object)

- **“Rotate the object toward the movement” of ‹Object› (Top-down movement) ‹Sign› ‹Value›** — `TopDown::is_rotate_object`
  Setting of the “Top-down movement” behavior, section “Turning and look”. Rotate the object toward the movement.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Turn speed” of ‹Object› (Top-down movement) ‹Sign› ‹Value›** — `TopDown::is_rotation_speed`
  Setting of the “Top-down movement” behavior, section “Turning and look”. Turn speed, degrees per second.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Run animation” of ‹Object› (Top-down movement) ‹Sign› ‹Value›** — `TopDown::is_run_animation`
  Setting of the “Top-down movement” behavior, section “Turning and look”. Run animation — a name from AnimatedSprite2D.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (text)

**Actions**

- **Dash ‹Object› toward the movement** — `TopDown::dash`
  From the “Top-down movement” behavior.
  Parameters: Object (object)

- **Dash ‹Object› at an angle of ‹Angle, degrees› degrees** — `TopDown::dash_at_angle`
  From the “Top-down movement” behavior.
  Parameters: Object (object), Angle, degrees (number)

- **Push ‹Object› at angle ‹Angle, degrees› with force ‹Force›** — `TopDown::push`
  From the “Top-down movement” behavior.
  Parameters: Object (object), Angle, degrees (number), Force (number)

- **Change “Acceleration” of ‹Object› (Top-down movement): ‹Sign› ‹Value›** — `TopDown::set_acceleration`
  Setting of the “Top-down movement” behavior, section “Movement”. Acceleration — how fast the speed builds up.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Automatic animations by state” of ‹Object› (Top-down movement): ‹Sign› ‹Value›** — `TopDown::set_animate`
  Setting of the “Top-down movement” behavior, section “Turning and look”. Automatic animations by state.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Dash cooldown” of ‹Object› (Top-down movement): ‹Sign› ‹Value›** — `TopDown::set_dash_cooldown`
  Setting of the “Top-down movement” behavior, section “Dash”. Dash cooldown — how many seconds until the next one.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Dash allowed” of ‹Object› (Top-down movement): ‹Sign› ‹Value›** — `TopDown::set_dash_enabled`
  Setting of the “Top-down movement” behavior, section “Dash”. Dash allowed — a short fast lunge forward.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Dash on Shift without events” of ‹Object› (Top-down movement): ‹Sign› ‹Value›** — `TopDown::set_dash_on_shift`
  Setting of the “Top-down movement” behavior, section “Dash”. Dash on Shift without events.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Speed during a dash” of ‹Object› (Top-down movement): ‹Sign› ‹Value›** — `TopDown::set_dash_speed`
  Setting of the “Top-down movement” behavior, section “Dash”. Speed during a dash.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Dash duration” of ‹Object› (Top-down movement): ‹Sign› ‹Value›** — `TopDown::set_dash_time`
  Setting of the “Top-down movement” behavior, section “Dash”. Dash duration, seconds.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Deceleration” of ‹Object› (Top-down movement): ‹Sign› ‹Value›** — `TopDown::set_deceleration`
  Setting of the “Top-down movement” behavior, section “Movement”. Deceleration — how fast the speed dies down without input.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Arrow keys controls” of ‹Object› (Top-down movement): ‹Sign› ‹Value›** — `TopDown::set_default_controls`
  Setting of the “Top-down movement” behavior, section “Controls”. Arrow keys controls, automatic.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Number of directions” of ‹Object› (Top-down movement): ‹Sign› ‹Value›** — `TopDown::set_directions`
  Setting of the “Top-down movement” behavior, section “Movement”. Number of directions: 4 — a cross, 8 — with diagonals, 0 — free.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Flip the sprite” of ‹Object› (Top-down movement): ‹Sign› ‹Value›** — `TopDown::set_flip_sprite`
  Setting of the “Top-down movement” behavior, section “Turning and look”. Flip the sprite — toward the movement direction.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Idle animation” of ‹Object› (Top-down movement): ‹Sign› ‹Value›** — `TopDown::set_idle_animation`
  Setting of the “Top-down movement” behavior, section “Turning and look”. Idle animation — a name from AnimatedSprite2D.
  Parameters: Object (object), Sign (= + - * /), Value (text)

- **Change “Maximum speed” of ‹Object› (Top-down movement): ‹Sign› ‹Value›** — `TopDown::set_max_speed`
  Setting of the “Top-down movement” behavior, section “Movement”. Maximum speed, pixels per second.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Rotate the object toward the movement” of ‹Object› (Top-down movement): ‹Sign› ‹Value›** — `TopDown::set_rotate_object`
  Setting of the “Top-down movement” behavior, section “Turning and look”. Rotate the object toward the movement.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Turn speed” of ‹Object› (Top-down movement): ‹Sign› ‹Value›** — `TopDown::set_rotation_speed`
  Setting of the “Top-down movement” behavior, section “Turning and look”. Turn speed, degrees per second.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Run animation” of ‹Object› (Top-down movement): ‹Sign› ‹Value›** — `TopDown::set_run_animation`
  Setting of the “Top-down movement” behavior, section “Turning and look”. Run animation — a name from AnimatedSprite2D.
  Parameters: Object (object), Sign (= + - * /), Value (text)

- **Move: ‹Object› by X ‹By X›, by Y ‹By Y›** — `TopDown::simulate_move`
  From the “Top-down movement” behavior.
  Parameters: Object (object), By X (number), By Y (number)

- **Stop ‹Object›** — `TopDown::stop`
  From the “Top-down movement” behavior.
  Parameters: Object (object)

**Expressions**

- `Object.TopDown::Acceleration()` — Acceleration — how fast the speed builds up.
- `Object.TopDown::Animate()` — Automatic animations by state.
- `Object.TopDown::CurrentSpeed()` — Current speed
- `Object.TopDown::DashCooldown()` — Dash cooldown — how many seconds until the next one.
- `Object.TopDown::DashCooldownLeft()` — Seconds until the next dash
- `Object.TopDown::DashEnabled()` — Dash allowed — a short fast lunge forward.
- `Object.TopDown::DashOnShift()` — Dash on Shift without events.
- `Object.TopDown::DashSpeed()` — Speed during a dash.
- `Object.TopDown::DashTime()` — Dash duration, seconds.
- `Object.TopDown::Deceleration()` — Deceleration — how fast the speed dies down without input.
- `Object.TopDown::DefaultControls()` — Arrow keys controls, automatic.
- `Object.TopDown::Directions()` — Number of directions: 4 — a cross, 8 — with diagonals, 0 — free.
- `Object.TopDown::FlipSprite()` — Flip the sprite — toward the movement direction.
- `Object.TopDown::IdleAnimation()` — Idle animation — a name from AnimatedSprite2D.
- `Object.TopDown::MaxSpeed()` — Maximum speed, pixels per second.
- `Object.TopDown::MoveAngle()` — Movement angle in degrees
- `Object.TopDown::RotateObject()` — Rotate the object toward the movement.
- `Object.TopDown::RotationSpeed()` — Turn speed, degrees per second.
- `Object.TopDown::RunAnimation()` — Run animation — a name from AnimatedSprite2D.

### ValueBar — Value bar

A bar of health or of any variable. It draws itself, no pictures needed. It shrinks smoothly, with a "catching up" trail behind it, as in fighting games. It can hang above an object or stay on the screen.

**Conditions**

- **The bar ‹Object› is still shrinking** — `ValueBar::is_draining`
  From the “Value bar” behavior.
  Parameters: Object (object)

- **“Bar speed” of ‹Object› (Value bar) ‹Sign› ‹Value›** — `ValueBar::is_fill_speed`
  Setting of the “Value bar” behavior, section “Motion”. Bar speed — share per second. 0 — at once.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Height” of ‹Object› (Value bar) ‹Sign› ‹Value›** — `ValueBar::is_height`
  Setting of the “Value bar” behavior, section “Place”. Height, pixels.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Hide when full” of ‹Object› (Value bar) ‹Sign› ‹Value›** — `ValueBar::is_hide_when_full`
  Setting of the “Value bar” behavior, section “Look”. Hide when full.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Low” of ‹Object› (Value bar) ‹Sign› ‹Value›** — `ValueBar::is_low_share`
  Setting of the “Value bar” behavior, section “Look”. Low — below this share, from 0 to 1.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Maximum for a variable” of ‹Object› (Value bar) ‹Sign› ‹Value›** — `ValueBar::is_max_value`
  Setting of the “Value bar” behavior, section “Value”. Maximum for a variable — a full bar.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“X offset” of ‹Object› (Value bar) ‹Sign› ‹Value›** — `ValueBar::is_offset_x`
  Setting of the “Value bar” behavior, section “Place”. X offset — from the object or, on screen, from the left edge, pixels.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Y offset” of ‹Object› (Value bar) ‹Sign› ‹Value›** — `ValueBar::is_offset_y`
  Setting of the “Value bar” behavior, section “Place”. Y offset — from the object (minus — higher) or, on screen, from the top edge.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“On screen” of ‹Object› (Value bar) ‹Sign› ‹Value›** — `ValueBar::is_on_screen`
  Setting of the “Value bar” behavior, section “Place”. On screen: the bar stays in a corner instead of hanging above the object.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“What to show” of ‹Object› (Value bar) ‹Sign› ‹Value›** — `ValueBar::is_source`
  Setting of the “Value bar” behavior, section “Value”. What to show: the "Health" of this object, the "Health" of another object, a scene variable or a global one.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Whose health” of ‹Object› (Value bar) ‹Sign› ‹Value›** — `ValueBar::is_source_object`
  Setting of the “Value bar” behavior, section “Value”. Whose health — the name of a sheet object, e.g. Player.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (text)

- **“Trail delay” of ‹Object› (Value bar) ‹Sign› ‹Value›** — `ValueBar::is_trail_delay`
  Setting of the “Value bar” behavior, section “Motion”. Trail delay — how many seconds it stays before catching up.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Trail speed” of ‹Object› (Value bar) ‹Sign› ‹Value›** — `ValueBar::is_trail_speed`
  Setting of the “Value bar” behavior, section “Motion”. Trail speed — share per second.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

- **“Variable name” of ‹Object› (Value bar) ‹Sign› ‹Value›** — `ValueBar::is_variable`
  Setting of the “Value bar” behavior, section “Value”. Variable name, e.g. hp.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (text)

- **“Width” of ‹Object› (Value bar) ‹Sign› ‹Value›** — `ValueBar::is_width`
  Setting of the “Value bar” behavior, section “Place”. Width, pixels.
  Parameters: Object (object), Sign (= ≠ < > ≤ ≥), Value (number)

**Actions**

- **Bar color of ‹Object›: R ‹R›, G ‹G›, B ‹B› (0…1)** — `ValueBar::set_color`
  From the “Value bar” behavior.
  Parameters: Object (object), R (number), G (number), B (number)

- **Change “Bar speed” of ‹Object› (Value bar): ‹Sign› ‹Value›** — `ValueBar::set_fill_speed`
  Setting of the “Value bar” behavior, section “Motion”. Bar speed — share per second. 0 — at once.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Height” of ‹Object› (Value bar): ‹Sign› ‹Value›** — `ValueBar::set_height`
  Setting of the “Value bar” behavior, section “Place”. Height, pixels.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Hide when full” of ‹Object› (Value bar): ‹Sign› ‹Value›** — `ValueBar::set_hide_when_full`
  Setting of the “Value bar” behavior, section “Look”. Hide when full.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Low” of ‹Object› (Value bar): ‹Sign› ‹Value›** — `ValueBar::set_low_share`
  Setting of the “Value bar” behavior, section “Look”. Low — below this share, from 0 to 1.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Maximum for a variable” of ‹Object› (Value bar): ‹Sign› ‹Value›** — `ValueBar::set_max_value`
  Setting of the “Value bar” behavior, section “Value”. Maximum for a variable — a full bar.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “X offset” of ‹Object› (Value bar): ‹Sign› ‹Value›** — `ValueBar::set_offset_x`
  Setting of the “Value bar” behavior, section “Place”. X offset — from the object or, on screen, from the left edge, pixels.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Y offset” of ‹Object› (Value bar): ‹Sign› ‹Value›** — `ValueBar::set_offset_y`
  Setting of the “Value bar” behavior, section “Place”. Y offset — from the object (minus — higher) or, on screen, from the top edge.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “On screen” of ‹Object› (Value bar): ‹Sign› ‹Value›** — `ValueBar::set_on_screen`
  Setting of the “Value bar” behavior, section “Place”. On screen: the bar stays in a corner instead of hanging above the object.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “What to show” of ‹Object› (Value bar): ‹Sign› ‹Value›** — `ValueBar::set_source`
  Setting of the “Value bar” behavior, section “Value”. What to show: the "Health" of this object, the "Health" of another object, a scene variable or a global one.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Whose health” of ‹Object› (Value bar): ‹Sign› ‹Value›** — `ValueBar::set_source_object`
  Setting of the “Value bar” behavior, section “Value”. Whose health — the name of a sheet object, e.g. Player.
  Parameters: Object (object), Sign (= + - * /), Value (text)

- **Change “Trail delay” of ‹Object› (Value bar): ‹Sign› ‹Value›** — `ValueBar::set_trail_delay`
  Setting of the “Value bar” behavior, section “Motion”. Trail delay — how many seconds it stays before catching up.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Trail speed” of ‹Object› (Value bar): ‹Sign› ‹Value›** — `ValueBar::set_trail_speed`
  Setting of the “Value bar” behavior, section “Motion”. Trail speed — share per second.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Change “Variable name” of ‹Object› (Value bar): ‹Sign› ‹Value›** — `ValueBar::set_variable`
  Setting of the “Value bar” behavior, section “Value”. Variable name, e.g. hp.
  Parameters: Object (object), Sign (= + - * /), Value (text)

- **Change “Width” of ‹Object› (Value bar): ‹Sign› ‹Value›** — `ValueBar::set_width`
  Setting of the “Value bar” behavior, section “Place”. Width, pixels.
  Parameters: Object (object), Sign (= + - * /), Value (number)

- **Show on the bar ‹Object› the variable ‹Variable› out of a maximum of ‹Maximum›** — `ValueBar::show_variable`
  From the “Value bar” behavior.
  Parameters: Object (object), Variable (text), Maximum (number)

- **Instantly show the exact value on the bar ‹Object›, without smoothing** — `ValueBar::snap`
  From the “Value bar” behavior.
  Parameters: Object (object)

**Expressions**

- `Object.ValueBar::FillSpeed()` — Bar speed — share per second. 0 — at once.
- `Object.ValueBar::Height()` — Height, pixels.
- `Object.ValueBar::HideWhenFull()` — Hide when full.
- `Object.ValueBar::LowShare()` — Low — below this share, from 0 to 1.
- `Object.ValueBar::MaxValue()` — Maximum for a variable — a full bar.
- `Object.ValueBar::OffsetX()` — X offset — from the object or, on screen, from the left edge, pixels.
- `Object.ValueBar::OffsetY()` — Y offset — from the object (minus — higher) or, on screen, from the top edge.
- `Object.ValueBar::OnScreen()` — On screen: the bar stays in a corner instead of hanging above the object.
- `Object.ValueBar::ShownShare()` — Shown share, from 0 to 1
- `Object.ValueBar::Source()` — What to show: the "Health" of this object, the "Health" of another object, a scene variable or a global one.
- `Object.ValueBar::SourceObject()` — Whose health — the name of a sheet object, e.g. Player.
- `Object.ValueBar::TrailDelay()` — Trail delay — how many seconds it stays before catching up.
- `Object.ValueBar::TrailShare()` — Trail share, from 0 to 1
- `Object.ValueBar::TrailSpeed()` — Trail speed — share per second.
- `Object.ValueBar::Variable()` — Variable name, e.g. hp.
- `Object.ValueBar::Width()` — Width, pixels.

