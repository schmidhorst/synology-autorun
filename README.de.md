# autorun
Führt Skripte aus, wenn ein externer Speicher (USB / eSATA) an ein Synology NAS angeschlossen wird. Typische Anwendung ist das Kopieren oder Sichern einiger Dateien. 
In Synologies Taskplaner gibt es die Möglichkeit, getriggerte Aufgaben zu erstellen, aber für das Trigger-Ereignis sind nur Boot-up und Shutdown verfügbar. Es sind keine USB-Ereignisse verfügbar. Dieses Defizit wird durch dieses Tool kompensiert.  

# installieren
* Laden Sie die *.spk Datei von "Releases", "Assets" in Github herunter und verwenden Sie "Manual Install" im Package Center.

Pakete von Drittanbietern werden von Synology im DSM 7 eingeschränkt. Da Autorun Root-Rechte benötigt 
Berechtigung benötigt, um seine Aufgabe zu erfüllen, ist nach der Installation ein zusätzlicher manueller Schritt erforderlich.

Verbinden Sie sich per SSH mit Ihrem NAS (als Admin-Benutzer) und führen Sie den folgenden Befehl aus:

```shell
sudo cp /var/packages/autorun/conf/privilege.root /var/packages/autorun/conf/privilege
```
Alternative zu SSH: 
Gehen Sie auf Control Panel => Task Scheduler => Create => Scheduled Task => User-defined Script. In der Registerkarte "Allgemein" geben Sie einen beliebigen Aufgabennamen ein und wählen "root" als Benutzer. In der Registerkarte "Aufgabeneinstellungen" geben Sie ein  
```shell
cp /var/packages/autorun/conf/privilege.root /var/packages/autorun/conf/privilege
```
als "Befehl ausführen" ein. Beenden Sie es mit OK. Wenn Sie nun während der Paketinstallation aufgefordert werden, diesen Befehl auszuführen, gehen Sie zum Aufgabenplaner, wählen Sie diese Aufgabe aus und führen Sie sie aus. 

Unter https://www.cphub.net/ im Package Center gibt es ältere Versionen für ältere DSM-Versionen:
* DSM 7: aktuell nur noch 1.8
* DSM 6: 1.7
* DSM 5: 1.6
* elder: 1.3

Übersetzt mit www.DeepL.com/Translator (kostenlose Version)
