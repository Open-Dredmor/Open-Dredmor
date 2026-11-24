# 02 — Menus, Settings & Display

Pre-game flow, responsive UI scaling across window sizes, and preserving player selections when navigating between menus.

---

- [x] **Support arbitrary window sizes & responsive UI**
  - *Current state*: [project.godot](../project.godot) hardcodes `1680x1050` with no viewport stretch settings; menus read `OD.Settings.display_size()` once on `_build_gui()` and use fixed pixel sizes/offsets.
  - *Done when*: Stretch mode/aspect is configured in `project.godot` (and/or responsive anchors/containers are used on resize) so all menus and the game viewport scale cleanly across arbitrary window sizes and aspect ratios without clipping or off-screen elements.

- [x] **Interstitial data management across menu navigation**
  - *Current state*: [script/scene/skills_menu.gd](../script/scene/skills_menu.gd) calls `OD.DungeonSettings.reset()` in `_build_gui()`, wiping previously selected difficulty/skills/character state; hitting **Back** from [script/scene/character_menu.gd](../script/scene/character_menu.gd) or [script/scene/skills_menu.gd](../script/scene/skills_menu.gd) loses prior selections.
  - *Done when*: `OD.DungeonSettings` is only reset when starting a fresh New Game from Main Menu (or explicitly), and Difficulty, Skills, and Character menus initialize their UI controls from existing `OD.DungeonSettings` state so Back/Forward navigation preserves all selections.

- [x] **Enable normal startup flow**
  - *Current state*: [script/singleton/scenes.gd](../script/singleton/scenes.gd) sets `FIRST_SCENE = GAME` for debugging, skipping `PRELOAD_ASSETS` and `MAIN_MENU`.
  - *Done when*: `FIRST_SCENE` defaults to `PRELOAD_ASSETS` (with a debug toggle/flag if desired) so players enter Main Menu → Difficulty → Skills → Character → Intro → Game.

- [x] **Main Menu missing features**
  - *Current state*: [script/scene/main_menu.gd](../script/scene/main_menu.gd) has stubbed `Load Game` and `High Scores` buttons; expansion subtitles in [script/singleton/resource.gd](../script/singleton/resource.gd) are unused.
  - *Done when*: `Load Game` opens a saved-game picker (when saves exist), `High Scores` opens a high-scores screen, and expansion subtitles render when matching backgrounds are shown.

- [ ] **Expansion & mod selection when starting a run**
  - *Current state*: [script/singleton/database.gd](../script/singleton/database.gd) loads packs in isolation and defaults to vanilla-only; `OD.DungeonSettings` stores `active_packs`, and no menu UI exposes pack toggles yet.
  - *Done when*: Starting a new run lets the player toggle discovered expansions/mods (`OD.Database.get_available_packs()`), calls `OD.Database.set_active_packs(...)`, and persists `active_packs` in `OD.DungeonSettings` (and future save files).

- [ ] **Skills Menu: "Last Selection" & skill metadata**
  - *Current state*: [script/scene/skills_menu.gd](../script/scene/skills_menu.gd) has `last_selection_button` assets loaded in [script/singleton/assets.gd](../script/singleton/assets.gd) but never adds the button or persists last-used skills.
  - *Done when*: Selecting skills persists the last 7 skill IDs to user settings, the "Last" button restores them, and skill archetype/category info is shown.

- [ ] **Settings Menu completeness**
  - *Current state*: [script/scene/settings_menu.gd](../script/scene/settings_menu.gd) only toggles `audio_enabled` and forgets the install directory; `audio_volume_master_percent` in [script/singleton/settings.gd](../script/singleton/settings.gd) is unused.
  - *Done when*: Audio buses (`Master`, `Music`, `Sound`, `Dialogue` in [default_bus_layout.tres](../default_bus_layout.tres)) are controlled by volume sliders, plus display/fullscreen and keybind options, all persisted in `open-dredmor-settings.ini`.
