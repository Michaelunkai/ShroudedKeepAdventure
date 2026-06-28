# Shrouded Keep Adventure

`Shrouded Keep Adventure` is a small single-player dark fantasy adventure inspired by the supplied violet moonlit keep reference. You begin in the blue ravine, collect three moon seals, open the tower gate, and end the journey at the high moon gate.

## Run

After packaging, run:

```powershell
F:\study\Software_Engineering\Applications\Games\Windows\SinglePlayer\Adventure\ShroudedKeepAdventure\dist\ShroudedKeepAdventure.exe
```

## Controls

- Move: `WASD` or arrow keys
- Interact / attack / advance text: `Space` or `Enter`
- Restart after ending: `R`
- Quit: `Esc`

## Build

```powershell
python -m pip install -r requirements.txt
pyinstaller --noconfirm --onefile --windowed --name ShroudedKeepAdventure src\shrouded_keep_adventure.py
```

## Verify

```powershell
python src\shrouded_keep_adventure.py --smoke-test
dist\ShroudedKeepAdventure.exe --smoke-test
```
