# 06 — Items, Inventory, Loot & Crafting

Equipment slots, consumables, level-scaled loot/artifacts, and the 4 crafting systems.

---

- [x] **Inventory & Equipment management**
  - *Current state*: Implemented in [script/instance/entity/player_character.gd](../script/instance/entity/player_character.gd), [script/instance/ui/inventory_dialog.gd](../script/instance/ui/inventory_dialog.gd), [script/singleton/database.gd](../script/singleton/database.gd), [script/instance/entity_grid.gd](../script/instance/entity_grid.gd), [script/instance/dungeon.gd](../script/instance/dungeon.gd), and [script/scene/game/game.gd](../script/scene/game/game.gd). Verified via `INVENTORY_TEST`.
  - *Done when*: Player has a grid/slot inventory, can pick up, drop, stack, inspect tooltips, and equip items into all Dredmor slots (main hand, off hand, head, chest, legs, feet, hands, 2x ring, amulet, belt, bolts, thrown), updating stats immediately.

- [ ] **Consumables & Wands**
  - *Current state*: None.
  - *Done when*: Food restores HP/turn, booze restores MP/turn (and applies tipsy/buffs), potions trigger their `spellDB` effects, and wands cast spells while tracking charges/burnout.

- [ ] **Loot generation & Artifacts**
  - *Current state*: [script/singleton/database.gd](../script/singleton/database.gd) has incomplete `get_loot` (`component` vs `reagent` TODO, no level filtering or artifact generation).
  - *Done when*: Chests, monsters, and floor spawns roll level-appropriate loot from `itemDB.xml` (including quality/artifact bonus stats and random names).

- [ ] **Crafting system (`craftDB.xml`)**
  - *Current state*: None.
  - *Done when*: Player can open crafting tools (Ingot Press, Tinkerer's Parts, Elven Ingot Grinder/Alchemy, Wand Lore) when possessed, see known recipes, auto-place or drag ingredients, and craft output items (respecting skill level requirements).
