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
| `-Secure` | 开启登录 / 多用户模式（迁移旧多用户数据时必须开启） |
| `-SecureKey` | 管理密码，配合 `-Secure` 使用 |
| `-InviteCode` | 注册邀请码，配合 `-Secure` 使用 |

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

### 配置项（端口、登录开关、账号密码）不会随 storage 自动迁移

`storage` 里只有业务数据，端口和登录开关在启动参数/`application.yml` 里，需要重新指定：

| 配置 | 存放位置 | 迁移方式 |
|---|---|---|
| 端口 | `application.yml` / 启动参数 | 安装时用 `-Port 9000` 指定（数据里没有端口） |
| 登录开关 `secure` | `application.yml` | 用 `-Secure` 开启；**旧版开过就必须开** |
| 管理密码 `secureKey` | `application.yml` | `-SecureKey "你的管理密码"` |
| 注册邀请码 `inviteCode` | `application.yml` | `-InviteCode "邀请码"` |
| 用户账号、密码哈希、Token、WebDAV 开关 | `storage/data/users.json` | 随 storage 自动迁移 |
| 每个用户的书架、书源、书签、进度、WebDAV 文件 | `storage/data/<用户名>/` | 随 storage 自动迁移 |
| 本地书仓 | `storage/localStore/` | 随 storage 自动迁移 |
| 自定义样式/资源 | `storage/assets/` | 随 storage 自动迁移 |

**最容易踩的坑**：旧部署如果开了登录（多用户），新部署必须加 `-Secure`，否则服务会以 `secure=false` 运行，只读 `data/default`，原来 `data/<用户名>/` 下的书架会看起来“全部丢失”。

迁移多用户实例的完整命令示例：

```powershell
# 1. 先装好（开启登录，管理密码和旧版保持一致）
.\install.ps1 -Port 8080 -Secure -SecureKey "旧版管理密码" -InviteCode "旧版邀请码"

# 2. 停服务后迁移数据
Stop-ScheduledTask -TaskName LegadoReader
.\migrate-data.ps1 -Source "D:\old-reader\storage" -InstallDir "C:\Reader" -Force

# 3. 启动并用原账号登录
.\start.ps1
```

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

**4.1 还原成功但书架为空**

旧版脚本（2026-10-18 之前生成的 jar）在绝对 `storagePath` 下会把 WebDAV 文件写到进程工作目录，常见位置：

```
C:\Windows\System32\storage
```

处理方式：

1. 停止任务：`Stop-ScheduledTask -TaskName LegadoReader`；
2. 用最新 `reader-cli-2.5.4.jar` 覆盖安装目录的 `reader-cli.jar`（或重新运行最新 `install.bat`）；
3. 把误写目录里的内容复制回来：
   ```powershell
   robocopy C:\Windows\System32\storage C:\Reader\storage /E
   ```
4. 启动后重新点一次「还原」。

**4.2 退出阅读 App 后服务端进度没更新**

先确认服务端有没有收到进度文件：

```
C:\Reader\storage\data\<用户>\webdav\legado\bookProgress\<书名>_<作者>.json
```

看它的修改时间，或访问 `http://<IP>:<端口>/reader3/getBookProgress?url=<bookUrl>`。

常见原因：

1. **App 只在离开阅读页时上传**（`onPause`）。如果停在阅读页直接从最近任务里划掉，上传协程可能来不及完成；建议先返回书架，等 1~2 秒再退出。
2. **安装的是 debug 包**：App 只有在 `!BuildConfig.DEBUG` 时才上传进度，debug 包不会同步。
3. **WebDAV 未初始化或地址/账号错误**：`uploadBookProgress` 在 `authorization == null` 时直接返回，属于静默失败；可在 App 日志里搜“上传进度失败”。
4. **开启了“同步增强”**：退出时会先拉云端进度，若认为云端更靠前就不上传；排查时可临时关闭。
5. **服务端版本较旧**：旧版本按时间戳比较，手机和服务器时钟不一致时会丢弃进度。升级到最新 `reader-cli` 后，PUT 上传的进度一律以 App 为准。

升级后，App 每次通过 WebDAV 上传进度，都会同步刷新「设备管理」里的最近活跃时间和正在读章节（按来源 IP 匹配备份文件名中的设备名）。如果同一公网 IP 下有多台手机，可能只更新其中一台，这是当前识别方式的限制。

另外，App 的进度文件名可能是 `书名_.json`（作者为空），旧版本要求作者也匹配，导致进度文件收到了但书架不更新。新版本会按书名回退匹配；书架里有同名书时取最近阅读的那本。

**5. 安全建议**

- 对外网开放时，建议在 `application.yml`/启动参数里开启 `reader.app.secure=true` 并配置用户，或只在反向代理（Nginx/IIS）后暴露；
- 不要直接把 `storage` 目录暴露为静态站点；
- 定期备份 `storage`。

## 说明

- 本目录使用的是 **CLI 版服务端 jar**（无 JavaFX、无桌面窗口），适合服务器长期运行；
- 桌面用户请使用 Release 里的 `LegadoReader-2.5.4-Setup.exe`；
- 计划任务以 SYSTEM 运行，日志和数据的读写权限由安装目录 ACL 继承。
