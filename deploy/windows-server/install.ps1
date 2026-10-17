<#
.SYNOPSIS
    阅读服务器（Legado Reader）Windows 一键部署脚本。
.DESCRIPTION
    适用于 Windows Server 2012 R2 / 2016 / 2019 / 2022（x64，PowerShell 4.0+）。
    默认从 GitHub Release 下载服务端 jar 和精简 JRE，注册为开机自启的计划任务，
    并开放防火墙端口。也可离线部署：把 reader-cli-2.5.4.jar 和
    reader-runtime-win64.zip 放在脚本同目录即可。
.PARAMETER InstallDir
    安装目录，默认 C:\Reader。
.PARAMETER Port
    服务端口，默认 8080。
.PARAMETER TaskName
    计划任务名称，默认 LegadoReader。
.PARAMETER JarPath
    本地 reader-cli jar 路径（离线部署时可指定）。
.PARAMETER RuntimeZip
    本地 JRE 压缩包路径（离线部署时可指定）。
.PARAMETER DownloadBase
    在线下载地址前缀，默认当前 Release。
.PARAMETER NoFirewall
    不创建防火墙规则。
.EXAMPLE
    .\install.ps1 -Port 8080
.EXAMPLE
    .\install.ps1 -InstallDir D:\Reader -Port 9000
#>
[CmdletBinding()]
param(
    [string]$InstallDir = "C:\Reader",
    [int]$Port = 8080,
    [string]$TaskName = "LegadoReader",
    [string]$JarPath = "",
    [string]$RuntimeZip = "",
    [string]$DownloadBase = "https://github.com/molian666/reader/releases/download/v2.5.4",
    [switch]$NoFirewall,
    [switch]$Secure,
    [string]$SecureKey = "",
    [string]$InviteCode = ""
)

$ErrorActionPreference = "Stop"
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
} catch {
    # Server 2012 R2 默认支持 TLS 1.2；个别老系统忽略即可
}

function Write-Step([string]$text) {
    Write-Host ("[*] " + $text) -ForegroundColor Cyan
}
function Write-Ok([string]$text) {
    Write-Host ("[+] " + $text) -ForegroundColor Green
}
function Fail([string]$text) {
    Write-Host ("[x] " + $text) -ForegroundColor Red
    exit 1
}

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Fail "请以管理员身份运行：右键 install.bat -> 以管理员身份运行"
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrEmpty($JarPath)) {
    $candidate = Join-Path $scriptDir "reader-cli-2.5.4.jar"
    if (Test-Path $candidate) { $JarPath = $candidate }
}
if ([string]::IsNullOrEmpty($RuntimeZip)) {
    $candidate = Join-Path $scriptDir "reader-runtime-win64.zip"
    if (Test-Path $candidate) { $RuntimeZip = $candidate }
}

Write-Step ("安装目录: " + $InstallDir)
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
$storageDir = Join-Path $InstallDir "storage"
$logsDir = Join-Path $InstallDir "logs"
New-Item -ItemType Directory -Force -Path $storageDir | Out-Null
New-Item -ItemType Directory -Force -Path $logsDir | Out-Null

$javaExe = Join-Path $InstallDir "runtime\bin\java.exe"
$runtimeDir = Join-Path $InstallDir "runtime"

# 1. 运行时
if (-not (Test-Path $javaExe)) {
    if ([string]::IsNullOrEmpty($RuntimeZip)) {
        $RuntimeZip = Join-Path $env:TEMP "reader-runtime-win64.zip"
        Write-Step "下载精简 JRE（约 41MB）..."
        try {
            Invoke-WebRequest -Uri ($DownloadBase + "/reader-runtime-win64.zip") -OutFile $RuntimeZip -UseBasicParsing
        } catch {
            Fail ("下载 JRE 失败: " + $_.Exception.Message + "`n可手动下载 reader-runtime-win64.zip 放到脚本目录后重试。")
        }
    }
    Write-Step "解压运行时..."
    if (Test-Path $runtimeDir) { Remove-Item $runtimeDir -Recurse -Force }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    try {
        [IO.Compression.ZipFile]::ExtractToDirectory($RuntimeZip, $InstallDir)
    } catch {
        Fail ("解压运行时失败: " + $_.Exception.Message)
    }
}
if (-not (Test-Path $javaExe)) {
    Fail ("运行时目录不完整，未找到 " + $javaExe)
}
Write-Ok "JRE 就绪"

