$ErrorActionPreference = 'SilentlyContinue'
$targets = @(
    'C:\Users\markl\.ollama',
    'C:\Users\markl\.nuget',
    'C:\Users\markl\.dotnet',
    'C:\Users\markl\.pub-cache',
    'C:\Users\markl\.pub',
    'C:\Users\markl\.dart',
    'C:\Users\markl\.dart-tool',
    'C:\Users\markl\.konan',
    'C:\Users\markl\go',
    'C:\Users\markl\vcpkg',
    'C:\Users\markl\.cabal',
    'C:\Users\markl\.stack',
    'C:\Users\markl\.gem',
    'C:\Users\markl\.cache',
    'C:\Users\markl\.vscode\extensions',
    'C:\Users\markl\.terraform.d',
    'C:\Users\markl\.kube',
    "$env:LOCALAPPDATA\pip",
    "$env:LOCALAPPDATA\uv",
    "$env:LOCALAPPDATA\pypoetry",
    "$env:LOCALAPPDATA\deno",
    "$env:LOCALAPPDATA\Volta",
    "$env:LOCALAPPDATA\go-build",
    "$env:LOCALAPPDATA\Android",
    "$env:LOCALAPPDATA\JetBrains",
    "$env:LOCALAPPDATA\nvm",
    "$env:LOCALAPPDATA\Yarn",
    "$env:LOCALAPPDATA\Parcel",
    "$env:APPDATA\npm",
    "$env:APPDATA\nvm",
    "$env:APPDATA\Composer",
    "$env:APPDATA\stack",
    "$env:APPDATA\cabal"
)
$found = @()
foreach ($t in $targets) {
    if (Test-Path $t) {
        $bytes = 0
        Get-ChildItem $t -Recurse -Force -File | ForEach-Object { $bytes += $_.Length }
        $found += [PSCustomObject]@{ Path = $t; MB = [math]::Round($bytes / 1MB) }
    }
}
$found | Sort-Object MB -Descending | ForEach-Object { Write-Output ("{0,8} MB  {1}" -f $_.MB, $_.Path) }
if ($found.Count -eq 0) { Write-Output 'none of the candidate caches exist' }
Write-Output ""
Write-Output ("C: free GB: " + [math]::Round((Get-PSDrive C).Free / 1GB, 1))
Write-Output ("V: free GB: " + [math]::Round((Get-PSDrive V).Free / 1GB, 1))
