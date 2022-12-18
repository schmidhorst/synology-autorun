# 适用于Synology NAS 的自动运行包
在使用DSM 7.x的Synology NAS上连接外部存储设备（USB / eSATA）时执行脚本。
在Synologies任务调度器中，有可能创建被触发的任务。但是对于触发事件，只有开机和关机可以使用。没有USB事件可用。这个缺陷可以通过这个工具来弥补。

## 免责声明和问题跟踪器
你使用这里的一切，风险自负。
对于问题，请使用德语或英语的[问题跟踪器](https://github.com/schmidhorst/synology-autorun/issues)。

# 安装
*从["Release"](https://github.com/schmidhorst/synology-autorun/releases)的 "Assets "下载*.spk文件到你的电脑，并在软件包中心使用 "Manual Install"。

第三方软件包在DSM 7中被Synology限制。由于自动运行需要root
权限来执行它的工作，所以在安装后需要额外的手动步骤。

SSH到你的NAS（以管理员身份）并执行以下命令。
``shell
sudo cp /var/packages/autorun/conf/privilege.root /var/packages/autorun/conf/privilege
```
替代SSH的方法。
进入控制面板 => 任务调度器 => 创建 => 预定任务 => 用户定义的脚本。在 "常规 "选项卡中设置任何任务名称，选择 "root "作为用户。在 "任务设置 "标签中输入
```shell
cp /var/packages/autorun/conf/privilege.root /var/packages/autorun/conf/privilege
```
作为 "运行命令"。用 "确定 "完成它。当你在软件包安装过程中被要求执行该命令时，就去任务调度器，选择该任务并 "运行 "它。

在软件包中心的https://www.cphub.net/，有[旧版本](https://github.com/reidemei/synology-autorun)可用于旧的DSM版本。
* DSM 7: 实际上仍然只有1.8
* DSM 6: 1.7
* DSM 5: 1.6
* elder: 1.3

## 贡献和参考文献
- 感谢[Jan Reidemeister](https://github.com/reidemei)的[1.8版](https://github.com/reidemei/synology-autorun)和他的[许可证](https://github.com/reidemei/synology-autorun/blob/main/LICENSE)
- 感谢[Synology论坛关于自动运行包的主题](https://www.synology-forum.de/threads/autorun-fuer-ext-datentraeger.18360/)
- 感谢 [toafez Tommes](https://github.com/toafez) 和他的 [Demo Package](https://github.com/toafez/DSM7DemoSPK)
- 感谢[geimist Stephan Geisler](https://github.com/geimist)和他提供的使用[DeepL API](https://www.deepl.com/docs-api)进行其他语言翻译的建议。


