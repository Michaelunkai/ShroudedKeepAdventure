# Shrouded Keep Adventure

`Shrouded Keep Adventure` is being rebuilt as a Godot 4 + GDScript 2.5D/3D dark fantasy action-adventure. The original Python/Pygame prototype is preserved under `legacy_pygame/`.

## Current Production Build

Godot project:

```powershell
F:\study\Software_Engineering\Applications\Games\Windows\SinglePlayer\Adventure\ShroudedKeepAdventure\godot
```

Target executable:

```powershell
F:\study\Software_Engineering\Applications\Games\Windows\SinglePlayer\Adventure\ShroudedKeepAdventure\godot\export\windows\ShroudedKeepAdventure.exe
```

## Controls

- Move: `A/D` or left/right arrows
- Lane shift: `W/S` or up/down arrows
- Attack: `J` or left mouse
- Dodge: `K` or right mouse
- Interact: `E` or `Enter`
- Pause: `Esc`

## Implementation Contract

- Engine: Godot 4
- Language: GDScript
- Asset policy: strict CC0/public-domain only
- Commercial target: paid indie adventure in the $10-$30 range
- Runtime target: 2-3 hours after full content buildout
- Preview cadence during active development: launch a playable build every 30 minutes or less, keep it open for 5 minutes, close that preview process, and continue.

## Project Documents

- `ASSET_MANIFEST.md`: asset provenance and CC0 proof
- `STEAM_PACKAGE.md`: Steam page and marketing material plan
- `tools/preview-cycle.ps1`: launch/close/log preview cycle
- `tools/export-windows.ps1`: export Windows executable with Godot CLI
