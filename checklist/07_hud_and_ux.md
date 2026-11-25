# 07 — In-Game HUD & UX

Screen-fixed HUD, event log, minimap, modal windows, and combat feedback.

---

- [x] **Core HUD overlay**
  - *Current state*: [script/instance/ui/core_hud.gd](../script/instance/ui/core_hud.gd) renders a screen-fixed `CanvasLayer` HUD in [script/scene/game/game.gd](../script/scene/game/game.gd) using the retail `bottombar_bg.png` bottom character bar, `lifebar0/1.png`, `manabar0/1.png`, `expbar0/1.png`, dynamic character portrait, Zorkmids, 9-slot item belt (`Shift+1..9`), 10-slot skill/spell hotbar (`1..9, 0`), menu tabs (`Menu`, `Character`, `Inventory`, `Skills`, `Quests`, `Crafting`), Digest/Wait button, top-left event log, top-right floor & room name, and `BuffBar`.
  - *Done when*: A `CanvasLayer` HUD displays screen-fixed HP/MP bars/orbs, XP bar, Zorkmids, current floor & room name, active buffs, and clickable/hotkeyed skill & item belt/hotbar.

- [x] **Event / Combat Log**
  - *Current state*: [script/singleton/event_log.gd](../script/singleton/event_log.gd) records up to 200 messages and emits `message_logged`; [script/instance/dungeon.gd](../script/instance/dungeon.gd) and [script/scene/game/game.gd](../script/scene/game/game.gd) log room discovery, combat hits/crits/dodges/counters/kills, level-ups, traps, pickups, breakables, and shop alerts; [script/instance/ui/core_hud.gd](../script/instance/ui/core_hud.gd) renders the top-left HUD ticker and toggles a scrollable log history view with `L`.
  - *Done when*: Combat hits, crits, level-ups, traps, pickups, and room messages are recorded and displayed in a scrollable HUD log.

- [x] **Minimap**
  - *Current state*: [script/instance/ui/minimap.gd](../script/instance/ui/minimap.gd) renders the retail top-right corner minimap inside [script/instance/ui/core_hud.gd](../script/instance/ui/core_hud.gd) with 4 zoom levels (`1x`–`4x` via `minimap_bg1x..4x.png`), `LEVEL X` header, `+`/`-` zoom buttons (`minimap_but_maximize`/`minimize`), `Tab`/`=`/`-` hotkeys, explored walls, floors, liquids, doors, stairs, dungeon elements, teleporters, and hero/heroine player icon, with the room name anchored below the frame.
  - *Done when*: An overlay/corner minimap shows explored rooms, walls, doors, stairs, shops, and player position, with toggleable full-floor view.

- [x] **In-game windows (Character, Skills, Inventory, Crafting, Quest, Pause)**
  - *Current state*: [script/instance/ui/inventory_dialog.gd](../script/instance/ui/inventory_dialog.gd) provides the combined Character Sheet (all primary/secondary stats, resists, warrior/wizard/rogue skillbars, equipment) & Inventory (`I`); [script/instance/ui/skill_tree_dialog.gd](../script/instance/ui/skill_tree_dialog.gd) provides the Skill Tome (all 7 chosen skill trees, tier tooltips, spending skill points, and a Spellbook tab with hotbar assignment, `M`); [script/instance/ui/crafting_dialog.gd](../script/instance/ui/crafting_dialog.gd) provides Crafting & Encrusting (`C`); [script/instance/ui/quest_dialog.gd](../script/instance/ui/quest_dialog.gd) provides the Quest Log (`Q`) backed by [script/instance/entity/player_character.gd](../script/instance/entity/player_character.gd) quest tracking and Inconsequentia statues; [script/instance/ui/pause_dialog.gd](../script/instance/ui/pause_dialog.gd) provides the Pause/Settings/Main Menu/Quit modal (`Esc`); all wired cleanly without overlapping via [script/instance/ui/core_hud.gd](../script/instance/ui/core_hud.gd) and [script/scene/game/game.gd](../script/scene/game/game.gd).
  - *Done when*: Hotkeys/HUD buttons open clean, responsive modals for Character Sheet (all primary/secondary stats & resists), Skill Trees, Inventory/Equipment, Crafting, Quests, and Pause/Save/Quit.

- [ ] **Floating combat text & visual polish**
  - *Current state*: None.
  - *Done when*: Damage numbers, resists, dodges, heals, and status text float above entities on combat/spell events.
