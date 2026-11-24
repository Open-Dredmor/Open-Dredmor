## Reference Context & Checklist Workflow
- This is a clean room implementation of Dungeons of Dredmor using Godot.
- It requires a valid retail version of Dungeons of Dredmor to function
- It will not ever contain copyrighted material
- Anything you need to know about the game files themselves is contained in `airef/`.
- If something you need is in neither the open repo nor `airef/`, ask me to place it in `airef/` before proceeding.
- Project progress is tracked in `CHECKLIST.md`. When working an item, choose the first ordered checklist/* file that contains unchecked action items. Work on the top-most unchecked item. When finished, check it off. Then explain how to best verify that it works.
- If there isn't a straightforward way already to verify a completed task is working, then implement a new scene to be accessed in scenes.gd for a human to verify.
- When finishing an item, make sure the scenes.gd `var FIRST_SCENE = <scene>` points to the correct scene for human verification