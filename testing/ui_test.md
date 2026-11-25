# Interaction UI Debug Test (`UI_TEST`)

- **Script**: [script/scene/dev/ui_test.gd](../script/scene/dev/ui_test.gd)
- **Scene Constant**: `OD.Scenes.UI_TEST` (`"dev/ui_test"`)

## Purpose
Tests `ElementDialog` and `DungeonElement` interactions in isolation: vending machines (long item names, food/drink DB pools), Anvil of Krong (selection workflow, pleased/displeased/already-used states), Lutefisk God Statue offerings, bookshelves, levers, pedestals, and statues.

## How to Run
1. Set `var FIRST_SCENE = UI_TEST` in [script/singleton/scenes.gd](../script/singleton/scenes.gd).
2. Run `./airef/godot`.

## What to Verify
1. Adjust test Zorkmids and Lutefisk counts using the top resource buttons.
2. Click each element button (**Vending**, **Krong**, **Lutefisk Statue**, **Bookshelf**, **Lever**, **Dredmor Statue**, **Pedestal**, **Statue**) to verify nine-patch layout, text wrapping, icons, tooltips, and purchase/offering/enchanting flows.
