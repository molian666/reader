# Windows 服务器一键部署

适用于 **Windows Server 2012 R2 / 2016 / 2019 / 2022**（x64），也适用于 Windows 10/11。
不需要安装 Java：脚本会下载项目自带精简 JRE，并以 **计划任务（开机自启，SYSTEM 账户）** 方式运行无界面服务端。

## 一键安装

1. 把整个 `windows-server` 目录复制到服务器；
2. 右键 **`install.bat` → 以管理员身份运行**；
3. 等待脚本下载并启动，看到 `部署完成` 即可访问：

```
http://<服务器IP>:8080
```

默认参数：

| 项目 | 默认值 |
|---|---|
| 安装目录 | `C:\Reader` |
| 端口 | `8080` |
| 计划任务名 | `LegadoReader` |
| 数据目录 | `C:\Reader\storage` |
| 日志目录 | `C:\Reader\logs` |

## 离线安装

服务器不能访问外网时，先把两个文件下载到 `windows-server` 目录，再运行 `install.bat`：

- `reader-cli-2.5.4.jar`（服务端 jar，约 38 MB）
- `reader-runtime-win64.zip`（精简 JRE，约 30 MB）

脚本会优先使用脚本同目录的这两个文件，不会联网。

## 自定义参数

用 PowerShell 直接运行：

```powershell
.\install.ps1 -InstallDir "D:\Reader" -Port 9000 -TaskName "Reader"
```

| 参数 | 说明 |
|---|---|
| `-InstallDir` | 安装目录 |
| `-Port` | 监听端口，自动加防火墙规则 |
| `-TaskName` | 计划任务名称 |
| `-JarPath` / `-RuntimeZip` | 指定离线包路径 |
| `-DownloadBase` | 下载地址前缀（默认当前 Release） |
| `-NoFirewall` | 不创建防火墙规则（由硬件防火墙统一管理时使用） |

## 日常管理

| 操作 | 命令 |
|---|---|
| 启动 | `start.bat`（管理员） |
| 停止 | `stop.bat`（管理员） |
| 查看状态/日志路径 | `status.bat` |
| 卸载 | `uninstall.bat`（管理员，默认保留数据） |
| 彻底删除 | `uninstall.ps1 -RemoveData` |

也可以用系统自带命令：

```powershell
Start-ScheduledTask -TaskName LegadoReader
Stop-ScheduledTask  -TaskName LegadoReader
Get-ScheduledTask   -TaskName LegadoReader
```

## 升级

1. 下载新的 `reader-cli-<版本>.jar`；
2. 覆盖到 `C:\Reader\reader-cli.jar`（先 `stop.bat`）；
3. `start.bat` 启动。

或直接重新运行 `install.bat`（脚本会停旧任务、替换 jar、重建任务并启动）。

## 迁移旧数据

所有持久化数据都在 `storage` 目录（纯 JSON 文件，没有数据库），可以直接继承。

### 从旧版 reader 服务器迁移

把旧服务器的 `storage` 目录拷到本机，然后：

```powershell
.\migrate-data.ps1 -Source "D:\old-reader\storage" -InstallDir "C:\Reader"
```

或双击 `migrate-data.bat`，按提示输入旧 `storage` 路径。

脚本会：

- 自动识别「新版多用户结构（`data\<用户>\`）」或「旧版扁平结构（根目录 `bookshelf.json` 等）」；
- 旧结构会转换到 `data\default\`，`users.json` 放到 `data\`，`localStore` / `assets` / `cache` 归位；
- 迁移前把现有 `storage` 备份为 `storage-backup-时间戳`；
- 默认只复制，加 `-Move` 才删除源目录；目录已有数据时需加 `-Force`。

迁移完成后 `start.bat`，打开页面确认书架、书源、WebDAV 文件都在。

### 从桌面安装版迁移

停掉桌面程序，把 `%LOCALAPPDATA%\LegadoReader\storage` 复制到 `C:\Reader\storage` 即可（结构完全一致）。

### 从 Docker 迁移

把容器挂载的 storage 卷目录复制出来，按上面的方式迁移。

### 从阅读 App 迁移

不需要搬目录：App 里「备份到 WebDAV」→ Web 端左侧菜单「WebDAV → 文件管理」找到备份 zip →「还原」。
阅读进度会随 `bookProgress/*.json` 一起同步。

> 注意：旧版本如果用的是未转义的进度文件名（书名含 `? : / \` 等字符），App 可能匹配不到对应文件，需要按 App 规则重命名；普通书名不受影响。

## 目录结构

```
C:\Reader
├─ reader-cli.jar        # 服务端（无界面）
├─ runtime\              # 精简 JRE 11
├─ storage\              # 书架、书源、WebDAV 文件、配置
│  ├─ data\default\
│  └─ localStore\
├─ logs\
│  ├─ spring.log         # 应用日志
│  └─ console.log
└─ uninstall 相关脚本（部署目录里的那些 .bat/.ps1）
```

## 常见问题

**1. 下载失败 / TLS 错误**

Server 2012 R2 需要 .NET Framework 4.5 以上并启用 TLS 1.2。脚本已主动设置 TLS 1.2；仍失败时请用「离线安装」，或先在服务器上安装系统补丁 KB3140245。

**2. 端口被占用**

```powershell
netstat -ano | findstr :8080
```

换端口：`.\install.ps1 -Port 9000`，脚本会自动更新任务和防火墙规则。

**3. 启动超时**

查看 `C:\Reader\logs\spring.log`；也可确认任务是否在运行：

```powershell
Get-ScheduledTaskInfo -TaskName LegadoReader
```

**4. 数据和 WebDAV**

数据全部在 `storage` 下。迁移服务器时，停服务后复制整个 `storage` 目录即可。
App 的 WebDAV 地址填 `http://<服务器IP>:<端口>/reader3/webdav/`，子目录保持 `legado`。

**5. 安全建议**

- 对外网开放时，建议在 `application.yml`/启动参数里开启 `reader.app.secure=true` 并配置用户，或只在反向代理（Nginx/IIS）后暴露；
- 不要直接把 `storage` 目录暴露为静态站点；
- 定期备份 `storage`。

## 说明

- 本目录使用的是 **CLI 版服务端 jar**（无 JavaFX、无桌面窗口），适合服务器长期运行；
- 桌面用户请使用 Release 里的 `LegadoReader-2.5.4-Setup.exe`；
- 计划任务以 SYSTEM 运行，日志和数据的读写权限由安装目录 ACL 继承。
