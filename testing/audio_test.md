# Audio Test (`AUDIO_TEST`)

- **Script**: [script/scene/dev/audio_test.gd](../script/scene/dev/audio_test.gd)
- **Scene Constant**: `OD.Scenes.AUDIO_TEST` (`"dev/audio_test"`)

## Purpose
Verifies audio system setup (`OD.Audio`), volume/mute persistence in `OD.Settings`, OGG music playback, and all indexed SFX cues parsed from `soundfx.xml`.

## How to Run
1. Set `var FIRST_SCENE = AUDIO_TEST` in [script/singleton/scenes.gd](../script/singleton/scenes.gd).
2. Run `./airef/godot`.

## What to Verify
1. Confirm the header shows the total indexed SFX cue count.
2. Toggle **Audio Enabled** and adjust the **Master %** and **SFX %** sliders to verify volume changes.
3. Click **Play Title Music**, **Play Game Music**, and **Stop All Audio**.
4. Enter a cue name in the SFX test box or filter the grid and click individual cue buttons to verify `.wav` / `.ogg` playback.
