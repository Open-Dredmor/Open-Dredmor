# Open Dredmor — Implementation Checklist

This checklist tracks all functionality needed to go from the current Godot 4 skeleton to a fully playable clean-room reimplementation of *Dungeons of Dredmor* using the user's local Dredmor installation assets.

Each item includes **what is missing** and **Done when** criteria. Items are ordered roughly by dependency—foundational engine systems first, then world/entity systems, gameplay loops, UI, and persistence.

---

## 1. Bootstrap, Asset Loading & Database

- [ ] **Validate Dredmor installation directory**
  - *Current state*: [bootstrap.gd](scene/Bootstrap/bootstrap.gd) accepts any directory selected in `FileDialog`.
  - *Done when*: Selection checks for required vanilla files (e.g., `game/itemDB.xml`, `game/skillDB.xml`, `game/monDB.xml`, `game/rooms.xml`), displays a clear error if invalid, and only saves/proceeds on a valid install.

- [ ] **Expansion & mod data discovery**
  - *Current state*: [database.gd](script/singleton/database.gd) only loads `game/*.xml`.
  - *Done when*: `OD.Database` detects installed expansions (`expansion/`, `expansion2/`, `expansion3/`) and optional mod folders, and merges their `skillDB`, `itemDB`, `monDB`, `craftDB`, `spellDB`, `rooms`, `branchDB`, `soundfx`, `speech`, and `text` records without breaking vanilla lookups.

- [ ] **SPR transparency mask support**
  - *Current state*: [load.gd](script/singleton/load.gd) (`_pro_motion_sprites`) reads `_trans_chunk` into a local variable but ignores it, only using color index `0` for alpha.
  - *Done when*: `_trans_chunk` (when present) is applied to the generated `Image` alpha channel so sprites with non-zero transparent indices render cleanly.

- [ ] **Clean XML parser text/hierarchy handling**
  - *Current state*: [load.gd](script/singleton/load.gd) (`xml`) stores `NODE_TEXT` in a flat `result['data_nodes']` array with a `length() > 4` workaround, which breaks or misaligns text nodes on general XML files.
  - *Done when*: Text content is attached directly to its owning element node (e.g., `node.text`) and `.xml` sprite animations + room `<row>`/`<script>`/`<text>` data parse cleanly without the `data_nodes` workaround.

- [ ] **Palette-swapped sprite loading (`.pal`)**
  - *Current state*: Commented-out stub in [sprite_test.gd](script/scene/sprite_test.gd).
  - *Done when*: `OD.Load` can parse `.pal` files and apply palette swaps to `.spr` sprites (needed for monster/hero variants).

- [ ] **Sound effects (SFX) loader & player**
  - *Current state*: [audio.gd](script/singleton/audio.gd) only plays a single looping music `AudioStreamPlayer`; `soundfx.xml` is ingested but unused.
  - *Done when*: `OD.Database` indexes `soundfx.xml` by cue name, `OD.Load` loads WAV/OGG SFX from the install dir, and `OD.Audio` provides a pooled `play_sfx(cue_name)` respecting SFX volume and audio-enabled settings.

- [ ] **Structured database indexing & getters**
  - *Current state*: [database.gd](script/singleton/database.gd) only has helpers for `character_creation_skill_list`, `rooms`, `branches`, `monsters`, and partial `loot_info` (missing `component` vs `reagent` distinction, items, skills, spells, crafts, tweaks, quests, speech).
  - *Done when*: `OD.Database` provides typed/indexed lookup helpers for skills (including level progression & granted spells/stats), spells, items (with slot/type/effects), crafting recipes, `tweakDB` constants, and `branchDB` floor definitions.

---

## 2. Menus & Settings

- [ ] **Enable normal startup flow**
  - *Current state*: [scenes.gd](script/singleton/scenes.gd) sets `FIRST_SCENE = GAME` for debugging, skipping `PRELOAD_ASSETS` and `MAIN_MENU`.
  - *Done when*: `FIRST_SCENE` defaults to `PRELOAD_ASSETS` (with a debug toggle/flag if desired) so players enter Main Menu → Difficulty → Skills → Character → Intro → Game.

- [ ] **Main Menu missing features**
  - *Current state*: [main_menu.gd](script/scene/main_menu.gd) has stubbed `Load Game` and `High Scores` buttons; expansion subtitles in [resource.gd](script/singleton/resource.gd) are unused.
  - *Done when*: `Load Game` opens a saved-game picker (when saves exist), `High Scores` opens a high-scores screen, and expansion subtitles render when matching backgrounds are shown.

