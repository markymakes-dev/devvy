$ErrorActionPreference = 'SilentlyContinue'
$src = 'C:\Users\markl\.rustup'
$dst = 'V:\caches\.rustup'
if (-not (Test-Path $src)) { Write-Output 'src absent - nothing to do'; return }
robocopy $src $dst /E /MOVE /R:1 /W:1 /NFL /NDL /NP | Out-Null
$rc = $LASTEXITCODE
Write-Output ("robocopy rc={0}" -f $rc)
if ($rc -lt 8) {
    Remove-Item $src -Recurse -Force
    if (-not (Test-Path $src)) {
        New-Item -ItemType Junction -Path $src -Target $dst | Out-Null
        Write-Output 'JUNCTIONED'
    } else {
        Write-Output 'src still present - files locked; retry later'
    }
} else {
    Write-Output 'robocopy failures - leftovers remain, resume later'
}
Write-Output ("rustup.exe via junction: " + (Test-Path 'C:\Users\markl\.rustup\toolchains'))
