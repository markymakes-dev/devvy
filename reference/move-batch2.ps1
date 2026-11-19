$ErrorActionPreference = 'SilentlyContinue'
# mirror source layout under V: — home / local / roaming buckets
$pairs = @(
    @{ src = 'C:\Users\markl\AppData\Local\Android';        dst = 'V:\local\Android' },
    @{ src = 'C:\Users\markl\.vscode\extensions';           dst = 'V:\home\.vscode\extensions' },
    @{ src = 'C:\Users\markl\.cache';                       dst = 'V:\home\.cache' },
    @{ src = 'C:\Users\markl\AppData\Local\uv';             dst = 'V:\local\uv' },
    @{ src = 'C:\Users\markl\AppData\Roaming\npm';          dst = 'V:\roaming\npm' },
    @{ src = 'C:\Users\markl\AppData\Local\JetBrains';      dst = 'V:\local\JetBrains' },
    @{ src = 'C:\Users\markl\.konan';                       dst = 'V:\home\.konan' },
    @{ src = 'C:\Users\markl\AppData\Local\pip';            dst = 'V:\local\pip' },
    @{ src = 'C:\Users\markl\.nuget';                       dst = 'V:\home\.nuget' }
)

adb kill-server 2>$null | Out-Null

foreach ($p in $pairs) {
    $src = $p.src; $dst = $p.dst
    if (-not (Test-Path $src)) { Write-Output "SKIP (absent)  $src"; continue }
    $item = Get-Item $src -Force
    if ($item.LinkType) { Write-Output "SKIP (junction) $src"; continue }

    # process guard: anything EXECUTING from inside this tree must not be moved
    $procs = Get-Process | Where-Object { $_.Path -like "$src\*" }
    if ($procs) {
        Write-Output "DEFER (in use)  $src -> $($procs.Name -join ',')"
        continue
    }

    robocopy $src $dst /E /MOVE /R:1 /W:1 /NFL /NDL /NP | Out-Null
    $rc = $LASTEXITCODE
    if ($rc -lt 8) {
        Remove-Item $src -Recurse -Force
        if (-not (Test-Path $src)) {
            New-Item -ItemType Junction -Path $src -Target $dst | Out-Null
            Write-Output "MOVED + JUNCTION  $src -> $dst (rc=$rc)"
        } else {
            Write-Output "MOVED, NO JUNCTION (src handle busy)  $src (rc=$rc)"
        }
    } else {
        Write-Output "PARTIAL (robocopy rc=$rc)  $src — resume later"
    }
}

Write-Output ""
Write-Output "=== junction check ==="
foreach ($p in $pairs) {
    $j = Get-Item $p.src -Force
    if ($j.LinkType) { Write-Output ("{0} -> {1}" -f $j.FullName, $j.Target) }
}
Write-Output ("C: free GB: " + [math]::Round((Get-PSDrive C).Free / 1GB, 1))
Write-Output ("V: free GB: " + [math]::Round((Get-PSDrive V).Free / 1GB, 1))
