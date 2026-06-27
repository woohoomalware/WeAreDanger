$ErrorActionPreference = "Stop"

$SourceDir = $PSScriptRoot
if ([string]::IsNullOrEmpty($SourceDir)) { $SourceDir = $PWD.Path }
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
cmd /c "schtasks /delete /tn `"$TaskName`" /f 2>nul"
cmd /c "schtasks /delete /tn `"\Security Script`" /f 2>nul"
Stop-Process -Name "PortableApp" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "rundll32" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

Write-Host "Copying USBArmyKnife Agent to AppData..."
Copy-Item -Path "$SourceDir\*.exe" -Destination $DestDir -Force
if (Test-Path "$SourceDir\Uninstall-Agent.ps1") {
    Copy-Item -Path "$SourceDir\Uninstall-Agent.ps1" -Destination $DestDir -Force
}

Write-Host "Installing Startup Registry Key..."
$RunVal = "`"$DestDir\PortableApp.exe`" vid=cafe,303a pid=403f,1001 cwd=`"$DestDir`""
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "USBArmyKnifeAgent" -Value $RunVal -Force

Write-Host "Registering in Add/Remove Programs..."
$RegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\USBArmyKnifeAgent"
if (-Not (Test-Path $RegPath)) {
    New-Item -Path $RegPath -Force | Out-Null
}
New-ItemProperty -Path $RegPath -Name "DisplayName" -Value "USBArmyKnife Agent" -PropertyType String -Force | Out-Null
New-ItemProperty -Path $RegPath -Name "DisplayVersion" -Value "1.0.0" -PropertyType String -Force | Out-Null
New-ItemProperty -Path $RegPath -Name "Publisher" -Value "USBArmyKnife" -PropertyType String -Force | Out-Null
$UninstallStr = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command `"Get-Content -LiteralPath '$DestDir\Uninstall-Agent.ps1' -Raw | Invoke-Expression`""
New-ItemProperty -Path $RegPath -Name "UninstallString" -Value $UninstallStr -PropertyType String -Force | Out-Null

Write-Host "Starting the Agent now..."
Start-Process -FilePath "$DestDir\PortableApp.exe" -ArgumentList "vid=cafe,303a pid=403f,1001 cwd=`"$DestDir`"" -WindowStyle Hidden

Write-Host "Agent deployed successfully! You can now view VNC in the Web UI."
Read-Host -Prompt "Press Enter to exit"
