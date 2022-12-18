# Autorun-Paket für Synology NAS
Führt Skripte aus, wenn externe Speicher (USB / eSATA) an ein Synology NAS mit DSM 7.x angeschlossen werden. Typische Anwendung ist das Kopieren oder Sichern von Dateien.
In Synologies Task Scheduler gibt es die Möglichkeit, ausgelöste Aufgaben zu erstellen. Aber für das Trigger-Ereignis sind nur Boot-up und Shutdown verfügbar. Es sind keine USB-Ereignisse verfügbar. Dieses Defizit wird durch dieses Tool ausgeglichen.

## Haftungsausschluss und Issue Tracker
Sie benutzen alles hier auf eigenes Risiko.
Für Probleme benutzen Sie bitte den [issue tracker](https://github.com/schmidhorst/synology-autorun/issues) mit deutscher oder englischer Sprache

# Installation
* Laden Sie die *.spk-Datei von ["Releases"](https://github.com/schmidhorst/synology-autorun/releases), "Assets" auf Ihren Computer herunter und verwenden Sie "Manual Install" im Package Center.

Pakete von Drittanbietern werden von Synology in DSM 7 eingeschränkt. Da Autorun Root-Rechte benötigt
Berechtigung benötigt, um seine Aufgabe zu erfüllen, ist nach der Installation ein zusätzlicher manueller Schritt erforderlich.

Verbinden Sie sich per SSH mit Ihrem NAS (als Admin-Benutzer) und führen Sie den folgenden Befehl aus:
```shell
sudo cp /var/packages/autorun/conf/privilege.root /var/packages/autorun/conf/privilege
```
Alternative zu SSH:
Gehen Sie zu Systemsteuerung => Aufgabenplaner => Erstellen => Geplante Aufgabe => Benutzerdefiniertes Skript. In der Registerkarte "Allgemein" geben Sie einen beliebigen Aufgabennamen ein und wählen Sie "root" als Benutzer. In der Registerkarte "Aufgabeneinstellungen" geben Sie ein
```shell
cp /var/packages/autorun/conf/privilege.root /var/packages/autorun/conf/privilege
```
als "Befehl ausführen" ein. Beenden Sie es mit OK. Wenn Sie nun während der Paketinstallation aufgefordert werden, diesen Befehl auszuführen, gehen Sie in den Aufgabenplaner, wählen Sie diese Aufgabe aus und "Ausführen" sie.

Unter https://www.cphub.net/ im Package Center sind [ältere Versionen](https://github.com/reidemei/synology-autorun) für ältere DSM Versionen verfügbar:
* DSM 7: eigentlich nur noch 1.8
* DSM 6: 1.7
* DSM 5: 1.6
* elder: 1.3

## Danksagungen und Referenzen
- Dank an [Jan Reidemeister](https://github.com/reidemei) für seine [Version 1.8](https://github.com/reidemei/synology-autorun) und seine [Lizenz](https://github.com/reidemei/synology-autorun/blob/main/LICENSE)
- Dank an den [Synology Forum Thread über das Autorun-Paket](https://www.synology-forum.de/threads/autorun-fuer-ext-datentraeger.18360/)
- Dank an [toafez Tommes](https://github.com/toafez) und sein [Demo-Paket](https://github.com/toafez/DSM7DemoSPK)
- Dank an [geimist Stephan Geisler](https://github.com/geimist) und den Tipp, die [DeepL API](https://www.deepl.com/docs-api) für Übersetzungen in andere Sprachen zu verwenden.



Übersetzt mit www.DeepL.com/Translator (kostenlose Version)

