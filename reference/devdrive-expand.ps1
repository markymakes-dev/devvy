# Self-elevating Dev Drive expansion 80GB -> 120GB. Params baked (no env across UAC).
$admin = (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $admin) {
    Start-Process pwsh -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File',"C:\Users\markl\AppData\Local\Temp\opencode\devdrive-expand.ps1" -Wait
    exit
}
$ErrorActionPreference = 'Stop'
Start-Transcript -Path 'C:\Users\markl\AppData\Local\Temp\opencode\devdrive-expand.log' -Force

$vhdx = 'C:\devdata\devdrive.vhdx'
$stepdir = 'C:\Users\markl\AppData\Local\Temp\opencode'

# Step 1: detach (expand requires the vdisk to be detached)
@"
select vdisk file="$vhdx"
detach vdisk
"@ | Set-Content "$stepdir\expand-step1.txt" -Encoding ascii
diskpart /s "$stepdir\expand-step1.txt"

# Step 2: expand container to 120 GB
@"
select vdisk file="$vhdx"
expand vdisk maximum=122880
"@ | Set-Content "$stepdir\expand-step2.txt" -Encoding ascii
diskpart /s "$stepdir\expand-step2.txt"

# Step 3: re-attach + assign V:
@"
select vdisk file="$vhdx"
attach vdisk
assign letter=V
"@ | Set-Content "$stepdir\expand-step3.txt" -Encoding ascii
diskpart /s "$stepdir\expand-step3.txt"

# Step 4: grow the ReFS volume into the new space
@"
select volume V
extend
"@ | Set-Content "$stepdir\expand-step4.txt" -Encoding ascii
diskpart /s "$stepdir\expand-step4.txt"

# Step 5: re-assert trust (idempotent if already trusted)
fsutil devdrv trust V:

# Step 6: verify
fsutil devdrv query V:
$drv = Get-PSDrive V
Write-Output ("V: total GB: " + [math]::Round(($drv.Used + $drv.Free) / 1GB, 1))
Write-Output ("V: free  GB: " + [math]::Round($drv.Free / 1GB, 1))
Write-Output "EXPAND OK"
Stop-Transcript
