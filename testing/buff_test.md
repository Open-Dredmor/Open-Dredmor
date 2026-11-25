# Buffs & Status Effects Test (`BUFF_TEST`)

- **Script**: [script/scene/dev/buff_test.gd](../script/scene/dev/buff_test.gd)
- **Scene Constant**: `OD.Scenes.BUFF_TEST` (`"dev/buff_test"`)

## Purpose
Tests the `PlayerCharacter` buff/debuff/DoT engine, `SpellEngine` buff application, stat recalculation, `brittle` (stack loss on hit) and `removable` (stack loss on attack) mechanics, `on_attack_performed` / `on_hit_received` procs, and the `BuffBar` UI.

## How to Run
1. Set `var FIRST_SCENE = BUFF_TEST` in [script/singleton/scenes.gd](../script/singleton/scenes.gd).
2. Run `./airef/godot` interactively, or headlessly with:
   ```bash
   HOME=/tmp ./airef/godot --headless --quit-after 8
   ```

## What to Verify
1. On load, `_run_automated_verification()` runs automatically and logs results in the right-hand panel.
2. Click the buff buttons (**Apply Monstrous Rage**, **Apply Lobstery Toughness**, **Apply Fell Power**, **Apply Radiant Aura**, **Apply Meatshield**, **Apply On Fire**) and confirm icons appear in the top `BuffBar` with turn/stack counters.
3. Click **Simulate Player Attack**, **Simulate Hit Received**, and **Advance Turn** to verify stack consumption, proc triggers, DoT ticks, and buff expiration.
