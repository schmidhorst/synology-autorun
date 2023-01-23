[![da](https://flagcdn.com/w20/dk.png)](https://github.com/schmidhorst/synology-autorun/blob/main/README.da.md)
[![de](https://flagcdn.com/w20/de.png)](https://github.com/schmidhorst/synology-autorun/blob/main/README.de.md)
[![fr](https://flagcdn.com/w20/fr.png)](https://github.com/schmidhorst/synology-autorun/blob/main/README.fr.md)
[![it](https://flagcdn.com/w20/it.png)](https://github.com/schmidhorst/synology-autorun/blob/main/README.it.md)
[![jp](https://flagcdn.com/w20/jp.png)](https://github.com/schmidhorst/synology-autorun/blob/main/README.jp.md)
[![nl](https://flagcdn.com/w20/nl.png)](https://github.com/schmidhorst/synology-autorun/blob/main/README.nl.md)
[![pl](https://flagcdn.com/w20/pl.png)](https://github.com/schmidhorst/synology-autorun/blob/main/README.pl.md)
[![pt-PT](https://flagcdn.com/w20/pt.png)](https://github.com/schmidhorst/synology-autorun/blob/main/README.pt-PT.md)
[![pt-BR](https://flagcdn.com/w20/br.png)](https://github.com/schmidhorst/synology-autorun/blob/main/README.pt-BR.md)
[![ru](https://flagcdn.com/w20/ru.png)](https://github.com/schmidhorst/synology-autorun/blob/main/README.ru.md)
[![sp](https://flagcdn.com/w20/es.png)](https://github.com/schmidhorst/synology-autorun/blob/main/README.sp.md)
[![sv](https://flagcdn.com/w20/sv.png)](https://github.com/schmidhorst/synology-autorun/blob/main/README.sv.md)
[![tr](https://flagcdn.com/w20/tr.png)](https://github.com/schmidhorst/synology-autorun/blob/main/README.tr.md)
[![zh](https://flagcdn.com/w20/cn.png)](https://github.com/schmidhorst/synology-autorun/blob/main/README.zh.md)

# autorun package V1.10 for Synology NAS
Executes a script when connecting external storages (USB / eSATA) on a Synology NAS with DSM 7.x. Typical use is to copy or backup some files.
In Synologies Task Scheduler there is the possibility to create triggered tasks. But for the trigger event there are only Boot-up and Shutdown available. There are no USB events available. This deficit is compensated by this tool.

## [License](https://htmlpreview.github.io/?https://github.com/schmidhorst/synology-autorun/blob/main/package/ui/licence_enu.html)

## Disclaimer and Issue Tracker
You are using everything here at your own risk.
For issues please use the [issue tracker](https://github.com/schmidhorst/synology-autorun/issues) with German or English language

# Build and Installation
* If you want to build the package yourself from the source: Download all files. Set the file 'build' in the root folder to executable and run that script to generate the *.spk file.
* Or download the *.spk file from ["Releases"](https://github.com/schmidhorst/synology-autorun/releases), "Assets" to your computer.

Then use "Manual Install" in the Package Center.

Third Party packages are restricted by Synology in DSM 7. Since autorun does require root permission to perform its job an additional manual step is required after the installation before a "Run" can be done successfully.

SSH to your NAS (as an admin user) and execute the following command:
```shell
sudo cp /var/packages/autorun/conf/privilege.root /var/packages/autorun/conf/privilege
```
Alternative to SSH:
Go to Control Panel => Task Scheduler => Create => Scheduled Task => User-defined Script. In the "General" tab set any task name, select 'root' as user. In the "Task Settings" tab enter
```shell
cp /var/packages/autorun/conf/privilege.root /var/packages/autorun/conf/privilege
```
as "Run command". Finish it with OK. When you are requested to execute that command now during package installation, then go to the task scheduler, select that task and "Run" it.

Under https://www.cphub.net/ in the Package Center there are [elder versions](https://github.com/reidemei/synology-autorun) for elder DSM versions available:
* DSM 7: 1.8
* DSM 6: 1.7
* DSM 5: 1.6
* elder: 1.3

## Credits and References
- Thanks to [Jan Reidemeister](https://github.com/reidemei) for his [Version 1.8](https://github.com/reidemei/synology-autorun) and his [License](https://github.com/reidemei/synology-autorun/blob/main/LICENSE)
- Thanks to the [Synology Forum Thread about that autorun package](https://www.synology-forum.de/threads/autorun-fuer-ext-datentraeger.18360/)
- Thanks to [toafez Tommes](https://github.com/toafez) and his [Demo Package](https://github.com/toafez/DSM7DemoSPK)
- Thanks to  [geimist Stephan Geisler](https://github.com/geimist) and hit tip to use the [DeepL API](https://www.deepl.com/docs-api) for translations to other languages.

