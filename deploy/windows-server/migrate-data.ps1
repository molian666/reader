<#
.SYNOPSIS
    把旧版阅读服务器的 storage 数据迁移到新部署目录。
.DESCRIPTION
    支持两种来源：
      1) 新版目录结构：<Source>\data\<用户>\...
      2) 旧版扁平结构：<Source>\bookshelf.json、bookSource.json、localStore\、webdav\ ...
    迁移前会把现有 storage 改名备份为 storage-backup-时间戳，不会直接覆盖。
.PARAMETER Source
    旧数据目录，通常是旧服务器上的 storage 目录。
.PARAMETER InstallDir
    新安装目录，默认 C:\Reader。
.PARAMETER TaskName
    计划任务名，默认 LegadoReader；存在时会先停止。
.PARAMETER Move
    迁移后删除源目录（默认只复制，保留源数据）。
.PARAMETER Force
    新目录已有数据时仍然继续（旧数据会先备份）。
.EXAMPLE
    .\migrate-data.ps1 -Source "D:\old-reader\storage"
.EXAMPLE
    .\migrate-data.ps1 -Source "\\nas\backup\reader\storage" -InstallDir "C:\Reader" -Move
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Source,
    [string]$InstallDir = "C:\Reader",
    [string]$TaskName = "LegadoReader",
    [switch]$Move,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

function Write-Step([string]$text) { Write-Host ("[*] " + $text) -ForegroundColor Cyan }
function Write-Ok([string]$text) { Write-Host ("[+] " + $text) -ForegroundColor Green }
function Fail([string]$text) { Write-Host ("[x] " + $text) -ForegroundColor Red; exit 1 }

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($identity)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Fail "请以管理员身份运行 migrate-data.bat"
}

if (-not (Test-Path $Source)) {
    Fail ("源目录不存在: " + $Source)
}
# 允许直接传安装目录（其下含 storage）
if ((Test-Path (Join-Path $Source "storage")) -and -not (Test-Path (Join-Path $Source "data"))) {
    $Source = Join-Path $Source "storage"
    Write-Step ("检测到 storage 子目录，使用: " + $Source)
}

$targetStorage = Join-Path $InstallDir "storage"
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null

function Copy-Tree([string]$src, [string]$dst) {
    if (-not (Test-Path $src)) { return }
    New-Item -ItemType Directory -Force -Path $dst | Out-Null
    $null = robocopy $src $dst /E /COPY:DAT /R:1 /W:1 /NFL /NDL /NJH /NJS
    if ($LASTEXITCODE -ge 8) {
        throw ("robocopy 复制失败 (" + $LASTEXITCODE + "): " + $src)
    }
}

# 1. 停服务
$task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($task -and $task.State -eq "Running") {
    Write-Step "停止服务..."
    Stop-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
}

# 2. 备份现有数据
if (Test-Path $targetStorage) {
    $hasData = (Get-ChildItem $targetStorage -Recurse -File -ErrorAction SilentlyContinue | Measure-Object).Count -gt 0
    if ($hasData) {
        if (-not $Force) {
            Fail ("目标已存在数据: " + $targetStorage + "`n确认要覆盖请加 -Force（脚本会自动备份旧数据）。")
        }
        $stamp = Get-Date -Format "yyyyMMddHHmmss"
        $backup = Join-Path $InstallDir ("storage-backup-" + $stamp)
        Write-Step ("备份现有数据到 " + $backup)
        Move-Item $targetStorage $backup
    } else {
        Remove-Item $targetStorage -Recurse -Force
    }
}
New-Item -ItemType Directory -Force -Path $targetStorage | Out-Null

# 3. 判断来源结构
$isNewLayout = Test-Path (Join-Path $Source "data")
$isOldLayout = $false
if (-not $isNewLayout) {
    $rootJson = Get-ChildItem $Source -Filter "*.json" -File -ErrorAction SilentlyContinue
    if ($rootJson -and $rootJson.Count -gt 0) { $isOldLayout = $true }
}
if (-not $isNewLayout -and -not $isOldLayout) {
    Fail ("无法识别数据目录结构，请确认 Source 是旧服务器的 storage 目录。")
}

$copied = 0

if ($isNewLayout) {
    Write-Step "识别为多用户目录结构，整体迁移..."
    Copy-Tree (Join-Path $Source "data") (Join-Path $targetStorage "data")

    foreach ($dir in @("localStore", "assets", "cache")) {
        $src = Join-Path $Source $dir
        if (Test-Path $src) {
            Copy-Tree $src (Join-Path $targetStorage $dir)
        }
    }
    $copied = (Get-ChildItem $targetStorage -Recurse -File | Measure-Object).Count
} else {
    Write-Step "识别为旧版扁平结构，转换到 data\default ..."
    $defaultDir = Join-Path $targetStorage "data\default"
    New-Item -ItemType Directory -Force -Path $defaultDir | Out-Null

    # 用户表位于 storage/data/users.json
    $usersFile = Join-Path $Source "users.json"
    if (Test-Path $usersFile) {
        Copy-Item $usersFile (Join-Path $targetStorage "data\users.json") -Force
    }

    # 其余 json 属于 default 命名空间
    Get-ChildItem $Source -Filter "*.json" -File | Where-Object { $_.Name -ne "users.json" } | ForEach-Object {
        Copy-Item $_.FullName (Join-Path $defaultDir $_.Name) -Force
        $copied++
    }

    # webdav / 本地书仓 / 资源 / 缓存
    foreach ($pair in @(
            @("webdav", (Join-Path $defaultDir "webdav")),
            @("localStore", (Join-Path $targetStorage "localStore")),
            @("assets", (Join-Path $targetStorage "assets")),
            @("cache", (Join-Path $targetStorage "cache"))
        )) {
        $src = Join-Path $Source $pair[0]
        if (Test-Path $src) {
            Copy-Tree $src $pair[1]
        }
    }

    # 旧版 WebDAV 目录可能在 storage 根，也可能在 data 下
    $oldWebdav = Join-Path $Source "webdav"
    if (Test-Path $oldWebdav) {
        Copy-Tree $oldWebdav (Join-Path $defaultDir "webdav")
    }

    $copied = (Get-ChildItem $targetStorage -Recurse -File | Measure-Object).Count
}

if ($Move) {
    Write-Step "删除源目录..."
    Remove-Item $Source -Recurse -Force
    Write-Ok ("已删除源目录 " + $Source)
}

Write-Ok ("迁移完成，共 " + $copied + " 个文件")
Write-Host ("数据目录: " + $targetStorage)
Write-Host ""
Write-Host "下一步："
Write-Host "  1. 运行 start.bat 启动服务"
Write-Host "  2. 打开 http://<服务器IP>:8080 检查书架、书源、WebDAV 文件是否正常"
Write-Host "  3. 确认无误后可删除 storage-backup-* 备份目录"
