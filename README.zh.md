# autorun
当在Synology NAS上连接外部存储（USB / eSATA）时，执行脚本。典型的用途是复制或备份一些文件。
在Synologies任务调度器中，可以创建触发式任务，但对于触发事件，只有开机和关机可用。没有USB事件可用。这个缺陷可以通过这个工具来弥补。 

# 安装
* 从Github的 "Release", "Assets "下载*.spk文件，并在软件包中心使用 "Manual Install"。

在软件包中心的https://www.cphub.net/，有老版本的DSM老版本可用。
* DSM 7: 实际上仍然只有1.8
* DSM 6: 1.7
* DSM 5: 1.6
* elder。1.3

第三方软件包在DSM 7中被Synology限制。由于自动运行需要root 
权限来执行其工作，因此在安装后需要额外的手动步骤。

SSH到你的NAS（以管理员身份）并执行以下命令。

``shell
sudo cp /var/packages/autorun/conf/privilege.root /var/packages/autorun/conf/privilege
```
替代SSH的方法。
转到控制窗格 => 任务调度器 => 创建 => 预定任务 => 用户定义的脚本。在 "常规 "标签中设置任何任务名称，选择 "root "作为用户。在 "任务设置 "标签中输入  
``shell
cp /var/packages/autorun/conf/privilege.root /var/packages/autorun/conf/privilege
```
作为 "运行命令"。用 "确定 "完成它。当你在软件包安装过程中被要求执行该命令时，就去任务调度器，选择该任务并 "运行 "它。

