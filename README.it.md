# autorun
Esegue gli script quando si collega un dispositivo di archiviazione esterno (USB / eSATA) su un NAS Synology. L'uso tipico è la copia o il backup di alcuni file. 
In Synology Task Scheduler è possibile creare attività attivate, ma per l'evento di attivazione sono disponibili solo l'avvio e lo spegnimento. Non sono disponibili eventi USB. Questa mancanza è compensata da questo strumento.  

# installare
* Scaricare il file *.spk da "Releases", "Assets" in Github e usare "Manual Install" nel Centro pacchetti.

Sotto https://www.cphub.net/ nel Centro Pacchetti sono disponibili le versioni più vecchie per le versioni DSM più vecchie:
* DSM 7: in realtà è ancora solo 1.8
* DSM 6: 1.7
* DSM 5: 1.6
* elder: 1.3

I pacchetti di terze parti sono limitati da Synology in DSM 7. Poiché l'esecuzione automatica richiede i permessi di 
per eseguire il suo lavoro, è necessario un ulteriore passaggio manuale dopo l'installazione.

SSH al NAS (come utente amministratore) ed eseguire il seguente comando:

```shell
sudo cp /var/packages/autorun/conf/privilege.root /var/packages/autorun/conf/privilege
```
Alternativa a SSH: 
Andare su Pannello di controllo => Pianificazione attività => Crea => Attività pianificata => Script definito dall'utente. Nella scheda "Generale" impostare il nome dell'attività, selezionare 'root' come utente. Nella scheda "Impostazioni attività" inserire  
```shell
cp /var/packages/autorun/conf/privilege.root /var/packages/autorun/conf/privilege
```
come "Comando di esecuzione". Terminate con OK. Se durante l'installazione di pckage vi viene richiesto di eseguire quel comando, andate nel task scheduler, selezionate quell'attività ed eseguitela. 

