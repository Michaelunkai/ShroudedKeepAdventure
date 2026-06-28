$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$ToolDir = Join-Path $Root "tools\godot"
$RuntimeZip = Join-Path $ToolDir "Godot_v4.7-stable_win64.exe.zip"
$TemplateZip = Join-Path $ToolDir "Godot_v4.7-stable_export_templates.tpz"
$TemplateZipAlias = Join-Path $ToolDir "Godot_v4.7-stable_export_templates.zip"
$TemplateExtract = Join-Path $ToolDir "export_templates_extract"
$TemplateTarget = Join-Path $env:APPDATA "Godot\export_templates\4.7.stable"

if (-not (Test-Path -LiteralPath $RuntimeZip)) { throw "Missing runtime zip: $RuntimeZip" }
if (-not (Test-Path -LiteralPath $TemplateZip)) { throw "Missing export template zip: $TemplateZip" }

Expand-Archive -LiteralPath $RuntimeZip -DestinationPath $ToolDir -Force
Copy-Item -LiteralPath $TemplateZip -Destination $TemplateZipAlias -Force
Expand-Archive -LiteralPath $TemplateZipAlias -DestinationPath $TemplateExtract -Force
New-Item -ItemType Directory -Force -Path $TemplateTarget | Out-Null
Copy-Item -Path (Join-Path $TemplateExtract "templates\*") -Destination $TemplateTarget -Recurse -Force

$GodotExe = Join-Path $ToolDir "Godot_v4.7-stable_win64.exe"
if (-not (Test-Path -LiteralPath $GodotExe)) { throw "Godot executable was not extracted: $GodotExe" }

& $GodotExe --version
Write-Host "GODOT_EXE=$GodotExe"
Write-Host "TEMPLATES=$TemplateTarget"
