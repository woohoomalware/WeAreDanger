$ErrorActionPreference = "Stop"

$SourceDir = $PSScriptRoot
$DestDir = "$env:APPDATA\USBArmyKnifeAgent"

if (-Not (Test-Path "$SourceDir\PortableApp.exe")) {
    Write-Host "Error: PortableApp.exe not found in the current directory."
    Write-Host "Please make sure it's in the same directory as this script."
    Read-Host -Prompt "Press Enter to exit"
    exit
}

Write-Host "Creating Agent directory in AppData..."
if (-Not (Test-Path $DestDir)) {
    New-Item -ItemType Directory -Path $DestDir -Force | Out-Null
}

Write-Host "Cleaning up old instances..."
$TaskName = "USBArmyKnife Agent"
schtasks /delete /tn $TaskName /f 2>$null
schtasks /delete /tn "\Security Script" /f 2>$null
Stop-Process -Name "PortableApp" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "rundll32" -Force -ErrorAction SilentlyContinue

Write-Host "Copying USBArmyKnife Agent to AppData..."
Copy-Item -Path "$SourceDir\*.exe" -Destination $DestDir -Force
if (Test-Path "$SourceDir\Uninstall-Agent.ps1") {
    Copy-Item -Path "$SourceDir\Uninstall-Agent.ps1" -Destination $DestDir -Force
}

Write-Host "Installing Scheduled Task..."
# Create scheduled task to run the agent every minute
$RunCommand = "`"$DestDir\PortableApp.exe`" vid=cafe,303a pid=403f,1001 cwd=`"$DestDir`""
schtasks /create /sc minute /mo 1 /tn $TaskName /tr $RunCommand /f

Write-Host "Registering in Add/Remove Programs..."
$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\USBArmyKnifeAgent"
if (-Not (Test-Path $RegPath)) {
    New-Item -Path $RegPath -Force | Out-Null
}
New-ItemProperty -Path $RegPath -Name "DisplayName" -Value "USBArmyKnife Agent" -PropertyType String -Force | Out-Null
New-ItemProperty -Path $RegPath -Name "DisplayVersion" -Value "1.0.0" -PropertyType String -Force | Out-Null
New-ItemProperty -Path $RegPath -Name "Publisher" -Value "USBArmyKnife" -PropertyType String -Force | Out-Null
$UninstallStr = "powershell.exe -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$DestDir\Uninstall-Agent.ps1`""
New-ItemProperty -Path $RegPath -Name "UninstallString" -Value $UninstallStr -PropertyType String -Force | Out-Null

Write-Host "Starting the Agent now..."
Start-Process -FilePath "$DestDir\PortableApp.exe" -ArgumentList "vid=cafe,303a pid=403f,1001 cwd=`"$DestDir`"" -WindowStyle Hidden

Write-Host "Agent deployed successfully! You can now view VNC in the Web UI."
Read-Host -Prompt "Press Enter to exit"
