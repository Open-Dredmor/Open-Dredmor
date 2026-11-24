# 08 — Save / Load & Persistence

Run serialization using Open Dredmor's own save format and persistent high scores.

---

- [ ] **Save & Load game state (Open Dredmor format)**
  - *Current state*: No save format or serialization exists; Main Menu `Load Game` is a stub.
  - *Done when*: Player can save and quit (and auto-save on floor transitions), serializing dungeon floors, rooms, entities, player stats/skills/inventory/buffs/cooldowns, discovered minimap, and RNG/settings to `user://saves/` in a stable Open Dredmor format, and resume seamlessly from Main Menu.
  - *Scope note*: Loading original *Dungeons of Dredmor* save files is explicitly out of scope until Open Dredmor's own save/load framework is stable.

- [ ] **High Scores persistence**
  - *Current state*: Main Menu `High Scores` is a stub.
  - *Done when*: Completed/dead runs persist to `user://high_scores.json` (or `.ini`) and render in a sortable High Scores screen.
