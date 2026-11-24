# 03 — Dungeon Generation, Tilesets & Room Features

Fast floor layout generation, branch tilesets, interactive room elements, traps, doors, and multi-floor progression.

---

- [x] **Improve dungeon floor generation algorithm & performance**
  - *Current state*: [script/instance/dungeon.gd](../script/instance/dungeon.gd) hardcodes `DEBUG_ROOMS` on floor 1; [connect_doors_strategy.gd](../script/instance/room_placement/connect_doors_strategy.gd) and [center_pack_strategy.gd](../script/instance/room_placement/center_pack_strategy.gd) are incomplete and instantiate full `Room` `Node2D`s (loading textures/animations) even for rejected placements, with `O(N^2)` collision retries.
  - *Done when*:
    - Layout/placement operates on lightweight room metadata/rects (bounding boxes + door coordinates) *before* instantiating `Room` nodes or loading sprites.
    - Generation runs quickly (sub-second per floor) with spatial indexing/grid occupancy instead of naive brute-force retries.
    - Generates a fully connected floor from `branchDB` + `rooms.xml` (respecting `minLevel`/`maxLevel`, `no_time_to_grind` floor size scaling, Starting Room on floor 1, stairs up/down, Brax shop room, and optional special/quest/zoo rooms) with zero overlapping or unreachable rooms.

- [x] **Branch tileset & wall/floor auto-tiling**
  - *Current state*: [script/instance/tileset.gd](../script/instance/tileset.gd) picks a random `floor` or `wall` tile from branch `0` without contextual wall/corner/edge selection or branch switching per floor.
  - *Done when*: Each floor uses its `branchDB` tileset and renders proper wall/floor/corner variants, destructible walls (`!`), and invisible blockers (`X`).

- [x] **Doors (placement, state, interaction)**
  - *Current state*: [script/instance/room.gd](../script/instance/room.gd) tracks `_doors` for room linking and seals unused ones, but `claim_door` has `# TODO Add the door and remove surrounding walls`.
  - *Done when*: Claimed doors spawn interactive Door entities (closed by default, openable by player/monsters, lockable/kickable/lockpickable, with proper L/R and U/D sprites).

- [x] **Room scripts & triggers**
  - *Current state*: [script/instance/room.gd](../script/instance/room.gd) parses `<script>` coordinates partially (note: lines 104–109 check `script_location.has(ii)` instead of `script_location._coordinate`) and executes no script actions.
  - *Done when*: Room `<script>` conditions and actions (e.g., levers, pressure plates, braziers, spawns, doors, traps) evaluate and trigger during gameplay.

- [x] **Interactive dungeon elements**
  - *Current state*: [script/instance/room.gd](../script/instance/room.gd) (`element_tile_handler`) places static animations for anvils, bookshelves, statues, levers, and vending machines.
  - *Done when*: Each element is an interactive entity:
    - **Krong Anvil**: corrupts/enchants an equipped or inventory item.
    - **Bookshelf**: grants a random crafting recipe or tome/lore.
    - **Lever**: toggles linked room script/door/trap.
    - **Vending Machines** (bolt/craft/drink/food/thrown): opens purchase UI for zorkmids.
    - **Lutefisk Statue**: accepts lutefisk offerings and grants artifacts at thresholds.
    - **Statues / Dredmor Statue**: flavor text / quest or buff interaction.
    - **Custom breakables / Pedestals**: breakable on attack/spell; pedestals hold/spawn items.

- [x] **Traps**
  - *Current state*: [script/instance/room.gd](../script/instance/room.gd) (`trap_tile_handler`) uses placeholder sprites and no trap logic.
  - *Done when*: Traps use proper definitions, respect player `TRAP_SENSE` / `TRAP_SIGHT` for visibility, trigger their spell/damage effect when stepped on, and can be disarmed or picked up (based on Trap Affinity / Tinkering).

- [x] **Brax & Shops**
  - *Current state*: [script/instance/room.gd](../script/instance/room.gd) places a static Brax sprite on `S`, ignores `s`, and places a static pedestal on `i`.
  - *Done when*: Shops spawn priced items on pedestals, allow buying/selling with Brax, teleport Brax to `s` when shopping, and turn Brax + Collector/demonic guards hostile if the player attempts to steal or leaves without paying.

- [x] **Multi-floor progression & Stairs**
  - *Current state*: [script/instance/dungeon.gd](../script/instance/dungeon.gd) has an unused `floors = []` array and only generates floor 1.
  - *Done when*: Stepping on/activating Stairs Down/Up generates or restores the target floor state, places the player at the corresponding stairs, and persists visited floors until save/quit.
