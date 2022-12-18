# Pacchetto di esecuzione automatica per Synology NAS
Esegue gli script quando si collegano archivi esterni (USB / eSATA) su un Synology NAS con DSM 7.x. L'uso tipico è la copia o il backup di alcuni file.
In Synology Task Scheduler esiste la possibilità di creare attività attivate. Ma per l'evento di attivazione sono disponibili solo l'avvio e lo spegnimento. Non sono disponibili eventi USB. Questo deficit è compensato da questo strumento.

## Disclaimer e tracciamento dei problemi
L'utilizzo di questo strumento è a proprio rischio e pericolo.
Per i problemi si prega di utilizzare il [issue tracker](https://github.com/schmidhorst/synology-autorun/issues) in lingua tedesca o inglese.

# Installazione
* Scaricare il file *.spk da ["Releases"](https://github.com/schmidhorst/synology-autorun/releases), "Assets" sul computer e utilizzare "Manual Install" nel Centro pacchetti.

I pacchetti di terze parti sono limitati da Synology in DSM 7. Poiché l'esecuzione automatica richiede i permessi di
per eseguire il suo lavoro, è necessario un ulteriore passaggio manuale dopo l'installazione.

SSH al NAS (come utente amministratore) ed eseguire il seguente comando:
```shell
sudo cp /var/packages/autorun/conf/privilege.root /var/packages/autorun/conf/privilege
```
Alternativa a SSH:
Andare a Pannello di controllo => Pianificazione attività => Crea => Attività pianificata => Script definito dall'utente. Nella scheda "Generale" impostare il nome dell'attività, selezionare 'root' come utente. Nella scheda "Impostazioni attività" inserire
```shell
cp /var/packages/autorun/conf/privilege.root /var/packages/autorun/conf/privilege
```
come "Comando di esecuzione". Terminate con OK. Se durante l'installazione del pacchetto vi viene richiesto di eseguire quel comando, andate nel task scheduler, selezionate l'attività ed eseguitela.

In https://www.cphub.net/ nel Centro pacchetti sono disponibili [versioni più vecchie](https://github.com/reidemei/synology-autorun) per le versioni DSM più vecchie:
* DSM 7: in realtà ancora solo 1.8
* DSM 6: 1.7
* DSM 5: 1.6
* elder: 1.3

## Crediti e riferimenti
- Grazie a [Jan Reidemeister](https://github.com/reidemei) per la sua [Versione 1.8](https://github.com/reidemei/synology-autorun) e la sua [Licenza](https://github.com/reidemei/synology-autorun/blob/main/LICENSE)
- Grazie al [Thread del forum Synology su quel pacchetto di autorun](https://www.synology-forum.de/threads/autorun-fuer-ext-datentraeger.18360/)
- Grazie a [toafez Tommes](https://github.com/toafez) e al suo [Pacchetto demo](https://github.com/toafez/DSM7DemoSPK)
- Grazie a [geimist Stephan Geisler](https://github.com/geimist) e al suggerimento di usare le [DeepL API](https://www.deepl.com/docs-api) per le traduzioni in altre lingue.

