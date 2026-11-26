# Save / Load & High Scores Test

Verifies Open Dredmor's JSON save/load serialization (`user://saves/`), `pack_manifest` and `skill_entries` mod-resilient skill restoration, floor/player/FOV restoration, and High Scores persistence (`user://high_scores.json`).

## Automated Verification

```bash
HOME=/tmp ./airef/godot --headless --quit-after 10
```

Expected output includes `SAVE_SYSTEM_VERIFIED`.

## Interactive Verification

1. Set `FIRST_SCENE = SAVE_TEST` (or `PRELOAD_ASSETS`) in `script/singleton/scenes.gd`.
2. Launch `./airef/godot`.
3. Click **Launch Game**, open the pause menu (`Esc` or `M`), click **Save Game** or **Save & Quit**.
4. From the Main Menu, open **Load Game** to see the saved run in `user://saves/`, select it, and click **Done** (or double-click) to resume.
5. From the Main Menu, open **Import Saves** to scan common Dungeons of Dredmor save paths (or enter a directory / drag & drop a `.dredmorsave` folder), import one or a checklisted batch, and resume the imported character from **Load Game**.
6. Open **High Scores** from the Main Menu and verify sorting by Score, Floor, Name, Difficulty, and Date.
