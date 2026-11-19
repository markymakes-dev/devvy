# Dev Drive final pass - run ONLY after OpenCode is fully closed.
# Moves the last 4 trees into V: and junctions them. Idempotent + resumable.
# No admin needed. Log: C:\Users\markl\devdrive-final-pass\final-pass.log
$ErrorActionPreference = 'Continue'

# Guard: refuse to run while OpenCode is alive (it holds .cache + npm-cache + session cwds)
$oc = Get-Process | Where-Object { $_.ProcessName -like 'opencode*' }
if ($oc) {
    Write-Output ("REFUSING to run: OpenCode is still running (" + (($oc | Select-Object -ExpandProperty ProcessName -Unique) -join ', ') + ").")
    Write-Output "Close OpenCode completely, then run this script again."
    if ($Host.Name -eq 'ConsoleHost') { Read-Host 'Press Enter to close' | Out-Null }
    exit 1
}

Start-Transcript -Path 'C:\Users\markl\devdrive-final-pass\final-pass.log' -Force

$pairs = @(
    @{ src = 'C:\Users\markl\.cache';                      dst = 'V:\home\.cache' },
    @{ src = 'C:\Users\markl\AppData\Local\npm-cache';     dst = 'V:\caches\npm-cache' },
    @{ src = 'C:\dev\Shifts';                              dst = 'V:\dev\Shifts' },
    @{ src = 'C:\dev\repogrep';                            dst = 'V:\dev\repogrep' }
)

foreach ($p in $pairs) {
    $src = $p.src; $dst = $p.dst
    Write-Output "=== $src"

    # Already a junction? Skip.
    $item = Get-Item $src -Force -ErrorAction SilentlyContinue
    if ($item -and ($item.LinkType -eq 'Junction')) { Write-Output 'SKIP: already junctioned'; continue }

    # Source missing? Skip (already moved by an earlier run, pre-junction crash).
    if (-not (Test-Path $src)) { Write-Output 'SKIP: source absent (earlier run moved it)'; continue }

    # Guard: anything still running from inside the tree? Defer.
    $busy = Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.Path -like "$src\*" }
    if ($busy) { Write-Output ("DEFER: in use by " + (($busy | Select-Object -ExpandProperty ProcessName -Unique) -join ', ')); continue }

    New-Item -ItemType Directory -Force -Path $dst | Out-Null
    robocopy $src $dst /E /MOVE /R:1 /W:1 /NFL /NDL /NJH | Out-Null
    $rc = $LASTEXITCODE
    if ($rc -ge 8) { Write-Output "DEFER: robocopy rc=$rc (files locked) - rerun this script later"; continue }

    # Move complete: remove the leftover empty source dir, then junction.
    Remove-Item $src -Recurse -Force -ErrorAction SilentlyContinue
    if (Test-Path $src) {
        Write-Output "PARTIAL: files still locked at $src - close the holding apps and rerun. No junction created."
        continue
    }
    New-Item -ItemType Junction -Path $src -Target $dst | Out-Null
    Write-Output "MOVED + JUNCTION  ($src -> $dst)"
}

Write-Output ''
Write-Output '--- Junction check ---'
foreach ($p in $pairs) {
    $item = Get-Item $p.src -Force -ErrorAction SilentlyContinue
    if ($item -and ($item.LinkType -eq 'Junction')) { Write-Output "OK  $($p.src) -> $((Get-Item $p.src).Target)" }
    else { Write-Output "PENDING  $($p.src)" }
}

$drv = Get-PSDrive V
Write-Output ("V: total GB: " + [math]::Round(($drv.Used + $drv.Free) / 1GB, 1) + "   free GB: " + [math]::Round($drv.Free / 1GB, 1))
Write-Output 'FINAL PASS DONE - if any PENDING lines remain, close more apps and rerun.'
Stop-Transcript
