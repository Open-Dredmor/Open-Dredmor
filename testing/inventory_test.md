# Inventory & Equipment Test (`INVENTORY_TEST`)

- **Script**: [script/scene/dev/inventory_test.gd](../script/scene/dev/inventory_test.gd)
- **Scene Constant**: `OD.Scenes.INVENTORY_TEST` (`"dev/inventory_test"`)

## Purpose
Tests the `InventoryDialog` UI and `PlayerCharacter` inventory/equipment system: slot equipping (weapons, shield, armour, 2x ring, amulet, belt, bolts, thrown), stacking, sorting, tooltips, dropping, and floor pickup.

## How to Run
1. Set `var FIRST_SCENE = INVENTORY_TEST` in [script/singleton/scenes.gd](../script/singleton/scenes.gd).
2. Run `./airef/godot` interactively, or headlessly with:
   ```bash
   HOME=/tmp ./airef/godot --headless --quit-after 8
   ```

## What to Verify
1. Confirm the automated self-check passes (and can be re-run via **Run Automated Self-Check**).
2. In the opened Inventory dialog (or via **Open Inventory (I)**), hover items to inspect tooltips, equip gear into all slots, and confirm primary/secondary stats update immediately.
3. Drop items and click **Pick Up Floor Item** to verify floor loot round-tripping.
