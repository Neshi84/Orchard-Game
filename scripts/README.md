# Orchard Game — Setup Guide

Six scripts, one job each. None of them know about each other except
`Game.gd`, which wires everything together with signals. This keeps each
piece testable and easy to reason about on its own — a good habit for any
Godot project as it grows.

```
Fruit.gd   -> grows, ripens, falls, rots, and can be clicked while fresh
Tree.gd    -> spawns Fruit instances at Marker2D points, relays "collected"
Barrel.gd  -> fills to 20, ferments (pulses), then can be clicked to empty
Still.gd   -> distills for a while (pulses), then spawns Bottle instances
Bottle.gd  -> just pops out with a little impulse
Game.gd    -> connects Tree -> Barrel -> Still
```

## 1. Fruit.tscn

1. Create new scene, root node **Area2D**, rename to `Fruit`.
2. Add child **Sprite2D** — assign a fruit texture.
3. Add child **CollisionShape2D** — give it a small `CircleShape2D`.
4. Attach `Fruit.gd` to the root.
5. Save as `Fruit.tscn`.

Tweak the exported values in the Inspector once it's running: `grow_time`,
`ripe_wait_min/max`, `fresh_duration`, `rotten_duration`, etc. Start with
short times (2–3 seconds) while testing so you don't sit around waiting.

## 2. Tree.tscn

1. Create new scene, root node **Node2D**, rename to `Tree`.
2. Add child **Sprite2D** — your tree art.
3. Add child **Node2D**, rename to `SpawnPoints`.
4. Under `SpawnPoints`, add 3–6 **Marker2D** nodes, and drag each one to a
   spot on the canopy in the 2D view — these are the "branches" fruit can
   grow on.
5. Attach `Tree.gd` to the root `Tree` node.
6. In the Inspector, drag your saved `Fruit.tscn` into the **Fruit Scene**
   export slot.
7. Save as `Tree.tscn`.

## 3. Barrel.tscn

1. Create new scene, root node **Area2D**, rename to `Barrel`.
2. Add child **Sprite2D** — barrel art.
3. Add child **CollisionShape2D** — a `RectangleShape2D` roughly the size
   of the sprite (this is what makes it clickable).
4. Optional: add child **Label** positioned above the barrel to show
   fill count.
5. Attach `Barrel.gd` to the root.
6. Save as `Barrel.tscn`.

## 4. Still.tscn

1. Create new scene, root node **Node2D**, rename to `Still`.
2. Add child **Sprite2D** — still art.
3. Add child **Marker2D**, rename to `BottleSpawnPoint`, position it at
   the still's spout.
4. Attach `Still.gd` to the root.
5. In the Inspector, drag your saved `Bottle.tscn` (see below) into the
   **Bottle Scene** slot.
6. Save as `Still.tscn`.

## 5. Bottle.tscn

1. Create new scene, root node **RigidBody2D**, rename to `Bottle`.
2. Add child **Sprite2D** — bottle art.
3. Add child **CollisionShape2D**.
4. Attach `Bottle.gd` to the root.
5. Save as `Bottle.tscn`.

(If physics feels like overkill for now, change the root to `Node2D`,
skip the collision shape, and delete the `apply_impulse` line in the
script — bottles will just appear at the spawn point instead of hopping.)

## 6. Main.tscn (put it all together)

1. Create new scene, root node **Node2D**, rename to `Main` (or `Game`).
2. Add three children by instancing your saved scenes:
   `Tree`, `Barrel`, `Still` — position them left-to-right so it reads
   like a little production line.
3. Attach `Game.gd` to the root.
4. Set this as your main scene: **Project → Project Settings → Application
   → Run → Main Scene**.
5. Press Play.

## Why signals instead of direct references

`Fruit` doesn't know a `Barrel` exists. It just emits `collected`. `Tree`
listens for that and re-emits `fruit_collected`. `Game.gd` is the only
place that says "when a fruit is collected, tell the barrel." If you
later want a second barrel, or want fruit to bounce off a full barrel
back onto the ground, you only ever touch `Game.gd` — none of the other
scripts need to change. This pattern (signals up, calls down) is worth
getting comfortable with early since it scales well as scenes multiply.

## Suggested next steps once this works

- Swap the color-tint rot effect for an actual second sprite frame/texture.
- Add a `Label` over the Still to show total bottles produced.
- Add sound effects on collect / ferment-start / bottle-spawn.
- Give the Barrel a rejection animation (shake) when clicked while full/fermenting.
- Turn the magic numbers (capacity, times) into an exported `GameConfig` resource
  so you can tune the economy without touching code.
