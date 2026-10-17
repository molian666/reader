[CmdletBinding()]
param(
    [string]$TaskName = "LegadoReader",
    [int]$Port = 8080
)

$ErrorActionPreference = "Stop"

$task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if (-not $task) {
    Write-Host ("[x] 未找到计划任务 " + $TaskName + "，请先运行 install.bat") -ForegroundColor Red
    exit 1
}

Write-Host ("[*] 启动 " + $TaskName + " ...") -ForegroundColor Cyan
Start-ScheduledTask -TaskName $TaskName

$healthy = $false
for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Seconds 2
    try {
        $resp = Invoke-WebRequest -Uri ("http://127.0.0.1:" + $Port + "/health") -UseBasicParsing -TimeoutSec 2
        if ($resp.StatusCode -eq 200) { $healthy = $true; break }
    } catch {
    }
}

if ($healthy) {
    Write-Host ("[+] 已启动: http://localhost:" + $Port) -ForegroundColor Green
} else {
    Write-Host "[!] 启动超时，请运行 status.bat 查看状态或检查日志。" -ForegroundColor Yellow
    exit 1
}
