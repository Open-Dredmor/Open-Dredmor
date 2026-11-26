## Code Standards
- Don't abbreviate words to make variable names shorter. For example, use "texture" instead of "tex"

## Architecture Overview
- See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for the module layout across `script/singleton/database/`, `script/instance/entity/player/`, `script/instance/combat/`, mod discovery (`mod.xml`), asset override resolution, and mod-safe saves.

## Reference Context & Checklist Workflow
- This is a clean room implementation of Dungeons of Dredmor using Godot.
- It requires a valid retail version of Dungeons of Dredmor to function
- It will not ever contain copyrighted material
- Anything you need to know about the game files themselves is contained in `airef/`.
- There is a copy of the godot engine binary at `airef/godot` you can use to run tests
- There is a full copy of the retail steam game at `airef/steam-install`
- If something you need is in neither the repo nor `airef/`, ask me to place it in `airef/` before proceeding.
- Project progress is tracked in `docs/CHECKLIST.md`, organized into round directories under `checklist/` (e.g., `checklist/round-1/` for the completed initial core feature set, `checklist/round-2/` for subsequent work).
- When working an item, choose the first ordered `checklist/round-<N>/*` file (in the earliest round with remaining work) that contains unchecked action items.
- Work on the top-most unchecked item. When finished, check it off. Then explain how to best verify that it works. Create or update a test document in the `testing/` dir if appropriate
- If there isn't a straightforward way already to verify a completed task is working, then implement a new scene to be accessed in scenes.gd for a human to verify.
- When finishing an item, make sure the scenes.gd `var FIRST_SCENE = <scene>` points to the correct scene for human verification

## UI & Nine-Patch Layout
- When greating GUIs in the game, try when it makes sense to match the look and feel of the retail version of the game's experience and graphics.
- Use nine-patch panels (`PanelContainer` with `StyleBoxTexture` or `NinePatchRect` inside layout containers like `CenterContainer`) for dialogs and windows instead of fixed-size `TextureRect` overlays.
- Set generous `texture_margin_*` and `content_margin_*` values so decorative borders/corners are preserved and child controls are never squished or overflowing.
- Scale dialog dimensions relative to the viewport size (with clamped min/max bounds) and use `ScrollContainer` + text autowrapping for dynamic content so UIs adapt cleanly when the window resizes.

## Retail Game Inspection (`airef/retail.json` & `airef/inspection/`)
- Before scanning or parsing `airef/steam-install` directly, read `airef/retail.json` first. It is a compact master index with pack layout (`base`, `expansion`, `expansion2`, `expansion3`), entity/asset counts, data format notes (`.spr`, `.pal`, `rooms.dat`, XML load order), and quick lookups (damage types, resistances, buffs, toolkit tags, skill/spell/effect types, monster taxa, tweaks).
- For detailed queries, inspect only the relevant targeted JSON under `airef/inspection/` (for example with `jq` or a short `python3` one-liner) instead of loading huge files or re-parsing raw XMLs:
  - `airef/inspection/schema.json`: `DredmorSchema.xsd` definitions plus all observed XML tags and attributes across base and expansions.
  - `airef/inspection/items.json`: `itemDB.xml`, `encrustDB.xml`, and `scrollDB.xml` entries with categories and icon existence checks.
  - `airef/inspection/crafts.json`: `craftDB.xml` recipes grouped by tool tag and pack.
  - `airef/inspection/skills.json`: `skillDB.xml` skill trees, tags, loadouts, and linked abilities.
  - `airef/inspection/spells.json`: `spellDB.xml` spells and effect definitions.
  - `airef/inspection/monsters.json`: `monDB.xml` monsters, stats, resistances, sprites, and taxa.
  - `airef/inspection/rooms_and_world.json`: `branchDB.xml`, `rooms.xml`, `rooms.dat`, `magicBoxRooms.xml`, `wizardRoomDB.xml`, `quests.xml`, `manTemplateDB.xml`, `tweakDB.xml`, `text.xml`, `tutorial.xml`, `manual.xml`, and `speech.xml`.
  - `airef/inspection/audio.json`: `soundfx.xml` entries plus all `.wav` and `.ogg` files.
  - `airef/inspection/sprites_and_animations.json`: sprite animation XMLs, binary `.spr` headers, and `.pal` palette files.
  - `airef/inspection/ui_and_assets.json`: `ui/` and `menus/` PNGs with pixel dimensions (`width`, `height`), `tilesets/`, and `fonts/`.
  - `airef/inspection/files_manifest.json`: full file listing of `airef/steam-install` (excluding `.import` metadata and the duplicate `Dungeons of Dredmor.app` macOS bundle).
- To regenerate `airef/retail.json` and `airef/inspection/`, run `python3 tools/inspect_retail.py`.