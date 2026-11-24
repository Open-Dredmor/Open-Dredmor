# 01 — Bootstrap, Asset Loading & Database

Foundational work to reliably validate the user's *Dungeons of Dredmor* installation, parse all vanilla/expansion/mod assets and XMLs, and expose structured lookups.

---

- [x] **Validate Dredmor installation directory**
  - *Current state*: [scene/Bootstrap/bootstrap.gd](../scene/Bootstrap/bootstrap.gd) accepts any directory selected in `FileDialog`.
  - *Done when*: Selection checks for required vanilla files (e.g., `game/itemDB.xml`, `game/skillDB.xml`, `game/monDB.xml`, `game/rooms.xml`), displays a clear error if invalid, and only saves/proceeds on a valid install.

- [x] **Expansion & mod data discovery**
  - *Current state*: [script/singleton/database.gd](../script/singleton/database.gd) only loads `game/*.xml`.
  - *Done when*: `OD.Database` detects installed expansions (`expansion/`, `expansion2/`, `expansion3/`) and optional mod folders, and merges their `skillDB`, `itemDB`, `monDB`, `craftDB`, `spellDB`, `rooms`, `branchDB`, `soundfx`, `speech`, and `text` records without breaking vanilla lookups.

- [x] **SPR transparency mask support**
  - *Current state*: [script/singleton/load.gd](../script/singleton/load.gd) (`_pro_motion_sprites`) reads `_trans_chunk` into a local variable but ignores it, only using color index `0` for alpha.
  - *Done when*: `_trans_chunk` (when present) is applied to the generated `Image` alpha channel so sprites with non-zero transparent indices render cleanly.

- [x] **Clean XML parser text/hierarchy handling**
  - *Current state*: [script/singleton/load.gd](../script/singleton/load.gd) (`xml`) stores `NODE_TEXT` in a flat `result['data_nodes']` array with a `length() > 4` workaround, which breaks or misaligns text nodes on general XML files.
  - *Done when*: Text content is attached directly to its owning element node (e.g., `node.text`) and `.xml` sprite animations + room `<row>`/`<script>`/`<text>` data parse cleanly without the `data_nodes` workaround.

- [x] **Palette-swapped sprite loading (`.pal`)**
  - *Current state*: Commented-out stub in [script/scene/sprite_test.gd](../script/scene/sprite_test.gd).
  - *Done when*: `OD.Load` can parse `.pal` files and apply palette swaps to `.spr` sprites (needed for monster/hero variants).

- [x] **Sound effects (SFX) loader & player**
  - *Current state*: [script/singleton/audio.gd](../script/singleton/audio.gd) only plays a single looping music `AudioStreamPlayer`; `soundfx.xml` is ingested but unused.
  - *Done when*: `OD.Database` indexes `soundfx.xml` by cue name, `OD.Load` loads WAV/OGG SFX from the install dir, and `OD.Audio` provides a pooled `play_sfx(cue_name)` respecting SFX volume and audio-enabled settings.

- [ ] **Structured database indexing & getters**
  - *Current state*: [script/singleton/database.gd](../script/singleton/database.gd) only has helpers for `character_creation_skill_list`, `rooms`, `branches`, `monsters`, and partial `loot_info` (missing `component` vs `reagent` distinction, items, skills, spells, crafts, tweaks, quests, speech).
  - *Done when*: `OD.Database` provides typed/indexed lookup helpers for skills (including level progression & granted spells/stats), spells, items (with slot/type/effects), crafting recipes, `tweakDB` constants, and `branchDB` floor definitions.
