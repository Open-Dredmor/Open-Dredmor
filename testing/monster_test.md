# Monster AI & Spawning Test (`MONSTER_TEST`)

- **Script**: [script/scene/dev/monster_test.gd](../script/scene/dev/monster_test.gd)
- **Scene Constant**: `OD.Scenes.MONSTER_TEST` (`"dev/monster_test"`)

## Purpose
Tests `monDB.xml` monster instantiation, `EntityGrid` monster spawning, turn-based AI movement and spellcasting, and periodic dungeon monster spawning.

## How to Run
1. Set `var FIRST_SCENE = MONSTER_TEST` in [script/singleton/scenes.gd](../script/singleton/scenes.gd).
2. Run `./airef/godot` interactively, or headlessly with:
   ```bash
   HOME=/tmp ./airef/godot --headless --quit-after 8
   ```
   Headless output should print `MONSTER_TEST_READY`.

## What to Verify
1. Confirm automated verification passes on load in the log panel.
2. Click **Spawn Diggle** and **Spawn Octo (Caster)** to instantiate monsters on the test grid.
3. Click **Step Turn (AI)** to advance `TurnScheduler` and observe monster movement/casting logs.
4. Click **Force Periodic Spawn** to test `maybe_spawn_periodic_monster`.
