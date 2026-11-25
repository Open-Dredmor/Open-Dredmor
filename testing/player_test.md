# PlayerCharacter Test (`PLAYER_TEST`)

- **Script**: [script/scene/dev/player_test.gd](../script/scene/dev/player_test.gd)
- **Scene Constant**: `OD.Scenes.PLAYER_TEST` (`"dev/player_test"`)

## Purpose
Tests `PlayerCharacter` initialization for both `hero` and `heroine`, directional idle/walk sprite animations, primary/secondary stat calculation from starting skills, XP/leveling, and `CombatResolver` melee resolution.

## How to Run
1. Set `var FIRST_SCENE = PLAYER_TEST` in [script/singleton/scenes.gd](../script/singleton/scenes.gd).
2. Run `./airef/godot`.

## What to Verify
1. Use **Down**, **Up**, **Left**, **Right** and **Toggle Move/Idle** to verify Hero and Heroine directional animations.
2. Switch between **Inspect Hero** and **Inspect Heroine** to inspect calculated stats, HP/MP, and skill trees.
3. Trigger combat/XP/damage buttons in the action grid to verify stat updates and leveling.
