# 04 — Turn-Based Loop, Commands, Pathfinding & FOV

Command decoupling, roguelike turn scheduling, grid collision/pathfinding, camera control, and line-of-sight.

---

- [x] **Decouple command system from input system**
  - *Current state*: [script/instance/dungeon.gd](../script/instance/dungeon.gd) (`_input`) and [script/scene/game/game.gd](../script/scene/game/game.gd) (`_input`) directly mutate positions or instantiate `MoveToLocationAction` inside input handlers.
  - *Done when*: Player actions are represented as discrete Command objects/interfaces (e.g., `MoveCommand`, `AttackCommand`, `InteractCommand`, `CastSpellCommand`, `UseItemCommand`, `WaitCommand`), and an InputMapper translates keyboard/mouse/UI events into commands—allowing rebindable keys, click-to-act, and non-input sources (AI/macros/tests) to drive the same command pipeline.

- [x] **True roguelike turn scheduler**
  - *Current state*: [script/singleton/action_queue.gd](../script/singleton/action_queue.gd) runs a real-time 0.5s `Timer` that ticks queued actions continuously.
  - *Done when*: Gameplay is strictly turn-based: a resolved player command advances 1 turn, then all active monsters, traps, cooldowns, regen, and status effects advance by 1 turn, with smooth animation pacing before accepting the next player turn.

- [x] **Grid occupancy, collision & A* pathfinding**
  - *Current state*: [script/instance/entity_grid.gd](../script/instance/entity_grid.gd) initializes `_grid_lookup` in `resize()` but never populates or queries it; [move_to_location_action.gd](../script/instance/action/move_to_location_action.gd) steps naively toward destination ignoring walls/entities; `OD.Math.pixel_to_grid` is a stub.
  - *Done when*: `EntityGrid` tracks walkability, opacity, and entity occupancy per cell; A* pathfinding routes around obstacles and stops on hazards/enemies; clicking a tile issues a pathing command that walks until arrival, interruption, or enemy spotted.

- [x] **Keyboard controls & camera follow**
  - *Current state*: [script/scene/game/game.gd](../script/scene/game/game.gd) pans the map with arrow keys and mouse drag; there is no player keyboard movement or camera centering on the player.
  - *Done when*: Player can move/attack via keyboard (WASD / arrows / numpad), wait a turn (`Space`), and the camera smoothly centers on the player (with optional manual pan/reset).

- [x] **Line of Sight (FOV) & Fog of War**
  - *Current state*: Entire floor is visible at all times.
  - *Done when*: Shadowcasting/raycast FOV computes visible tiles using player `SIGHT` radius and wall/closed-door opacity; unexplored tiles are hidden, previously explored tiles render dimmed (fog of war), and monsters/items outside FOV are hidden.
