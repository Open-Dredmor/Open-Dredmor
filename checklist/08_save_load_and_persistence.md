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

- [ ] **Load Retail saves**
  - *Current state*: Retail saves cannot be opened
  - *Done when*: Player can see their retail saves in a new Import Save scene, accessible from "Import Saves" on the main menu. This scene checks common Dungeons of Dredmor saves paths for existing saves and allows them to either be imported one at a time or in a checklisted batch. If no known save locations provide any save files to read, then allow inputing a dir to scan. Also support dragging and dropping a save to import it. We never need to support exporting Open Dredmor saves back to Dungeons of Dredmor. Its a one way import.