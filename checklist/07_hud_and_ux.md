# 07 — In-Game HUD & UX

Screen-fixed HUD, event log, minimap, modal windows, and combat feedback.

---

- [x] **Core HUD overlay**
  - *Current state*: [script/instance/ui/core_hud.gd](../script/instance/ui/core_hud.gd) renders a screen-fixed `CanvasLayer` HUD in [script/scene/game/game.gd](../script/scene/game/game.gd) using the retail `bottombar_bg.png` bottom character bar, `lifebar0/1.png`, `manabar0/1.png`, `expbar0/1.png`, dynamic character portrait, Zorkmids, 9-slot item belt (`Shift+1..9`), 10-slot skill/spell hotbar (`1..9, 0`), menu tabs (`Menu`, `Character`, `Inventory`, `Skills`, `Quests`, `Crafting`), Digest/Wait button, top-left event log, top-right floor & room name, and `BuffBar`.
  - *Done when*: A `CanvasLayer` HUD displays screen-fixed HP/MP bars/orbs, XP bar, Zorkmids, current floor & room name, active buffs, and clickable/hotkeyed skill & item belt/hotbar.

- [ ] **Event / Combat Log**
  - *Current state*: [script/singleton/event_log.gd](../script/singleton/event_log.gd) is an empty `notify(_message)` stub.
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
