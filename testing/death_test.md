# Death, Permadeath & High Scores Test (`DEATH_TEST`)

- **Script**: [script/scene/dev/death_test.gd](../script/scene/dev/death_test.gd)
- **Scene Constant**: `OD.Scenes.DEATH_TEST` (`"dev/death_test"`)

## Purpose
Verifies lethal damage handling on `PlayerCharacter`, `died` signal emission with damage source, `DeathManager` permadeath save deletion, and high score persistence.

## How to Run
1. Set `var FIRST_SCENE = DEATH_TEST` in [script/singleton/scenes.gd](../script/singleton/scenes.gd).
2. Run `./airef/godot` interactively, or headlessly with:
   ```bash
   HOME=/tmp ./airef/godot --headless --quit-after 8
   ```
   Headless output should print `DEATH_TEST_READY`.

## What to Verify
1. Confirm automated verification logs pass on startup.
2. Click **Trigger Lethal Hit** to kill the test hero and record a high score entry.
3. Click **View High Scores** to confirm the recorded entry appears in the High Scores menu.
