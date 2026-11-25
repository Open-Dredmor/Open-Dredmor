# Spellcasting & spellDB Engine Test (`SPELL_TEST`)

- **Script**: [script/scene/dev/spell_test.gd](../script/scene/dev/spell_test.gd)
- **Scene Constant**: `OD.Scenes.SPELL_TEST` (`"dev/spell_test"`)

## Purpose
Tests `SpellEngine` parsing and execution of `spellDB.xml` spells across targeting shapes (`missile`, `beam`, `cone`, `template`, `targetfloor` mine, `self`), damage/healing, buffs, terrain digging, summoning, and polymorphing.

## How to Run
1. Set `var FIRST_SCENE = SPELL_TEST` in [script/singleton/scenes.gd](../script/singleton/scenes.gd).
2. Run `./airef/godot` interactively, or headlessly with:
   ```bash
   HOME=/tmp ./airef/godot --headless --quit-after 8
   ```
   Headless output should print `SPELL_TEST_READY`.

## What to Verify
1. Confirm automated spell verification passes on load in the log panel.
2. Click individual cast buttons (**Cast Weak Firebolt**, **Cast Smoke Ray**, **Cast Acidical Projector**, **Cast Torus Blast 1**, **Cast Toxic Spore Cloud**, **Cast Monstrous Rage**, **Cast Knitting Tissue**, **Cast Digging Ray**, **Cast Summon Slime**, **Cast Polymorph**) and **Advance Turn** to inspect spell effects and turn ticks.
