param(
  [string]$GodotExe,
  [string]$ProjectPath = "F:\study\Software_Engineering\Applications\Games\Windows\SinglePlayer\Adventure\ShroudedKeepAdventure\godot"
)

$ErrorActionPreference = "Stop"
if (-not $GodotExe) {
  $cmd = Get-Command godot -ErrorAction SilentlyContinue
  if (-not $cmd) { $cmd = Get-Command godot4 -ErrorAction SilentlyContinue }
  if (-not $cmd) { throw "Godot executable not found. Pass -GodotExe." }
  $GodotExe = $cmd.Source
}

New-Item -ItemType Directory -Force -Path (Join-Path $ProjectPath "export\windows") | Out-Null
& $GodotExe --headless --path $ProjectPath --export-release "Windows Desktop"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$exe = Join-Path $ProjectPath "export\windows\ShroudedKeepAdventure.exe"
if (-not (Test-Path -LiteralPath $exe)) { throw "Export did not create $exe" }
Get-Item -LiteralPath $exe | Select-Object FullName,Length
