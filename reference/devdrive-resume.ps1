$ErrorActionPreference = 'Continue'
# Resume pass: idempotent. Junctioned trees are never touched; partial trees
# resume; clean trees get their junction.
$script:EXCLUDE = @('Shifts', 'repogrep')
$script:procPaths = (Get-Process | Where-Object Path).Path

function Move-Tree([string]$src, [string]$dst) {
  if (-not (Test-Path $src)) { "SKIP(absent)        $src"; return }
  $item = Get-Item $src -Force
  if ($item.LinkType) { "SKIP(junction-ok)   $src"; return }
  $holders = $script:procPaths | Where-Object { $_ -like ($src + '\*') } | Select-Object -First 2
  if ($holders) { "SKIP(in-use)        $src  <- $($holders -join ' | ')"; return }
  New-Item -ItemType Directory -Force -Path (Split-Path $dst) | Out-Null
  $out = robocopy $src $dst /E /MOVE /R:1 /W:1 /NFL /NDL /NP 2>&1
  $rc = $LASTEXITCODE
  $errs = @($out | Where-Object { $_ -match 'ERROR' } | Select-Object -First 3)
  if ($errs) { "  errors in ${src}:"; $errs | ForEach-Object { "    $_" } }
  if ($rc -ge 8 -and -not $errs) { "  robocopy rc=$rc (no ERROR lines captured) for $src" }
  if (Test-Path $src) {
    $left = @(Get-ChildItem $src -Recurse -Force -ErrorAction SilentlyContinue)
    if ($left.Count -gt 0) {
      "PARTIAL            $src  ($($left.Count) items left; copy on $dst)"
      $left | Select-Object -First 3 | ForEach-Object { "    left: $($_.FullName)" }
      return
    }
    Remove-Item $src -Force -ErrorAction SilentlyContinue
    if (Test-Path $src) { "BUSY(dir-handle)   $src  (empty; junction after close)"; return }
  }
  New-Item -ItemType Junction -Path $src -Target $dst | Out-Null
  "MOVED+junction     $src -> $dst"
}

"=== dev trees (excluding live-session trees: $($script:EXCLUDE -join ', ')) ==="
Get-ChildItem 'C:\dev' -Directory | Where-Object { $script:EXCLUDE -notcontains $_.Name } | ForEach-Object {
  Move-Tree $_.FullName ("V:\dev\" + $_.Name)
}

"=== caches ==="
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
