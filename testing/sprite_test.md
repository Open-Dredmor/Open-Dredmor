# Sprite & Animation Loader Test (`SPRITE_TEST`)

- **Script**: [script/scene/dev/sprite_test.gd](../script/scene/dev/sprite_test.gd)
- **Scene Constant**: `OD.Scenes.SPRITE_TEST` (`"dev/sprite_test"`)

## Purpose
Verifies low-level retail asset loading via `OD.Load.animation` and `OD.Assets.tilesets()` for binary `.spr` (ProMotion) sprites, `.xml` sprite sheets, `.pal` palette swapping (ghost palette), and tileset animations.

## How to Run
1. Set `var FIRST_SCENE = SPRITE_TEST` in [script/singleton/scenes.gd](../script/singleton/scenes.gd).
2. Run `./airef/godot`.

## What to Verify
1. Confirm all four animated sprites render and play smoothly:
   - ProMotion `.spr` (`hero_atk_axe_d.spr`)
   - XML sprite (`hero_atk_dagger_d.xml`)
   - Tileset liquid animation (`water`)
   - Palette-swapped `.spr` (`hero_atk_axe_d.spr` with `ghost.pal`)