- [ ] **Skills Menu: "Last Selection" & skill metadata**
  - *Current state*: [skills_menu.gd](script/scene/skills_menu.gd) has `last_selection_button` assets loaded in [assets.gd](script/singleton/assets.gd) but never adds the button or persists last-used skills.
  - *Done when*: Selecting skills persists the last 7 skill IDs to user settings, the "Last" button restores them, and skill archetype/category info is shown.

- [ ] **Settings Menu completeness**
  - *Current state*: [settings_menu.gd](script/scene/settings_menu.gd) only toggles `audio_enabled` and forgets the install directory; `audio_volume_master_percent` in [settings.gd](script/singleton/settings.gd) is unused.
  - *Done when*: Audio buses (`Master`, `Music`, `Sound`, `Dialogue` in [default_bus_layout.tres](default_bus_layout.tres)) are controlled by volume sliders, plus display/fullscreen and keybind options, all persisted in `open-dredmor-settings.ini`.

---

## 3. Dungeon Generation, Tilesets & Room Features

- [ ] **Complete floor generation strategy**
  - *Current state*: [dungeon.gd](script/instance/dungeon.gd) hardcodes `DEBUG_ROOMS` on floor 1; [connect_doors_strategy.gd](script/instance/room_placement/connect_doors_strategy.gd) and [center_pack_strategy.gd](script/instance/room_placement/center_pack_strategy.gd) are incomplete prototypes.
  - *Done when*: A floor generator creates a fully connected dungeon floor from `branchDB` + `rooms.xml` (respecting `minLevel`/`maxLevel`, `no_time_to_grind` floor size scaling, Starting Room on floor 1, stairs up/down, Brax shop room, and optional special/quest/zoo rooms) with zero overlapping or unreachable rooms.

- [ ] **Branch tileset & wall/floor auto-tiling**
  - *Current state*: [tileset.gd](script/instance/tileset.gd) picks a random `floor` or `wall` tile from branch `0` without contextual wall/corner/edge selection or branch switching per floor.
  - *Done when*: Each floor uses its `branchDB` tileset and renders proper wall/floor/corner variants, destructible walls (`!`), and invisible blockers (`X`).

- [ ] **Doors (placement, state, interaction)**
  - *Current state*: [room.gd](script/instance/room.gd) tracks `_doors` for room linking and seals unused ones, but `claim_door` has `# TODO Add the door and remove surrounding walls`.
  - *Done when*: Claimed doors spawn interactive Door entities (closed by default, openable by player/monsters, lockable/kickable/lockpickable, with proper L/R and U/D sprites).

- [ ] **Room scripts & triggers**
  - *Current state*: [room.gd](script/instance/room.gd) parses `<script>` coordinates partially (note: lines 104–109 check `script_location.has(ii)` instead of `script_location._coordinate`) and executes no script actions.
  - *Done when*: Room `<script>` conditions and actions (e.g., levers, pressure plates, braziers, spawns, doors, traps) evaluate and trigger during gameplay.

- [ ] **Interactive dungeon elements**
  - *Current state*: [room.gd](script/instance/room.gd) (`element_tile_handler`) places static animations for anvils, bookshelves, statues, levers, and vending machines.
  - *Done when*: Each element is an interactive entity:
    - **Krong Anvil**: corrupts/enchants an equipped or inventory item.
    - **Bookshelf**: grants a random crafting recipe or tome/lore.
    - **Lever**: toggles linked room script/door/trap.
    - **Vending Machines** (bolt/craft/drink/food/thrown): opens purchase UI for zorkmids.
    - **Lutefisk Statue**: accepts lutefisk offerings and grants artifacts at thresholds.
    - **Statues / Dredmor Statue**: flavor text / quest or buff interaction.
    - **Custom breakables / Pedestals**: breakable on attack/spell; pedestals hold/spawn items.

- [ ] **Traps**
  - *Current state*: [room.gd](script/instance/room.gd) (`trap_tile_handler`) uses placeholder sprites and no trap logic.
  - *Done when*: Traps use proper definitions, respect player `TRAP_SENSE` / `TRAP_SIGHT` for visibility, trigger their spell/damage effect when stepped on, and can be disarmed or picked up (based on Trap Affinity / Tinkering).

