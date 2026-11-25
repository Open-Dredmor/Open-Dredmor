# Loot Generation & Artifacts Test (`LOOT_TEST`)

- **Script**: [script/scene/dev/loot_test.gd](../script/scene/dev/loot_test.gd)
- **Scene Constant**: `OD.Scenes.LOOT_TEST` (`"dev/loot_test"`)

## Purpose
Tests level-filtered loot rolling from `itemDB.xml`, `component` vs. `reagent` classification, procedural artifact generation (random `text.xml` names, quality scaling, bonus stats), chest/pedestal loot (`uberchest`, `evilchest`, `pedestal`), and `MonsterEntity.roll_drops()`.

## How to Run
1. Set `var FIRST_SCENE = LOOT_TEST` in [script/singleton/scenes.gd](../script/singleton/scenes.gd).
2. Run `./airef/godot` interactively, or headlessly with:
   ```bash
   HOME=/tmp ./airef/godot --headless --quit-after 8
   ```
   Headless output should print `[LOOT_TEST] PASS`.

## What to Verify
1. Confirm the status label displays `ALL LOOT & ARTIFACT CHECKS PASSED!`.
2. Click **Roll Floor 1 Artifact** and **Roll Floor 8 Artifact** to verify random artifact names and higher quality on deeper floors.
3. Click **Open Inventory (Inspect & Equip)**, hover over artifacts to inspect `Artifact (Quality X)` tooltips and bonus stats, and equip them to confirm stats update.
