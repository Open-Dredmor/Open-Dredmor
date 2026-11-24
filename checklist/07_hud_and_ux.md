# 07 — In-Game HUD & UX

Screen-fixed HUD, event log, minimap, modal windows, and combat feedback.

---

- [ ] **Core HUD overlay**
  - *Current state*: [script/scene/game.gd](../script/scene/game.gd) creates an empty `Control` named `GUI` inside `moveable_container` (which moves with the map rather than staying screen-fixed).
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