- [ ] **Brax & Shops**
  - *Current state*: [room.gd](script/instance/room.gd) places a static Brax sprite on `S`, ignores `s`, and places a static pedestal on `i`.
  - *Done when*: Shops spawn priced items on pedestals, allow buying/selling with Brax, teleport Brax to `s` when shopping, and turn Brax + Collector/demonic guards hostile if the player attempts to steal or leaves without paying.

- [ ] **Multi-floor progression & Stairs**
  - *Current state*: [dungeon.gd](script/instance/dungeon.gd) has an unused `floors = []` array and only generates floor 1.
  - *Done when*: Stepping on/activating Stairs Down/Up generates or restores the target floor state, places the player at the corresponding stairs, and persists visited floors until save/quit.

---

## 4. Turn-Based Core, Pathfinding, FOV & Camera

- [ ] **True roguelike turn scheduler**
  - *Current state*: [action_queue.gd](script/singleton/action_queue.gd) runs a real-time 0.5s `Timer` that ticks queued actions continuously.
  - *Done when*: Gameplay is strictly turn-based: player input (move, attack, cast, use item, wait) resolves a player turn, then all active monsters, traps, cooldowns, regen, and status effects advance by 1 turn, with smooth animation pacing.

- [ ] **Grid occupancy, collision & A* pathfinding**
  - *Current state*: [entity_grid.gd](script/instance/entity_grid.gd) initializes `_grid_lookup` in `resize()` but never populates or queries it; [move_to_location_action.gd](script/instance/action/move_to_location_action.gd) steps naively toward destination ignoring walls/entities; `OD.Math.pixel_to_grid` is a stub.
  - *Done when*: `EntityGrid` tracks walkability, opacity, and entity occupancy per cell; A* pathfinding routes around obstacles and stops on hazards/enemies; clicking a tile paths and walks until arrival, interruption, or enemy spotted.

- [ ] **Keyboard controls & camera follow**
  - *Current state*: [game.gd](script/scene/game.gd) pans the map with arrow keys and mouse drag; there is no player keyboard movement or camera centering on the player.
  - *Done when*: Player can move/attack in 4 or 8 directions via keyboard (WASD / arrows / numpad), wait a turn (`Space`), and the camera smoothly centers on the player (with optional manual pan/reset).

- [ ] **Line of Sight (FOV) & Fog of War**
  - *Current state*: Entire floor is visible at all times.
  - *Done when*: Shadowcasting/raycast FOV computes visible tiles using player `SIGHT` radius and wall/closed-door opacity; unexplored tiles are hidden, previously explored tiles render dimmed (fog of war), and monsters/items outside FOV are hidden.

---

## 5. Player Character, Stats, Skills & Combat

- [ ] **Player character model & Hero/Heroine sprites**
  - *Current state*: [player_character.gd](script/instance/entity/player_character.gd) hardcodes `OD.Resources.paths.player.hero` (ignoring `DungeonSettings.hero == "heroine"`) and has no stats, HP/MP, XP, or equipment.
  - *Done when*: `PlayerCharacter` loads `hero` or `heroine` sprites, tracks HP/MaxHP, MP/MaxMP, XP/Level, Zorkmids, Primary stats (6), Secondary stats (18+), and Elemental resistances/damage.

- [ ] **Skill system & Leveling**
  - *Current state*: Chosen skill IDs are stored in `DungeonSettings.starting_skill_ids` and never used in `game.gd`.
  - *Done when*: Starting skills grant level-1 abilities/stats; XP from kills/quests/disarms levels up the character, awards skill points, and lets the player unlock higher tiers in their 7 chosen skill trees (`skillDB.xml`).

- [ ] **Combat resolution (Melee, Ranged, Thrown, Bolts)**
  - *Current state*: None.
  - *Done when*: Bumping an enemy or firing a crossbow/thrown weapon resolves hit vs. dodge, block, counter, critical, haywire, armor absorption, and elemental damage/resistances using `tweakDB.xml` formulas, spawns attack animations/SFX, and handles monster death & loot/XP drops.

- [ ] **Spellcasting & `spellDB.xml` effect engine**
  - *Current state*: None.
  - *Done when*: Spells can be cast from hotbar/menu with mana cost and cooldowns; targeting supports self, single target, beam, cone, template/AOE, missile, and mine; core `spellDB` effects (damage, heal, buff, DoT, summon, knockback, dig, teleport, polymorph, etc.) execute accurately.

