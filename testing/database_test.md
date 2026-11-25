# Database Inspection Test (`DATABASE_TEST`)

- **Script**: [script/scene/dev/database_test.gd](../script/scene/dev/database_test.gd)
- **Scene Constant**: `OD.Scenes.DATABASE_TEST` (`"dev/database_test"`)

## Purpose
Provides an interactive browser for `OD.Database.ingest()` across all enabled retail packs (`base` + expansions), verifying counts and parsed entries for Skills, Spells, Items, Crafts, Tweaks, and Branches.

## How to Run
1. Set `var FIRST_SCENE = DATABASE_TEST` in [script/singleton/scenes.gd](../script/singleton/scenes.gd).
2. Run `./airef/godot`.

## What to Verify
1. Confirm the top summary bar shows non-zero counts for Skills, Spells, Items, Crafts, Tweaks, Branches, and SFX.
2. Switch between category buttons (**Skills**, **Spells**, **Items**, **Crafts**, **Tweaks**, **Branches**), filter with the search box, and select entries to inspect their parsed fields.
