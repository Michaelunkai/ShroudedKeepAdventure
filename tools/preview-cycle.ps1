param(
  [string]$ExePath = "F:\study\Software_Engineering\Applications\Games\Windows\SinglePlayer\Adventure\ShroudedKeepAdventure\godot\export\windows\ShroudedKeepAdventure.exe",
  [int]$Seconds = 300,
  [string]$LogPath = "F:\study\Software_Engineering\Applications\Games\Windows\SinglePlayer\Adventure\ShroudedKeepAdventure\preview-log.jsonl"
)

$ErrorActionPreference = "Stop"
if (-not (Test-Path -LiteralPath $ExePath)) {
  throw "Preview executable does not exist: $ExePath"
}

$startedAt = Get-Date
$process = Start-Process -FilePath $ExePath -PassThru
Start-Sleep -Seconds $Seconds
if (-not $process.HasExited) {
  $process.CloseMainWindow() | Out-Null
  Start-Sleep -Seconds 5
}
if (-not $process.HasExited) {
  $process.Kill()
  $process.WaitForExit()
}

$exitCode = $null
try {
  $exitCode = $process.ExitCode
} catch {
  $exitCode = "unknown"
}

$entry = [ordered]@{
  timestamp = $startedAt.ToString("o")
  exePath = $ExePath
  secondsOpen = $Seconds
  processId = $process.Id
  exitCode = $exitCode
}
($entry | ConvertTo-Json -Compress) | Add-Content -LiteralPath $LogPath
Write-Host "PREVIEW_CYCLE_COMPLETE $ExePath"
exit 0
