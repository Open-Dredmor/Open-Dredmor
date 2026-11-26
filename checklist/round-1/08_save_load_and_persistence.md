# 08 — Save / Load & Persistence

Run serialization using Open Dredmor's own save format and persistent high scores.

---

- [x] **Save & Load game state (Open Dredmor format)**
  - *Current state*: Implemented in `SaveManager` (`script/instance/save_manager.gd`) and `GridSerializer` (`script/instance/grid_serializer.gd`), wired into `Dungeon`, `PauseDialog`, `CoreHud`, and `LoadGameMenu` (`user://saves/*.json`) with auto-save on floor transitions.
  - *Done when*: Player can save and quit (and auto-save on floor transitions), serializing dungeon floors, rooms, entities, player stats/skills/inventory/buffs/cooldowns, discovered minimap, and RNG/settings to `user://saves/` in a stable Open Dredmor format, and resume seamlessly from Main Menu.
  - *Scope note*: Loading original *Dungeons of Dredmor* save files is explicitly out of scope until Open Dredmor's own save/load framework is stable.

- [x] **High Scores persistence**
  - *Current state*: Persisted in `DeathManager` (`user://high_scores.json`) for both deaths and Lord Dredmor victory runs, rendered in `high_scores_menu.gd` with ascending/descending sorting by Score, Floor, Name, Difficulty, and Date.
  - *Done when*: Completed/dead runs persist to `user://high_scores.json` (or `.ini`) and render in a sortable High Scores screen.

- [x] **Load Retail saves**
  - *Current state*: Implemented defensive binary retail `.dredmorsave` importer in `RetailSaveImporter` (`script/instance/retail_save_importer.gd`) and `ImportSavesMenu` (`script/scene/game/import_saves_menu.gd`), accessible from **Import Saves** on the Main Menu with common path scanning, custom directory scanning, single/batch checklisted import, and drag-and-drop support.
  - *Done when*: Player can see their retail saves in a new Import Save scene, accessible from "Import Saves" on the main menu. This scene checks common Dungeons of Dredmor saves paths for existing saves and allows them to either be imported one at a time or in a checklisted batch. If no known save locations provide any save files to read, then allow inputing a dir to scan. Also support dragging and dropping a save to import it. We never need to support exporting Open Dredmor saves back to Dungeons of Dredmor. Its a one way import.