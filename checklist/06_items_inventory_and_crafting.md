# 06 — Items, Inventory, Loot & Crafting

Equipment slots, consumables, level-scaled loot/artifacts, and the 4 crafting systems.

---

- [x] **Inventory & Equipment management**
  - *Current state*: Implemented in [script/instance/entity/player_character.gd](../script/instance/entity/player_character.gd), [script/instance/ui/inventory_dialog.gd](../script/instance/ui/inventory_dialog.gd), [script/singleton/database.gd](../script/singleton/database.gd), [script/instance/entity_grid.gd](../script/instance/entity_grid.gd), [script/instance/dungeon.gd](../script/instance/dungeon.gd), and [script/scene/game/game.gd](../script/scene/game/game.gd). Verified via `INVENTORY_TEST`.
  - *Done when*: Player has a grid/slot inventory, can pick up, drop, stack, inspect tooltips, and equip items into all Dredmor slots (main hand, off hand, head, chest, legs, feet, hands, 2x ring, amulet, belt, bolts, thrown), updating stats immediately.

- [x] **Consumables & Wands**
  - *Current state*: Implemented in [script/singleton/database.gd](../script/singleton/database.gd), [script/instance/entity/player_character.gd](../script/instance/entity/player_character.gd), [script/instance/combat/spell_engine.gd](../script/instance/combat/spell_engine.gd), [script/instance/ui/inventory_dialog.gd](../script/instance/ui/inventory_dialog.gd), [script/instance/dungeon.gd](../script/instance/dungeon.gd), [script/scene/game/game.gd](../script/scene/game/game.gd), and [script/scene/dev/consumable_test.gd](../script/scene/dev/consumable_test.gd). Verified via `CONSUMABLE_TEST`.
  - *Done when*: Food restores HP/turn, booze restores MP/turn (and applies tipsy/buffs), potions trigger their `spellDB` effects, and wands cast spells while tracking charges/burnout.

- [x] **Loot generation & Artifacts**
  - *Current state*: Implemented in [script/singleton/database.gd](../script/singleton/database.gd), [script/instance/entity/dungeon_element.gd](../script/instance/entity/dungeon_element.gd), [script/instance/ui/element_dialog.gd](../script/instance/ui/element_dialog.gd), [script/instance/dungeon.gd](../script/instance/dungeon.gd), [script/instance/room_placement/floor_populator.gd](../script/instance/room_placement/floor_populator.gd), [script/instance/entity/monster_entity.gd](../script/instance/entity/monster_entity.gd), [script/instance/room.gd](../script/instance/room.gd), [script/instance/ui/inventory_dialog.gd](../script/instance/ui/inventory_dialog.gd), and [script/scene/dev/loot_test.gd](../script/scene/dev/loot_test.gd). Verified via `LOOT_TEST`.
  - *Done when*: Chests, monsters, and floor spawns roll level-appropriate loot from `itemDB.xml` (including quality/artifact bonus stats and random names).

- [ ] **Crafting system (`craftDB.xml`)**
  - *Current state*: None.
  - *Done when*: Player can open crafting tools (Ingot Press, Tinkerer's Parts, Elven Ingot Grinder/Alchemy, Wand Lore) when possessed, see known recipes, auto-place or drag ingredients, and craft output items (respecting skill level requirements).
