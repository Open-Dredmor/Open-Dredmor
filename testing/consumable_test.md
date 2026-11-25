# Consumables & Wands Test (`CONSUMABLE_TEST`)

- **Script**: [script/scene/dev/consumable_test.gd](../script/scene/dev/consumable_test.gd)
- **Scene Constant**: `OD.Scenes.CONSUMABLE_TEST` (`"dev/consumable_test"`)

## Purpose
Tests using food (HP/turn regeneration), booze (MP/turn regeneration and Tipsy buff), potions (triggering `spellDB.xml` effects), mushrooms, and wands (casting spells, decrementing charges, wandcrafting preservation, and burnout).

## How to Run
1. Set `var FIRST_SCENE = CONSUMABLE_TEST` in [script/singleton/scenes.gd](../script/singleton/scenes.gd).
2. Run `./airef/godot` interactively, or headlessly with:
   ```bash
   HOME=/tmp ./airef/godot --headless --quit-after 8
   ```

## What to Verify
1. Confirm the automated self-check passes on load (and can be re-run via **Run Automated Self-Check**).
2. Click **Open Inventory**, right-click or use seeded items (`Steak`, `Grog`, `Potion of Healing`, `Potion of Steeling`, `Night Cap`, `Wand of Tesla`, etc.).
3. Click **Tick 1 Turn** to observe HP/MP regeneration and buff duration ticks in the `BuffBar` and summary panel.
