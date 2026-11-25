# Dev Test Scenes

Open Dredmor includes standalone dev scenes under [script/scene/dev/](../script/scene/dev/) for testing individual subsystems in isolation.

## How to Run a Dev Scene

1. Open [script/singleton/scenes.gd](../script/singleton/scenes.gd).
2. Set `FIRST_SCENE` to the constant for the desired dev scene (for example, `var FIRST_SCENE = CRAFTING_TEST`).
3. Launch Godot interactively from the repo root:
   ```bash
   ./airef/godot
   ```
4. For scenes with automated self-checks, you can also run headlessly:
   ```bash
   HOME=/tmp ./airef/godot --headless --quit-after 8
   ```
   (Ensure `dredmor_install_directory` is configured in Godot's user config, or run once interactively so Bootstrap saves the retail path.)

## Available Dev Screens

- [audio_test.md](audio_test.md) (`AUDIO_TEST`): Music playback, volume sliders, and `soundfx.xml` SFX cue browser.
- [buff_test.md](buff_test.md) (`BUFF_TEST`): Buffs, debuffs, brittle/removable flags, DoTs, procs, and `BuffBar`.
- [consumable_test.md](consumable_test.md) (`CONSUMABLE_TEST`): Food, booze, potions, mushrooms, and wand charges/burnout.
- [crafting_test.md](crafting_test.md) (`CRAFTING_TEST`): `craftDB.xml` recipes, toolkits, skill gating, and `CraftingDialog`.
- [database_test.md](database_test.md) (`DATABASE_TEST`): Retail XML database ingestion browser across all packs.
- [death_test.md](death_test.md) (`DEATH_TEST`): Lethal damage, permadeath save deletion, and high score recording.
- [inventory_test.md](inventory_test.md) (`INVENTORY_TEST`): Grid inventory, equipment slots, stacking, tooltips, and floor loot.
- [loot_test.md](loot_test.md) (`LOOT_TEST`): Level-filtered loot, procedural/predefined artifacts, chests, and monster drops.
- [monster_test.md](monster_test.md) (`MONSTER_TEST`): Monster spawning, AI turns, spellcasting, and periodic spawns.
- [player_test.md](player_test.md) (`PLAYER_TEST`): Hero/Heroine sprites, primary/secondary stats, XP/leveling, and combat.
- [quick_game.md](quick_game.md) (`QUICK_GAME`): Fast random character launch directly into the dungeon with debug teleport.
- [spell_test.md](spell_test.md) (`SPELL_TEST`): `spellDB.xml` targeting shapes, projectiles, beams, cones, templates, and effects.
- [sprite_test.md](sprite_test.md) (`SPRITE_TEST`): `.spr`, `.xml`, `.pal` palette swap, and tileset animation loading.
- [ui_test.md](ui_test.md) (`UI_TEST`): Dungeon element dialogs (vending machines, Anvil of Krong, Lutefisk statue, bookshelves).
