$ErrorActionPreference = 'Continue'
# One-time migration pass driven remotely. Excludes trees owned by live
# OpenCode sessions (cwd handles are invisible to Get-Process).
$script:EXCLUDE = @('Shifts', 'repogrep')

try { gradle --stop 2>&1 | Out-Null; "gradle daemons stopped (or none running)" } catch { "gradle not on PATH - skipping daemon stop" }

"=== processes running FROM the move set (their trees will be skipped) ==="
$procPaths = (Get-Process | Where-Object Path).Path

function Move-Tree([string]$src, [string]$dst) {
  if (-not (Test-Path $src)) { "SKIP(absent)       $src"; return }
  if (Test-Path $dst)       { "SKIP(dst-exists)   $src"; return }
  $holders = $procPaths | Where-Object { $_ -like ($src + '\*') } | Select-Object -First 2
  if ($holders) { "SKIP(in-use)       $src  <- $($holders -join ' | ')"; return }
  New-Item -ItemType Directory -Force -Path (Split-Path $dst) | Out-Null
  $null = robocopy $src $dst /E /MOVE /R:1 /W:1 /NFL /NDL /NP
  $rc = $LASTEXITCODE
  if ($rc -ge 8) { "FAIL(rc=$rc)       $src"; return }
  if (Test-Path $src) { Remove-Item $src -Recurse -Force -ErrorAction SilentlyContinue }
  if (Test-Path $src) { "BUSY(left intact)  $src  (copy on $dst; re-run later)"; return }
  New-Item -ItemType Junction -Path $src -Target $dst | Out-Null
  "MOVED+junction    $src -> $dst"
}

"=== migrating C:\dev children (excluding live-session trees: $($script:EXCLUDE -join ', ')) ==="
Get-ChildItem 'C:\dev' -Directory | Where-Object { $script:EXCLUDE -notcontains $_.Name } | ForEach-Object {
  Move-Tree $_.FullName ("V:\dev\" + $_.Name)
}

"=== migrating caches ==="
Move-Tree "$env:USERPROFILE\.gradle"      'V:\caches\.gradle'
Move-Tree "$env:USERPROFILE\.bun"         'V:\caches\.bun'
Move-Tree "$env:USERPROFILE\.m2"          'V:\caches\.m2'
Move-Tree "$env:LOCALAPPDATA\pnpm"        'V:\caches\pnpm'
Move-Tree "$env:LOCALAPPDATA\npm-cache"   'V:\caches\npm-cache'

"=== verify ==="
$bytes = New-Object byte[] (200MB)
foreach ($f in @('V:\speedtest.bin', (Join-Path $env:TEMP 'speedtest-c.bin'))) {
  $t = Measure-Command { [IO.File]::WriteAllBytes($f, $bytes) }
  "  write " + $f + " : " + [math]::Round(200 / $t.TotalSeconds, 0) + " MB/s"
  Remove-Item $f -Force -ErrorAction SilentlyContinue
}
"  C: free: " + [math]::Round((Get-Volume C).SizeRemaining/1GB,1) + " GB"
"  V: free: " + [math]::Round((Get-Volume V).SizeRemaining/1GB,1) + " GB"
"=== junctions in C:\dev ==="
Get-ChildItem 'C:\dev' -Directory | Where-Object { $_.LinkType -eq 'Junction' } | ForEach-Object { "  " + $_.FullName + " -> " + ($_.Target -join '') }
"=== still on C: (final pass after closing OpenCode) ==="
Get-ChildItem 'C:\dev' -Directory | Where-Object { $_.LinkType -ne 'Junction' } | ForEach-Object { "  " + $_.Name }
