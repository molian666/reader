[CmdletBinding()]
param(
    [string]$TaskName = "LegadoReader",
    [int]$Port = 8080
)

$ErrorActionPreference = "Stop"

$task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if (-not $task) {
    Write-Host ("[x] 未找到计划任务 " + $TaskName) -ForegroundColor Red
    exit 1
}

Write-Host ("[*] 停止 " + $TaskName + " ...") -ForegroundColor Cyan
Stop-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

$running = $false
try {
    $resp = Invoke-WebRequest -Uri ("http://127.0.0.1:" + $Port + "/health") -UseBasicParsing -TimeoutSec 2
    if ($resp.StatusCode -eq 200) { $running = $true }
} catch {
}

if ($running) {
    Write-Host "[!] 端口仍在响应，可能有手动启动的 java 进程占用该端口。" -ForegroundColor Yellow
    exit 1
}

Write-Host "[+] 已停止" -ForegroundColor Green