# 2. 服务端 jar
if ([string]::IsNullOrEmpty($JarPath)) {
    $JarPath = Join-Path $env:TEMP "reader-cli-2.5.4.jar"
    Write-Step "下载服务端 jar（约 38MB）..."
    try {
        Invoke-WebRequest -Uri ($DownloadBase + "/reader-cli-2.5.4.jar") -OutFile $JarPath -UseBasicParsing
    } catch {
        Fail ("下载服务端 jar 失败: " + $_.Exception.Message + "`n可手动下载 reader-cli-2.5.4.jar 放到脚本目录后重试。")
    }
}
$targetJar = Join-Path $InstallDir "reader-cli.jar"
Copy-Item $JarPath $targetJar -Force
Write-Ok ("服务端已复制: " + $targetJar)

# 3. 重建计划任务
$existing = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($existing) {
    Write-Step "停止并删除旧任务..."
    Stop-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

$javaArgs = '-Djava.awt.headless=true -Dreader.app.showUI=false -Xms256m -Xmx1024m ' +
    ('-Dlogging.path="{0}" ' -f $logsDir) +
    ('-jar "{0}" ' -f $targetJar) +
    ('--reader.server.port={0} ' -f $Port) +
    ('--reader.server.webUrl=http://localhost:{0} ' -f $Port) +
    ('--reader.app.storagePath="{0}"' -f $storageDir)

if ($Secure) {
    $javaArgs += ' --reader.app.secure=true'
    if ($SecureKey -ne "") {
        $javaArgs += (' --reader.app.secureKey="{0}"' -f $SecureKey)
    }
    if ($InviteCode -ne "") {
        $javaArgs += (' --reader.app.inviteCode="{0}"' -f $InviteCode)
    }
}

Write-Step "注册计划任务（开机自启，SYSTEM 账户）..."
$action = New-ScheduledTaskAction -Execute $javaExe -Argument $javaArgs
$trigger = New-ScheduledTaskTrigger -AtStartup
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -MultipleInstances IgnoreNew `
    -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1) -ExecutionTimeLimit ([TimeSpan]::Zero)
$taskPrincipal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings `
    -Principal $taskPrincipal -Description "Legado Reader 阅读服务器" -Force | Out-Null
Write-Ok ("计划任务已创建: " + $TaskName)

# 4. 防火墙
if (-not $NoFirewall) {
    $ruleName = "LegadoReader " + $Port
    Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue | Remove-NetFirewallRule -ErrorAction SilentlyContinue
    New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -Protocol TCP -LocalPort $Port -Action Allow | Out-Null
    Write-Ok ("防火墙已放行 TCP " + $Port)
}

# 5. 启动并等待
Write-Step "启动服务..."
Start-ScheduledTask -TaskName $TaskName
$healthy = $false
for ($i = 0; $i -lt 40; $i++) {
    Start-Sleep -Seconds 2
    try {
        $resp = Invoke-WebRequest -Uri ("http://127.0.0.1:" + $Port + "/health") -UseBasicParsing -TimeoutSec 2
        if ($resp.StatusCode -eq 200) { $healthy = $true; break }
    } catch {
        # 继续等待
    }
}

if ($healthy) {
    Write-Ok "部署完成，服务已启动"
} else {
    Write-Host ""
    Write-Host "[!] 服务启动超时，请检查：" -ForegroundColor Yellow
    Write-Host ("    任务状态: Get-ScheduledTask -TaskName " + $TaskName)
    Write-Host ("    运行日志: " + (Join-Path $logsDir "spring.log"))
    Write-Host ("    控制台日志: " + (Join-Path $logsDir "console.log"))
}
Write-Host ""
Write-Host ("访问地址: http://<服务器IP>:" + $Port)
Write-Host ("数据目录: " + $storageDir)
Write-Host ("日志目录: " + $logsDir)
Write-Host ("开机自启: 计划任务 " + $TaskName)
Write-Host "管理命令: start.bat / stop.bat / status.bat / uninstall.bat"
