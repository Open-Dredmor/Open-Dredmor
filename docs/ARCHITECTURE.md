# Open Dredmor Architecture

This document describes the core runtime architecture of Open Dredmor, with a focus on content pack loading, retail mod support, and modular subsystem boundaries.

## 1. Content Packs, Mod Discovery, and Asset Resolution

- **Pack & Mod Discovery** ([script/singleton/settings.gd](../script/singleton/settings.gd)):
  - `OD.Settings.get_available_content_packs()` discovers official expansions (`expansion`, `expansion2`, `expansion3`) under the retail install directory and community mods across:
    - `<install_dir>/mods/`
    - `user://mods/`
    - `~/.local/share/Gaslamp Games/Dungeons of Dredmor/mods/`
  - Each mod directory is checked for `mod/mod.xml` (or `mod.xml`) to extract manifest metadata (`name`, `author`, `description`, `revision`, `require_expansion`) and determine its data subdirectory (`mod/` or `game/`).

- **Asset Override Priority & Fallbacks** ([script/singleton/load.gd](../script/singleton/load.gd)):
  - `OD.Load.resolve()` resolves relative paths in reverse priority order: active mods and expansions (`OD.Database.get_active_pack_roots()` from highest to lowest priority) are checked before the base retail install directory, allowing mods to override base sprites, UI assets, audio, and XML files.
  - `OD.Load.clear_cache()` is called automatically when active packs change.
  - Missing or malformed images, fonts, animations, and XML files log warnings to `OD.Load.diagnostics` via `push_warning()` and return safe fallbacks (such as a 32x32 checkerboard `ImageTexture`) instead of terminating the application.

## 2. Database & XML Normalization

[script/singleton/database.gd](../script/singleton/database.gd) acts as a facade over focused modules under [script/singleton/database/](../script/singleton/database/):

- [xml_normalizer.gd](../script/singleton/database/xml_normalizer.gd): Parses XML directly from each pack's filesystem root, normalizes inconsistent XML element/attribute casing (e.g. `primaryBuff` -> `primarybuff`, `roomDB` -> `roomdb`, `templateDB` -> `templatedb`), and tags entries with `_pack_id` provenance.
- [pack_loader.gd](../script/singleton/database/pack_loader.gd): Lazily loads only enabled packs (`get_or_load_pack()`), merges active pack data into the combined cache, and updates `active_pack_prefixes` and `active_pack_roots`.
- [skill_spell_repository.gd](../script/singleton/database/skill_spell_repository.gd): Indexes skills, abilities, spells, and `manTemplateDB` templates. Colliding integer `skill.id` values across packs are deterministically remapped (`>= 10000`) while keeping abilities from the same `_pack_id` attached to the remapped skill.
- [item_repository.gd](../script/singleton/database/item_repository.gd) & [item_factory.gd](../script/singleton/database/item_factory.gd): Indexes crafts, encrusts, unstable effects, items, and loot pools (deduplicating `list` collections from `by_name` maps on overrides), and constructs item/artifact instances.
- [world_repository.gd](../script/singleton/database/world_repository.gd): Indexes monsters (including variant merging), tweaks, branches, room layouts, wizard/magic-box rooms, and `soundfx.xml` cues.

## 3. Spell Engine & Effect Registry

- [spell_engine.gd](../script/instance/combat/spell_engine.gd) & [spell_effect_handlers.gd](../script/instance/combat/spell_effect_handlers.gd):
  - Spell targeting shapes and effect types (`damage`, `heal`, `spellpoints`, `drain`, `dot`, `trigger`, `triggerfromlist`, `knock`, `suction`, `dig`, `teleport`, `summon`, `transformmonster`, status flags, etc.) are dispatched through handler maps.
  - Custom handlers can be registered via `SpellEngine.register_effect_handler()` and `SpellEngine.register_target_shape()`.
  - Unknown effect types emit a one-time `push_warning()` instead of failing silently.

## 4. Player Character Components

[player_character.gd](../script/instance/entity/player_character.gd) preserves its public API and signals while delegating core subsystems to focused helpers under [script/instance/entity/player/](../script/instance/entity/player/):

- [stat_block.gd](../script/instance/entity/player/stat_block.gd): Primary/secondary stat initialization and derived stat recalculation.
- [buff_manager.gd](../script/instance/entity/player/buff_manager.gd): Buff stacking, brittle/attack-count expiration, mana/zorkmid upkeep, DoT ticking, and on-hit/on-attack/on-move hooks.
- [character_animator.gd](../script/instance/entity/player/character_animator.gd): Directional idle/walk/action sprite loading and playback for hero and heroine models.

## 5. Dungeon Combat & Mod-Safe Saves

- [dungeon_combat_helper.gd](../script/instance/combat/dungeon_combat_helper.gd): Isolates player melee/ranged attack resolution and enemy death/drop/quest handling from [dungeon.gd](../script/instance/dungeon.gd).
- [save_manager.gd](../script/instance/save_manager.gd): Records `pack_manifest` (active pack IDs, names, and revisions) and `skill_entries` (`id`, `name`, `pack_id`, `tier`) in save files. On load, skills are matched by ID and verified by name (falling back to name lookup if pack reordering remapped IDs), and missing mod skills are skipped with a warning instead of failing deserialization.
