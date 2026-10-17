<#
.SYNOPSIS
    停止并卸载阅读服务器（保留数据目录可选）。
.EXAMPLE
    .\uninstall.ps1
    .\uninstall.ps1 -InstallDir D:\Reader -RemoveData
#>
[CmdletBinding()]
param(
    [string]$InstallDir = "C:\Reader",
    [string]$TaskName = "LegadoReader",
    [int]$Port = 8080,
    [switch]$RemoveData
)

$ErrorActionPreference = "Stop"

function Write-Step([string]$text) { Write-Host ("[*] " + $text) -ForegroundColor Cyan }
function Write-Ok([string]$text) { Write-Host ("[+] " + $text) -ForegroundColor Green }

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[x] 请以管理员身份运行 uninstall.bat" -ForegroundColor Red
    exit 1
}

$task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($task) {
    Write-Step "停止计划任务..."
    Stop-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    Write-Ok ("已删除计划任务 " + $TaskName)
} else {
    Write-Host ("[i] 未找到计划任务 " + $TaskName)
}

$ruleName = "LegadoReader " + $Port
$rule = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
if ($rule) {
    Remove-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
    Write-Ok ("已删除防火墙规则 " + $ruleName)
}

if (Test-Path $InstallDir) {
    if ($RemoveData) {
        Write-Step "删除整个安装目录（含数据）..."
        Remove-Item $InstallDir -Recurse -Force
        Write-Ok ("已删除 " + $InstallDir)
    } else {
        Write-Step "删除程序文件（保留 storage / logs）..."
        foreach ($item in @("runtime", "reader-cli.jar")) {
            $path = Join-Path $InstallDir $item
            if (Test-Path $path) { Remove-Item $path -Recurse -Force }
        }
        Write-Ok ("程序已移除，数据保留在 " + (Join-Path $InstallDir "storage"))
        Write-Host ("如需彻底删除，请手动删除目录: " + $InstallDir)
    }
}

Write-Host ""
Write-Host "卸载完成。"
