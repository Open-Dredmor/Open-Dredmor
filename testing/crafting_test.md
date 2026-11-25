# Crafting System Test (`CRAFTING_TEST`)

- **Script**: [script/scene/dev/crafting_test.gd](../script/scene/dev/crafting_test.gd)
- **Scene Constant**: `OD.Scenes.CRAFTING_TEST` (`"dev/crafting_test"`)

## Purpose
Tests `craftDB.xml` and `encrustDB.xml` parsing, toolkit possession detection for all 7 tools (including Anvil/`smithing` and Porta-Still/`still`), hidden vs. known recipe gating, crafting skill level requirements, ingredient consumption, output creation, equipment encrusting with instability, and the retail-styled `CraftingDialog` UI (Craft & Encrust tabs).

## How to Run
1. Set `var FIRST_SCENE = CRAFTING_TEST` in [script/singleton/scenes.gd](../script/singleton/scenes.gd).
2. Run `./airef/godot` interactively, or headlessly with:
   ```bash
   HOME=/tmp ./airef/godot --headless --quit-after 8
   ```
   Headless output should print `[CRAFTING_TEST] PASS`.

## What to Verify
1. Confirm the status label displays `ALL CRAFTING CHECKS PASSED!`.
2. Click **Open Crafting Workbench** to open the retail crafting panel (`ubercraft_bg.png`).
3. Switch between all 7 possessed tool icons on the left sidebar (`tool_travel_anvil`, `tool_alchemy_kit`, `tool_distilling_kit`, `tool_ingot_press`, `tool_ingot_grinder`, `tool_tinkerer_kit`, `tool_n-dimensional_lathe`) and toggle the top filter buttons (`have ingredients`, `have skill`, `secret recipes`).
4. Select a recipe row (e.g. `Hard Cider` on the Still or `Copper Plate Boots` on the Anvil), hover ingredient/output icons for tooltips, and click **CRAFT** (or press `Enter`).
5. Click the **Encrust** tab on the top-left (or click **Open Encrusting Workbench** from the test screen) to switch to `ubercrust_bg.png`, select an encrust recipe (e.g. `Polymer Shell` under Smithing), click the target equipment slot on the right to cycle eligible items, and click **ENCRUST**.
6. Click **Open Inventory** to inspect crafted/encrusted items (including encrust and instability tooltips) and use any toolkit item to confirm it opens the workbench to that tool.