- [ ] **Buffs, Debuffs & Status Effects**
  - *Current state*: None.
  - *Done when*: Timed buffs/debuffs, brittle/on-hit procs, and DoTs tick per turn, modify stats dynamically, and display active icons/durations.

- [ ] **Monster AI & Spawning**
  - *Current state*: [room.gd](script/instance/room.gd) spawns static idle animations for monsters/hordes.
  - *Done when*: Monsters instantiate as full entities from `monDB.xml` (stats, resistances, spells, drops, sprites for idle/walk/attack/die), roam/alert on FOV, pathfind toward the player, attack or cast spells, and spawn periodically if `no_time_to_grind` is false.

- [ ] **Player Death, Permadeath & High Scores**
  - *Current state*: None.
  - *Done when*: Reaching 0 HP plays death sequence, deletes the save file if `permadeath` is enabled, records the run to the High Scores list (name, level, score, cause of death, skills), and returns to Main Menu / High Scores.

---

## 6. Items, Inventory & Crafting

- [ ] **Inventory & Equipment management**
  - *Current state*: None.
  - *Done when*: Player has a grid/slot inventory, can pick up, drop, stack, inspect tooltips, and equip items into all Dredmor slots (main hand, off hand, head, chest, legs, feet, hands, 2x ring, amulet, belt, bolts, thrown), updating stats immediately.

- [ ] **Consumables & Wands**
  - *Current state*: None.
  - *Done when*: Food restores HP/turn, booze restores MP/turn (and applies tipsy/buffs), potions trigger their `spellDB` effects, and wands cast spells while tracking charges/burnout.

- [ ] **Loot generation & Artifacts**
  - *Current state*: [database.gd](script/singleton/database.gd) has incomplete `get_loot` (`component` vs `reagent` TODO, no level filtering or artifact generation).
  - *Done when*: Chests, monsters, and floor spawns roll level-appropriate loot from `itemDB.xml` (including quality/artifact bonus stats and random names).

- [ ] **Crafting system (`craftDB.xml`)**
  - *Current state*: None.
  - *Done when*: Player can open crafting tools (Ingot Press, Tinkerer's Parts, Elven Ingot Grinder/Alchemy, Wand Lore) when possessed, see known recipes, auto-place or drag ingredients, and craft output items (respecting skill level requirements).

---

## 7. In-Game HUD & UX

- [ ] **Core HUD overlay**
  - *Current state*: [game.gd](script/scene/game.gd) creates an empty `Control` named `GUI` inside `moveable_container` (which would move with the map rather than stay screen-fixed!).
  - *Done when*: A `CanvasLayer` HUD displays screen-fixed HP/MP bars/orbs, XP bar, Zorkmids, current floor & room name, active buffs, and clickable/hotkeyed skill & item belt/hotbar.

- [ ] **Event / Combat Log**
  - *Current state*: [event_log.gd](script/singleton/event_log.gd) is an empty `notify(_message)` stub.
  - *Done when*: Combat hits, crits, level-ups, traps, pickups, and room messages are recorded and displayed in a scrollable HUD log.

- [ ] **Minimap**
  - *Current state*: None.
  - *Done when*: An overlay/corner minimap shows explored rooms, walls, doors, stairs, shops, and player position, with toggleable full-floor view.

- [ ] **In-game windows (Character, Skills, Inventory, Crafting, Quest, Pause)**
  - *Current state*: None.
  - *Done when*: Hotkeys/HUD buttons open clean, responsive modals for Character Sheet (all primary/secondary stats & resists), Skill Trees, Inventory/Equipment, Crafting, Quests, and Pause/Save/Quit.

- [ ] **Floating combat text & visual polish**
  - *Current state*: None.
  - *Done when*: Damage numbers, resists, dodges, heals, and status text float above entities on combat/spell events.

---

## 8. Save / Load & Persistence

- [ ] **Save & Load game state**
  - *Current state*: No save format or serialization exists; Main Menu `Load Game` is a stub.
  - *Done when*: Player can save and quit (and auto-save on floor transitions), serializing dungeon floors, rooms, entities, player stats/skills/inventory/buffs/cooldowns, and RNG/settings to `user://saves/`, and resume seamlessly from Main Menu.

- [ ] **High Scores persistence**
  - *Current state*: Main Menu `High Scores` is a stub.
  - *Done when*: Completed/dead runs persist to `user://high_scores.json` (or `.ini`) and render in a sortable High Scores screen.
