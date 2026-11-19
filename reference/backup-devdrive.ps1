# Dev Drive backup: detach VHD -> copy to D:\backups -> re-attach -> trust.
# MUST be run while OpenCode is fully closed (script refuses otherwise).
# ETA ~10-15 min for ~75 GB to the D: HDD. Log: backup-devdrive.log next to this script.
$date = Get-Date -Format 'yyyyMMdd'
$dstDir = 'D:\backups'
$dst = Join-Path $dstDir "devdrive-$date.vhdx"

# --- self-elevate (diskpart + trust need admin) ---
$admin = (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $admin) {
    Start-Process pwsh -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File',"C:\Users\markl\devdrive-final-pass\backup-devdrive.ps1" -Wait
    exit
}
$ErrorActionPreference = 'Stop'
Start-Transcript -Path 'C:\Users\markl\devdrive-final-pass\backup-devdrive.log' -Force

# --- refuse while OpenCode is alive (open handles block a clean detach) ---
$oc = Get-Process -Name 'OpenCode' -ErrorAction SilentlyContinue
if ($oc) { Write-Output "REFUSING: OpenCode is running ($($oc.Count) processes). Close it first (Task Manager -> End process tree), then rerun."; Stop-Transcript; exit 1 }

$vhdx = 'C:\devdata\devdrive.vhdx'
New-Item -ItemType Directory -Force -Path $dstDir | Out-Null
if (Test-Path $dst) { Write-Output "Backup for today already exists: $dst - nothing to do."; Stop-Transcript; exit 0 }

Write-Output ("Source: " + $vhdx + "  (" + [math]::Round((Get-Item $vhdx).Length/1GB,1) + " GB)")

# --- 1. detach ---
@"
select vdisk file="$vhdx"
detach vdisk
"@ | Set-Content 'C:\devdata\backup-step1.txt' -Encoding ascii
diskpart /s 'C:\devdata\backup-step1.txt'

# --- 2. copy ---
Write-Output "Copying to $dst ..."
robocopy 'C:\devdata' $dstDir 'devdrive.vhdx' /R:2 /W:5 /NP | Out-Null
if ($LASTEXITCODE -ge 8) { Write-Output "COPY FAILED rc=$($LASTEXITCODE) - re-attaching V: now, no backup written."; diskpart /s 'C:\devdata\backup-step3.txt'; Stop-Transcript; exit 1 }
Move-Item (Join-Path $dstDir 'devdrive.vhdx') $dst

# --- 3. verify copy, then re-attach ---
$srcGB = [math]::Round((Get-Item $vhdx).Length/1GB,2)
$dstGB = [math]::Round((Get-Item $dst).Length/1GB,2)
Write-Output "Source $srcGB GB  ->  Backup $dstGB GB"
@"
select vdisk file="$vhdx"
attach vdisk
assign letter=V
"@ | Set-Content 'C:\devdata\backup-step3.txt' -Encoding ascii
diskpart /s 'C:\devdata\backup-step3.txt'

# --- 4. trust + verify ---
fsutil devdrv trust V:
$drv = Get-PSDrive V -ErrorAction SilentlyContinue
if (-not $drv) { Write-Output "WARNING: V: did not come back! Run the DevDriveAttach scheduled task or attach manually."; Stop-Transcript; exit 1 }
Write-Output ("V: back online, free GB: " + [math]::Round($drv.Free/1GB,1))
if ($srcGB -eq $dstGB) { Write-Output "BACKUP OK  ($dst)" } else { Write-Output "BACKUP SIZE MISMATCH - check $dst" }
Stop-Transcript
