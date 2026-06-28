import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "src" / "shrouded_keep_adventure.py"
EXE = ROOT / "dist" / "ShroudedKeepAdventure.exe"


def run_smoke(target):
    result = subprocess.run([str(target), "--smoke-test"], cwd=ROOT, text=True, capture_output=True, timeout=20)
    assert result.returncode == 0, result.stderr or result.stdout
    assert "SMOKE_OK" in result.stdout


def main():
    run_smoke(sys.executable)


if __name__ == "__main__":
    result = subprocess.run([sys.executable, str(SOURCE), "--smoke-test"], cwd=ROOT, text=True, capture_output=True, timeout=20)
    if result.returncode != 0 or "SMOKE_OK" not in result.stdout:
        print(result.stdout)
        print(result.stderr, file=sys.stderr)
        raise SystemExit(result.returncode or 1)
    if EXE.exists():
        run_smoke(EXE)
    print("SMOKE_OK")
