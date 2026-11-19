$ErrorActionPreference = 'SilentlyContinue'
$busy = Get-Process -Name cargo,rustc,rustup,rust-analyzer
if ($busy) { Write-Output ("BUSY: " + ($busy.Name -join ',')); return }

$pairs = @(
    @{ src = 'C:\Users\markl\.cargo';  dst = 'V:\caches\.cargo' },
    @{ src = 'C:\Users\markl\.rustup'; dst = 'V:\caches\.rustup' }
)

foreach ($p in $pairs) {
    $src = $p.src; $dst = $p.dst
    robocopy $src $dst /E /MOVE /R:1 /W:1 /NFL /NDL /NP | Out-Null
    $rc = $LASTEXITCODE
    $left = @(Get-ChildItem $src -Recurse -Force)
    Write-Output ("{0} : rc={1}, leftovers={2}" -f $src, $rc, $left.Count)
    if ($left.Count -eq 0) {
        Remove-Item $src -Force
        if (-not (Test-Path $src)) {
            New-Item -ItemType Junction -Path $src -Target $dst | Out-Null
            Write-Output ("  -> JUNCTIONED to " + $dst)
        } else {
            Write-Output "  -> source handle busy; final pass"
        }
    }
}

Write-Output ""
Write-Output "=== verify ==="
foreach ($p in @('C:\Users\markl\.cargo','C:\Users\markl\.rustup')) {
    $j = Get-Item $p -Force
    Write-Output ("{0}  {1} -> {2}" -f $j.LinkType, $p, $j.Target)
}
Write-Output ("cargo.exe reachable through junction: " + (Test-Path 'C:\Users\markl\.cargo\bin\cargo.exe'))
