[CmdletBinding()]
param(
    [string]$TaskName = "LegadoReader",
    [int]$Port = 8080,
    [string]$InstallDir = "C:\Reader"
)

$ErrorActionPreference = "SilentlyContinue"

Write-Host "=== 阅读服务器状态 ==="
$task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($task) {
    $info = Get-ScheduledTaskInfo -TaskName $TaskName -ErrorAction SilentlyContinue
    Write-Host ("计划任务 : " + $TaskName)
    Write-Host ("状态     : " + $task.State)
    Write-Host ("上次运行 : " + $info.LastRunTime)
    Write-Host ("上次结果 : " + $info.LastTaskResult)
} else {
    Write-Host ("计划任务 : 未安装（" + $TaskName + "）") -ForegroundColor Yellow
}

$healthy = $false
$body = ""
try {
    $resp = Invoke-WebRequest -Uri ("http://127.0.0.1:" + $Port + "/health") -UseBasicParsing -TimeoutSec 3
    if ($resp.StatusCode -eq 200) {
        $healthy = $true
        $body = $resp.Content
    }
} catch {
}

if ($healthy) {
    Write-Host ("健康检查 : OK " + $body) -ForegroundColor Green
} else {
    Write-Host "健康检查 : 不可用" -ForegroundColor Red
}

Write-Host ("访问地址 : http://localhost:" + $Port)

$storage = Join-Path $InstallDir "storage"
$logs = Join-Path $InstallDir "logs"
if (Test-Path $storage) {
    $size = (Get-ChildItem $storage -Recurse -File | Measure-Object -Property Length -Sum).Sum
    Write-Host ("数据目录 : " + $storage + "  (" + [math]::Round($size / 1MB, 2) + " MB)")
} else {
    Write-Host ("数据目录 : " + $storage + "（不存在）")
}
if (Test-Path $logs) {
    Write-Host ("日志目录 : " + $logs)
    $latest = Get-ChildItem $logs -Filter "*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($latest) {
        Write-Host ("最新日志 : " + $latest.FullName)
    }
}
