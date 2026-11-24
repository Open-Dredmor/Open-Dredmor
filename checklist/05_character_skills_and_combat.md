# 05 — Character, Skills, Combat & Monsters

Player stats, skill tree progression, melee/ranged combat, `spellDB` effects, status buffs/debuffs, monster AI, and death.

---

- [x] **Player character model & Hero/Heroine sprites**
  - *Current state*: [script/instance/entity/player_character.gd](../script/instance/entity/player_character.gd) hardcodes `OD.Resources.paths.player.hero` (ignoring `DungeonSettings.hero == "heroine"`) and has no stats, HP/MP, XP, or equipment.
  - *Done when*: `PlayerCharacter` loads `hero` or `heroine` sprites, tracks HP/MaxHP, MP/MaxMP, XP/Level, Zorkmids, Primary stats (6), Secondary stats (18+), and Elemental resistances/damage.

- [x] **Skill system & Leveling**
  - *Current state*: Chosen skill IDs are stored in `DungeonSettings.starting_skill_ids` and never used in `game.gd`.
  - *Done when*: Starting skills grant level-1 abilities/stats; XP from kills/quests/disarms levels up the character, awards skill points, and lets the player unlock higher tiers in their 7 chosen skill trees (`skillDB.xml`).

- [ ] **Combat resolution (Melee, Ranged, Thrown, Bolts)**
  - *Current state*: None.
  - *Done when*: Bumping an enemy or firing a crossbow/thrown weapon resolves hit vs. dodge, block, counter, critical, haywire, armor absorption, and elemental damage/resistances using `tweakDB.xml` formulas, spawns attack animations/SFX, and handles monster death & loot/XP drops.

- [ ] **Spellcasting & `spellDB.xml` effect engine**
  - *Current state*: None.
  - *Done when*: Spells can be cast from hotbar/menu with mana cost and cooldowns; targeting supports self, single target, beam, cone, template/AOE, missile, and mine; core `spellDB` effects (damage, heal, buff, DoT, summon, knockback, dig, teleport, polymorph, etc.) execute accurately.

- [ ] **Buffs, Debuffs & Status Effects**
  - *Current state*: None.
  - *Done when*: Timed buffs/debuffs, brittle/on-hit procs, and DoTs tick per turn, modify stats dynamically, and display active icons/durations.

- [ ] **Monster AI & Spawning**
  - *Current state*: [script/instance/room.gd](../script/instance/room.gd) spawns static idle animations for monsters/hordes.
  - *Done when*: Monsters instantiate as full entities from `monDB.xml` (stats, resistances, spells, drops, sprites for idle/walk/attack/die), roam/alert on FOV, pathfind toward the player, attack or cast spells, and spawn periodically if `no_time_to_grind` is false.

- [ ] **Player Death, Permadeath & High Scores**
  - *Current state*: None.
  - *Done when*: Reaching 0 HP plays death sequence, deletes the save file if `permadeath` is enabled, records the run to the High Scores list (name, level, score, cause of death, skills), and returns to Main Menu / High Scores.
