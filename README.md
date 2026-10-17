# reader

阅读3服务器版，不需要手机。

加入TG群(限时开放) 👉 [https://t.me/+pQ8HDlANPZ84ZWNl](https://t.me/+pQ8HDlANPZ84ZWNl)

关注公众号，查看教程和书源👇

![](imgs/mpcode.png)


> 注意❗️
>
> Reader 完整源码仅开放到 v2.5.4，新版本当前仅开放部分开源源码，见 https://github.com/hectorqin/reader-legado.

<details><summary>免责声明（Disclaimer）</summary>
阅读是一款提供网络文学搜索的工具，为广大网络文学爱好者提供一种方便、快捷舒适的试读体验。

当您搜索一本书的时，阅读会将该书的书名以关键词的形式提交到各个第三方网络文学网站。各第三方网站返回的内容与阅读无关，阅读对其概不负责，亦不承担任何法律责任。任何通过使用阅读而链接到的第三方网页均系他人制作或提供，您可能从第三方网页上获得其他服务，阅读对其合法性概不负责，亦不承担任何法律责任。第三方搜索引擎结果根据您提交的书名自动搜索获得并提供试读，不代表阅读赞成或被搜索链接到的第三方网页上的内容或立场。您应该对使用搜索引擎的结果自行承担风险。

阅读不做任何形式的保证：不保证第三方搜索引擎的搜索结果满足您的要求，不保证搜索服务不中断，不保证搜索结果的安全性、正确性、及时性、合法性。因网络状况、通讯线路、第三方网站等任何原因而导致您不能正常使用阅读，阅读不承担任何法律责任。阅读尊重并保护所有使用阅读用户的个人隐私权，您注册的用户名、电子邮件地址等个人资料，非经您亲自许可或根据相关法律、法规的强制性规定，阅读不会主动地泄露给第三方。

阅读致力于最大程度地减少网络文学阅读者在自行搜寻过程中的无意义的时间浪费，通过专业搜索展示不同网站中网络文学的最新章节。阅读在为广大小说爱好者提供方便、快捷舒适的试读体验的同时，也使优秀网络文学得以迅速、更广泛的传播，从而达到了在一定程度促进网络文学充分繁荣发展之目的。阅读鼓励广大小说爱好者通过阅读发现优秀网络小说及其提供商，并建议阅读正版图书。任何单位或个人认为通过阅读搜索链接到的第三方网页内容可能涉嫌侵犯其信息网络传播权，应该及时向阅读提出书面权力通知，并提供身份证明、权属证明及详细侵权情况证明。阅读在收到上述法律文件后，将会依法尽快断开相关链接内容。
</details>

<details><summary>功能说明</summary>
  书源管理 <br/>
- 书架管理 <br/>
- 书架布局 <br/>
- 搜索 <br/>
- 书海 <br/>
- 看书 <br/>
- 移动端适配 <br/>
- 换源 <br/>
- 翻页方式 <br/>
- 手势支持 <br/>
- 自定义主题 <br/>
- 自定义样式 <br/>
- WebDAV同步 <br/>
- 文字替换过滤 <br/>
- 听书<仅部分浏览器支持，手机端会因为锁屏而失效> <br/>
- 用户配置备份恢复 <br/>
- 支持漫画 <br/>
- 支持音频 <br/>
- 书源失效检测 <br/>
- 导入本地TXT、EPUB、UMD、PDF格式的书籍 <br/>
- 书籍分组 <br/>
- RSS订阅 <br/>
- 定时更新书架 <br/>
- 并发搜书 <br/>
- 本地书仓 <br/>
- 支持kindle阅读 <br/>
</details>

## 下载与安装

详见[文档](https://github.com/hectorqin/reader/blob/master/doc.md)

## Windows 安装包

- `LegadoReader-2.5.4-Setup.exe`：自带精简 JRE，按当前用户安装到 `%LOCALAPPDATA%\LegadoReader`，创建开始菜单快捷方式，无需管理员权限。
- `LegadoReader-2.5.4-portable.zip`：解压后运行 `Reader.exe`，数据保存在同目录 `storage`。
- 安装包未做代码签名，SmartScreen 提示时选择「更多信息 → 仍要运行」。

安装包构建方法见 [installer/README.md](installer/README.md)，发布说明见 [RELEASE_NOTES.md](RELEASE_NOTES.md)。

## Windows Server 一键部署

`deploy/windows-server/` 提供适用于 **Windows Server 2012 R2 / 2016 / 2019 / 2022** 的部署脚本：

1. 把 `deploy/windows-server` 目录复制到服务器；
2. 右键 **`install.bat` → 以管理员身份运行**；
3. 默认安装到 `C:\Reader`、端口 `8080`，注册开机自启计划任务，自带精简 JRE，无需预装 Java。

管理命令：`start.bat` / `stop.bat` / `status.bat` / `uninstall.bat`。
离线部署、自定义端口与目录、升级方法见 [deploy/windows-server/README.md](deploy/windows-server/README.md)。

> 服务器使用无界面的 `reader-cli-2.5.4.jar`（不含 JavaFX），桌面版仍使用上面的安装包。

## 本地构建与运行

需要 JDK 11 与 Node.js（建议 16 及以上）。

```bash
cd web
npm install
npm run build
# 把前端产物同步到服务端静态资源目录
rm -rf ../src/main/resources/web && mv dist ../src/main/resources/web

cd ..
./gradlew bootRun
```

Windows 使用 `gradlew.bat bootRun`。启动后访问 http://localhost:8080 ，默认不开启登录（`reader.app.secure=false`）。

前端依赖已通过 `overrides` 锁定 `lodash 4.17.21`、`lodash.template 4.5.0`：新版 lodash 会让 workbox 生成 service worker 时报 `assignWith is not defined`，导致 `npm run build` 失败。

## 与阅读 App 同步（含 legado-with-MD3）

- App 的 WebDAV 地址填 `http://<服务器地址>:8080/reader3/webdav/`，子目录保持默认 `legado`。
- Web 端阅读进度会写入 `legado/bookProgress/<书名>_<作者>.json`，文件名、字段与 App 的规则一致；App 打开书籍时会按该进度续读。
- App 上传的进度文件（`bookProgress/*.json`）会即时同步到服务端书架，Web 端打开书即从上次位置继续。
- 左侧菜单的 WebDAV 里点“保存备份”，会把服务端书架、书源、分组、书签等写成 `backup<日期>-reader.zip`，App 可在恢复列表里选择；没有 App 备份时也会直接生成。
- 阅读页左侧工具栏有同步状态：`同步中 / 已同步 / 待同步`，点一下可立即同步；网络失败会进入待同步队列，联网或 30 秒后自动重试。
- 打开书籍时若云端进度更新，顶部会提示“已同步其它设备进度：第 X 章”，8 秒内可点“撤销”回到原来的位置。
- 两端都在最近 10 分钟内读过、且章节相差 2 章以上时，会弹窗让用户选择“使用云端进度”或“保留当前进度”，不再直接覆盖。
- 左侧菜单 WebDAV 里的“设备管理”会列出所有设备（Web 浏览器按 UA 命名，App 按备份文件名识别），显示最近活跃时间、正在读的章节，可移除设备。
- 左侧菜单 WebDAV 里的“同步自检”会列出 WebDAV 目录、App 应填写的地址、进度目录是否可写、进度文件数量与最近写入时间、备份数量与最新备份。
- 书架右上角可在“单列列表 / 多列网格”之间切换，选择保存在浏览器本地。

## 问题

- 部分使用了 `Javascript` 的书源可能会报错，如调用原生java等高级Javascript功能
- `webview` 功能需要另外部署接口，不支持 `sourceRegex` 匹配资源响应
- 不支持书源登录功能

## 感谢

- 项目初期参考了 [lightink-小说API](https://github.com/lightink-qingmo/lightink-server)
- [阅读](https://github.com/gedoor/MyBookshelf)
- [阅读3.0](https://github.com/gedoor/legado)
- 项目初期参考了 [阅读3.0Web端](https://github.com/celetor/web-yuedu3)

## 其它

- [帮助文档](https://github.com/hectorqin/reader/blob/master/doc.md)
- [界面预览](https://github.com/hectorqin/reader/blob/master/preview.md)
