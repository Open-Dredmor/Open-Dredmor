# Quick Game Launcher (`QUICK_GAME`)

- **Script**: [script/scene/dev/quick_game.gd](../script/scene/dev/quick_game.gd)
- **Scene Constant**: `OD.Scenes.QUICK_GAME` (`"dev/quick_game"`)

## Purpose
Skips the main menu, character creation, and skill selection screens by generating a randomized hero/heroine with 7 random skills, enabling debug teleport, and launching directly into `GAME`.

## How to Run
1. Set `var FIRST_SCENE = QUICK_GAME` in [script/singleton/scenes.gd](../script/singleton/scenes.gd).
2. Run `./airef/godot`.

## What to Verify
1. Confirm the game boots straight into a generated dungeon floor with a randomized character name, sprite, and skill loadout.
2. Useful for rapid end-to-end testing of dungeon generation, HUD, combat, looting, and crafting in-game.
