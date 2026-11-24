## Reference Context & Checklist Workflow
- This is a clean room implementation of Dungeons of Dredmor using Godot.
- It requires a valid retail version of Dungeons of Dredmor to function
- It will not ever contain copyrighted material
- Anything you need to know about the game files themselves is contained in `airef/`.
- If something you need is in neither the open repo nor `airef/`, ask me to place it in `airef/` before proceeding.
- Project progress is tracked in `CHECKLIST.md`. When working an item, choose the first ordered checklist/* file that contains unchecked action items. Work on the top-most unchecked item. When finished, check it off. Then explain how to best verify that it works.
- If there isn't a straightforward way already to verify a completed task is working, then implement a new scene to be accessed in scenes.gd for a human to verify.
- When finishing an item, make sure the scenes.gd `var FIRST_SCENE = <scene>` points to the correct scene for human verification

## UI & Nine-Patch Layout
- Use nine-patch panels (`PanelContainer` with `StyleBoxTexture` or `NinePatchRect` inside layout containers like `CenterContainer`) for dialogs and windows instead of fixed-size `TextureRect` overlays.
- Set generous `texture_margin_*` and `content_margin_*` values so decorative borders/corners are preserved and child controls are never squished or overflowing.
- Scale dialog dimensions relative to the viewport size (with clamped min/max bounds) and use `ScrollContainer` + text autowrapping for dynamic content so UIs adapt cleanly when the window resizes.