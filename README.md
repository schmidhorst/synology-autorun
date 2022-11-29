[![da](https://flagcdn.com/w20/da.png)](https://github.com/schmidhorst/synology-autorun/blob/main/README.da.md)
[![de](https://flagcdn.com/w20/de.png)](https://github.com/schmidhorst/synology-autorun/blob/main/README.de.md)
[![fr](https://flagcdn.com/w20/fr.png)](https://github.com/schmidhorst/synology-autorun/blob/main/README.fr.md)
[![it](https://flagcdn.com/w20/it.png)](https://github.com/schmidhorst/synology-autorun/blob/main/README.it.md)
[![jp](https://flagcdn.com/w20/jp.png)](https://github.com/schmidhorst/synology-autorun/blob/main/README.jp.md)
[![nl](https://flagcdn.com/w20/nl.png)](https://github.com/schmidhorst/synology-autorun/blob/main/README.nl.md)
[![pl](https://flagcdn.com/w20/pl.png)](https://github.com/schmidhorst/synology-autorun/blob/main/README.pl.md)
[![pt-PT](https://flagcdn.com/w20/pt-PT.png)](https://github.com/schmidhorst/synology-autorun/blob/main/README.pt-PT.md)
[![pt-BR](https://flagcdn.com/w20/pt-BR.png)](https://github.com/schmidhorst/synology-autorun/blob/main/README.pt-BR.md)
[![ru](https://flagcdn.com/w20/ru.png)](https://github.com/schmidhorst/synology-autorun/blob/main/README.ru.md)
[![sp](https://flagcdn.com/w20/sp.png)](https://github.com/schmidhorst/synology-autorun/blob/main/README.sp.md)
[![sv](https://flagcdn.com/w20/sv.png)](https://github.com/schmidhorst/synology-autorun/blob/main/README.sv.md)
[![tr](https://flagcdn.com/w20/tr.png)](https://github.com/schmidhorst/synology-autorun/blob/main/README.tr.md)
[![zh](https://flagcdn.com/w20/zh.png)](https://github.com/schmidhorst/synology-autorun/blob/main/README.zh.md)

# autorun
Execute scripts when connecting external storage (USB / eSATA) on a Synology NAS. Typical use is to copy or backup some files. 
In Synologies Task Scheduler there is the posibility to create triggered tasks. But for the trigger event there is only Boot-up and Shutdown available. There are no USB events available. This deficit is compensated by this tool.  

# install
* Download the *.spk file from "Releases", "Assets" in Github and use "Manual Install" in the Package Center.

Under https://www.cphub.net/ in the Package Center there are elder versions for elder DSM versions available:
* DSM 7: actually still only 1.8
* DSM 6: 1.7
* DSM 5: 1.6
* elder: 1.3

Third Party packages are restricted by Synology in DSM 7. Since autorun does require root 
permission to perform its job an additional manual step is required after the installation.

SSH to your NAS (as an admin user) and execute the following command:

```shell
sudo cp /var/packages/autorun/conf/privilege.root /var/packages/autorun/conf/privilege
```
Alternative to SSH: 
Goto Control Panelel => Task Scheduler => Create => Scheduled Task => User-defined Script. In the "General" tab set any task name, select 'root' as user. In the "Task Settings" tab enter  
```shell
cp /var/packages/autorun/conf/privilege.root /var/packages/autorun/conf/privilege
```
as "Run command". Finish it with OK. When you are requested to execute that command now during pckage installation, then go to the task scheduler, select that task and "Run" it. 

