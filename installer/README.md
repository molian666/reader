# 安装程序构建

产物：`build/installer/LegadoReader-2.5.4-Setup.exe`（约 96 MB，自带精简 JRE，安装到当前用户目录，无需管理员权限）。

## 依赖

- JDK 11（用于 `jlink` 生成运行时、`bootJar` 打包）
- Inno Setup 6（`ISCC.exe`，默认安装在 `%LOCALAPPDATA%\Programs\Inno Setup 6`）

## 步骤

```powershell
$env:JAVA_HOME = "D:\VibeCoding\tools\jdk-11.0.2"
$env:Path = "$env:JAVA_HOME\bin;$env:Path"

# 1. 构建包含前端资源的可执行 jar
gradle.bat --no-daemon bootJar -x test

# 2. 用 jlink 生成精简运行时（约 41 MB）
jlink --module-path "$env:JAVA_HOME\jmods" `
  --add-modules java.base,java.desktop,java.logging,java.management,java.naming,java.net.http,java.prefs,java.scripting,java.security.jgss,java.sql,java.xml,jdk.crypto.ec,jdk.management,jdk.unsupported,jdk.zipfs `
  --strip-debug --no-header-files --no-man-pages --compress=2 `
  --output build\dist\runtime

# 3. 组装目录
New-Item -ItemType Directory -Force build\dist\app
Copy-Item build\libs\reader-2.5.4.jar build\dist\app\reader.jar

# 4. 编译启动器
csc /nologo /target:winexe /out:build\dist\Reader.exe `
  /win32icon:assets\windows\reader.ico installer\ReaderLauncher.cs

# 5. 编译安装包
& "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe" installer\installer.iss
```

## 说明

- 安装包未做代码签名，Windows SmartScreen 可能提示“已保护你的电脑”，选择“更多信息 → 仍要运行”即可。
- 安装目录：`%LOCALAPPDATA%\LegadoReader`；数据写在安装目录的 `storage` 下，卸载时会一并删除。
- 启动器 `Reader.exe` 会调用 `runtime\bin\javaw.exe -jar app\reader.jar`，工作目录为安装目录。
